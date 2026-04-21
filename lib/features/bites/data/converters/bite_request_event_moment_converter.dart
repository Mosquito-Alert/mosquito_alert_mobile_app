import 'package:built_value/serializer.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mosquito_alert/mosquito_alert.dart' as sdk;

class BiteRequestEventMomentConverter
    implements JsonConverter<sdk.BiteRequestEventMomentEnum, String> {
  const BiteRequestEventMomentConverter();

  static final _serializer =
      sdk.BiteRequestEventMomentEnum.serializer
          as PrimitiveSerializer<sdk.BiteRequestEventMomentEnum>;

  @override
  sdk.BiteRequestEventMomentEnum fromJson(String json) {
    return _serializer.deserialize(
      sdk.serializers,
      json,
      specifiedType: const FullType(sdk.BiteRequestEventMomentEnum),
    );
  }

  @override
  String toJson(sdk.BiteRequestEventMomentEnum object) {
    return _serializer.serialize(
          sdk.serializers,
          object,
          specifiedType: const FullType(sdk.BiteRequestEventMomentEnum),
        )
        as String;
  }
}
