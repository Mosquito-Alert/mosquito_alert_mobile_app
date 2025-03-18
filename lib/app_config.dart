import 'dart:convert';
import 'package:flutter/services.dart';

class AppConfig {
  final String baseUrl;

  AppConfig({required this.baseUrl});

  static Future<AppConfig> forEnvironment({String env = 'dev'}) async {
    final contents = await rootBundle.loadString(
      'assets/config/$env.json',
    );

    final json = jsonDecode(contents);

    return AppConfig(baseUrl: json['baseUrl']);
  }
}
