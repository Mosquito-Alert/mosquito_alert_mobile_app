import 'dart:io';

import 'package:mosquito_alert/mosquito_alert.dart';

class BreedingSiteReportData {
  // Step 1: Site type
  String? siteType; // 'storm_drain' or 'other'

  // Step 2: Photos
  List<File> photos = [];

  // Step 3: Water presence
  bool? hasWater; // true = yes, false = no

  // Step 3.1: Larvae presence (only asked if hasWater == true)
  bool? hasLarvae; // true = yes, false = no

  // Step 4: Location
  double? latitude;
  double? longitude;
  LocationRequestSource_Enum locationSource =
      LocationRequestSource_Enum.auto;

  // Step 5: Notes
  String? notes;

  // Metadata
  DateTime createdAt = DateTime.now();

  /// Validates if the report data is complete enough to submit
  bool get isValid {
    return siteType != null &&
        photos.isNotEmpty &&
        hasWater != null &&
        // If water is present, larvae question must be answered
        (hasWater == false || hasLarvae != null) &&
        latitude != null &&
        longitude != null;
  }

  /// Gets a user-friendly location description
  String get locationDescription {
    if (latitude != null && longitude != null) {
      return '${latitude!.toStringAsFixed(4)}, ${longitude!.toStringAsFixed(4)}';
    }
    return 'No location selected';
  }

  /// Gets a user-friendly site type description
  String get siteTypeDescription {
    switch (siteType) {
      case 'storm_drain':
        return 'Storm drain';
      case 'other':
        return 'Other';
      default:
        return 'No site type selected';
    }
  }

  /// Gets a user-friendly water status description
  String get waterStatusDescription {
    if (hasWater == null) return 'Water status not selected';
    return hasWater! ? 'Water present' : 'No water';
  }

  /// Gets a user-friendly larvae status description
  String get larvaeStatusDescription {
    if (hasLarvae == null) return 'Larvae status not selected';
    return hasLarvae! ? 'Larvae visible' : 'No larvae visible';
  }

  /// Resets all data
  void reset() {
    siteType = null;
    photos.clear();
    hasWater = null;
    hasLarvae = null;
    latitude = null;
    longitude = null;
    locationSource = LocationRequestSource_Enum.auto;
    notes = null;
    createdAt = DateTime.now();
  }

  /// Creates a copy of the current data
  BreedingSiteReportData copy() {
    final copy = BreedingSiteReportData();
    copy.siteType = siteType;
    copy.photos = List.from(photos);
    copy.hasWater = hasWater;
    copy.hasLarvae = hasLarvae;
    copy.latitude = latitude;
    copy.longitude = longitude;
    copy.locationSource = locationSource;
    copy.notes = notes;
    copy.createdAt = createdAt;
    return copy;
  }
}
