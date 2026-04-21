// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'breeding_site_report_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BreedingSiteCreateRequest _$BreedingSiteCreateRequestFromJson(
  Map<String, dynamic> json,
) => BreedingSiteCreateRequest(
  createdAt: DateTime.parse(json['createdAt'] as String),
  location: const LocationRequestConverter().fromJson(
    json['location'] as Map<String, dynamic>,
  ),
  photos: (json['photos'] as List<dynamic>)
      .map(
        (e) => const BaseUploadPhotoConverter().fromJson(
          e as Map<String, dynamic>,
        ),
      )
      .toList(),
  siteType: const BreedingSiteTypeConverter().fromJson(
    json['siteType'] as String,
  ),
  hasWater: json['hasWater'] as bool?,
  hasLarvae: json['hasLarvae'] as bool?,
  inPublicArea: json['inPublicArea'] as bool?,
  hasNearMosquitoes: json['hasNearMosquitoes'] as bool?,
  note: json['note'] as String?,
  tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
  localId: json['localId'] as String,
);

Map<String, dynamic> _$BreedingSiteCreateRequestToJson(
  BreedingSiteCreateRequest instance,
) => <String, dynamic>{
  'localId': instance.localId,
  'createdAt': instance.createdAt.toIso8601String(),
  'note': instance.note,
  'tags': instance.tags,
  'location': const LocationRequestConverter().toJson(instance.location),
  'photos': instance.photos
      .map(const BaseUploadPhotoConverter().toJson)
      .toList(),
  'siteType': const BreedingSiteTypeConverter().toJson(instance.siteType),
  'hasWater': instance.hasWater,
  'inPublicArea': instance.inPublicArea,
  'hasNearMosquitoes': instance.hasNearMosquitoes,
  'hasLarvae': instance.hasLarvae,
};
