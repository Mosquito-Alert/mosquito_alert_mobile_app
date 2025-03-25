import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  final String baseUrl;

  AppConfig({required this.baseUrl});

  static Future<void> setEnvironment(String name) async {
    // Get the SharedPreferences instance
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('env', name);
  }

  static Future<AppConfig> loadConfig() async {
    // Get the SharedPreferences instance
    final prefs = await SharedPreferences.getInstance();

    // Get the 'env' value from SharedPreferences
    String? env = prefs.getString('env');

    // Check if 'env' is null or empty and throw an error
    if (env == null || env.isEmpty) {
      throw Exception(
          'AppConfig env is not defined. Be sure to call AppConfig.setEnvironment');
    }

    final contents = await rootBundle.loadString(
      'assets/config/$env.json',
    );

    final json = jsonDecode(contents);

    return AppConfig(baseUrl: json['baseUrl']);
  }
}
