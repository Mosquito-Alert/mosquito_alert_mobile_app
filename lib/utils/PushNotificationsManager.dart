import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  static bool _initialized = false;
  static List<Topic> currentTopics = <Topic>[];

  /*
  * Push Notification Manager Init
  */
  static Future<void> init() async {
    if (!_initialized) {
      _firebaseMessaging.requestNotificationPermissions();
      _firebaseMessaging.configure(
        onMessage: (Map<String, dynamic> message) async {
          launchMessage(message);
        },
        onLaunch: (Map<String, dynamic> message) async {
          openMessageScreen(message);
        },
        onResume: (Map<String, dynamic> message) async {
          openMessageScreen(message);
        },
      );
      _firebaseMessaging.onIosSettingsRegistered
          .listen((IosNotificationSettings settings) {});

      var token = await _firebaseMessaging
          .getToken()
          .timeout(Duration(seconds: 10), onTimeout: () => null);

      if (token != null) {
        await registerFCMToken(token);
        await getTopicsSubscribed();
        // Utils.firebaseLoaded = true;
        Utils.initializedCheckData["firebase"] = true;
        _initialized = true;
      }
    }
  }

  static launchMessage(Map<String, dynamic> message) {
    var title = "";
    var msg = "";
    var notifId = "";

    if (Platform.isIOS) {
      final jsonData = jsonDecode(message['notification']);

      try {
        title = jsonData["title"];
      } catch (e) {
        print(e);
      }

      try {
        msg = jsonData["body"];
      } catch (e) {
        print(e);
      }
      try {
        notifId = "${jsonDecode(message['notification_id'])}";
      } catch (e) {
        print(e);
      }
    } else {
      try {
        title = message['notification']["title"];
      } catch (e) {
        print(e);
      }

      try {
        msg = message['notification']["body"];
      } catch (e) {
        print(e);
      }

      try {
        notifId = "${message['data']['notification_id']}";
      } catch (e) {
        print(e);
      }
    }

    if (title.isNotEmpty || msg.isNotEmpty) {
      showOverlayNotification((context) {
        return MessageNotification(
          title: title,
          message: msg,
          onTap: () {
            OverlaySupportEntry.of(context).dismiss();
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

  static openMessageScreen(Map<String, dynamic> message) {
    var notifId = "";

    if (Platform.isIOS) {
      try {
        notifId = "${jsonDecode(message['notification_id'])}";
      } catch (e) {
        print(e);
      }
    } else {
      try {
        notifId = "${message['data']['notification_id']}";
      } catch (e) {
        print(e);
      }
    }

    SchedulerBinding.instance.addPostFrameCallback((_) {
      Navigator.push(
        navigatorKey.currentContext,
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
    var result = ApiSingleton().setFirebaseToken(userId, fcmToken);
    await subscribeToGlobal();
  }

  static Future<void> subscribeToGlobal() async {
    var topic = "global";
    await subscribeToTopic(topic);
  }

  static Future<void> subscribeToReportResult(Report report) async {
    try {
      if (report != null) {
        if (report.country != null) {
          await subscribeToTopic('${report.country}');
        }
        if (report.nuts2 != null) {
          await subscribeToTopic('${report.nuts2}');
        }
        if (report.nuts3 != null) {
          await subscribeToTopic('${report.nuts3}');
        }
      }
    } catch (e) {
      print('Report subscription failed for reason: ${e}');
    }
  }

  static Future<void> subscribeToLanguage() async {
    var languageId = await UserManager.getLanguage();
    await subscribeToTopic(languageId);
  }

  static Future<void> subscribeToTopic(String topic) async {
    if (_initialized) {
      var userId = await UserManager.getUUID();
      if (userId != null && !_checkIfSubscribed(topic)) {
        var result = await ApiSingleton().subscribeToTopic(userId, topic);
        if (result != null && result) {
          await _firebaseMessaging.subscribeToTopic(topic);
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
      if (result != null && result) {
        await _firebaseMessaging.unsubscribeFromTopic(topic);
      }
    }
  }

  static Future<List<Topic>> getTopicsSubscribed() async {
    var userId = await UserManager.getUUID();
    if (userId != null) {
      var result = await ApiSingleton().getTopicsSubscribed(userId);
      if (result != null) {
        currentTopics = result;
      }
    }
  }

  static bool _checkIfSubscribed(String topicCode) {
    for (var topic in currentTopics) {
      if (topic.topicCode == topicCode) {
        return true;
      }
    }
    return false;
  }
}
