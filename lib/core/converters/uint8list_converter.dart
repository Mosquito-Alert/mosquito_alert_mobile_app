import 'package:json_annotation/json_annotation.dart';
import 'dart:typed_data';
import 'dart:convert';

class Uint8ListConverter implements JsonConverter<Uint8List, String> {
  const Uint8ListConverter();

  @override
  Uint8List fromJson(String json) {
    return Uint8List.fromList(base64Decode(json));
  }

  @override
  String toJson(Uint8List object) {
    return base64Encode(object);
  }
}
