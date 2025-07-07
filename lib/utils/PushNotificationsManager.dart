import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:mosquito_alert_app/app_config.dart';
import 'package:mosquito_alert_app/models/report.dart';
import 'package:mosquito_alert_app/models/topic.dart';
import 'package:mosquito_alert_app/utils/MessageNotification.dart';
import 'package:mosquito_alert_app/utils/Utils.dart';
import 'package:overlay_support/overlay_support.dart';

import '../api/api.dart';
import '../main.dart';
import '../pages/notification_pages/notifications_page.dart';
import 'UserManager.dart';

class PushNotificationsManager {
  PushNotificationsManager._();

  factory PushNotificationsManager() => _instance;
  static final PushNotificationsManager _instance =
      PushNotificationsManager._();
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static bool _initialized = false;
  static List<Topic> currentTopics = <Topic>[];

  /*
  * Push Notification Manager Init
  */
  static Future<void> init() async {
    final appConfig = await AppConfig.loadConfig();
    if (!_initialized && appConfig.useAuth) {
      await _firebaseMessaging.requestPermission();

      FirebaseMessaging.onMessage.listen((RemoteMessage remoteMessage) {
        launchMessage(remoteMessage);
      });

      FirebaseMessaging.onMessageOpenedApp
          .listen((RemoteMessage remoteMessage) {
        openMessageScreen(remoteMessage.data);
      });

      if (Platform.isIOS) {
        await FirebaseMessaging.instance.getAPNSToken();
      }

      var token = await FirebaseMessaging.instance
          .getToken()
          .timeout(Duration(seconds: 10), onTimeout: () => null);

      if (token != null) {
        await registerFCMToken(token);
        await getTopicsSubscribed();
        Utils.initializedCheckData['firebase'] = true;
        _initialized = true;
      }
    }
  }

  static void launchMessage(RemoteMessage message) {
    String? title = message.notification?.title;
    String? msg = message.notification?.body;
    var notifId = message.data['id'];

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
    var notifId = '';

    if (Platform.isIOS) {
      try {
        notifId = "${jsonDecode(message['id'])}";
      } catch (e) {
        print(e);
      }
    } else {
      try {
        notifId = "${message['id']}";
      } catch (e) {
        print(e);
      }
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

  static Future<void> registerFCMToken(String fcmToken) async {
    var userId = await UserManager.getUUID();
    ApiSingleton().setFirebaseToken(userId, fcmToken);
    await subscribeToGlobal();
  }

  static Future<void> subscribeToGlobal() async {
    var topic = 'global';
    await subscribeToTopic(topic);
  }

  static Future<void> subscribeToReportResult(Report report) async {
    try {
      if (report.country != null) {
        await subscribeToTopic('${report.country}');
      }
      if (report.nuts2 != null) {
        await subscribeToTopic('${report.nuts2}');
      }
      if (report.nuts3 != null) {
        await subscribeToTopic('${report.nuts3}');
      }
    } catch (e) {
      print('Report subscription failed for reason: $e');
    }
  }

  static Future<void> subscribeToLanguage() async {
    var languageId = await UserManager.getLanguage();
    await subscribeToTopic(languageId);
  }

  static Future<void> subscribeToTopic(String? topic) async {
    if (_initialized) {
      var userId = await UserManager.getUUID();
      if (userId != null && !_checkIfSubscribed(topic)) {
        var result = await ApiSingleton().subscribeToTopic(userId, topic);
        if (result) {
          await _firebaseMessaging.subscribeToTopic(topic!);
        } else if (topic == 'global') {
          await _firebaseMessaging.subscribeToTopic('global');
        }
      }
    }
  }

  static Future<void> unsubscribeToTopic(String topic) async {
    var userId = await UserManager.getUUID();
    if (userId != null && _checkIfSubscribed(topic)) {
      var result = await ApiSingleton().unsubscribeFromTopic(userId, topic);
      if (result) {
        await _firebaseMessaging.unsubscribeFromTopic(topic);
      }
    }
  }

  static Future<List<Topic>?> getTopicsSubscribed() async {
    var userId = await UserManager.getUUID();
    if (userId != null) {
      var result = await ApiSingleton().getTopicsSubscribed(userId);
      if (result != null) {
        currentTopics = result;
      }
    }
    return null;
  }

  static bool _checkIfSubscribed(String? topicCode) {
    for (var topic in currentTopics) {
      if (topic.topicCode == topicCode) {
        return true;
      }
    }
    return false;
  }
}
