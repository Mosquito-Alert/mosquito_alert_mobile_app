// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fix_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FixCreateRequest _$FixCreateRequestFromJson(Map<String, dynamic> json) =>
    FixCreateRequest(
      coverageUuid: json['coverageUuid'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      point: const FixLocationRequestConverter().fromJson(
        json['point'] as Map<String, dynamic>,
      ),
      power: (json['power'] as num?)?.toDouble(),
      localId: json['localId'] as String,
    );

Map<String, dynamic> _$FixCreateRequestToJson(FixCreateRequest instance) =>
    <String, dynamic>{
      'localId': instance.localId,
      'coverageUuid': instance.coverageUuid,
      'createdAt': instance.createdAt.toIso8601String(),
      'point': const FixLocationRequestConverter().toJson(instance.point),
      'power': instance.power,
    };
