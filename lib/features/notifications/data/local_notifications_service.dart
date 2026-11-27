import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Posts FCM messages received while the app is in the foreground as Android
/// system notifications. FCM only displays notification messages by itself
/// while the app is in the background.
///
/// Android only. iOS presents foreground messages natively (see
/// `FirebaseMessagingService.setUp`), and leaving this plugin uninitialized
/// there keeps the UNUserNotificationCenter delegate chain set up in
/// AppDelegate.swift untouched.
class LocalNotificationsService {
  LocalNotificationsService._();

  /// Also FCM's default channel (`default_notification_channel_id` in
  /// AndroidManifest.xml), so messages FCM displays while the app is in the
  /// background get the same importance.
  static const String channelId = 'high_importance_channel';

  // Plain English on purpose: the channel is created at startup, before the
  // app's localizations are loaded. Android allows renaming a channel later
  // by creating it again with the same id.
  static const String channelName = 'Notifications';
  static const String channelDescription =
      'Updates on the status of your contributions.';

  /// Drawable shown in the status bar; also FCM's
  /// `default_notification_icon` in AndroidManifest.xml.
  static const String androidIcon = 'ic_launcher_monochrome';

  /// High importance is what makes Android show heads-up notifications. A
  /// channel's importance is fixed once it exists: creating it again cannot
  /// raise it.
  static const AndroidNotificationChannel channel = AndroidNotificationChannel(
    channelId,
    channelName,
    description: channelDescription,
    importance: Importance.high,
  );

  static const NotificationDetails notificationDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      icon: androidIcon,
      importance: Importance.high,
      // Android 7 predates channels and uses the priority instead.
      priority: Priority.high,
    ),
  );

  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Creates [channel]. Until it exists, FCM posts background messages to a
  /// fallback channel of default importance, which never shows heads-up.
  static Future<void> createChannel() async {
    if (!isSupported) return;
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  /// [onTap] receives the payload of a notification posted by [show] that
  /// is tapped while the app is running. See [launchPayload] for a tap that
  /// launches the app.
  static Future<void> initialize({
    required void Function(String? payload) onTap,
  }) async {
    if (!isSupported) return;
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings(androidIcon),
      ),
      onDidReceiveNotificationResponse: (response) => onTap(response.payload),
    );
  }

  /// The payload of the notification posted by [show] whose tap launched the
  /// app, or null if the app was not launched that way.
  static Future<String?> launchPayload() async {
    if (!isSupported) return null;
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details == null || !details.didNotificationLaunchApp) return null;
    return details.notificationResponse?.payload;
  }

  static Future<void> show({
    required int id,
    String? title,
    String? body,
    String? payload,
  }) async {
    if (!isSupported) return;
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: payload,
    );
  }
}
