import 'package:json_annotation/json_annotation.dart';
import 'package:mosquito_alert/mosquito_alert.dart' as sdk;
import 'package:mosquito_alert_app/core/data/models/requests.dart';
import 'package:mosquito_alert_app/features/fixes/data/converters/fix_location_request_converter.dart';
import 'package:mosquito_alert_app/features/fixes/domain/fix_masking.dart';
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
         // Mask to the south-west corner of the 0.025 degree cell, on the
         // phone, before the fix is queued or sent. This also runs each time
         // the request is rebuilt from the outbox (fromJson) or from a stored
         // model (fromModel), which is safe because maskCoordinate leaves an
         // already masked value unchanged.
         b
           ..latitude = maskCoordinate(point.latitude)
           ..longitude = maskCoordinate(point.longitude);
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
