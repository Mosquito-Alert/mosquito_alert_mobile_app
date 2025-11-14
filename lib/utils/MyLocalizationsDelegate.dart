import 'package:flutter/foundation.dart';

import 'MyLocalizations.dart';
import 'package:flutter/material.dart';

class MyLocalizationsDelegate extends LocalizationsDelegate<MyLocalizations> {
  const MyLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      MyLocalizations.languages().contains(locale.languageCode);

  @override
  Future<MyLocalizations> load(Locale locale) async {
    // Returning a SynchronousFuture here because an async "load" operation
    // isn't needed to produce an instance of DemoLocalizations.
    return SynchronousFuture<MyLocalizations>(MyLocalizations(locale));
  }

  @override
  bool shouldReload(MyLocalizationsDelegate old) => false;
}
