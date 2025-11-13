import 'dart:async';

import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:mosquito_alert_app/pages/settings_pages/consent_form.dart';
import 'package:mosquito_alert_app/pages/settings_pages/location_consent_screen/background_tracking_explanation.dart';
import 'package:mosquito_alert_app/utils/Utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Application.dart';

class UserManager {
  static Future<bool> startFirstTime(context) async {
    var prefs = await SharedPreferences.getInstance();
    var firstTime = prefs.getBool('firstTime');

    if (firstTime == null || !firstTime) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ConsentForm(),
        ),
      );

      await prefs.setBool('firstTime', true);

      await setLocale(Utils.language);

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => LocationConsentScreen(),
        ),
      );
    } else {
      var languageCode = await getLanguage();
      var countryCode = await getLanguageCountry();
      if (languageCode != null && countryCode != null) {
        Utils.language = Locale(languageCode, countryCode);
      } else {
        Utils.getLanguage();
      }
    }

    application.onLocaleChanged(Utils.language);

    return true;
  }

  //set
  static Future<void> setLocale(Locale locale) async {
    final String languageCode = locale.languageCode;
    final String? countryCode = locale.countryCode;

    final String localeIdentifier =
        countryCode != null ? '${languageCode}_$countryCode' : languageCode;
    await setLocaleIdentifier(localeIdentifier); // From geolocator.
    await _setLanguage(languageCode);
    await _setLanguageCountry(countryCode ?? '');
  }

  static Future<void> _setLanguage(String language) async {
    var prefs = await SharedPreferences.getInstance();
    // NOTE: this is important for DateFormat to work correctly
    Intl.defaultLocale = Intl.verifiedLocale(language, DateFormat.localeExists,
        onFailure: (newLocale) => 'en');
    await prefs.setString('language', language);
  }

  static Future<void> _setLanguageCountry(String lngCountry) async {
    var prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCountry', lngCountry);
  }

  static Future<bool> setHashtags(List<String>? hashtags) async {
    var prefs = await SharedPreferences.getInstance();
    if (hashtags == null || hashtags.isEmpty) {
      return prefs.remove('hashtags');
    }
    return prefs.setStringList('hashtags', hashtags);
  }

  static Future<void> setLastReviewRequest(int lastReviewRequest) async {
    var prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastReviewRequest', lastReviewRequest);
  }

  static Future<void> setLastReportCount(int lastReportCount) async {
    var prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastReportCount', lastReportCount);
  }

  //get
  static Future<String?> getLanguage() async {
    var prefs = await SharedPreferences.getInstance();
    return prefs.getString('language');
  }

  static Future<String?> getLanguageCountry() async {
    var prefs = await SharedPreferences.getInstance();
    return prefs.getString('languageCountry');
  }

  static Future<void> migrateHashtagToHashtags() async {
    final prefs = await SharedPreferences.getInstance();

    // Check if the old variable exists
    if (!prefs.containsKey('hashtag')) {
      return;
    }

    var oldHashtag = prefs.getString('hashtag');

    if (oldHashtag == null) {
      return;
    }

    // Users were adding the hashtag manually to the strings
    if (oldHashtag.startsWith('#')) {
      oldHashtag = oldHashtag.substring(1);
    }

    await prefs.setStringList('hashtags', [oldHashtag]);
    // Remove the old variable
    await prefs.remove('hashtag');
  }

  static Future<List<String>?> getHashtags() async {
    await UserManager.migrateHashtagToHashtags();
    var prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('hashtags');
  }

  static Future<int?> getLastReviewRequest() async {
    var prefs = await SharedPreferences.getInstance();
    return prefs.getInt('lastReviewRequest');
  }

  static Future<int?> getLastReportCount() async {
    var prefs = await SharedPreferences.getInstance();
    return prefs.getInt('lastReportCount');
  }
}
