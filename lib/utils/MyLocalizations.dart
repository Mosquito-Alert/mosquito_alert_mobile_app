import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MyLocalizations {
  Locale locale;
  static Map<dynamic, dynamic> _localisedValues = {};
  static Map<dynamic, dynamic> _englishValues = {};

  MyLocalizations(this.locale) {
    locale = locale;
    _loadEnglishTranslations();
  }

  static Future<void> _loadEnglishTranslations() async {
    var jsonContent = await rootBundle.loadString('assets/language/en_US.json');
    _englishValues = json.decode(jsonContent);
  }

  static Future<MyLocalizations> loadTranslations(Locale locale) async {
    var appTranslations = MyLocalizations(locale);
    var jsonContent = await rootBundle.loadString(
      'assets/language/${locale.languageCode}_${locale.countryCode}.json'
    );
    _localisedValues = json.decode(jsonContent);
    return appTranslations;
  }

  String translate(String? key) {
    // Check if the key is null or empty
    if (key == null || key.isEmpty) {
      return '';
    }

    // Look for the localized value first, then fallback to English if not found
    String? localizedValue = _localisedValues[key];
    if (localizedValue != null && localizedValue.isNotEmpty) {
      return localizedValue;
    }

    // If localized value is null, empty, or not found, fallback to English
    return _englishValues[key] ?? '';
  }

  static String? of(BuildContext context, String? key) {
    return Localizations.of<MyLocalizations>(context, MyLocalizations)!
        .translate(key);
  }
}
