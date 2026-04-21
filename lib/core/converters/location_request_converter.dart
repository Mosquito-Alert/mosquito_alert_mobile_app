import 'package:json_annotation/json_annotation.dart';
import 'package:mosquito_alert/mosquito_alert.dart' as sdk;

class LocationRequestConverter
    implements JsonConverter<sdk.LocationRequest, Map<String, dynamic>> {
  const LocationRequestConverter();

  @override
  sdk.LocationRequest fromJson(Map<String, dynamic> json) {
    return sdk.standardSerializers.deserializeWith(
          sdk.LocationRequest.serializer,
          json,
        )
        as sdk.LocationRequest;
  }

  @override
  Map<String, dynamic> toJson(sdk.LocationRequest location) {
    final obj = sdk.standardSerializers.serializeWith(
      sdk.LocationRequest.serializer,
      location,
    );
    return obj as Map<String, dynamic>;
  }
}
