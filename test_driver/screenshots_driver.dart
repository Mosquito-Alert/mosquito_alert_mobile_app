import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Host-side driver for `integration_test/screenshots_test.dart`.
///
/// Usage:
///   flutter drive --driver=test_driver/screenshots_driver.dart \
///     --target=integration_test/screenshots_test.dart -d <device>
///
/// Screenshots are written to `screenshots/<platform>/<name>.png`
/// (override with SCREENSHOTS_DIR).
Future<void> main() async {
  final outDir = Directory(
    Platform.environment['SCREENSHOTS_DIR'] ?? 'screenshots',
  );
  await integrationDriver(
    onScreenshot: (String name, List<int> bytes, [Map<String, Object?>? args]) async {
      final file = File('${outDir.path}/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes);
      // ignore: avoid_print
      print('Saved screenshot ${file.path}');
      return true;
    },
  );
}
