import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:mosquito_alert_app/models/report.dart';
import 'package:mosquito_alert_app/models/topic.dart';
import 'dart:async';
import '../api/api.dart';
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
        // ignore: missing_return
        onMessage: (Map<String, dynamic> message) {
          print(message);
        }
      );
      _firebaseMessaging.onIosSettingsRegistered
          .listen((IosNotificationSettings settings) {});

      var token = await _firebaseMessaging.getToken();
      await registerFCMToken(token);
      await getTopicsSubscribed();
      _initialized = true;
    }
  }

  static Future<void> registerFCMToken(String fcmToken) async {
    var userId = await UserManager.getUUID();
    var result = ApiSingleton().setFirebaseToken(userId, fcmToken);
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
    var userId = await UserManager.getUUID();
    if (userId != null && !_checkIfSubscribed(topic)) {
      var result = await ApiSingleton().subscribeToTopic(userId, topic);
      //print('Registering for TOPIC: $result');
    }
  }

  static Future<void> unsubscribeToTopic(String topic) async {
    var userId = await UserManager.getUUID();
    if (userId != null && _checkIfSubscribed(topic)) {
      var result = await ApiSingleton().unsubscribeFromTopic(userId, topic);
      //print('Unregistering for TOPIC: $result');
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
