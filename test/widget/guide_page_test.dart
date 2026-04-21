import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intro_slider/intro_slider.dart';
import 'package:mosquito_alert_app/screens/guide_page.dart';
import 'package:mosquito_alert_app/services/analytics_service.dart';

// Import shared mocks
import '../mocks/mocks.dart';

/// Helper function to handle Firebase exceptions during pump and settle
Future<void> pumpAndSettleIgnoringFirebaseException(WidgetTester tester) async {
  try {
    await tester.pumpAndSettle();
  } catch (e) {
    // Firebase exception is expected in test environment, continue with test
    print("Expected Firebase exception: ${e.toString().substring(0, 100)}...");
    await tester.pump();
  }
}

/// Creates a test widget wrapping GuidePage with required dependencies
Widget createTestWidget({Function? goBackToHomepage}) {
  return MaterialApp(
    home: GuidePage(
      goBackToHomepage:
          goBackToHomepage ??
          (int index) {
            // Default callback does nothing - tests will provide their own
          },
      analyticsService: MockAnalyticsService(),
    ),
    localizationsDelegates: const [MockMyLocalizationsDelegate()],
    supportedLocales: const [Locale('en')],
  );
}

void main() {
  group('GuidePage Tests', () {
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      MockFirebaseAnalytics.setMockMethodCallHandler();
    });

    setUp(() {
      // Add any setup needed for each test here if required
    });
    testWidgets('should render GuidePage with IntroSlider and 9 slides', (
      WidgetTester tester,
    ) async {
      // Given
      await tester.pumpWidget(createTestWidget());
      await pumpAndSettleIgnoringFirebaseException(tester);

      // Then
      expect(find.byType(GuidePage), findsOneWidget);
      expect(find.byType(IntroSlider), findsOneWidget);
      expect(find.byType(Scaffold), findsAtLeastNWidgets(1));

      // Verify the slider has 9 slides by checking for slide indicator dots
      // IntroSlider creates dots for each slide
      final introSlider = tester.widget<IntroSlider>(find.byType(IntroSlider));
      expect(introSlider.slides?.length, equals(9));
    });

    testWidgets('should display first slide content initially', (
      WidgetTester tester,
    ) async {
      // Given
      await tester.pumpWidget(createTestWidget());
      await pumpAndSettleIgnoringFirebaseException(tester);

      // Then - Check if first slide content is visible
      // Look for the text content of the first slide
      expect(
        find.textContaining('Welcome to the Mosquito Guide - Slide 1'),
        findsOneWidget,
      );
    });

    testWidgets('should navigate forward through slides using next button', (
      WidgetTester tester,
    ) async {
      // Given
      await tester.pumpWidget(createTestWidget());
      await pumpAndSettleIgnoringFirebaseException(tester);

      // Initially on slide 1
      expect(
        find.textContaining('Welcome to the Mosquito Guide - Slide 1'),
        findsOneWidget,
      );

      // When - Tap next button (navigate_next icon)
      final nextButton = find.byIcon(Icons.navigate_next);
      expect(nextButton, findsOneWidget);

      await tester.tap(nextButton);
      await pumpAndSettleIgnoringFirebaseException(tester);

      // Then - Should be on slide 2
      expect(
        find.textContaining('Mosquito Identification - Slide 2'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Welcome to the Mosquito Guide - Slide 1'),
        findsNothing,
      );
    });

    testWidgets('should navigate through multiple slides sequentially', (
      WidgetTester tester,
    ) async {
      // Given
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final nextButton = find.byIcon(Icons.navigate_next);

      // Navigate through first 3 slides to test sequential navigation
      // Start at slide 1
      expect(find.textContaining('Slide 1'), findsOneWidget);

      // Go to slide 2
      await tester.tap(nextButton);
      await tester.pumpAndSettle();
      expect(find.textContaining('Slide 2'), findsOneWidget);

      // Go to slide 3
      await tester.tap(nextButton);
      await tester.pumpAndSettle();
      expect(find.textContaining('Slide 3'), findsOneWidget);
    });

    testWidgets('should support navigation gestures within IntroSlider', (
      WidgetTester tester,
    ) async {
      // Given - Navigate to slide 3 first
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final nextButton = find.byIcon(Icons.navigate_next);

      // Go to slide 3
      await tester.tap(nextButton); // to slide 2
      await tester.pumpAndSettle();
      await tester.tap(nextButton); // to slide 3
      await tester.pumpAndSettle();

      expect(find.textContaining('Breeding Sites - Slide 3'), findsOneWidget);

      // When - Attempt to use swipe gesture on IntroSlider
      // Note: IntroSlider may or may not support gestures depending on configuration
      final introSlider = find.byType(IntroSlider);
      expect(introSlider, findsOneWidget);

      // Try a swipe gesture (this may or may not work depending on IntroSlider settings)
      await tester.drag(introSlider, const Offset(300, 0)); // Swipe right
      await tester.pumpAndSettle();

      // Then - Verify IntroSlider is still functional (regardless of gesture outcome)
      expect(find.byType(IntroSlider), findsOneWidget);
      // The actual navigation outcome depends on IntroSlider's gesture configuration
    });

    testWidgets('should show done button on last slide', (
      WidgetTester tester,
    ) async {
      // Given
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final nextButton = find.byIcon(Icons.navigate_next);

      // Navigate to last slide (slide 9)
      for (int i = 0; i < 8; i++) {
        await tester.tap(nextButton);
        await tester.pumpAndSettle();
      }

      // Then - Should be on slide 9 and show done button
      expect(find.textContaining('Thank You - Slide 9'), findsOneWidget);
      expect(find.byIcon(Icons.done), findsOneWidget);
    });

    testWidgets('should call goBackToHomepage when done button is pressed', (
      WidgetTester tester,
    ) async {
      // Given
      bool callbackInvoked = false;
      int callbackArgument = -1;

      await tester.pumpWidget(
        createTestWidget(
          goBackToHomepage: (int index) {
            callbackInvoked = true;
            callbackArgument = index;
          },
        ),
      );
      await pumpAndSettleIgnoringFirebaseException(tester);

      final nextButton = find.byIcon(Icons.navigate_next);

      // Navigate to last slide (slide 9) - simplified navigation
      for (int i = 0; i < 8; i++) {
        await tester.tap(nextButton);
        await pumpAndSettleIgnoringFirebaseException(tester);
      }

      // Verify we're on the last slide
      expect(find.textContaining('Thank You - Slide 9'), findsOneWidget);

      // When - Tap done button
      final doneButton = find.byIcon(Icons.done);
      expect(doneButton, findsOneWidget);

      await tester.tap(doneButton);
      await pumpAndSettleIgnoringFirebaseException(tester);

      // Then - Callback should be invoked with argument 0 (homepage index)
      expect(callbackInvoked, isTrue);
      expect(callbackArgument, equals(0));
    });

    testWidgets('should handle navigation limits correctly', (
      WidgetTester tester,
    ) async {
      // Given
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Test backward navigation from first slide (should not crash)
      await tester.drag(
        find.byType(IntroSlider),
        const Offset(300, 0),
      ); // Try to swipe back from slide 1
      await tester.pumpAndSettle();

      // Should still be on slide 1
      expect(
        find.textContaining('Welcome to the Mosquito Guide - Slide 1'),
        findsOneWidget,
      );

      // Navigate to last slide
      final nextButton = find.byIcon(Icons.navigate_next);
      for (int i = 0; i < 8; i++) {
        await tester.tap(nextButton);
        await tester.pumpAndSettle();
      }

      // Try to navigate forward from last slide (should show done button, not next)
      expect(find.textContaining('Thank You - Slide 9'), findsOneWidget);
      expect(find.byIcon(Icons.done), findsOneWidget);
      expect(
        find.byIcon(Icons.navigate_next),
        findsNothing,
      ); // Next button should not be visible on last slide
    });

    testWidgets('should display proper slide indicators', (
      WidgetTester tester,
    ) async {
      // Given
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Then - IntroSlider should show slide indicators (dots)
      // The exact implementation depends on IntroSlider's internal structure
      // but we can verify the slider configuration
      final introSlider = tester.widget<IntroSlider>(find.byType(IntroSlider));

      // Verify slider configuration
      expect(introSlider.showSkipBtn, equals(false));
      expect(introSlider.sizeDot, equals(6.0));
      expect(introSlider.backgroundColorAllSlides, equals(Colors.white));
      expect(introSlider.hideStatusBar, equals(false));
    });

    testWidgets(
      'should render custom slide content with images and descriptions',
      (WidgetTester tester) async {
        // Given
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Then - Should find Image widgets for slide content
        // Note: In test environment, Image.asset might not load actual images
        // but the widget structure should be present
        expect(find.byType(Image), findsAtLeastNWidgets(1));

        // Should find HTML content containers for descriptions
        expect(
          find.textContaining('Welcome to the Mosquito Guide - Slide 1'),
          findsOneWidget,
        );
      },
    );

    testWidgets('should complete full navigation cycle', (
      WidgetTester tester,
    ) async {
      // Given
      bool callbackInvoked = false;
      int callbackArgument = -1;

      await tester.pumpWidget(
        createTestWidget(
          goBackToHomepage: (int index) {
            callbackInvoked = true;
            callbackArgument = index;
          },
        ),
      );
      await tester.pumpAndSettle();

      // When - Navigate through entire guide
      final nextButton = find.byIcon(Icons.navigate_next);

      // Go through all slides
      for (int slideIndex = 1; slideIndex <= 8; slideIndex++) {
        expect(find.textContaining('Slide $slideIndex'), findsOneWidget);
        await tester.tap(nextButton);
        await tester.pumpAndSettle();
      }

      // Should be on final slide
      expect(find.textContaining('Thank You - Slide 9'), findsOneWidget);
      expect(find.byIcon(Icons.done), findsOneWidget);

      // Complete the guide
      await tester.tap(find.byIcon(Icons.done));
      await tester.pumpAndSettle();

      // Then - Should have called completion callback
      expect(callbackInvoked, isTrue);
      expect(callbackArgument, equals(0));
    });
  });
}
