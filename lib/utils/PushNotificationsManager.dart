import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
        launchMessage(remoteMessage);
      });

      // When the app is opened from a background state
      FirebaseMessaging.onMessageOpenedApp
          .listen((RemoteMessage remoteMessage) {
        openMessageScreen(remoteMessage.data);
      });
    }
  }

  static void launchMessage(RemoteMessage message) {
    String? title = message.notification?.title;
    String? msg = message.notification?.body;
    int? notifId = int.tryParse(message.data['id'].toString());
    // Don't proceed if notifId is null
    if (notifId == null) {
      print('Notification ID is null, aborting navigation.');
      return;
    }

    if (title!.isNotEmpty || msg!.isNotEmpty) {
      showOverlayNotification((context) {
        return MessageNotification(
          title: title,
          message: msg,
          onTap: () {
            OverlaySupportEntry.of(context)!.dismiss();
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
  }

  static void openMessageScreen(Map<String, dynamic> message) {
    int? notifId;

    try {
      final rawId = message['id'];

      if (Platform.isIOS) {
        notifId = int.tryParse(jsonDecode(rawId).toString());
      } else {
        notifId = int.tryParse(rawId.toString());
      }
    } catch (e) {
      print('Error parsing notification ID: $e');
    }

    // Don't proceed if notifId is null
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
