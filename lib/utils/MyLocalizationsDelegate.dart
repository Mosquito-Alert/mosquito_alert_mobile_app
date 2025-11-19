import 'MyLocalizations.dart';
import 'package:flutter/material.dart';

class MyLocalizationsDelegate extends LocalizationsDelegate<MyLocalizations> {
  const MyLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      MyLocalizations.languages().contains(locale.languageCode);

  @override
  Future<MyLocalizations> load(Locale locale) async {
    return MyLocalizations.load(locale);
  }

  @override
  bool shouldReload(MyLocalizationsDelegate old) => false;
}
