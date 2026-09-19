// Drives the app through its main screens and captures a screenshot of each,
// for use in store listings / ad creatives.
//
// Run with:
//   flutter drive --driver=test_driver/screenshots_driver.dart \
//     --target=integration_test/screenshots_test.dart -d <device> \
//     [--dart-define=SCREENSHOT_LOCALE=vi] [--dart-define=SCREENSHOT_PREFIX=ios]
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mosquito_alert_app/app_config.dart';
import 'package:mosquito_alert_app/features/user/presentation/state/user_provider.dart';
import 'package:mosquito_alert_app/main.dart' as app;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kLocale = String.fromEnvironment('SCREENSHOT_LOCALE', defaultValue: '');
const String kPrefix = String.fromEnvironment('SCREENSHOT_PREFIX', defaultValue: '');

Future<void> waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump();
    if (finder.evaluate().isNotEmpty) return;
    await Future.delayed(const Duration(milliseconds: 100));
  }
  throw Exception('Widget not found: $finder');
}

Future<void> settle(WidgetTester tester, [int ms = 1500]) async {
  await tester.pump();
  await Future.delayed(Duration(milliseconds: ms));
  await tester.pump();
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  Future<void> shot(WidgetTester tester, String name) async {
    await settle(tester);
    if (Platform.isAndroid) {
      await binding.convertFlutterSurfaceToImage();
      await tester.pump();
    }
    final full = [
      if (kPrefix.isNotEmpty) kPrefix,
      if (kLocale.isNotEmpty) kLocale,
      name,
    ].join('_');
    debugPrint('[shots] taking $full');
    final bytes = await binding.takeScreenshot(full);
    // Also persist on-device so the images can be pulled without `flutter drive`
    // (e.g. `xcrun simctl get_app_container <udid> <bundleId> data`).
    final docs = await getApplicationDocumentsDirectory();
    final file = File('${docs.path}/screenshots/$full.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes);
    debugPrint('[shots] saved ${file.path}');
  }

  Future<void> tapAndWait(WidgetTester tester, Finder f) async {
    await waitFor(tester, f);
    await tester.ensureVisible(f);
    await tester.tap(f);
    await settle(tester);
  }

  testWidgets('capture screenshots', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('firstTime');
    await prefs.remove('onboarding_completed');

    debugPrint('[shots] starting app');
    // Not awaited: main() sets up services and calls runApp.
    // ignore: unawaited_futures
    app.main(env: 'test');
    await settle(tester, 4000);
    // Hide the "TEST" ribbon: pretend to be prod for UI purposes only
    // (backend used is still the test one).
    AppConfig.envName = 'prod';
    await settle(tester, 1000);
    debugPrint('[shots] app started');

    // Optional locale override
    if (kLocale.isNotEmpty) {
      final ctx = tester.element(find.byType(MaterialApp));
      await ctx.read<UserProvider>().setLocale(Locale(kLocale));
      await settle(tester);
    }

    // Onboarding (only when there are no credentials yet)
    final terms = find.byKey(const ValueKey('acceptConditionsCheckbox'));
    await tester.pump();
    bool onboarding = false;
    try {
      await waitFor(tester, terms, timeout: const Duration(seconds: 8));
      onboarding = true;
    } catch (_) {}
    if (onboarding) {
      await shot(tester, '00_terms');
      await tapAndWait(tester, terms);
      await tapAndWait(tester, find.byKey(const ValueKey('acceptPrivacyPolicy')));
      await tapAndWait(tester, find.byKey(const ValueKey('acceptTermsButton')));
      final reject = find.byKey(const Key('rejectBackgroundTrackingBtn'));
      await waitFor(tester, reject);
      await shot(tester, '01_location_consent');
      await tapAndWait(tester, reject);
    }

    // Home
    await waitFor(tester, find.byIcon(Icons.menu),
        timeout: const Duration(seconds: 30));
    await settle(tester, 4000);
    await shot(tester, '10_home');

    // The 4 home cards
    final cardNames = ['20_report_mosquito', '21_report_bite', '22_report_breeding_site', '23_public_map'];
    for (var i = 0; i < cardNames.length; i++) {
      final cards = find.byType(InkWell);
      await waitFor(tester, cards);
      // Cards are the InkWells inside Material with elevation 5
      final card = find.descendant(
        of: find.byWidgetPredicate((w) => w is Material && w.elevation == 5.0),
        matching: find.byType(InkWell),
      ).at(i);
      await tapAndWait(tester, card);
      await settle(tester, i == 3 ? 8000 : 2500);
      await shot(tester, cardNames[i]);
      // Go back
      final back = find.byType(BackButton);
      if (back.evaluate().isNotEmpty) {
        await tester.tap(back.first);
      } else {
        Navigator.of(tester.element(find.byType(Scaffold).last)).maybePop();
      }
      await settle(tester, 1500);
      // Some flows ask to confirm discarding
      final discard = find.byType(AlertDialog);
      if (discard.evaluate().isNotEmpty) {
        final buttons = find.descendant(of: discard, matching: find.byType(TextButton));
        // Tap the last button (typically the confirming one)
        await tester.tap(buttons.last);
        await settle(tester, 1500);
      }
    }

    // Drawer pages
    Future<void> openDrawerItem(IconData icon, String name, [int wait = 3000]) async {
      await tapAndWait(tester, find.byIcon(Icons.menu).first);
      await settle(tester, 800);
      final tile = find.widgetWithIcon(ListTile, icon);
      await waitFor(tester, tile);
      await tester.tap(tile.first);
      await settle(tester, wait);
      await shot(tester, name);
    }

    await tapAndWait(tester, find.byIcon(Icons.menu).first);
    await settle(tester, 800);
    await shot(tester, '30_drawer');
    // close drawer
    await tester.tapAt(const Offset(380, 500));
    await settle(tester, 800);

    await openDrawerItem(Icons.biotech, '31_guide', 4000);
    await openDrawerItem(Icons.file_copy, '32_my_reports', 3000);
    await openDrawerItem(Icons.info, '33_info', 5000);
    await openDrawerItem(Icons.settings, '34_settings', 2000);
  });
}
