import 'dart:convert';
import 'dart:io';

import 'package:hive_ce/hive.dart';
import 'package:mosquito_alert/mosquito_alert.dart';
import 'package:mosquito_alert_app/features/bites/data/bite_repository.dart';
import 'package:mosquito_alert_app/features/bites/domain/models/bite_report.dart';
import 'package:mosquito_alert_app/features/breeding_sites/data/breeding_site_repository.dart';
import 'package:mosquito_alert_app/features/breeding_sites/domain/models/breeding_site_report.dart';
import 'package:mosquito_alert_app/features/observations/data/observation_repository.dart';
import 'package:mosquito_alert_app/features/observations/domain/models/observation_report.dart';
import 'package:mosquito_alert_app/features/reports/domain/models/base_report.dart';
import 'package:mosquito_alert_app/features/reports/domain/models/photo.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> migrateLegacyLocalReports() async {
  final prefs = await SharedPreferences.getInstance();
  final savedReports = List<String>.from(
    prefs.getStringList('reportsList') ?? const <String>[],
  );
  final savedImages = List<String>.from(
    prefs.getStringList('imagesList') ?? const <String>[],
  );

  if (savedReports.isEmpty && savedImages.isEmpty) {
    return;
  }

  final remainingReports = <String>[];
  final remainingImages = <String>[];
  final imagesByVersion = <String, List<_LegacySavedImage>>{};

  for (final rawImage in savedImages) {
    final image = _LegacySavedImage.tryParse(rawImage);
    if (image == null || image.versionUuid == null) {
      remainingImages.add(rawImage);
      continue;
    }
    imagesByVersion.putIfAbsent(image.versionUuid!, () => []).add(image);
  }

  for (final rawReport in savedReports) {
    final reportJson = _decodeJsonObject(rawReport);
    if (reportJson == null) {
      remainingReports.add(rawReport);
      continue;
    }

    final versionUuid = _nullableString(reportJson['version_UUID']);
    final linkedImages = versionUuid != null
        ? imagesByVersion.remove(versionUuid) ?? const <_LegacySavedImage>[]
        : const <_LegacySavedImage>[];

    try {
      final migratedReport = _LegacyReportMigrator(
        reportJson,
      ).migrate(linkedImages: linkedImages);
      if (migratedReport == null) {
        remainingReports.add(rawReport);
        remainingImages.addAll(linkedImages.map((image) => image.raw));
        continue;
      }
      await _storeMigratedReport(migratedReport);
    } catch (_) {
      remainingReports.add(rawReport);
      remainingImages.addAll(linkedImages.map((image) => image.raw));
    }
  }

  for (final orphanImages in imagesByVersion.values) {
    remainingImages.addAll(orphanImages.map((image) => image.raw));
  }

  await prefs.setStringList('reportsList', remainingReports);
  await prefs.setStringList('imagesList', remainingImages);
}

Future<void> _storeMigratedReport(BaseReportModel report) async {
  switch (report) {
    case ObservationReport observation:
      await Hive.box<ObservationReport>(
        ObservationRepository.itemBoxName,
      ).put(observation.localId, observation);
    case BiteReport bite:
      await Hive.box<BiteReport>(
        BiteRepository.itemBoxName,
      ).put(bite.localId, bite);
    case BreedingSiteReport breedingSite:
      await Hive.box<BreedingSiteReport>(
        BreedingSiteRepository.itemBoxName,
      ).put(breedingSite.localId, breedingSite);
  }
}

Map<String, dynamic>? _decodeJsonObject(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return null;
    }
    return decoded.map((key, value) => MapEntry(key.toString(), value));
  } catch (_) {
    return null;
  }
}

class _LegacyReportMigrator {
  final Map<String, dynamic> reportJson;

  const _LegacyReportMigrator(this.reportJson);

