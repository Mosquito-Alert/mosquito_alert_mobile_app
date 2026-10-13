import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mosquito_alert_app/features/notifications/data/local_notifications_service.dart';

import '../mocks/mocks.dart';

/// Value of the `<meta-data>` named [name] in the main AndroidManifest.xml.
String? manifestMetaData(String name) {
  final manifest = File(
    'android/app/src/main/AndroidManifest.xml',
  ).readAsStringSync();
  final match = RegExp(
    '<meta-data\\s+android:name="${RegExp.escape(name)}"\\s+'
    'android:(?:value|resource)="([^"]*)"',
  ).firstMatch(manifest);
  return match?.group(1);
}

void main() {
  group('channel', () {
    test('is high importance, which is what shows heads-up', () {
      expect(LocalNotificationsService.channel.id, 'high_importance_channel');
      expect(LocalNotificationsService.channel.importance, Importance.high);
    });

    test('gets notifications at high priority with the monochrome icon', () {
      final details = LocalNotificationsService.notificationDetails.android!;
      expect(details.channelId, LocalNotificationsService.channel.id);
      expect(details.channelName, LocalNotificationsService.channel.name);
      expect(details.importance, Importance.high);
      expect(details.priority, Priority.high);
      expect(details.icon, LocalNotificationsService.androidIcon);
    });
  });

  group('Android resources (source tripwire)', () {
    // Each of these fails silently on devices: FCM falls back to a channel of
    // default importance, or the plugin rejects an unknown icon.
    test('FCM posts background messages to the channel the app creates', () {
      expect(
        manifestMetaData(
          'com.google.firebase.messaging.default_notification_channel_id',
        ),
        LocalNotificationsService.channelId,
      );
    });

    test('FCM uses the same status bar icon as local notifications', () {
      expect(
        manifestMetaData(
          'com.google.firebase.messaging.default_notification_icon',
        ),
        '@drawable/${LocalNotificationsService.androidIcon}',
      );
    });

    test('the icon is a drawable resource', () {
      final drawableDirs = Directory('android/app/src/main/res')
          .listSync()
          .whereType<Directory>()
          .where(
            (dir) => dir.path
                .split(Platform.pathSeparator)
                .last
                .startsWith('drawable'),
          );
      final icon = LocalNotificationsService.androidIcon;
      expect(
        drawableDirs.any(
          (dir) =>
              File('${dir.path}/$icon.png').existsSync() ||
              File('${dir.path}/$icon.xml').existsSync(),
        ),
        isTrue,
      );
    });
  });

  group('platform calls', () {
    late MockLocalNotifications mock;

    setUp(() => mock = MockLocalNotifications()..install());

    tearDown(() {
      mock.uninstall();
      debugDefaultTargetPlatformOverride = null;
    });

    test('create the channel on Android', () async {
      await LocalNotificationsService.createChannel();

      final calls = mock.callsTo('createNotificationChannel');
      expect(calls, hasLength(1));
      expect(calls.single.arguments['id'], LocalNotificationsService.channelId);
      expect(calls.single.arguments['importance'], Importance.high.value);
    });

    test('are skipped on iOS, which presents foreground messages', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      mock.install();

      expect(LocalNotificationsService.isSupported, isFalse);
      await LocalNotificationsService.createChannel();
      await LocalNotificationsService.initialize(onTap: (_) {});
      await LocalNotificationsService.show(id: 1, title: 'title', body: 'body');
      expect(await LocalNotificationsService.launchPayload(), isNull);
      expect(mock.calls, isEmpty);
    });

    test(
      'report the payload of a notification that launched the app',
      () async {
        mock.launchDetails = {
          'notificationLaunchedApp': true,
          'notificationResponse': {
            'notificationId': 7,
            'payload': '7',
            'notificationResponseType': 0,
          },
        };

        expect(await LocalNotificationsService.launchPayload(), '7');
      },
    );

    test('report no payload when no notification launched the app', () async {
      expect(await LocalNotificationsService.launchPayload(), isNull);
    });

    test('pass the payload of a tapped notification to onTap', () async {
      final payloads = <String?>[];
      await LocalNotificationsService.initialize(onTap: payloads.add);

      await mock.tap(payload: '7');

      expect(payloads, ['7']);
    });
  });
}
