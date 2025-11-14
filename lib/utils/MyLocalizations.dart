import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:timeago/timeago.dart' as timeago;

class MyLocalizations {
  final Locale locale;
  static Map<dynamic, dynamic> _localisedValues = {};
  static Map<dynamic, dynamic> _englishValues = {};

  MyLocalizations(this.locale) {
    _loadTranslations(locale);
    _loadEnglishTranslations();
    _localeMessages.forEach((key, value) {
      timeago.setLocaleMessages(key, value);
    });
  }

  static List<Locale> supportedLocales = [
    Locale('bg', 'BG'),
    Locale('bn', 'BD'),
    Locale('ca', 'ES'),
    Locale('de', 'DE'),
    Locale('el', 'GR'),
    Locale('en', 'US'),
    Locale('es', 'ES'),
    Locale('es', 'UY'),
    Locale('eu', 'ES'),
    Locale('fr', 'FR'),
    Locale('gl', 'ES'),
    Locale('hr', 'HR'),
    Locale('hu', 'HU'),
    Locale('it', 'IT'),
    Locale('lb', 'LU'),
    Locale('mk', 'MK'),
    Locale('nl', 'NL'),
    Locale('pt', 'PT'),
    Locale('ro', 'RO'),
    Locale('sl', 'SI'),
    Locale('sq', 'AL'),
    Locale('sr', 'RS'),
    Locale('sv', 'SE'),
    Locale('tr', 'TR'),
  ];

  final Map<String, timeago.LookupMessages> _localeMessages = {
    // 'bg',
    'bn': timeago.BnMessages(),
    'bn_short': timeago.BnShortMessages(),
    'ca': timeago.CaMessages(),
    'ca_short': timeago.CaShortMessages(),
    'de': timeago.DeMessages(),
    'de_short': timeago.DeShortMessages(),
    'el': timeago.GrMessages(),
    'el_short': timeago.GrShortMessages(),
    'en': timeago.EnMessages(),
    'en_short': timeago.EnShortMessages(),
    'es': timeago.EsMessages(),
    'es_short': timeago.EsShortMessages(),
    'fr': timeago.FrMessages(),
    'fr_short': timeago.FrShortMessages(),
    'hr': timeago.HrMessages(),
    'hr_short': timeago.HrMessages(),
    'hu': timeago.HuMessages(),
    'hu_short': timeago.HuShortMessages(),
    'it': timeago.ItMessages(),
    'it_short': timeago.ItShortMessages(),
    'lb': timeago.DeMessages(),
    'lb_short': timeago.DeShortMessages(),
    // 'mk': ,
    'nl': timeago.NlMessages(),
    'nl_short': timeago.NlShortMessages(),
    'pt': timeago.PtBrMessages(),
    'pt_short': timeago.PtBrShortMessages(),
    'ro': timeago.RoMessages(),
    'ro_short': timeago.RoShortMessages(),
    'ru': timeago.RuMessages(),
    'ru_short': timeago.RuShortMessages(),
    // 'sl': ,
    // 'sq': ,
    'sr': timeago.SrMessages(),
    'sr_short': timeago.SrShortMessages(),
    'sv': timeago.SvMessages(),
    'sv_short': timeago.SvShortMessages(),
    'tr': timeago.TrMessages(),
    'tr_short': timeago.TrShortMessages(),
    'zh': timeago.ZhCnMessages(),
    'zh_short': timeago.ZhCnMessages(),
  };

  static List<String> languages() =>
      supportedLocales.map((locale) => locale.languageCode).toSet().toList();

  Future<void> _loadEnglishTranslations() async {
    var jsonContent = await rootBundle.loadString('assets/language/en_US.json');
    _englishValues = json.decode(jsonContent);
  }

  Future<void> _loadTranslations(Locale locale) async {
    String? jsonContent;
    final regionFilename =
        'assets/language/${locale.languageCode}_${locale.countryCode}.json';

    try {
      // Try loading the region-specific file
      jsonContent = await rootBundle.loadString(regionFilename);
    } catch (_) {
      // If not found, load the language from any region
      final selectedLocale = supportedLocales
          .firstWhere((lang) => lang.languageCode == locale.languageCode);

      final code =
          '${selectedLocale.languageCode}_${selectedLocale.countryCode}';

      try {
        jsonContent =
            await rootBundle.loadString('assets/language/' + code + '.json');
      } catch (_) {
        // Load the default language
        jsonContent = await rootBundle.loadString('assets/language/en_US.json');
      }
    }

    _localisedValues = json.decode(jsonContent);
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
