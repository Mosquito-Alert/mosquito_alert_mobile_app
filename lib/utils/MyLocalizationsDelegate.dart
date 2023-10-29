import 'package:mosquito_alert_app/utils/UserManager.dart';
import 'package:mosquito_alert_app/utils/Utils.dart';

import 'MyLocalizations.dart';
import 'package:flutter/material.dart';

class MyLocalizationsDelegate extends LocalizationsDelegate<MyLocalizations> {
  final Locale? newLocale;

  const MyLocalizationsDelegate({this.newLocale});

  @override
  bool isSupported(Locale locale) => [
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
      ].contains(
          '${locale.languageCode}');

  @override
  Future<MyLocalizations> load(Locale locale) async {
    String? lang = await UserManager.getLanguage();
    String? country = await UserManager.getLanguageCountry();
    Locale savedLocale = Utils.getLanguage();
    if (lang != null && country != null) {
      savedLocale = Locale(lang, country);
    }
    return MyLocalizations.loadTranslations(newLocale ?? savedLocale);
  }

  @override
  bool shouldReload(MyLocalizationsDelegate old) => true;
}
