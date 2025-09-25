import 'dart:io';

import 'package:mosquito_alert/mosquito_alert.dart';

class AdultReportData {
  // Step 1: Photos
  List<File> photos = [];

  // Step 2: Location
  double? latitude;
  double? longitude;
  LocationRequestSource_Enum locationSource =
      LocationRequestSource_Enum.auto;

  // Step 3: Environment question
  String? environmentAnswer; // 'vehicle', 'indoors', 'outdoors', '', null

  // Step 4: Event timing (when the mosquito was found)
  String?
      eventMoment; // 'now', 'last_morning', 'last_midday', 'last_afternoon', 'last_night', '', null,

  // Step 5: Notes
  String? notes;

  // Metadata
  DateTime createdAt = DateTime.now();

  /// Validates if the report data is complete enough to submit
  bool get isValid {
    return photos.isNotEmpty && latitude != null && longitude != null;
  }

  /// Gets a user-friendly location description
  String get locationDescription {
    if (latitude != null && longitude != null) {
      return '${latitude!.toStringAsFixed(4)}, ${longitude!.toStringAsFixed(4)}';
    }
    return 'No location selected';
  }

  /// Resets all data
  void reset() {
    photos.clear();
    latitude = null;
    longitude = null;
    locationSource = LocationRequestSource_Enum.auto;
    environmentAnswer = null;
    eventMoment = null;
    notes = null;
    createdAt = DateTime.now();
  }

  /// Creates a copy of the current data
  AdultReportData copy() {
    final copy = AdultReportData();
    copy.photos = List.from(photos);
    copy.latitude = latitude;
    copy.longitude = longitude;
    copy.locationSource = locationSource;
    copy.environmentAnswer = environmentAnswer;
    copy.eventMoment = eventMoment;
    copy.notes = notes;
    copy.createdAt = createdAt;
    return copy;
  }
}
