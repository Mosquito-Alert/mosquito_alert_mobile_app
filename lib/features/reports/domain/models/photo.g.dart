// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'photo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LocalPhoto _$LocalPhotoFromJson(Map<String, dynamic> json) =>
    LocalPhoto(json['path'] as String);

Map<String, dynamic> _$LocalPhotoToJson(LocalPhoto instance) =>
    <String, dynamic>{'path': instance.path};

MemoryPhoto _$MemoryPhotoFromJson(Map<String, dynamic> json) =>
    MemoryPhoto(const Uint8ListConverter().fromJson(json['bytes'] as String));

Map<String, dynamic> _$MemoryPhotoToJson(MemoryPhoto instance) =>
    <String, dynamic>{
      'bytes': const Uint8ListConverter().toJson(instance.bytes),
    };
