import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:mosquito_alert_app/app_config.dart';
import 'package:mosquito_alert_app/features/device/data/device_repository.dart';
import 'package:mosquito_alert_app/features/notifications/data/local_notifications_service.dart';
import 'package:mosquito_alert_app/features/notifications/presentation/pages/notification_detail_page.dart';
import 'package:mosquito_alert_app/features/notifications/presentation/state/notification_provider.dart';
import 'package:provider/provider.dart';

/// Receives FCM messages while the app is in the background or terminated:
/// on Android in a separate isolate, on iOS in the main one. The OS displays
/// notification messages itself then, so there is no UI here. Without a
/// registered handler FCM drops data messages and logs "A background message
/// could not be handled in Dart as no onBackgroundMessage handler has been
/// registered".
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

/// The backend Notification id a push refers to: `data['id']` of the FCM
/// message, which is also the payload of the local notification showing it.
int? parseNotificationId(Object? value) =>
    value == null ? null : int.tryParse(value.toString().trim());

/// Id of the local notification showing [message]. Reusing the backend id
/// makes a redelivered message replace its notification instead of adding a
/// copy. Android notification ids are 32-bit.
int localNotificationIdFor(RemoteMessage message) {
  final id = parseNotificationId(message.data['id']);
  if (id != null && id >= 0 && id <= 0x7FFFFFFF) return id;
  return (message.messageId?.hashCode ?? message.hashCode) & 0x7FFFFFFF;
}

class FirebaseMessagingService {
  final GlobalKey<NavigatorState> navigatorKey;

  static late DeviceRepository deviceRepository;

  static void configure({required DeviceRepository deviceRepository}) {
    FirebaseMessagingService.deviceRepository = deviceRepository;
  }

  FirebaseMessagingService({required this.navigatorKey});

  /// Startup wiring for the main isolate, before runApp (not for Workmanager's
  /// callbackDispatcher).
  static Future<void> setUp() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    try {
      await LocalNotificationsService.createChannel();
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        // iOS shows foreground messages as system banners itself, so no local
        // notification is posted there (it would be a duplicate).
        await FirebaseMessaging.instance
            .setForegroundNotificationPresentationOptions(
              alert: true,
              badge: true,
              sound: true,
            );
      }
    } catch (e) {
      print('[FCM] Notification setup failed: $e');
    }
  }

  static Future<void>? _initialization;

  /// Registers the listeners and handles a notification tap that launched the
  /// app. Runs once per isolate: LayoutPage calls this from initState and can
  /// be mounted more than once (e.g. after logging out and in again).
  Future<void> init() => _initialization ??= _init();

  @visibleForTesting
  static void resetForTesting() => _initialization = null;

  Future<void> _init() async {
    final appConfig = await AppConfig.loadConfig();
    if (!appConfig.useAuth) return;

    final messaging = FirebaseMessaging.instance;

    FirebaseMessaging.onMessage.listen(handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(handleMessageOpenedApp);
    messaging.onTokenRefresh.listen((fcmToken) async {
      await deviceRepository.updateFcmToken(fcmToken);
    });

    try {
      await LocalNotificationsService.initialize(onTap: handleNotificationTap);

      // A tap that launched the app from a terminated state.
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) handleMessageOpenedApp(initialMessage);
      final launchPayload = await LocalNotificationsService.launchPayload();
      if (launchPayload != null) handleNotificationTap(launchPayload);
    } catch (e) {
      print('[FCM] Could not handle notification taps: $e');
    }

    await messaging.requestPermission();
  }

  /// A message received while the app is in the foreground.
  @visibleForTesting
  void handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    // Data-only messages are not meant to be shown.
    if (notification == null) return;

    _refreshNotifications();

    if (notification.title == null && notification.body == null) return;
    unawaited(_showLocalNotification(message, notification));
  }

  /// The user tapped a notification displayed by FCM.
  @visibleForTesting
  void handleMessageOpenedApp(RemoteMessage message) =>
      _openNotification(parseNotificationId(message.data['id']));

  /// The user tapped a notification posted by [LocalNotificationsService].
  @visibleForTesting
  void handleNotificationTap(String? payload) =>
      _openNotification(parseNotificationId(payload));

  Future<void> _showLocalNotification(
    RemoteMessage message,
    RemoteNotification notification,
  ) async {
    try {
      await LocalNotificationsService.show(
        id: localNotificationIdFor(message),
        title: notification.title,
        body: notification.body,
        payload: parseNotificationId(message.data['id'])?.toString(),
      );
    } catch (e) {
      print('[FCM] Could not show notification: $e');
    }
  }

  void _refreshNotifications() {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;
    unawaited(ctx.read<NotificationProvider>().refresh());
  }

  void _openNotification(int? notificationId) {
    if (notificationId == null) return;
    // On a cold start the navigator may not have been built yet.
    SchedulerBinding.instance.addPostFrameCallback(
      (_) => _navigateToNotificationDetail(notificationId),
    );
    SchedulerBinding.instance.ensureVisualUpdate();
  }

  Future<void> _navigateToNotificationDetail(int notificationId) async {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) {
      print('[FCM] Navigator context not available, cannot navigate.');
      return;
    }

    try {
      final page = await NotificationDetailPage.fromId(
        context: ctx,
        notificationId: notificationId,
        refresh: true,
      );

      if (ctx.mounted) {
        Navigator.push(
          ctx,
          MaterialPageRoute(builder: (_) => page, fullscreenDialog: true),
        );
      }
    } catch (e) {
      print('[FCM] Could not open notification $notificationId: $e');
    }
  }
}
