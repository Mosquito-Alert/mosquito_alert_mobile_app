import 'package:flutter/material.dart';
import 'package:mosquito_alert/mosquito_alert.dart';
import 'package:mosquito_alert_app/features/bites/data/models/bite_report_request.dart';
import 'package:mosquito_alert_app/features/reports/domain/models/base_report.dart';
import 'package:mosquito_alert_app/core/localizations/MyLocalizations.dart';

class BiteReport extends BaseReportModel {
  final BiteCounts counts;
  final BiteEventEnvironmentEnum? eventEnvironment;
  final BiteEventMomentEnum? eventMoment;

  BiteReport({
    required this.counts,
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
    super.localId,
  });

  factory BiteReport.fromSdkBite(Bite bite) {
    return BiteReport(
      uuid: bite.uuid,
      shortId: bite.shortId,
      userUuid: bite.userUuid,
      createdAt: bite.createdAt,
      createdAtLocal: bite.createdAtLocal,
      sentAt: bite.sentAt,
      receivedAt: bite.receivedAt,
      updatedAt: bite.updatedAt,
      location: bite.location,
      note: bite.note,
      tags: bite.tags?.toList(),
      counts: bite.counts,
      eventEnvironment: bite.eventEnvironment,
      eventMoment: bite.eventMoment,
    );
  }

  factory BiteReport.fromCreateRequest(BiteCreateRequest request) {
    return BiteReport(
      localId: request.localId,
      counts: BiteCounts(
        (b) => b
          ..head = request.counts.head
          ..leftArm = request.counts.leftArm
          ..chest = request.counts.chest
          ..rightArm = request.counts.rightArm
          ..leftLeg = request.counts.leftLeg
          ..rightLeg = request.counts.rightLeg
          ..total =
              (request.counts.head ?? 0) +
              (request.counts.leftArm ?? 0) +
              (request.counts.chest ?? 0) +
              (request.counts.rightArm ?? 0) +
              (request.counts.leftLeg ?? 0) +
              (request.counts.rightLeg ?? 0),
      ),
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
      eventEnvironment: request.eventEnvironment != null
          ? BiteEventEnvironmentEnum.valueOf(request.eventEnvironment!.name)
          : null,
      eventMoment: request.eventMoment != null
          ? BiteEventMomentEnum.valueOf(request.eventMoment!.name)
          : null,
    );
  }

  @override
  String getTitle(BuildContext context) {
    final totalBites = counts.total;
    String text;

    if (totalBites == 0) {
      text = MyLocalizations.of(context, 'no_bites');
    } else if (totalBites == 1) {
      text = '1 ${MyLocalizations.of(context, 'single_bite').toLowerCase()}';
    } else {
      text =
          '$totalBites ${MyLocalizations.of(context, 'plural_bite').toLowerCase()}';
    }
    return text;
  }

  String? getLocalizedEnvironment(BuildContext context) {
    switch (eventEnvironment) {
      case BiteEventEnvironmentEnum.vehicle:
        return MyLocalizations.of(context, 'question_13_answer_131');
      case BiteEventEnvironmentEnum.indoors:
        return MyLocalizations.of(context, 'question_13_answer_132');
      case BiteEventEnvironmentEnum.outdoors:
        return MyLocalizations.of(context, 'question_13_answer_133');
      default:
        return null;
    }
  }

  String? getEventMoment(BuildContext context) {
    switch (eventMoment) {
      case BiteEventMomentEnum.now:
        return MyLocalizations.of(context, 'question_5_answer_51');
      case BiteEventMomentEnum.lastMorning:
        return MyLocalizations.of(context, 'question_3_answer_31');
      case BiteEventMomentEnum.lastMidday:
        return MyLocalizations.of(context, 'question_3_answer_32');
      case BiteEventMomentEnum.lastAfternoon:
        return MyLocalizations.of(context, 'question_3_answer_33');
      case BiteEventMomentEnum.lastNight:
        return MyLocalizations.of(context, 'question_3_answer_34');
      default:
        return null;
    }
  }
}
