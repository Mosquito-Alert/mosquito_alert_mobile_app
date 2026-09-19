import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mosquito_alert_app/app_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pins the prod/test backend wiring end to end. A silent regression here --
/// production reports going to the dev server, or fake test reports going to
/// production -- has no error message anywhere, so every link in the chain
/// gets its own assertion. See docs/mosquito-alert/google-play-listing.md.
const prodApi = 'https://api.mosquitoalert.com/v1';
const devApi = 'https://apidev.mosquitoalert.com/v1';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppConfig.envName = null;
  });

  group('resolved backend per environment (real config assets)', () {
    test('prod resolves to the production API with auth', () async {
      await AppConfig.setEnvironment('prod');
      final config = await AppConfig.loadConfig();
      expect(config.baseUrl, prodApi);
      expect(config.useAuth, isTrue);
      expect(AppConfig.isProduction, isTrue);
    });

    test('dev resolves to the dev API with auth', () async {
      await AppConfig.setEnvironment('dev');
      final config = await AppConfig.loadConfig();
      expect(config.baseUrl, devApi);
      expect(config.useAuth, isTrue);
      expect(AppConfig.isProduction, isFalse);
    });

    test('production host is unambiguous', () async {
      await AppConfig.setEnvironment('prod');
      final host = Uri.parse((await AppConfig.loadConfig()).baseUrl).host;
      expect(host, 'api.mosquitoalert.com');
      for (final word in ['dev', 'test', 'staging', 'example']) {
        expect(host.contains(word), isFalse, reason: 'prod host looks like $word');
      }
    });

    test('prod and dev never share a backend', () async {
      await AppConfig.setEnvironment('prod');
      final prod = (await AppConfig.loadConfig()).baseUrl;
      await AppConfig.setEnvironment('dev');
      final dev = (await AppConfig.loadConfig()).baseUrl;
      expect(prod, isNot(dev));
    });
  });

  group('entrypoint wiring (source tripwire)', () {
    // The Dart target chosen at build time is what selects the backend. These
    // read the entrypoints as text so a swapped or defaulted env fails CI.
    String read(String path) => File(path).readAsStringSync();

    test('lib/main.dart defaults to prod', () {
      expect(read('lib/main.dart'), contains("main({String env = 'prod'})"));
    });

    test('lib/main_prod.dart passes prod', () {
      expect(read('lib/main_prod.dart'), contains("app.main(env: 'prod')"));
    });

    test('lib/main_dev.dart passes dev', () {
      expect(read('lib/main_dev.dart'), contains("app.main(env: 'dev')"));
    });

    test('main.dart runs the package/env tripwire after loading config', () {
      final src = read('lib/main.dart');
      final load = src.indexOf('AppConfig.loadConfig()');
      final guard = src.indexOf('AppConfig.assertMatchesPackage()');
      expect(load, greaterThan(-1));
      expect(guard, greaterThan(load));
    });
  });

  group('runtime tripwire (assertMatchesPackage)', () {
    Future<void> runAs({required String package, required String env}) async {
      PackageInfo.setMockInitialValues(
        appName: 'Mosquito Alert',
        packageName: package,
        version: '0.0.0',
        buildNumber: '0',
        buildSignature: '',
        installerStore: null,
      );
      await AppConfig.setEnvironment(env);
      await AppConfig.loadConfig();
    }

    test('production package built against dev backend fails at startup',
        () async {
      await runAs(package: 'ceab.movelab.tigatrapp', env: 'dev');
      expect(AppConfig.assertMatchesPackage(), throwsA(isA<StateError>()));
    });

    test('test package built against production fails at startup', () async {
      await runAs(package: 'ceab.movelab.tigatrapp.test', env: 'prod');
      expect(AppConfig.assertMatchesPackage(), throwsA(isA<StateError>()));
    });

    test('correct pairings pass', () async {
      await runAs(package: 'ceab.movelab.tigatrapp', env: 'prod');
      await AppConfig.assertMatchesPackage();
      await runAs(package: 'ceab.movelab.tigatrapp.test', env: 'dev');
      await AppConfig.assertMatchesPackage();
      await runAs(package: 'cat.ibeji.tigatrapp', env: 'prod');
      await AppConfig.assertMatchesPackage();
      await runAs(package: 'com.mosquitoalert.devtest', env: 'dev');
      await AppConfig.assertMatchesPackage();
    });

    test('unknown package is never asserted on', () async {
      await runAs(package: 'com.example.other', env: 'dev');
      await AppConfig.assertMatchesPackage();
    });
  });

  group('app identity <-> environment mapping', () {
    test('production identities require prod', () {
      expect(AppConfig.expectedEnvForPackage('ceab.movelab.tigatrapp'), 'prod');
      expect(AppConfig.expectedEnvForPackage('cat.ibeji.tigatrapp'), 'prod');
    });

    test('test identities require dev', () {
      expect(AppConfig.expectedEnvForPackage('ceab.movelab.tigatrapp.test'), 'dev');
      expect(AppConfig.expectedEnvForPackage('com.mosquitoalert.devtest'), 'dev');
    });

    test('unknown identities are not asserted on', () {
      expect(AppConfig.expectedEnvForPackage('com.example.other'), isNull);
    });

    test('mapping agrees with the Android flavors in build.gradle.kts', () {
      final gradle = File('android/app/build.gradle.kts').readAsStringSync();
      expect(gradle, contains('applicationId = "ceab.movelab.tigatrapp"'));
      expect(gradle, contains('applicationIdSuffix = ".test"'));
    });

    test('mapping agrees with the iOS bundle ids in the Xcode project', () {
      final pbx = File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
      expect(pbx, contains('PRODUCT_BUNDLE_IDENTIFIER = cat.ibeji.tigatrapp;'));
      expect(pbx, contains('PRODUCT_BUNDLE_IDENTIFIER = com.mosquitoalert.devtest;'));
    });
  });
}
