import 'package:built_value/serializer.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mosquito_alert/mosquito_alert.dart' as sdk;

class ObservationEventMomentConverter
    implements JsonConverter<sdk.ObservationEventMomentEnum, String> {
  const ObservationEventMomentConverter();

  static final _serializer =
      sdk.ObservationEventMomentEnum.serializer
          as PrimitiveSerializer<sdk.ObservationEventMomentEnum>;

  @override
  sdk.ObservationEventMomentEnum fromJson(String json) {
    return _serializer.deserialize(
      sdk.serializers,
      json,
      specifiedType: const FullType(sdk.ObservationEventMomentEnum),
    );
  }

  @override
  String toJson(sdk.ObservationEventMomentEnum object) {
    return _serializer.serialize(
          sdk.serializers,
          object,
          specifiedType: const FullType(sdk.ObservationEventMomentEnum),
        )
        as String;
  }
}
