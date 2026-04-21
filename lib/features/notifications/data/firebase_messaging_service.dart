import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:mosquito_alert_app/app_config.dart';
import 'package:mosquito_alert_app/features/device/data/device_repository.dart';
import 'package:mosquito_alert_app/features/notifications/presentation/pages/notification_detail_page.dart';
import 'package:mosquito_alert_app/features/notifications/presentation/state/notification_provider.dart';
import 'package:mosquito_alert_app/features/notifications/presentation/widgets/notification_banner.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:provider/provider.dart';

class FirebaseMessagingService {
  final GlobalKey<NavigatorState> navigatorKey;

  static late DeviceRepository deviceRepository;

  static void configure({required DeviceRepository deviceRepository}) {
    FirebaseMessagingService.deviceRepository = deviceRepository;
  }

  FirebaseMessagingService({required this.navigatorKey});

  Future<void> init() async {
    final appConfig = await AppConfig.loadConfig();
    if (!appConfig.useAuth) return;

    await FirebaseMessaging.instance.requestPermission();

    // Foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage remoteMessage) {
      _handleForegroundMessage(remoteMessage);
    });

    // When the app is opened from a background state
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage remoteMessage) {
      _handleBackgroundMessage(remoteMessage);
    });

    FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken) async {
      await deviceRepository.updateFcmToken(fcmToken);
    });
  }

  void _refreshNotificationProvider(int notifId) {
    final ctx = navigatorKey.currentContext;
    if (ctx != null) {
      final provider = ctx.read<NotificationProvider>();
      unawaited(provider.refresh());
    }
  }

  Future<void> _navigateToNotificationDetail(int? notifId) async {
    if (notifId == null) return;

    final ctx = navigatorKey.currentContext;
    if (ctx == null) {
      print('[FCM] Navigator context not available, cannot navigate.');
      return;
    }

    final page = await NotificationDetailPage.fromId(
      context: ctx,
      notificationId: notifId,
      refresh: true,
    );

    Navigator.push(
      ctx,
      MaterialPageRoute(builder: (_) => page, fullscreenDialog: true),
    );
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final RemoteNotification? notification = message.notification;
    if (notification == null) {
      print('Notification is null, aborting launch.');
      return;
    }
    String? title = notification.title;
    String? msg = notification.body;
    if (title == null || msg == null) {
      print('Title or message is null, aborting launch.');
      return;
    }

    int? notifId = int.tryParse(message.data['id'].toString());

    if (notifId != null) {
      _refreshNotificationProvider(notifId);
    }

    showOverlayNotification((context) {
      return NotificationBanner(
        title: title,
        message: msg,
        onTap: () => _navigateToNotificationDetail(notifId),
      );
    }, duration: Duration(milliseconds: 4000));
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    final RemoteNotification? notification = message.notification;
    if (notification == null) {
      print('Notification is null, aborting launch.');
      return;
    }

    int? notifId = int.tryParse(message.data['id'].toString());

    if (notifId == null) {
      print('Notification ID is null, aborting navigation.');
      return;
    }

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      _navigateToNotificationDetail(notifId);
    });
  }
}
