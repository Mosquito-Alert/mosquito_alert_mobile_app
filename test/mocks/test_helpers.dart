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
