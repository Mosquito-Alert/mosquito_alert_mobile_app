import 'package:built_value/serializer.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mosquito_alert/mosquito_alert.dart' as sdk;

class BiteRequestEventEnvironmentConverter
    implements JsonConverter<sdk.BiteRequestEventEnvironmentEnum, String> {
  const BiteRequestEventEnvironmentConverter();

  static final _serializer =
      sdk.BiteRequestEventEnvironmentEnum.serializer
          as PrimitiveSerializer<sdk.BiteRequestEventEnvironmentEnum>;

  @override
  sdk.BiteRequestEventEnvironmentEnum fromJson(String json) {
    return _serializer.deserialize(
      sdk.serializers,
      json,
      specifiedType: const FullType(sdk.BiteRequestEventEnvironmentEnum),
    );
  }

  @override
  String toJson(sdk.BiteRequestEventEnvironmentEnum object) {
    return _serializer.serialize(
          sdk.serializers,
          object,
          specifiedType: const FullType(sdk.BiteRequestEventEnvironmentEnum),
        )
        as String;
  }
}
