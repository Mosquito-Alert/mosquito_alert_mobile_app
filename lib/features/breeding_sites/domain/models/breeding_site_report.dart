import 'package:flutter/src/widgets/framework.dart';
import 'package:mosquito_alert/mosquito_alert.dart';
import 'package:mosquito_alert_app/features/breeding_sites/data/models/breeding_site_report_request.dart';
import 'package:mosquito_alert_app/features/reports/domain/models/base_report.dart';
import 'package:mosquito_alert_app/core/localizations/MyLocalizations.dart';
import 'package:mosquito_alert_app/features/reports/domain/models/photo.dart';

class BreedingSiteReport extends BaseReportWithPhotos {
  final BreedingSiteSiteTypeEnum siteType;
  final bool? hasWater;
  final bool? inPublicArea;
  final bool? hasNearMosquitoes;
  final bool? hasLarvae;

  BreedingSiteReport({
    required this.siteType,
    this.hasWater,
    this.inPublicArea,
    this.hasNearMosquitoes,
    this.hasLarvae,
    super.uuid,
    super.shortId,
    super.userUuid,
    required super.createdAt,
    super.createdAtLocal,
    super.sentAt,
    super.receivedAt,
    super.updatedAt,
    required super.location,
    super.note,
    super.tags,
    super.photos,
    super.localId,
  });

  factory BreedingSiteReport.fromSdkBreedingSite(BreedingSite site) {
    return BreedingSiteReport(
      uuid: site.uuid,
      shortId: site.shortId,
      userUuid: site.userUuid,
      createdAt: site.createdAt,
      createdAtLocal: site.createdAtLocal,
      sentAt: site.sentAt,
      receivedAt: site.receivedAt,
      updatedAt: site.updatedAt,
      location: site.location,
      note: site.note,
      tags: site.tags?.toList(),
      photos: site.photos
          .map((photo) => BasePhoto.fromSimplePhoto(photo))
          .toList(),
      siteType: site.siteType,
      hasWater: site.hasWater,
      inPublicArea: site.inPublicArea,
      hasNearMosquitoes: site.hasNearMosquitoes,
      hasLarvae: site.hasLarvae,
    );
  }

  factory BreedingSiteReport.fromCreateRequest(
    BreedingSiteCreateRequest request,
  ) {
    return BreedingSiteReport(
      localId: request.localId,
      createdAt: request.createdAt,
      location: Location(
        (b) => b
          ..point.latitude = request.location.point.latitude
          ..point.longitude = request.location.point.longitude
          ..source_ = LocationSource_Enum.valueOf(
            request.location.source_.name,
          ),
      ),
      photos: request.photos,
      siteType: request.siteType,
      hasWater: request.hasWater,
      inPublicArea: request.inPublicArea,
      hasNearMosquitoes: request.hasNearMosquitoes,
      hasLarvae: request.hasLarvae,
      note: request.note,
      tags: request.tags,
    );
  }

  @override
  String getTitle(BuildContext context) {
    return MyLocalizations.of(context, 'single_breeding_site');
  }
}
