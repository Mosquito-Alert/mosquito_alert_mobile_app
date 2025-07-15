import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mosquito_alert_app/main.dart' as app;
import 'package:mosquito_alert_app/pages/main/components/custom_card_widget.dart';

Future<void> waitForWidget(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 15),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump();
    if (finder.evaluate().isNotEmpty) return;
    await Future.delayed(const Duration(milliseconds: 100));
  }
  throw Exception('Widget not found: $finder');
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  group('end-to-end test', () {
    testWidgets(
        'Test background tracking can be easily disabled on first use, to satisfy Google/Apple requirements',
        (tester) async {
      app.main(env: "test");
      await tester.pumpAndSettle(Duration(seconds: 3));

      // New user is created: Show consent form
      final acceptConditionsCheckbox =
          find.byKey(ValueKey("acceptConditionsCheckbox"));
      await waitForWidget(tester, acceptConditionsCheckbox);
      await tester.ensureVisible(acceptConditionsCheckbox);
      await tester.tap(acceptConditionsCheckbox);

      final acceptPrivacyPolicy = find.byKey(ValueKey("acceptPrivacyPolicy"));
      await waitForWidget(tester, acceptPrivacyPolicy);
      await tester.ensureVisible(acceptPrivacyPolicy);
      await tester.tap(acceptPrivacyPolicy);

      final continueButton = find.byKey(ValueKey("style.button"));
      await waitForWidget(tester, continueButton);
      await tester.ensureVisible(continueButton);
      await tester.tap(continueButton);

      // Reject background traking
      final rejectBtn = find.byKey(Key("rejectBackgroundTrackingBtn"));
      await waitForWidget(tester, rejectBtn);
      expect(rejectBtn, findsOne);
      await tester.ensureVisible(rejectBtn);
      await tester.tap(rejectBtn);

      // Home page
      final homePageButtons = find.byType(CustomCard);
      await waitForWidget(tester, homePageButtons);
      expect(homePageButtons, findsNWidgets(4));
    });
  });
}
