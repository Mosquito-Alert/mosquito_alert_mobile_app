import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:mosquito_alert/mosquito_alert.dart';
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
