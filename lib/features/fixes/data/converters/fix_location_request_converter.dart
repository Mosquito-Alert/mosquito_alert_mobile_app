import 'package:json_annotation/json_annotation.dart';
import 'package:mosquito_alert/mosquito_alert.dart' as sdk;

class FixLocationRequestConverter
    implements JsonConverter<sdk.FixLocationRequest, Map<String, dynamic>> {
  const FixLocationRequestConverter();

  @override
  sdk.FixLocationRequest fromJson(Map<String, dynamic> json) {
    return sdk.standardSerializers.deserializeWith(
          sdk.FixLocationRequest.serializer,
          json,
        )
        as sdk.FixLocationRequest;
  }

  @override
  Map<String, dynamic> toJson(sdk.FixLocationRequest location) {
    final obj = sdk.standardSerializers.serializeWith(
      sdk.FixLocationRequest.serializer,
      location,
    );
    return obj as Map<String, dynamic>;
  }
}
