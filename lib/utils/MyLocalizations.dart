import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:geocoding/geocoding.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:country_codes/country_codes.dart';
import 'package:intl/intl.dart';

class MyLocalizations {
  final Locale locale;
  final Map<dynamic, dynamic> _localisedValues;
  final Map<dynamic, dynamic> _fallbackValues;

  static bool _timeagoInitialized = false;

  MyLocalizations._(this.locale, this._localisedValues, this._fallbackValues);

  static const defaultFallbackLocale = Locale('en', 'US');

  static List<Locale> supportedLocales = <Locale>[
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

  /// List of unique language codes
  static List<String> languages() =>
      supportedLocales.map((locale) => locale.languageCode).toSet().toList();

  // ---------------------------------------------------------------------------
  // Loading JSON + resolving locale
  // ---------------------------------------------------------------------------

  static Future<Map<String, dynamic>> _loadJsonAsset(Locale locale) async {
    final fileName =
        (locale.countryCode != null && locale.countryCode!.isNotEmpty)
            ? '${locale.languageCode}_${locale.countryCode}'
            : locale.languageCode;

    final path = 'assets/language/$fileName.json';
    try {
      final jsonContent = await rootBundle.loadString(path);
      return json.decode(jsonContent);
    } catch (e) {
      // Return empty map on failure to avoid null checks
      return {};
    }
  }

  /// Returns the best matching locale from supportedLocales
  static Locale resolveLocale(Locale locale) {
    // Exact match first
    return supportedLocales.firstWhere(
      (l) => l == locale,
      orElse: () => _fallbackLanguageMatch(locale),
    );
  }

  static Locale _fallbackLanguageMatch(Locale locale) {
    // Try language-only fallback
    return supportedLocales.firstWhere(
      (l) => l.languageCode == locale.languageCode,
      orElse: () => defaultFallbackLocale,
    );
  }

  static Future<MyLocalizations> load(Locale locale) async {
    final resolvedLocale = resolveLocale(locale);

    final fallbackValues = await _loadJsonAsset(defaultFallbackLocale);
    final localisedValues = await _loadJsonAsset(resolvedLocale);

    _initializeTimeagoMessages();
    await _configureLibraries(locale);

    return MyLocalizations._(locale, localisedValues, fallbackValues);
  }

  // ---------------------------------------------------------------------------
  // External libraries configuration
  // ---------------------------------------------------------------------------
  static Future<void> _configureLibraries(Locale locale) async {
    // For geolocator.
    setLocaleIdentifier(locale.toString());

    // Date formatting
    Intl.defaultLocale = Intl.verifiedLocale(
      locale.languageCode,
      DateFormat.localeExists,
      onFailure: (_) => 'en',
    );

    // Timeago formatting
    try {
      timeago.setDefaultLocale('${locale.languageCode}_short');
    } catch (e) {
      // Fallback to language only
      timeago.setDefaultLocale('en');
    }

    await CountryCodes.init(locale);
  }

  // ---------------------------------------------------------------------------
  // Timeago messages initialization
  // ---------------------------------------------------------------------------
  static void _initializeTimeagoMessages() {
    if (_timeagoInitialized) return;

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

    _localeMessages.forEach((key, value) {
      timeago.setLocaleMessages(key, value);
    });

    _timeagoInitialized = true;
  }

  // ---------------------------------------------------------------------------
  // Translation
  // ---------------------------------------------------------------------------
  String translate(String? key) {
    // Check if the key is null or empty
    if (key == null || key.isEmpty) return '';

    return _localisedValues[key] ?? _fallbackValues[key] ?? '';
  }

  static String of(BuildContext context, String? key) {
    return Localizations.of<MyLocalizations>(context, MyLocalizations)!
        .translate(key);
  }
}
