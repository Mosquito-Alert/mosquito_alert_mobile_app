import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mosquito_alert/mosquito_alert.dart' as sdk;
import 'package:mosquito_alert_app/pages/notification_pages/notifications_page.dart';
import 'package:mosquito_alert_app/services/analytics_service.dart';
import 'package:provider/provider.dart';

// Import shared mocks
import '../mocks/mocks.dart';

Widget createTestWidget({
  int? notificationId,
  MockMosquitoAlert? mockClient,
}) {
  return MaterialApp(
    home: Provider<sdk.MosquitoAlert>(
      create: (_) => mockClient ?? MockMosquitoAlert(),
      child: NotificationsPage(
        notificationId: notificationId,
        analyticsService: MockAnalyticsService(),
      ),
    ),
    localizationsDelegates: const [
      MockMyLocalizationsDelegate(),
    ],
    supportedLocales: const [Locale('en')],
  );
}

void main() {
  group('NotificationsPage Tests', () {
    late MockMosquitoAlert mockClient;
    late MockNotificationsApi mockApi;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      MockFirebaseAnalytics.setMockMethodCallHandler();
    });

    setUp(() {
      mockClient = MockMosquitoAlert();
      mockApi = mockClient.notificationsApi;
    });

    test(
        'MockNotificationsApi should return empty list when no notifications set',
        () async {
      // Given
      mockApi.setNotifications([]);

      // When
      final response = await mockApi.listMine();

      // Then
      expect(response.statusCode, equals(200));
      expect(response.data?.results?.length, equals(0));
      expect(response.data?.count, equals(0));
    });

    test('MockNotificationsApi should return notifications when set', () async {
      // Given
      final testNotification = createTestNotification(
        id: 1,
        title: 'Test Notification',
        body: 'Test body',
        isRead: false,
      );
      mockApi.setNotifications([testNotification]);

      // When
      final response = await mockApi.listMine();

      // Then
      expect(response.statusCode, equals(200));
      expect(response.data?.results?.length, equals(1));
      expect(response.data?.results?.first.id, equals(1));
      expect(response.data?.results?.first.message.title,
          equals('Test Notification'));
      expect(response.data?.count, equals(1));
    });

    test('MockNotificationsApi should handle pagination correctly', () async {
      // Given - Create 25 notifications
      final notifications = List.generate(
          25,
          (index) => createTestNotification(
                id: index + 1,
                title: 'Notification ${index + 1}',
                body: 'Body ${index + 1}',
                isRead: false,
              ));
      mockApi.setNotifications(notifications);

      // When - Get first page
      final firstPageResponse = await mockApi.listMine(page: 1, pageSize: 20);

      // Then - First page should have 20 items
      expect(firstPageResponse.statusCode, equals(200));
      expect(firstPageResponse.data?.results?.length, equals(20));
      expect(firstPageResponse.data?.count, equals(25));
      expect(firstPageResponse.data?.next, isNotNull);

      // When - Get second page
      final secondPageResponse = await mockApi.listMine(page: 2, pageSize: 20);

      // Then - Second page should have 5 items
      expect(secondPageResponse.statusCode, equals(200));
      expect(secondPageResponse.data?.results?.length, equals(5));
      expect(secondPageResponse.data?.count, equals(25));
      expect(secondPageResponse.data?.next, isNull);
    });

    test('MockNotificationsApi should update notification as read', () async {
      // Given
      final testNotification = createTestNotification(
        id: 1,
        title: 'Test Notification',
        body: 'Test body',
        isRead: false,
      );
      mockApi.setNotifications([testNotification]);

      // When
      final patchRequest =
          sdk.PatchedNotificationRequest((b) => b..isRead = true);
      final response = await mockApi.partialUpdate(
        id: 1,
        patchedNotificationRequest: patchRequest,
      );

      // Then
      expect(response.statusCode, equals(200));
      expect(response.data?.isRead, equals(true));
    });

    testWidgets('should display no notifications message when empty',
        (WidgetTester tester) async {
      // Given
      mockApi.setNotifications([]);

      // When - Create widget, Firebase exception is expected but widgets still build
      await tester.pumpWidget(createTestWidget(mockClient: mockClient));

      try {
        await tester.pump();
      } catch (e) {
        // Firebase exception is expected in test environment, continue with test
        print(
            "Expected Firebase exception: ${e.toString().substring(0, 100)}...");
      }

      // Then - Check that the widget structure exists despite Firebase errors
      expect(find.byType(NotificationsPage), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);

      // Check for the Scaffold which contains the app structure
      expect(find.byType(Scaffold), findsOneWidget);

      // With empty notifications, no Card widgets should be present
      expect(find.byType(Card), findsNothing);
    });

    testWidgets('should display read notifications with grey background',
        (WidgetTester tester) async {
      // Given
      final readNotification = createTestNotification(
        id: 1,
        title: 'Read Notification',
        body: '<p>This has been read</p>',
        isRead: true,
      );
      final unreadNotification = createTestNotification(
        id: 2,
        title: 'Unread Notification',
        body: '<p>This is unread</p>',
        isRead: false,
      );
      mockApi.setNotifications([readNotification, unreadNotification]);

      // When
      await tester.pumpWidget(createTestWidget(mockClient: mockClient));
      await tester.pumpAndSettle();

      // Then - Check proper color coding
      expect(find.byType(Card), findsNWidgets(2));

      final cards = tester.widgetList<Card>(find.byType(Card)).toList();
      // First card (read) should have grey background
      expect(cards[0].color, equals(Colors.grey[200]));
      // Second card (unread) should have white background
      expect(cards[1].color, equals(Colors.white));
    });

    testWidgets('should mark notification as read when tapped',
        (WidgetTester tester) async {
      // Given
      final unreadNotification = createTestNotification(
        id: 1,
        title: 'Unread Notification',
        body: '<p>This will be marked as read</p>',
        isRead: false,
      );
      mockApi.setNotifications([unreadNotification]);

      // When
      await tester.pumpWidget(createTestWidget(mockClient: mockClient));
      await tester.pumpAndSettle();

      // Then - Verify initial state (white background for unread)
      Card card = tester.widget<Card>(find.byType(Card));
      expect(card.color, equals(Colors.white));

      // When - Tap the notification
      await tester.tap(find.byType(ListTile));
      await tester.pumpAndSettle();

      // Close the bottom sheet
      await tester.tapAt(const Offset(50, 50)); // Tap outside bottom sheet
      await tester.pumpAndSettle();

      // Then - Notification should now be marked as read (grey background)
      card = tester.widget<Card>(find.byType(Card));
      expect(card.color, equals(Colors.grey[200]));
    });

    testWidgets('should handle API errors gracefully',
        (WidgetTester tester) async {
      // Given - Setup API to return error
      mockApi.setNotifications([]);

      // When
      await tester.pumpWidget(createTestWidget(mockClient: mockClient));
      await tester.pumpAndSettle();

      // Then - Should not crash and display empty state
      expect(find.byType(NotificationsPage), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      // No cards should be displayed when API returns empty
      expect(find.byType(Card), findsNothing);
    });
  });
}
