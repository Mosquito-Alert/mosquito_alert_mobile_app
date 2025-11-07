import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:mosquito_alert_app/utils/style.dart';

class Utils {
  static Locale language = Locale('en', 'US');

  static Widget loading(_isLoading, [Color? indicatorColor]) {
    return _isLoading == true
        ? IgnorePointer(
            child: Container(
            color: Colors.transparent,
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                    indicatorColor ?? Style.colorPrimary),
              ),
            ),
          ))
        : Container();
  }

  static ui.Locale getLanguage() {
    var stringLanguange =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    var stringCountry =
        WidgetsBinding.instance.platformDispatcher.locale.countryCode;

    language = Locale('en', 'US');

    if (stringLanguange == 'es' && stringCountry == 'ES' ||
        stringLanguange == 'ca' && stringCountry == 'ES' ||
        stringLanguange == 'en' && stringCountry == 'US' ||
        stringLanguange == 'sq' ||
        stringLanguange == 'bg' ||
        stringLanguange == 'nl' ||
        stringLanguange == 'de' ||
        stringLanguange == 'it' ||
        stringLanguange == 'pt' ||
        stringLanguange == 'ro') {
      language = WidgetsBinding.instance.platformDispatcher.locale;
    }

    return language;
  }

  static String getRandomPassword(int length) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*';
    final rand = Random.secure();
    return List.generate(length, (index) => chars[rand.nextInt(chars.length)])
        .join();
  }
}
