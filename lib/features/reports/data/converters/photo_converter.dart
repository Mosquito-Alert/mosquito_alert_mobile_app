import 'package:json_annotation/json_annotation.dart';
import 'package:mosquito_alert_app/features/reports/domain/models/photo.dart';

class BaseUploadPhotoConverter
    implements JsonConverter<BaseUploadPhoto, Map<String, dynamic>> {
  const BaseUploadPhotoConverter();

  @override
  BaseUploadPhoto fromJson(Map<String, dynamic> json) {
    return BaseUploadPhoto.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(BaseUploadPhoto photo) => photo.toJson();
}