  BaseReportModel? migrate({required List<_LegacySavedImage> linkedImages}) {
    final type = _nullableString(reportJson['type']);
    final localId = _nullableString(reportJson['version_UUID']);
    final createdAt = _parseDateTime(
      reportJson['creation_time'] ??
          reportJson['version_time'] ??
          reportJson['phone_upload_time'],
    );
    final location = _buildLocation(reportJson);

    if (type == null ||
        localId == null ||
        createdAt == null ||
        location == null) {
      return null;
    }

    final photos = _buildPhotos(linkedImages: linkedImages);
    final userUuid = _nullableString(reportJson['user']);
    final note = _nullableString(reportJson['note']);

    switch (type) {
      case 'adult':
        return ObservationReport(
          localId: localId,
          uuid: null,
          shortId: _nullableString(reportJson['report_id']),
          userUuid: userUuid,
          createdAt: createdAt,
          location: location,
          note: note,
          photos: photos,
          eventEnvironment: _mapObservationEnvironment(
            _findFirstAnswerId(questionId: 13),
          ),
          eventMoment: null,
        );
      case 'bite':
        final counts = _buildBiteCounts();
        if (counts == null) {
          return null;
        }
        return BiteReport(
          localId: localId,
          uuid: null,
          shortId: _nullableString(reportJson['report_id']),
          userUuid: userUuid,
          createdAt: createdAt,
          location: location,
          note: note,
          counts: counts,
          eventEnvironment: _mapBiteEnvironment(
            _findFirstAnswerId(questionId: 4),
          ),
          eventMoment: _mapBiteMoment(),
        );
      case 'site':
        return BreedingSiteReport(
          localId: localId,
          uuid: null,
          shortId: _nullableString(reportJson['report_id']),
          userUuid: userUuid,
          createdAt: createdAt,
          location: location,
          note: note,
          photos: photos,
          siteType: _mapBreedingSiteType(_findFirstAnswerId(questionId: 12)),
          hasWater: _mapLegacyBool(_findFirstAnswerId(questionId: 10)),
          hasLarvae: _mapLegacyBool(_findFirstAnswerId(questionId: 17)),
          inPublicArea: true,
          hasNearMosquitoes: null,
        );
      default:
        return null;
    }
  }

  List<BasePhoto> _buildPhotos({
    required List<_LegacySavedImage> linkedImages,
  }) {
    return linkedImages
        .where((image) => image.path != null && File(image.path!).existsSync())
        .map((image) => LocalPhoto(image.path!))
        .cast<BasePhoto>()
        .toList();
  }

  Location? _buildLocation(Map<String, dynamic> json) {
    final locationChoice = _nullableString(json['location_choice']);
    final latitude = (locationChoice == 'selected')
        ? _toDouble(json['selected_location_lat'])
        : _toDouble(json['current_location_lat']);
    final longitude = (locationChoice == 'selected')
        ? _toDouble(json['selected_location_lon'])
        : _toDouble(json['current_location_lon']);

    if (latitude == null || longitude == null) {
      return null;
    }

    final source = locationChoice == 'selected'
        ? LocationSource_Enum.manual
        : LocationSource_Enum.auto;

    return Location(
      (b) => b
        ..point.latitude = latitude
        ..point.longitude = longitude
        ..source_ = source,
    );
  }

  BiteCounts? _buildBiteCounts() {
    final total = _toInt(_findFirstAnswerValue(questionId: 1));
    final head = _toInt(_findFirstAnswerValue(answerId: 21)) ?? 0;
    final leftArm = _toInt(_findFirstAnswerValue(answerId: 22)) ?? 0;
    final rightArm = _toInt(_findFirstAnswerValue(answerId: 23)) ?? 0;
    final chest = _toInt(_findFirstAnswerValue(answerId: 24)) ?? 0;
    final leftLeg = _toInt(_findFirstAnswerValue(answerId: 25)) ?? 0;
    final rightLeg = _toInt(_findFirstAnswerValue(answerId: 26)) ?? 0;
    final resolvedTotal =
        total ?? head + leftArm + rightArm + chest + leftLeg + rightLeg;

    return BiteCounts(
      (b) => b
        ..head = head
        ..leftArm = leftArm
        ..rightArm = rightArm
        ..chest = chest
        ..leftLeg = leftLeg
        ..rightLeg = rightLeg
        ..total = resolvedTotal,
    );
  }

