import 'package:built_value/serializer.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mosquito_alert/mosquito_alert.dart' as sdk;

class ObservationEventEnvironmentConverter
    implements JsonConverter<sdk.ObservationEventEnvironmentEnum, String> {
  const ObservationEventEnvironmentConverter();

  static final _serializer =
      sdk.ObservationEventEnvironmentEnum.serializer
          as PrimitiveSerializer<sdk.ObservationEventEnvironmentEnum>;

  @override
  sdk.ObservationEventEnvironmentEnum fromJson(String json) {
    return _serializer.deserialize(
      sdk.serializers,
      json,
      specifiedType: const FullType(sdk.ObservationEventEnvironmentEnum),
    );
  }

  @override
  String toJson(sdk.ObservationEventEnvironmentEnum object) {
    return _serializer.serialize(
          sdk.serializers,
          object,
          specifiedType: const FullType(sdk.ObservationEventEnvironmentEnum),
        )
        as String;
  }
}
