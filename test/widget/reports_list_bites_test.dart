import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mosquito_alert/mosquito_alert.dart' as sdk;
import 'package:mosquito_alert_app/pages/my_reports_pages/components/reports_list_bites.dart';
import 'package:provider/provider.dart';

// Import shared mocks and helpers
import '../mocks/mocks.dart';

Widget createReportsListBitesTestWidget({
  MockMosquitoAlert? mockClient,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Provider<sdk.MosquitoAlert>(
        create: (_) => mockClient ?? MockMosquitoAlert(),
        child: ReportsListBites(),
      ),
    ),
    localizationsDelegates: const [
      MockMyLocalizationsDelegate(),
    ],
    supportedLocales: const [Locale('en')],
  );
}

void main() {
  group('ReportsListBites Tests', () {
    late MockMosquitoAlert mockClient;
    late MockBitesApi mockBitesApi;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      MockFirebaseAnalytics.setMockMethodCallHandler();
    });

    setUp(() {
      mockClient = MockMosquitoAlert();
      mockBitesApi = mockClient.bitesApi;
    });

    testWidgets('should display bite reports when bites are available',
        (WidgetTester tester) async {
      // Given - Mock bite reports using consolidated helper
      final testBites = [
        createTestBite(
          uuid: 'bite-1',
          createdAt: DateTime(2024, 9, 15, 10, 30),
          totalBites: 3,
        ),
        createTestBite(
          uuid: 'bite-2',
          createdAt: DateTime(2024, 9, 14, 15, 45),
          totalBites: 4,
        ),
      ];
      mockBitesApi.setBites(testBites);

      // When - Create widget
      await tester
          .pumpWidget(createReportsListBitesTestWidget(mockClient: mockClient));

      // Handle expected Firebase exception
      await pumpAndSettleIgnoringFirebaseException(tester);

      // Then - Verify bite reports are displayed as cards
      expect(find.byType(ListTile), findsNWidgets(2));

      // Verify specific bite content is displayed
      expect(find.text('3 bites'), findsOneWidget);
      expect(find.text('4 bites'), findsOneWidget);
    });

    testWidgets('should display no reports message when no bites are available',
        (WidgetTester tester) async {
      // Given - Empty bite reports
      mockBitesApi.setBites([]);

      // When - Create widget
      final widget = createReportsListBitesTestWidget(mockClient: mockClient);
      await tester.pumpWidget(widget);

      // Handle expected Firebase exception
      await pumpAndSettleIgnoringFirebaseException(tester);

      // Then - Verify empty state is displayed
      expect(find.byType(ReportsListBites), findsOneWidget);

      // No cards should be displayed
      expect(find.byType(ListTile), findsNothing);

      // Should display localized "no reports yet" message
      // Get the localized text from the mock localizations
      final mockLocalizations = MockMyLocalizations();
      final expectedText = mockLocalizations.translate('no_reports_yet_txt');
      expect(find.text(expectedText), findsOneWidget);
    });

    testWidgets('should display single bite correctly',
        (WidgetTester tester) async {
      // Given - Single bite with one bite count using consolidated helper
      final testBites = [
        createTestBite(
          uuid: 'bite-single',
          createdAt: DateTime(2024, 9, 15, 10, 30),
          totalBites: 1,
        ),
      ];
      mockBitesApi.setBites(testBites);

      // When - Create widget
      await tester
          .pumpWidget(createReportsListBitesTestWidget(mockClient: mockClient));

      // Handle expected Firebase exception
      await pumpAndSettleIgnoringFirebaseException(tester);

      // Then - Verify single bite is displayed correctly
      expect(find.byType(ListTile), findsOneWidget);
      expect(find.text('1 bite'), findsOneWidget);
    });

    testWidgets('should render bite report cards correctly',
        (WidgetTester tester) async {
      // Given - Mock bite reports
      final testBites = [
        createTestBite(
          uuid: 'bite-1',
          createdAt: DateTime(2024, 9, 15, 10, 30),
          totalBites: 2,
        ),
        createTestBite(
          uuid: 'bite-2',
          createdAt: DateTime(2024, 9, 14, 15, 45),
          totalBites: 3,
        ),
      ];
      mockBitesApi.setBites(testBites);

      // When - Create widget and wait for loading
      await tester
          .pumpWidget(createReportsListBitesTestWidget(mockClient: mockClient));
      await pumpAndSettleIgnoringFirebaseException(tester);

      // Then - Verify cards are displayed correctly
      expect(find.byType(ListTile), findsNWidgets(2));
      expect(find.text('2 bites'), findsOneWidget);
      expect(find.text('3 bites'), findsOneWidget);
    });
  });
}
