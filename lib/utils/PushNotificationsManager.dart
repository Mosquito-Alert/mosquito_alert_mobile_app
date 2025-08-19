import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:mosquito_alert_app/app_config.dart';
import 'package:mosquito_alert_app/utils/MessageNotification.dart';
import 'package:overlay_support/overlay_support.dart';

import '../main.dart';
import '../pages/notification_pages/notifications_page.dart';

class PushNotificationsManager {
  PushNotificationsManager._();

  factory PushNotificationsManager() => _instance;
  static final PushNotificationsManager _instance =
      PushNotificationsManager._();

  /*
  * Push Notification Manager Init
  */
  static Future<void> init() async {
    final appConfig = await AppConfig.loadConfig();
    if (appConfig.useAuth) {
      await FirebaseMessaging.instance.requestPermission();

      // Foreground message handler
      FirebaseMessaging.onMessage.listen((RemoteMessage remoteMessage) {
        _handleForegroundMessage(remoteMessage);
      });

      // When the app is opened from a background state
      FirebaseMessaging.onMessageOpenedApp
          .listen((RemoteMessage remoteMessage) {
        _handleBackgroundMessage(remoteMessage);
      });
    }
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
        onTap: () {
          OverlaySupportEntry.of(context)!.dismiss();
          if (notifId == null) {
            print('Notification ID is null, not navigating.');
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => NotificationsPage(
                      notificationId: notifId,
                    ),
                fullscreenDialog: true),
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

    SchedulerBinding.instance.addPostFrameCallback((_) {
      Navigator.push(
        navigatorKey.currentContext!,
        MaterialPageRoute(
            builder: (context) => NotificationsPage(
                  notificationId: notifId,
                ),
            fullscreenDialog: true),
      );
      ;
    });
  }
}
