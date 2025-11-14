import 'package:mosquito_alert_app/utils/UserManager.dart';
import 'package:mosquito_alert_app/utils/Utils.dart';

import 'MyLocalizations.dart';
import 'Application.dart';
import 'package:flutter/material.dart';

class MyLocalizationsDelegate extends LocalizationsDelegate<MyLocalizations> {
  final Locale? newLocale;

  const MyLocalizationsDelegate({this.newLocale});

  @override
  bool isSupported(Locale locale) =>
      application.supportedLocales().contains(locale);

  @override
  Future<MyLocalizations> load(Locale locale) async {
    var lang = await UserManager.getLanguage();
    var country = await UserManager.getLanguageCountry();
    var savedLocale = Utils.getLanguage();
    if (lang != null && country != null) {
      savedLocale = Locale(lang, country);
    }
    return MyLocalizations.loadTranslations(newLocale ?? savedLocale);
  }

  @override
  bool shouldReload(MyLocalizationsDelegate old) => true;
}
