// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bite_report_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BiteCreateRequest _$BiteCreateRequestFromJson(Map<String, dynamic> json) =>
    BiteCreateRequest(
      location: const LocationRequestConverter().fromJson(
        json['location'] as Map<String, dynamic>,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      eventEnvironment:
          _$JsonConverterFromJson<String, BiteRequestEventEnvironmentEnum>(
            json['eventEnvironment'],
            const BiteRequestEventEnvironmentConverter().fromJson,
          ),
      eventMoment: _$JsonConverterFromJson<String, BiteRequestEventMomentEnum>(
        json['eventMoment'],
        const BiteRequestEventMomentConverter().fromJson,
      ),
      counts: const BiteRequestCountsConverter().fromJson(
        json['counts'] as Map<String, dynamic>,
      ),
      note: json['note'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      localId: json['localId'] as String,
    );

Map<String, dynamic> _$BiteCreateRequestToJson(BiteCreateRequest instance) =>
    <String, dynamic>{
      'localId': instance.localId,
      'createdAt': instance.createdAt.toIso8601String(),
      'note': instance.note,
      'tags': instance.tags,
      'location': const LocationRequestConverter().toJson(instance.location),
      'eventEnvironment':
          _$JsonConverterToJson<String, BiteRequestEventEnvironmentEnum>(
            instance.eventEnvironment,
            const BiteRequestEventEnvironmentConverter().toJson,
          ),
      'eventMoment': _$JsonConverterToJson<String, BiteRequestEventMomentEnum>(
        instance.eventMoment,
        const BiteRequestEventMomentConverter().toJson,
      ),
      'counts': const BiteRequestCountsConverter().toJson(instance.counts),
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
