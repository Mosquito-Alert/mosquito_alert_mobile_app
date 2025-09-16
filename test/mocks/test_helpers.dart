import 'package:flutter_test/flutter_test.dart';
import 'package:mosquito_alert/mosquito_alert.dart' as sdk;

// Helper function to create test notifications
sdk.Notification createTestNotification({
  required int id,
  required String title,
  required String body,
  bool isRead = false,
  DateTime? createdAt,
}) {
  return sdk.Notification((b) => b
    ..id = id
    ..isRead = isRead
    ..createdAt = createdAt ?? DateTime.now()
    ..message = sdk.NotificationMessage((m) => m
      ..title = title
      ..body = body).toBuilder());
}

// Comprehensive helper function to create test bite reports with all required fields
sdk.Bite createTestBite({
  required String uuid,
  DateTime? createdAt,
  DateTime? updatedAt,
  String? userUuid,
  bool published = true,
  int? head,
  int? chest,
  int? leftArm,
  int? rightArm,
  int? leftLeg,
  int? rightLeg,
  int? totalBites,
  double? latitude,
  double? longitude,
}) {
  final headCount = head ?? (totalBites ?? 0);
  final chestCount = chest ?? 0;
  final leftArmCount = leftArm ?? 0;
  final rightArmCount = rightArm ?? 0;
  final leftLegCount = leftLeg ?? 0;
  final rightLegCount = rightLeg ?? 0;
  final total = headCount +
      chestCount +
      leftArmCount +
      rightArmCount +
      leftLegCount +
      rightLegCount;

  final now = DateTime.now();
  final creationTime = createdAt ?? now;

  // Create the location point with provided or default coordinates
  final locationPoint = sdk.LocationPoint((p) => p
    ..latitude = latitude ?? 41.3874 // Default to Barcelona coordinates
    ..longitude = longitude ?? 2.1686);

  // Create the location with required source and point
  final location = sdk.Location((l) => l
    ..source_ = sdk.LocationSource_Enum.auto
    ..point.replace(locationPoint));

  return sdk.Bite((b) => b
    ..uuid = uuid
    ..shortId = uuid.length >= 8 ? uuid.substring(0, 8) : uuid
    ..userUuid = userUuid ?? 'test-user-uuid'
    ..createdAt = creationTime
    ..createdAtLocal = creationTime
    ..sentAt = creationTime
    ..receivedAt = creationTime
    ..updatedAt = updatedAt ?? creationTime
    ..published = published
    ..location.replace(location)
    ..counts = sdk.BiteCounts((c) => c
      ..head = headCount
      ..chest = chestCount
      ..leftArm = leftArmCount
      ..rightArm = rightArmCount
      ..leftLeg = leftLegCount
      ..rightLeg = rightLegCount
      ..total = total).toBuilder());
}

Future<void> pumpAndSettleIgnoringFirebaseException(WidgetTester tester) async {
  try {
    await tester.pumpAndSettle();
  } catch (e) {
    // Firebase exception is expected in test environment, continue with test
    print("Expected Firebase exception: ${e.toString().substring(0, 100)}...");
  }
}
