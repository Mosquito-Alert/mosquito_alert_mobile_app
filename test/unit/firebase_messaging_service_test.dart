import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mosquito_alert_app/app_config.dart';
import 'package:mosquito_alert_app/features/notifications/data/firebase_messaging_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('parseNotificationId', () {
    test('reads the backend id from FCM data and local payloads', () {
      expect(parseNotificationId('42'), 42);
      expect(parseNotificationId(42), 42);
      expect(parseNotificationId(' 42 '), 42);
    });

    test('is null for anything that is not an id', () {
      for (final value in <Object?>[null, '', 'null', 'abc', '4.2', '42a']) {
        expect(parseNotificationId(value), isNull, reason: '$value');
      }
    });
  });

  group('localNotificationIdFor', () {
    test('reuses the backend id', () {
      const message = RemoteMessage(messageId: 'm1', data: {'id': '42'});
      expect(localNotificationIdFor(message), 42);
    });

    test('otherwise derives a stable 32-bit id from the message id', () {
      final cases = <Map<String, dynamic>>[
        {},
        {'id': 'abc'},
        {'id': '-1'},
        {'id': '2147483648'},
      ];
      for (final data in cases) {
        final id = localNotificationIdFor(
          RemoteMessage(messageId: 'm1', data: data),
        );
        expect(id, inInclusiveRange(0, 0x7FFFFFFF), reason: '$data');
        expect(
          localNotificationIdFor(RemoteMessage(messageId: 'm1', data: data)),
          id,
          reason: '$data',
        );
      }
    });
  });

  group('init', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      FirebaseMessagingService.resetForTesting();
    });

    tearDown(FirebaseMessagingService.resetForTesting);

    test('runs once however many times LayoutPage is mounted', () async {
      // Push is off in the test environment (useAuth: false), so the run
      // returns before it reaches Firebase.
      await AppConfig.setEnvironment('test');

      final first = FirebaseMessagingService(navigatorKey: GlobalKey()).init();
      expect(
        FirebaseMessagingService(navigatorKey: GlobalKey()).init(),
        same(first),
      );
      await first;
      expect(
        FirebaseMessagingService(navigatorKey: GlobalKey()).init(),
        same(first),
      );
    });
  });
}
