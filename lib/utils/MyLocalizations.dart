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
    String? jsonContent;
    final regionFilename = 'assets/language/${locale.languageCode}_${locale.countryCode}.json';

    try {
      // Try loading the region-specific file
      jsonContent = await rootBundle.loadString(regionFilename);
    } catch (_) {
      // If not found, load the language from any region
      final supportedLanguages = ['bg_BG', 'bn_BD', 'ca_ES', 'de_DE', 'el_GR', 'en_US', 'es_ES', 'es_UY', 'eu_ES',
        'fr_FR', 'gl_ES', 'hr_HR', 'hu_HU', 'it_IT', 'lb_LU', 'mk_MK', 'nl_NL', 'pt_PT', 'ro_RO', 'sl_SI',
        'sq_AL', 'sr_RS', 'sv_SE', 'tr_TR',
      ];

      final code = supportedLanguages.firstWhere((lang) => lang.startsWith(locale.languageCode));

      try {
        jsonContent = await rootBundle.loadString('assets/language/' + code + '.json');
      } catch (_) {
        // Load the default language
        jsonContent = await rootBundle.loadString('assets/language/en_US.json');
      }
    }

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

  static String of(BuildContext context, String? key) {
    return Localizations.of<MyLocalizations>(context, MyLocalizations)!
        .translate(key);
  }
}
