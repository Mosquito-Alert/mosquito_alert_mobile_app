import 'package:mosquito_alert/mosquito_alert.dart';
import 'package:mosquito_alert_app/features/bites/data/converters/bite_request_counts_conveter.dart';
import 'package:mosquito_alert_app/features/bites/data/converters/bite_request_event_environment_converter.dart';
import 'package:mosquito_alert_app/features/bites/data/converters/bite_request_event_moment_converter.dart';
import 'package:mosquito_alert_app/core/converters/location_request_converter.dart';
import 'package:mosquito_alert_app/features/bites/domain/models/bite_report.dart';
import 'package:mosquito_alert_app/features/reports/data/models/base_report_request.dart';

import 'package:json_annotation/json_annotation.dart';
part 'bite_report_request.g.dart';

@JsonSerializable()
class BiteCreateRequest extends BaseCreateReportRequest {
  @BiteRequestEventEnvironmentConverter()
  final BiteRequestEventEnvironmentEnum? eventEnvironment;

  @BiteRequestEventMomentConverter()
  final BiteRequestEventMomentEnum? eventMoment;

  @BiteRequestCountsConverter()
  final BiteCountsRequest counts;

  BiteCreateRequest({
    required super.location,
    required super.createdAt,
    required this.eventEnvironment,
    required this.eventMoment,
    required this.counts,
    super.note,
    super.tags,
    required super.localId,
  });

  factory BiteCreateRequest.fromModel(BiteReport bite) {
    return BiteCreateRequest(
      localId: bite.localId!,
      createdAt: bite.createdAt,
      location: LocationRequest(
        (b) => b
          ..point.latitude = bite.location.point.latitude
          ..point.longitude = bite.location.point.longitude
          ..source_ = LocationRequestSource_Enum.valueOf(
            bite.location.source_.name,
          ),
      ),
      note: bite.note,
      tags: bite.tags,
      eventEnvironment: bite.eventEnvironment != null
          ? BiteRequestEventEnvironmentEnum.valueOf(bite.eventEnvironment!.name)
          : null,
      eventMoment: bite.eventMoment != null
          ? BiteRequestEventMomentEnum.valueOf(bite.eventMoment!.name)
          : null,
      counts: BiteCountsRequest(
        (b) => b
          ..head = bite.counts.head
          ..leftArm = bite.counts.leftArm
          ..chest = bite.counts.chest
          ..rightArm = bite.counts.rightArm
          ..leftLeg = bite.counts.leftLeg
          ..rightLeg = bite.counts.rightLeg,
      ),
    );
  }

  factory BiteCreateRequest.fromJson(Map<String, dynamic> json) =>
      _$BiteCreateRequestFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$BiteCreateRequestToJson(this);
}
