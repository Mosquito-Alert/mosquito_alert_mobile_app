import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:mosquito_alert/mosquito_alert.dart';
import 'package:mosquito_alert_app/core/outbox/outbox_offline_model.dart';
import 'package:mosquito_alert_app/features/reports/domain/models/photo.dart';

abstract class BaseReportModel extends OfflineModel {
  final String? uuid;
  final String? shortId;
  final String? userUuid;
  final DateTime createdAt;
  final DateTime createdAtLocal;
  final DateTime? sentAt;
  final DateTime? receivedAt;
  final DateTime? updatedAt;
  final Location location;
  final String? note;
  final List<String>? tags;

  BaseReportModel({
    this.uuid,
    this.shortId,
    this.userUuid,
    required this.createdAt,
    DateTime? createdAtLocal,
    this.sentAt,
    this.receivedAt,
    this.updatedAt,
    required this.location,
    this.note,
    this.tags,
    super.localId,
  }) : createdAtLocal = createdAtLocal ?? createdAt.toLocal();

  String getTitle(BuildContext context);
  bool get titleItalicized => false;

  Future<String> get locationDisplayName async {
    String? cityName;
    String? countryName;

    // 1. Try using administrative boundaries first
    final admBoundaries = location.admBoundaries;
    if (admBoundaries.isNotEmpty) {
      try {
        // Use the most specific administrative boundary available
        final cityBoundary = admBoundaries.firstWhere(
          (adm) => adm.level == 4 && adm.code == 'NUTS',
        );
        cityName = cityBoundary.nameValue;
      } catch (_) {
        // No city-level boundary found
      }
      countryName = location.country?.nameEn;
      if (cityName != null && countryName != null) {
        return [cityName, countryName].join(", ");
      }
    }

    // 2. Use displayName if available (preferred human-readable name)
    final displayName = location.displayName;
    if (displayName != null && displayName.isNotEmpty) {
      final parts = displayName.split(',').map((p) => p.trim()).toList();
      if (parts.isNotEmpty) cityName = parts.first;
      if (parts.length > 1) countryName = parts.last;
      if (cityName != null && countryName != null) {
        return [cityName, countryName].join(", ");
      }
    }

    // 3. Fallback: Reverse geocoding from coordinates
    final point = location.point;
    try {
      final placemarks = await geo.placemarkFromCoordinates(
        point.latitude,
        point.longitude,
      );
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        cityName ??= placemark.locality?.trim();
        countryName ??= placemark.country?.trim();
        if (cityName != null && countryName != null) {
          return [cityName, countryName].join(", ");
        }
      }
    } catch (e) {
      print('Error getting city name: $e');
    }

    // 4. Final fallback: just coordinates if no name found
    if (cityName != null && countryName != null)
      return [cityName, countryName].join(", ");
    if (cityName != null) return cityName;
    if (countryName != null) return countryName;

    return '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
  }
}

abstract class BaseReportWithPhotos extends BaseReportModel {
  // NOTE: make it nullable since there are reports without photos
  List<BasePhoto>? photos = [];

  BaseReportWithPhotos({
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
    this.photos,
    super.localId,
  });

  BasePhoto? get thumbnail {
    if (photos != null && photos!.isNotEmpty) {
      return photos!.first;
    }
    return null;
  }
}
