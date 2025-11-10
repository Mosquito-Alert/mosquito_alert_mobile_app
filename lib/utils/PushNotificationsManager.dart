import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:mosquito_alert_app/app_config.dart';
import 'package:mosquito_alert_app/pages/notification_pages/notification_detail_page.dart';
import 'package:mosquito_alert_app/providers/device_provider.dart';
import 'package:mosquito_alert_app/utils/MessageNotification.dart';
import 'package:overlay_support/overlay_support.dart';

import '../main.dart';

class PushNotificationsManager {
  PushNotificationsManager._();

  factory PushNotificationsManager() => _instance;
  static final PushNotificationsManager _instance =
      PushNotificationsManager._();

  /*
  * Push Notification Manager Init
  */
  static Future<void> init({required DeviceProvider provider}) async {
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
      await provider.updateFcmToken(fcmToken);
    });
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
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

    showOverlayNotification((context) {
      return MessageNotification(
        title: title,
        message: msg,
        onTap: () async {
          OverlaySupportEntry.of(context)!.dismiss();
          if (notifId == null) {
            print('Notification ID is null, not navigating.');
            return;
          }

          final BuildContext? ctx = navigatorKey.currentContext;
          if (ctx == null) {
            print('Navigator context not ready.');
            return;
          }
          final notificationDetailPage = await NotificationDetailPage.fromId(
            context: ctx,
            notificationId: notifId,
          );
          Navigator.push(
            ctx,
            MaterialPageRoute(
                builder: (_) => notificationDetailPage, fullscreenDialog: true),
          );
        },
      );
    }, duration: Duration(milliseconds: 4000));
  }

  static void _handleBackgroundMessage(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
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
      final ctx = navigatorKey.currentContext;
      if (ctx == null) {
        print('Navigator context not available yet.');
        return;
      }
      final notificationDetailPage = await NotificationDetailPage.fromId(
        context: ctx,
        notificationId: notifId,
      );
      Navigator.push(
        ctx,
        MaterialPageRoute(
            builder: (_) => notificationDetailPage, fullscreenDialog: true),
      );
    });
  }
}
