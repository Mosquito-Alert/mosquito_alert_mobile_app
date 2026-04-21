import 'package:built_value/serializer.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mosquito_alert/mosquito_alert.dart' as sdk;

class BreedingSiteTypeConverter
    implements JsonConverter<sdk.BreedingSiteSiteTypeEnum, String> {
  const BreedingSiteTypeConverter();

  static final _serializer =
      sdk.BreedingSiteSiteTypeEnum.serializer
          as PrimitiveSerializer<sdk.BreedingSiteSiteTypeEnum>;

  @override
  sdk.BreedingSiteSiteTypeEnum fromJson(String json) {
    return _serializer.deserialize(
      sdk.serializers,
      json,
      specifiedType: const FullType(sdk.BreedingSiteSiteTypeEnum),
    );
  }

  @override
  String toJson(sdk.BreedingSiteSiteTypeEnum object) {
    return _serializer.serialize(
          sdk.serializers,
          object,
          specifiedType: const FullType(sdk.BreedingSiteSiteTypeEnum),
        )
        as String;
  }
}
