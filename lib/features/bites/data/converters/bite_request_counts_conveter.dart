import 'package:json_annotation/json_annotation.dart';
import 'package:mosquito_alert/mosquito_alert.dart' as sdk;

class BiteRequestCountsConverter
    implements JsonConverter<sdk.BiteCountsRequest, Map<String, dynamic>> {
  const BiteRequestCountsConverter();

  @override
  sdk.BiteCountsRequest fromJson(Map<String, dynamic> json) {
    return sdk.standardSerializers.deserializeWith(
          sdk.BiteCountsRequest.serializer,
          json,
        )
        as sdk.BiteCountsRequest;
  }

  @override
  Map<String, dynamic> toJson(sdk.BiteCountsRequest object) {
    final obj = sdk.standardSerializers.serializeWith(
      sdk.BiteCountsRequest.serializer,
      object,
    );
    return obj as Map<String, dynamic>;
  }
}
