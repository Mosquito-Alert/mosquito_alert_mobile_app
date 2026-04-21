import 'package:json_annotation/json_annotation.dart';
import 'package:mosquito_alert/mosquito_alert.dart' as sdk;
import 'package:mosquito_alert_app/core/data/models/requests.dart';
import 'package:mosquito_alert_app/features/fixes/data/converters/fix_location_request_converter.dart';
import 'package:mosquito_alert_app/features/fixes/domain/models/fix.dart';

part 'fix_request.g.dart';

@JsonSerializable()
class FixCreateRequest extends CreateRequest {
  final String coverageUuid;
  final DateTime createdAt;
  @FixLocationRequestConverter()
  final sdk.FixLocationRequest point;
  final double? power;

  FixCreateRequest({
    required this.coverageUuid,
    required this.createdAt,
    required sdk.FixLocationRequest point,
    this.power,
    required super.localId,
  }) : point = point.rebuild((b) {
         // Mask coordinates to 0.025 degrees
         final maskedLatitude = (point.latitude / 0.025).round() * 0.025;
         final maskedLongitude = (point.longitude / 0.025).round() * 0.025;

         b
           ..latitude = maskedLatitude
           ..longitude = maskedLongitude;
       });

  factory FixCreateRequest.fromModel(FixModel model) {
    return FixCreateRequest(
      localId: model.localId!,
      coverageUuid: model.coverageUuid,
      createdAt: model.createdAt,
      point: sdk.FixLocationRequest(
        (p) => p
          ..latitude = model.point.latitude
          ..longitude = model.point.longitude,
      ),
      power: model.power,
    );
  }

  factory FixCreateRequest.fromJson(Map<String, dynamic> json) =>
      _$FixCreateRequestFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$FixCreateRequestToJson(this);
}
