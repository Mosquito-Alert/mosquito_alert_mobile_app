// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'observation_report_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ObservationCreateRequest _$ObservationCreateRequestFromJson(
  Map<String, dynamic> json,
) => ObservationCreateRequest(
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
  eventEnvironment:
      _$JsonConverterFromJson<String, ObservationEventEnvironmentEnum>(
        json['eventEnvironment'],
        const ObservationEventEnvironmentConverter().fromJson,
      ),
  eventMoment: _$JsonConverterFromJson<String, ObservationEventMomentEnum>(
    json['eventMoment'],
    const ObservationEventMomentConverter().fromJson,
  ),
  note: json['note'] as String?,
  tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
  localId: json['localId'] as String,
);

Map<String, dynamic> _$ObservationCreateRequestToJson(
  ObservationCreateRequest instance,
) => <String, dynamic>{
  'localId': instance.localId,
  'createdAt': instance.createdAt.toIso8601String(),
  'note': instance.note,
  'tags': instance.tags,
  'location': const LocationRequestConverter().toJson(instance.location),
  'photos': instance.photos
      .map(const BaseUploadPhotoConverter().toJson)
      .toList(),
  'eventEnvironment':
      _$JsonConverterToJson<String, ObservationEventEnvironmentEnum>(
        instance.eventEnvironment,
        const ObservationEventEnvironmentConverter().toJson,
      ),
  'eventMoment': _$JsonConverterToJson<String, ObservationEventMomentEnum>(
    instance.eventMoment,
    const ObservationEventMomentConverter().toJson,
  ),
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
