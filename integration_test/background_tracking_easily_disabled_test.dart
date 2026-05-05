import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mosquito_alert_app/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';

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

  Future<void> resetFirstUseState() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove('firstTime');
    await preferences.remove('onboarding_completed');
  }

  group('end-to-end test', () {
    testWidgets(
      'Test background tracking can be easily disabled on first use, to satisfy Google/Apple requirements',
      (tester) async {
        await resetFirstUseState();
        app.main(env: "test");
        await tester.pumpAndSettle(Duration(seconds: 3));

        // New user is created: Show consent form
        final acceptConditionsCheckbox = find.byKey(
          ValueKey("acceptConditionsCheckbox"),
        );
        await waitForWidget(tester, acceptConditionsCheckbox);
        await tester.ensureVisible(acceptConditionsCheckbox);
        await tester.tap(acceptConditionsCheckbox);
        await tester.pumpAndSettle();

        final acceptPrivacyPolicy = find.byKey(ValueKey("acceptPrivacyPolicy"));
        await waitForWidget(tester, acceptPrivacyPolicy);
        await tester.ensureVisible(acceptPrivacyPolicy);
        await tester.tap(acceptPrivacyPolicy);
        await tester.pumpAndSettle();

        final continueButton = find.byKey(ValueKey("acceptTermsButton"));
        await waitForWidget(tester, continueButton);
        await tester.ensureVisible(continueButton);
        await tester.tap(continueButton);
        await tester.pumpAndSettle();

        // Reject background traking
        final rejectBtn = find.byKey(Key("rejectBackgroundTrackingBtn"));
        await waitForWidget(tester, rejectBtn);
        expect(rejectBtn, findsOne);
        await tester.ensureVisible(rejectBtn);
        await tester.tap(rejectBtn);
        await tester.pumpAndSettle();
      },
    );
  });
}
