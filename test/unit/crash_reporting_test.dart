import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mosquito_alert_app/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Crashlytics ships wired up but switched off until the privacy policy and
/// the store privacy disclosures cover crash data (#789). These pin "off" at
/// every layer, so turning it on has to be a deliberate change to this file.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppConfig.envName = null;
  });

  String read(String path) => File(path).readAsStringSync();

  group('AppConfig.crashReporting', () {
    test('is off when the config does not mention it', () {
      expect(AppConfig.fromJson({'useAuth': true}).crashReporting, isFalse);
    });

    test('only a JSON true turns it on', () {
      AppConfig parse(Object? value) =>
          AppConfig.fromJson({'useAuth': true, 'crashReporting': value});

      for (final value in [false, null, 'true', 1]) {
        expect(parse(value).crashReporting, isFalse, reason: '$value');
      }
      expect(parse(true).crashReporting, isTrue);
    });

    for (final env in ['prod', 'dev', 'test']) {
      test('is off in the shipped $env config', () async {
        await AppConfig.setEnvironment(env);
        final config = await AppConfig.loadConfig();
        expect(config.crashReporting, isFalse);
      });
    }
  });

  group('native default is off (source tripwire)', () {
    test('AndroidManifest.xml disables collection', () {
      expect(
        read('android/app/src/main/AndroidManifest.xml'),
        matches(
          RegExp(
            r'android:name="firebase_crashlytics_collection_enabled"\s+'
            r'android:value="false"',
          ),
        ),
      );
    });

    test('Info.plist disables collection', () {
      expect(
        read('ios/Runner/Info.plist'),
        matches(
          RegExp(r'<key>FirebaseCrashlyticsCollectionEnabled</key>\s*<false/>'),
        ),
      );
    });
  });

  test('Android applies the Crashlytics Gradle plugin', () {
    // firebase_crashlytics tolerates a missing build ID, so dropping the
    // plugin would not show up anywhere at runtime.
    expect(
      read('android/settings.gradle.kts'),
      contains('id("com.google.firebase.crashlytics") version'),
    );
    expect(
      read('android/app/build.gradle.kts'),
      contains('id("com.google.firebase.crashlytics")'),
    );
  });
}
