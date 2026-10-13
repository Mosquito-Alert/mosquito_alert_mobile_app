import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mosquito_alert_app/features/notifications/data/firebase_messaging_service.dart';
import 'package:mosquito_alert_app/features/notifications/data/local_notifications_service.dart';
import 'package:mosquito_alert_app/features/notifications/notification_repository.dart';
import 'package:mosquito_alert_app/features/notifications/presentation/pages/notification_detail_page.dart';
import 'package:mosquito_alert_app/features/notifications/presentation/state/notification_provider.dart';
import 'package:provider/provider.dart';

import '../mocks/mocks.dart';

const title = 'Your mosquito was identified';
const body = 'It is a tiger mosquito.';

RemoteMessage push({String? id, bool withNotification = true}) {
  return RemoteMessage(
    messageId: 'message-1',
    data: {'id': ?id},
    notification: withNotification
        ? const RemoteNotification(title: title, body: body)
        : null,
  );
}

void main() {
  late MockMosquitoAlert client;
  late MockLocalNotifications localNotifications;
  late GlobalKey<NavigatorState> navigatorKey;
  late FirebaseMessagingService service;

  setUp(() {
    client = MockMosquitoAlert();
    client.notificationsApi.setNotifications([
      createTestNotification(id: 7, title: title, body: '<p>$body</p>'),
    ]);
    localNotifications = MockLocalNotifications();
    navigatorKey = GlobalKey<NavigatorState>();
    service = FirebaseMessagingService(navigatorKey: navigatorKey);
  });

  tearDown(() => localNotifications.uninstall());

  Future<NotificationProvider> pumpApp(WidgetTester tester) async {
    // Here rather than in setUp, which runs before a variant's platform
    // override takes effect.
    localNotifications.install();
    final provider = NotificationProvider(
      repository: NotificationRepository(apiClient: client),
    );
    await tester.pumpWidget(
      ChangeNotifierProvider<NotificationProvider>.value(
        value: provider,
        child: MaterialApp(
          navigatorKey: navigatorKey,
          home: const Scaffold(body: Text('Home')),
        ),
      ),
    );
    return provider;
  }

  group('A message received in the foreground', () {
    testWidgets('is posted on Android to the high-importance channel', (
      tester,
    ) async {
      final provider = await pumpApp(tester);

      service.handleForegroundMessage(push(id: '7'));
      await tester.pumpAndSettle();

      final shown = localNotifications.callsTo('show');
      expect(shown, hasLength(1));
      final args = shown.single.arguments as Map;
      expect(args['id'], 7);
      expect(args['title'], title);
      expect(args['body'], body);
      expect(args['payload'], '7');
      final android = args['platformSpecifics'] as Map;
      expect(android['channelId'], LocalNotificationsService.channelId);
      expect(android['icon'], LocalNotificationsService.androidIcon);
      expect(android['importance'], Importance.high.value);
      expect(android['priority'], Priority.high.value);

      expect(provider.unreadNotificationsCount, 1);
    });

    testWidgets(
      'is left to iOS, which presents it itself',
      (tester) async {
        final provider = await pumpApp(tester);

        service.handleForegroundMessage(push(id: '7'));
        await tester.pumpAndSettle();

        expect(localNotifications.calls, isEmpty);
        expect(provider.unreadNotificationsCount, 1);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );

    testWidgets('is ignored without a notification block', (tester) async {
      final provider = await pumpApp(tester);

      service.handleForegroundMessage(push(id: '7', withNotification: false));
      await tester.pumpAndSettle();

      expect(localNotifications.calls, isEmpty);
      expect(provider.unreadNotificationsCount, 0);
    });
  });

  group('Tapping a notification', () {
    testWidgets('displayed by FCM opens it', (tester) async {
      await pumpApp(tester);

      service.handleMessageOpenedApp(push(id: '7'));
      await tester.pumpAndSettle();

      expect(find.byType(NotificationDetailPage), findsOneWidget);
      expect(find.text(title), findsOneWidget);
    });

    testWidgets('posted while in the foreground opens it', (tester) async {
      await pumpApp(tester);
      await LocalNotificationsService.initialize(
        onTap: service.handleNotificationTap,
      );

      await localNotifications.tap(payload: '7');
      await tester.pumpAndSettle();

      expect(find.byType(NotificationDetailPage), findsOneWidget);
      expect(find.text(title), findsOneWidget);
    });

    testWidgets('without a notification id stays put', (tester) async {
      await pumpApp(tester);

      service.handleMessageOpenedApp(push());
      service.handleNotificationTap('');
      service.handleNotificationTap(null);
      await tester.pumpAndSettle();

      expect(find.byType(NotificationDetailPage), findsNothing);
      expect(find.text('Home'), findsOneWidget);
    });
  });
}
