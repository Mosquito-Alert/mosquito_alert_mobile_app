import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:mosquito_alert/mosquito_alert.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  final String baseUrl;
  final bool useAuth;

  AppConfig({required this.baseUrl, required this.useAuth});

  /// Name of the environment loaded by the most recent [loadConfig] call
  /// (e.g. `prod`, `dev`, `test`). Set as a static so widgets can decide
  /// synchronously whether to show flavor-specific UI without having to
  /// thread an [AppConfig] instance through the widget tree.
  static String? envName;

  /// Whether the current build is the production environment. Returns
  /// `false` for `dev`, `test`, or any other non-prod environment.
  static bool get isProduction => envName == 'prod';

  /// Which environment each shipped app identity must run against. The
  /// Gradle flavor / Xcode scheme decides the package or bundle id, while the
  /// Dart entrypoint (`--target`) decides the environment -- nothing in the
  /// toolchain ties the two together, so `--flavor prod --target
  /// lib/main_dev.dart` would silently point the production app at the dev
  /// backend. This table is what [assertMatchesPackage] enforces.
  static const Map<String, String> envByPackage = {
    'ceab.movelab.tigatrapp': 'prod', // Android, Mosquito Alert
    'cat.ibeji.tigatrapp': 'prod', // iOS, Mosquito Alert
    'ceab.movelab.tigatrapp.test': 'dev', // Android, Test Mosquito Alert
    'com.mosquitoalert.devtest': 'dev', // iOS, Test Mosquito Alert (DevTF)
  };

  /// The environment a build with this package/bundle id must use, or null
  /// for an identity this table does not know (tests, future flavors).
  static String? expectedEnvForPackage(String packageName) =>
      envByPackage[packageName];

  /// Fails loudly at startup if the running binary's identity and its loaded
  /// environment disagree. Only a misconfigured build can trigger this, and
  /// the alternative -- production users' reports going to the dev server, or
  /// testers' fake reports going to production -- is a silent failure that
  /// could run for a whole release. Call after [loadConfig], foreground only.
  static Future<void> assertMatchesPackage() async {
    final info = await PackageInfo.fromPlatform();
    final expected = expectedEnvForPackage(info.packageName);
    if (expected != null && expected != envName) {
      throw StateError(
        'Build misconfiguration: ${info.packageName} must run with env '
        '"$expected" but this binary was built with env "$envName". '
        'Check the --flavor / --target pairing used for the build.',
      );
    }
  }

  static Future<void> setEnvironment(String name) async {
    // Get the SharedPreferences instance
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('env', name);
  }

  static Future<AppConfig> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    String? env = prefs.getString('env');

    if (env == null || env.isEmpty) {
      throw Exception(
        'AppConfig env is not defined. Be sure to call AppConfig.setEnvironment',
      );
    }

    envName = env;

    final contents = await rootBundle.loadString('assets/config/$env.json');

    final json = jsonDecode(contents);

    return AppConfig(
      baseUrl: json['baseUrl'] ?? MosquitoAlert.basePath,
      useAuth: json['useAuth'],
    );
  }
}