  BiteEventMomentEnum? _mapBiteMoment() {
    final whenAnswerId = _findFirstAnswerId(questionId: 5);
    if (whenAnswerId == 51) {
      return BiteEventMomentEnum.now;
    }

    final timeAnswerId = _findFirstAnswerId(questionId: 3);
    switch (timeAnswerId) {
      case 31:
        return BiteEventMomentEnum.lastMorning;
      case 32:
        return BiteEventMomentEnum.lastMidday;
      case 33:
        return BiteEventMomentEnum.lastAfternoon;
      case 34:
        return BiteEventMomentEnum.lastNight;
      default:
        return null;
    }
  }

  ObservationEventEnvironmentEnum? _mapObservationEnvironment(int? answerId) {
    switch (answerId) {
      case 131:
        return ObservationEventEnvironmentEnum.vehicle;
      case 132:
        return ObservationEventEnvironmentEnum.indoors;
      case 133:
        return ObservationEventEnvironmentEnum.outdoors;
      default:
        return null;
    }
  }

  BiteEventEnvironmentEnum? _mapBiteEnvironment(int? answerId) {
    switch (answerId) {
      case 41:
        return BiteEventEnvironmentEnum.vehicle;
      case 42:
        return BiteEventEnvironmentEnum.indoors;
      case 43:
        return BiteEventEnvironmentEnum.outdoors;
      default:
        return null;
    }
  }

  BreedingSiteSiteTypeEnum _mapBreedingSiteType(int? answerId) {
    switch (answerId) {
      case 121:
        return BreedingSiteSiteTypeEnum.stormDrain;
      default:
        return BreedingSiteSiteTypeEnum.other;
    }
  }

  bool? _mapLegacyBool(int? answerId) {
    switch (answerId) {
      case 101:
        return true;
      case 81:
      case 102:
        return false;
      default:
        return null;
    }
  }

  List<Map<String, dynamic>> _responses() {
    final responses = reportJson['responses'];
    if (responses is! List) {
      return const [];
    }

    return responses.whereType<Map>().map((response) {
      return response.map((key, value) => MapEntry(key.toString(), value));
    }).toList();
  }

  int? _findFirstAnswerId({int? questionId}) {
    for (final response in _responses()) {
      if (questionId != null && _toInt(response['question_id']) != questionId) {
        continue;
      }
      final answerId = _toInt(response['answer_id']);
      if (answerId != null) {
        return answerId;
      }
    }
    return null;
  }

  String? _findFirstAnswerValue({int? questionId, int? answerId}) {
    for (final response in _responses()) {
      if (questionId != null && _toInt(response['question_id']) != questionId) {
        continue;
      }
      if (answerId != null && _toInt(response['answer_id']) != answerId) {
        continue;
      }
      final answerValue = response['answer_value'];
      if (answerValue != null) {
        return answerValue.toString();
      }
    }
    return null;
  }
}

class _LegacySavedImage {
  final String raw;
  final String? path;
  final String? versionUuid;

  const _LegacySavedImage({
    required this.raw,
    required this.path,
    required this.versionUuid,
  });

  static _LegacySavedImage? tryParse(String raw) {
    final decoded = _decodeJsonObject(raw);
    if (decoded == null) {
      return null;
    }
    return _LegacySavedImage(
      raw: raw,
      path: _nullableString(decoded['image']),
      versionUuid: _nullableString(
        decoded['verison_UUID'] ?? decoded['version_UUID'] ?? decoded['id'],
      ),
    );
  }
}

DateTime? _parseDateTime(dynamic value) {
  final stringValue = _nullableString(value);
  if (stringValue == null) {
    return null;
  }
  return DateTime.tryParse(stringValue)?.toUtc();
}

String? _nullableString(dynamic value) {
  if (value == null) {
    return null;
  }
  final stringValue = value.toString().trim();
  if (stringValue.isEmpty || stringValue == 'null') {
    return null;
  }
  return stringValue;
}

double? _toDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value == null) {
    return null;
  }
  return double.tryParse(value.toString());
}

int? _toInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value == null) {
    return null;
  }
  return int.tryParse(value.toString());
}
