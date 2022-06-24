import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MyLocalizations {
  Locale locale;
  static Map<dynamic, dynamic> _localisedValues;

  MyLocalizations(this.locale) {
    this.locale = locale;
    _localisedValues = null;
  }

  static Future<MyLocalizations> loadTranslations(Locale locale) async {
    MyLocalizations appTranslations = MyLocalizations(locale);
    String jsonContent = await rootBundle.loadString(locale.languageCode == 'zh'
        ? 'assets/language/${locale.languageCode}_${locale.countryCode}.json'
        : 'assets/language/${locale.languageCode}.json');
    _localisedValues = json.decode(jsonContent);
    return appTranslations;
  }

  String translate(key) {
    return _localisedValues != null && _localisedValues[key] != null
        ? _localisedValues[key]
        : '';
  }

  static String of(BuildContext context, String key) {
    return Localizations.of<MyLocalizations>(context, MyLocalizations)
        .translate(key);
  }
}
