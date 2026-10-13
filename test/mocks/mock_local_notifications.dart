import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

/// Stands in for the native side of flutter_local_notifications: records the
/// calls the app makes and can play back a notification tap.
class MockLocalNotifications {
  static const MethodChannel channel = MethodChannel(
    'dexterous.com/flutter/local_notifications',
  );

  final List<MethodCall> calls = [];

  /// What getNotificationAppLaunchDetails returns.
  Map<String, Object?> launchDetails = {'notificationLaunchedApp': false};

  /// Call after any [debugDefaultTargetPlatformOverride]: the plugin only
  /// reaches the channel through the implementation for the current platform.
  void install() {
    TestWidgetsFlutterBinding.ensureInitialized();
    // Tests do not run the plugin registrant that does this in the app.
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      IOSFlutterLocalNotificationsPlugin.registerWith();
    } else {
      AndroidFlutterLocalNotificationsPlugin.registerWith();
    }
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
          calls.add(call);
          switch (call.method) {
            case 'initialize':
              return true;
            case 'getNotificationAppLaunchDetails':
              return launchDetails;
            default:
              return null;
          }
        });
  }

  void uninstall() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  }

  List<MethodCall> callsTo(String method) =>
      calls.where((call) => call.method == method).toList();

  /// Plays back the user tapping a notification while the app is running.
  Future<void> tap({required String payload}) async {
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
          channel.name,
          channel.codec.encodeMethodCall(
            MethodCall('didReceiveNotificationResponse', {
              'notificationId': 1,
              'payload': payload,
              'notificationResponseType': 0,
            }),
          ),
          (_) {},
        );
  }
}
