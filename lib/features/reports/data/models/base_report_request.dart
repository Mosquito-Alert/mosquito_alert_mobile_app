import 'package:json_annotation/json_annotation.dart';
import 'package:mosquito_alert/mosquito_alert.dart' as sdk;
import 'package:mosquito_alert_app/core/data/models/requests.dart';
import 'package:mosquito_alert_app/core/converters/location_request_converter.dart';
import 'package:mosquito_alert_app/features/reports/domain/models/photo.dart';
import 'package:mosquito_alert_app/features/reports/data/converters/photo_converter.dart';

part 'base_report_request.g.dart';

@JsonSerializable()
class DeleteReportRequest implements DeleteRequest {
  final String uuid;
  DeleteReportRequest({required this.uuid});

  factory DeleteReportRequest.fromJson(Map<String, dynamic> json) =>
      _$DeleteReportRequestFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$DeleteReportRequestToJson(this);
}

abstract class BaseCreateReportRequest extends CreateRequest {
  final DateTime createdAt;
  final String? note;
  final List<String>? tags;

  @LocationRequestConverter()
  final sdk.LocationRequest location;

  BaseCreateReportRequest({
    required super.localId,
    required this.location,
    required this.createdAt,
    this.note,
    this.tags,
  });
}

abstract class BaseCreateReportWithPhotosRequest
    extends BaseCreateReportRequest {
  @BaseUploadPhotoConverter()
  List<BaseUploadPhoto> photos;

  BaseCreateReportWithPhotosRequest({
    required this.photos,
    required super.location,
    required super.createdAt,
    super.note,
    super.tags,
    required super.localId,
  });
}
