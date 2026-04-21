import 'package:flutter/material.dart';
import 'package:mosquito_alert/mosquito_alert.dart';
import 'package:mosquito_alert_app/features/observations/data/models/observation_report_request.dart';
import 'package:mosquito_alert_app/features/reports/domain/models/base_report.dart';
import 'package:mosquito_alert_app/core/localizations/MyLocalizations.dart';
import 'package:mosquito_alert_app/features/reports/domain/models/photo.dart';

class ObservationReport extends BaseReportWithPhotos {
  final Identification? identification;
  final ObservationEventEnvironmentEnum? eventEnvironment;
  final ObservationEventMomentEnum? eventMoment;

  ObservationReport({
    this.identification,
    this.eventEnvironment,
    this.eventMoment,
    super.uuid,
    super.shortId,
    super.userUuid,
    required super.createdAt,
    super.createdAtLocal,
    super.sentAt,
    super.receivedAt,
    super.updatedAt,
    required super.location,
    super.note,
    super.tags,
    super.photos,
    super.localId,
  });

  factory ObservationReport.fromSdkObservation(Observation observation) {
    return ObservationReport(
      uuid: observation.uuid,
      shortId: observation.shortId,
      userUuid: observation.userUuid,
      createdAt: observation.createdAt,
      createdAtLocal: observation.createdAtLocal,
      sentAt: observation.sentAt,
      receivedAt: observation.receivedAt,
      updatedAt: observation.updatedAt,
      location: observation.location,
      note: observation.note,
      tags: observation.tags?.toList(),
      photos: observation.photos
          .map((photo) => BasePhoto.fromSimplePhoto(photo))
          .toList(),
      identification: observation.identification,
      eventEnvironment: observation.eventEnvironment,
      eventMoment: observation.eventMoment,
    );
  }

  factory ObservationReport.fromCreateRequest(
    ObservationCreateRequest request,
  ) {
    return ObservationReport(
      localId: request.localId,
      createdAt: request.createdAt,
      location: Location(
        (b) => b
          ..point.latitude = request.location.point.latitude
          ..point.longitude = request.location.point.longitude
          ..source_ = LocationSource_Enum.valueOf(
            request.location.source_.name,
          ),
      ),
      note: request.note,
      tags: request.tags,
      photos: request.photos,
      eventEnvironment: request.eventEnvironment,
      eventMoment: request.eventMoment,
    );
  }

  @override
  String getTitle(BuildContext context) {
    if (identification == null) {
      return MyLocalizations.of(context, 'non_identified_specie');
    }

    // Navigate through nested nullable fields
    final result = identification?.result;
    final taxon = result?.taxon;
    final nameValue = taxon?.nameValue;

    if (nameValue == null || nameValue.isEmpty) {
      return MyLocalizations.of(context, 'non_identified_specie');
    }

    return nameValue;
  }

  @override
  bool get titleItalicized {
    return identification?.result?.taxon?.italicize ?? false;
  }

  String? getLocalizedEnvironment(BuildContext context) {
    switch (eventEnvironment) {
      case ObservationEventEnvironmentEnum.vehicle:
        return MyLocalizations.of(context, 'question_13_answer_131');
      case ObservationEventEnvironmentEnum.indoors:
        return MyLocalizations.of(context, 'question_13_answer_132');
      case ObservationEventEnvironmentEnum.outdoors:
        return MyLocalizations.of(context, 'question_13_answer_133');
      default:
        return null;
    }
  }
}
