import 'package:flutter/foundation.dart';
import 'package:mosquito_alert/mosquito_alert.dart';

class BiteReportData extends ChangeNotifier {
  // Bite counts by body part
  int _headBites = 0;
  int _leftHandBites = 0;
  int _rightHandBites = 0;
  int _chestBites = 0;
  int _leftLegBites = 0;
  int _rightLegBites = 0;

  // Getters
  int get headBites => _headBites;
  int get leftHandBites => _leftHandBites;
  int get rightHandBites => _rightHandBites;
  int get chestBites => _chestBites;
  int get leftLegBites => _leftLegBites;
  int get rightLegBites => _rightLegBites;

  // Setters with notifications
  set headBites(int value) {
    _headBites = value;
    notifyListeners();
  }

  set leftHandBites(int value) {
    _leftHandBites = value;
    notifyListeners();
  }

  set rightHandBites(int value) {
    _rightHandBites = value;
    notifyListeners();
  }

  set chestBites(int value) {
    _chestBites = value;
    notifyListeners();
  }

  set leftLegBites(int value) {
    _leftLegBites = value;
    notifyListeners();
  }

  set rightLegBites(int value) {
    _rightLegBites = value;
    notifyListeners();
  }

  // Location
  double? latitude;
  double? longitude;
  LocationRequestSource_Enum locationSource = LocationRequestSource_Enum.auto;

  // Environment question (where did the biting occur)
  BiteRequestEventEnvironmentEnum? eventEnvironment;

  // Event timing (when did the biting occur)
  BiteRequestEventMomentEnum? eventMoment;

  // Notes
  String? notes;

  // Metadata
  DateTime createdAt = DateTime.now();

  /// Gets total number of bites across all body parts
  int get totalBites {
    return headBites +
        leftHandBites +
        rightHandBites +
        chestBites +
        leftLegBites +
        rightLegBites;
  }

  /// Validates if the report data is complete enough to submit
  bool get isValid {
    return totalBites > 0 &&
        latitude != null &&
        longitude != null &&
        eventEnvironment != null &&
        eventMoment != null;
  }

  /// Gets a user-friendly location description
  String get locationDescription {
    if (latitude != null && longitude != null) {
      return '${latitude!.toStringAsFixed(4)}, ${longitude!.toStringAsFixed(4)}';
    }
    return 'No location selected';
  }

  /// Checks if bite counts step is complete
  bool get hasValidBiteCounts {
    return totalBites > 0;
  }

  /// Checks if location step is complete
  bool get hasValidLocation {
    return latitude != null && longitude != null;
  }

  /// Checks if environment question is answered
  bool get hasValidEnvironment {
    return eventEnvironment != null;
  }

  /// Checks if timing question is answered
  bool get hasValidTiming {
    return eventMoment != null;
  }

  /// Resets all data
  void reset() {
    headBites = 0;
    leftHandBites = 0;
    rightHandBites = 0;
    chestBites = 0;
    leftLegBites = 0;
    rightLegBites = 0;
    latitude = null;
    longitude = null;
    locationSource = LocationRequestSource_Enum.auto;
    eventEnvironment = null;
    eventMoment = null;
    notes = null;
    createdAt = DateTime.now();
  }

  /// Creates a copy of the current data
  BiteReportData copy() {
    final copy = BiteReportData();
    copy.headBites = headBites;
    copy.leftHandBites = leftHandBites;
    copy.rightHandBites = rightHandBites;
    copy.chestBites = chestBites;
    copy.leftLegBites = leftLegBites;
    copy.rightLegBites = rightLegBites;
    copy.latitude = latitude;
    copy.longitude = longitude;
    copy.locationSource = locationSource;
    copy.eventEnvironment = eventEnvironment;
    copy.eventMoment = eventMoment;
    copy.notes = notes;
    copy.createdAt = createdAt;
    return copy;
  }
}
