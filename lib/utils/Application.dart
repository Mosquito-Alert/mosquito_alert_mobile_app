import 'package:flutter/material.dart';

class Application {
  static final Application _application = Application._internal();

  factory Application() {
    return _application;
  }

  Application._internal();

  final List<String> supportedLanguagesCodes = [
    'bg',
    'ca',
    'de',
    'el',
    'en',
    'es',
    'fr',
    'hr',
    'hu',
    'it',
    'lb',
    'mk',
    'nl',
    'pt',
    'ro',
    'ru',
    'sl',
    'sq',
    'sr',
    'tr',
    'zh',
  ];

  //returns the list of supported Locales
  Iterable<Locale> supportedLocales() =>
      supportedLanguagesCodes.map<Locale>((language) {
        // var languageCodes = language.split('_');
        return Locale(language);
      });

  //function to be invoked when changing the language
  LocaleChangeCallback onLocaleChanged;
}

Application application = Application();

typedef void LocaleChangeCallback(Locale locale);
