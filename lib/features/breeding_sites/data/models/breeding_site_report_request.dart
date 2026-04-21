import 'package:mosquito_alert/mosquito_alert.dart';
import 'package:mosquito_alert_app/features/breeding_sites/data/converters/breeding_site_type_converter.dart';
import 'package:mosquito_alert_app/features/breeding_sites/domain/models/breeding_site_report.dart';
import 'package:mosquito_alert_app/features/reports/data/models/base_report_request.dart';
import 'package:mosquito_alert_app/core/converters/location_request_converter.dart';
import 'package:mosquito_alert_app/features/reports/data/converters/photo_converter.dart';

import 'package:json_annotation/json_annotation.dart';
import 'package:mosquito_alert_app/features/reports/domain/models/photo.dart';
part 'breeding_site_report_request.g.dart';

@JsonSerializable()
class BreedingSiteCreateRequest extends BaseCreateReportWithPhotosRequest {
  @BreedingSiteTypeConverter()
  final BreedingSiteSiteTypeEnum siteType;
  final bool? hasWater;
  final bool? inPublicArea;
  final bool? hasNearMosquitoes;
  final bool? hasLarvae;

  BreedingSiteCreateRequest({
    required super.createdAt,
    required super.location,
    required super.photos,
    required this.siteType,
    required this.hasWater,
    required this.hasLarvae,
    this.inPublicArea,
    this.hasNearMosquitoes,
    String? note,
    List<String>? tags,
    required super.localId,
  });

  factory BreedingSiteCreateRequest.fromModel(BreedingSiteReport breedingSite) {
    return BreedingSiteCreateRequest(
      localId: breedingSite.localId!,
      createdAt: breedingSite.createdAt,
      location: LocationRequest(
        (b) => b
          ..point.latitude = breedingSite.location.point.latitude
          ..point.longitude = breedingSite.location.point.longitude
          ..source_ = LocationRequestSource_Enum.valueOf(
            breedingSite.location.source_.name,
          ),
      ),
      photos: breedingSite.photos != null
          ? breedingSite.photos as List<BaseUploadPhoto>
          : [],
      siteType: breedingSite.siteType,
      hasWater: breedingSite.hasWater,
      inPublicArea: breedingSite.inPublicArea,
      hasNearMosquitoes: breedingSite.hasNearMosquitoes,
      hasLarvae: breedingSite.hasLarvae,
      note: breedingSite.note,
      tags: breedingSite.tags,
    );
  }

  factory BreedingSiteCreateRequest.fromJson(Map<String, dynamic> json) =>
      _$BreedingSiteCreateRequestFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$BreedingSiteCreateRequestToJson(this);
}
