import 'package:mosquito_alert/mosquito_alert.dart';
import 'package:mosquito_alert_app/features/observations/data/converters/observation_event_environment_converter.dart';
import 'package:mosquito_alert_app/features/observations/data/converters/observation_event_moment_converter.dart';
import 'package:mosquito_alert_app/features/observations/domain/models/observation_report.dart';
import 'package:mosquito_alert_app/features/reports/data/models/base_report_request.dart';
import 'package:mosquito_alert_app/core/converters/location_request_converter.dart';
import 'package:mosquito_alert_app/features/reports/data/converters/photo_converter.dart';

import 'package:json_annotation/json_annotation.dart';
import 'package:mosquito_alert_app/features/reports/domain/models/photo.dart';
part 'observation_report_request.g.dart';

@JsonSerializable()
class ObservationCreateRequest extends BaseCreateReportWithPhotosRequest {
  @ObservationEventEnvironmentConverter()
  final ObservationEventEnvironmentEnum? eventEnvironment;

  @ObservationEventMomentConverter()
  final ObservationEventMomentEnum? eventMoment;

  ObservationCreateRequest({
    required super.createdAt,
    required super.location,
    required super.photos,
    required this.eventEnvironment,
    required this.eventMoment,
    String? note,
    List<String>? tags,
    required super.localId,
  });

  factory ObservationCreateRequest.fromModel(ObservationReport observation) {
    return ObservationCreateRequest(
      localId: observation.localId!,
      createdAt: observation.createdAt,
      location: LocationRequest(
        (b) => b
          ..point.latitude = observation.location.point.latitude
          ..point.longitude = observation.location.point.longitude
          ..source_ = LocationRequestSource_Enum.valueOf(
            observation.location.source_.name,
          ),
      ),
      photos: observation.photos != null
          ? observation.photos as List<BaseUploadPhoto>
          : [],
      eventEnvironment: observation.eventEnvironment,
      eventMoment: observation.eventMoment,
      note: observation.note,
      tags: observation.tags,
    );
  }

  factory ObservationCreateRequest.fromJson(Map<String, dynamic> json) =>
      _$ObservationCreateRequestFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$ObservationCreateRequestToJson(this);
}
