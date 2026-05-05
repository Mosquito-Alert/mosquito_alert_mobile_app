import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mosquito_alert/mosquito_alert.dart';
import 'package:mosquito_alert_app/features/bites/data/bite_repository.dart';
import 'package:mosquito_alert_app/features/bites/domain/models/bite_report.dart';
import 'package:mosquito_alert_app/features/breeding_sites/data/breeding_site_repository.dart';
import 'package:mosquito_alert_app/features/breeding_sites/domain/models/breeding_site_report.dart';
import 'package:mosquito_alert_app/features/observations/data/observation_repository.dart';
import 'package:mosquito_alert_app/features/observations/domain/models/observation_report.dart';
import 'package:mosquito_alert_app/features/reports/data/legacy_local_reports_migration.dart';
import 'package:mosquito_alert_app/features/reports/domain/models/photo.dart';
import 'package:mosquito_alert_app/hive/hive_adapters.dart';
import 'package:mosquito_alert_app/hive/hive_registrar.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Directory hiveDir;
  late Directory imageDir;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    _registerHiveAdapters();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    hiveDir = await Directory.systemTemp.createTemp('legacy_reports_hive_');
    imageDir = await Directory.systemTemp.createTemp('legacy_report_images_');
    Hive.init(hiveDir.path);
    await Future.wait([
      Hive.openBox<ObservationReport>(ObservationRepository.itemBoxName),
      Hive.openBox<BiteReport>(BiteRepository.itemBoxName),
      Hive.openBox<BreedingSiteReport>(BreedingSiteRepository.itemBoxName),
    ]);
  });

  tearDown(() async {
    await Hive.close();
    await hiveDir.delete(recursive: true);
    await imageDir.delete(recursive: true);
  });

  test('migrates valid legacy reports into offline report boxes', () async {
    final imageFile = File('${imageDir.path}/adult.jpg')
      ..writeAsStringSync('fake image bytes');
    final prefs = await SharedPreferences.getInstance();
    final adultReport = _legacyReport(
      type: 'adult',
      versionUuid: 'adult-local-id',
      creationTime: '2025-10-12T09:30:00Z',
      responses: [
        {'question_id': 13, 'answer_id': 133},
      ],
    );
    final biteReport = _legacyReport(
      type: 'bite',
      versionUuid: 'bite-local-id',
      creationTime: '2023-08-04T20:15:00Z',
      responses: [
        {'question_id': 1, 'answer_value': '3'},
        {'answer_id': 21, 'answer_value': '1'},
        {'answer_id': 22, 'answer_value': '2'},
        {'question_id': 4, 'answer_id': 43},
        {'question_id': 5, 'answer_id': 51},
      ],
    );
    final siteReport = _legacyReport(
      type: 'site',
      versionUuid: 'site-local-id',
      creationTime: '2023-07-01T08:00:00Z',
      responses: [
        {'question_id': 12, 'answer_id': 121},
        {'question_id': 10, 'answer_id': 101},
        {'question_id': 17, 'answer_id': 102},
      ],
    );

    await prefs.setStringList('reportsList', [
      jsonEncode(adultReport),
      jsonEncode(biteReport),
      jsonEncode(siteReport),
    ]);
    await prefs.setStringList('imagesList', [
      jsonEncode({'image': imageFile.path, 'verison_UUID': 'adult-local-id'}),
    ]);

    await migrateLegacyLocalReports();

    expect(prefs.getStringList('reportsList'), isEmpty);
    expect(prefs.getStringList('imagesList'), isEmpty);

    final observation = Hive.box<ObservationReport>(
      ObservationRepository.itemBoxName,
    ).get('adult-local-id');
    expect(observation, isNotNull);
    expect(observation!.uuid, isNull);
    expect(observation.localId, 'adult-local-id');
    expect(observation.createdAt, DateTime.parse('2025-10-12T09:30:00Z'));
    expect(
      observation.eventEnvironment,
      ObservationEventEnvironmentEnum.outdoors,
    );
    expect(observation.photos, hasLength(1));
    expect(observation.photos!.single, isA<LocalPhoto>());

    final bite = Hive.box<BiteReport>(
      BiteRepository.itemBoxName,
    ).get('bite-local-id');
    expect(bite, isNotNull);
    expect(bite!.counts.total, 3);
    expect(bite.eventEnvironment, BiteEventEnvironmentEnum.outdoors);
    expect(bite.eventMoment, BiteEventMomentEnum.now);

    final site = Hive.box<BreedingSiteReport>(
      BreedingSiteRepository.itemBoxName,
    ).get('site-local-id');
    expect(site, isNotNull);
    expect(site!.siteType, BreedingSiteSiteTypeEnum.stormDrain);
    expect(site.hasWater, isTrue);
    expect(site.hasLarvae, isFalse);
  });

  test(
    'keeps unparseable entries and migrates reports with missing images',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final rawInvalidReport = 'not json';
      final rawInvalidImage = 'not json either';
      final rawMissingImage = jsonEncode({
        'image': '${imageDir.path}/missing.jpg',
        'verison_UUID': 'adult-with-missing-image',
      });
      final adultReport = _legacyReport(
        type: 'adult',
        versionUuid: 'adult-with-missing-image',
        creationTime: '2025-10-12T09:30:00Z',
      );

      await prefs.setStringList('reportsList', [
        rawInvalidReport,
        jsonEncode(adultReport),
      ]);
      await prefs.setStringList('imagesList', [
        rawInvalidImage,
        rawMissingImage,
      ]);

      await migrateLegacyLocalReports();

      expect(prefs.getStringList('reportsList'), [rawInvalidReport]);
      expect(prefs.getStringList('imagesList'), [rawInvalidImage]);

      final observation = Hive.box<ObservationReport>(
        ObservationRepository.itemBoxName,
      ).get('adult-with-missing-image');
      expect(observation, isNotNull);
      expect(observation!.photos, isEmpty);
    },
  );
}

void _registerHiveAdapters() {
  void registerAdapter<T>(TypeAdapter<T> adapter) {
    if (!Hive.isAdapterRegistered(adapter.typeId)) {
      Hive.registerAdapter(adapter);
    }
  }

  registerAdapter(BiteCountsAdapter());
  registerAdapter(BiteEventEnvironmentEnumAdapter());
  registerAdapter(BiteEventMomentEnumAdapter());
  registerAdapter(LocationAdapter());
  registerAdapter(ObservationEventEnvironmentEnumAdapter());
  registerAdapter(ObservationEventMomentEnumAdapter());
  registerAdapter(BreedingSiteSiteTypeEnumAdapter());
  Hive.registerAdapters();
}

Map<String, dynamic> _legacyReport({
  required String type,
  required String versionUuid,
  required String creationTime,
  List<Map<String, dynamic>> responses = const [],
}) {
  return {
    'version_UUID': versionUuid,
    'version_number': 0,
    'user': 'legacy-user-uuid',
    'report_id': 'legacy-short-id',
    'creation_time': creationTime,
    'version_time': creationTime,
    'phone_upload_time': creationTime,
    'type': type,
    'location_choice': 'current',
    'current_location_lat': 41.390205,
    'current_location_lon': 2.154007,
    'note': 'legacy note',
    'responses': responses,
  };
}
