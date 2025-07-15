import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mosquito_alert_app/pages/settings_pages/consent_form.dart';
import 'package:mosquito_alert_app/pages/settings_pages/location_consent_screen/background_tracking_explanation.dart';
import 'package:mosquito_alert_app/providers/user_provider.dart';
import 'package:mosquito_alert_app/utils/Utils.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Application.dart';

class UserManager {
  static final _secureStorage = FlutterSecureStorage();
  static var profileUUIDs;

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

      await Provider.of<UserProvider>(context, listen: false).createUser();

      await setLanguage(Utils.language.languageCode);
      await setLanguageCountry(Utils.language.countryCode);

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

    final userUuid =
        Provider.of<UserProvider>(context, listen: false).user?.uuid;
    if (userUuid != null && userUuid.isNotEmpty) {
      await FirebaseAnalytics.instance.setUserId(id: userUuid);
    }
    return true;
  }

  //set
  static Future<void> setFrirebaseId(id) async {
    var prefs = await SharedPreferences.getInstance();
    await prefs.setString('firebaseId', id);
  }

  static Future<void> setSowInfoAdult(show) async {
    var prefs = await SharedPreferences.getInstance();
    await prefs.setBool('infoCameraAdult', show);
  }

  static Future<void> setSowInfoBreeding(show) async {
    var prefs = await SharedPreferences.getInstance();
    await prefs.setBool('infoCameraBreeding', show);
  }

  static Future<void> setLanguage(language) async {
    var prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', language);
  }

  static Future<void> setLanguageCountry(lngCountry) async {
    var prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCountry', lngCountry);
  }

  static Future<void> setReportList(reportList) async {
    var prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('reportsList', reportList);
  }

  static Future<void> setImageList(imageList) async {
    var prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('imagesList', imageList);
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

  static Future<void> setToken(String token) async {
    await _secureStorage.write(key: 'jwt_token', value: token);
  }

  static Future<void> setRefreshToken(String token) async {
    await _secureStorage.write(key: 'jwt_refresh_token', value: token);
  }

  static Future<void> setUser(String username, String password) async {
    await _secureStorage.write(key: 'username', value: username);
    await _secureStorage.write(key: 'password', value: password);
  }

  //get
  static Future<String?> getFirebaseId() async {
    var prefs = await SharedPreferences.getInstance();
    return prefs.getString('firebaseId');
  }

  static Future<bool?> getShowInfoAdult() async {
    var prefs = await SharedPreferences.getInstance();
    return prefs.getBool('infoCameraAdult');
  }

  static Future<bool?> getShowInfoBreeding() async {
    var prefs = await SharedPreferences.getInstance();
    return prefs.getBool('infoCameraBreeding');
  }

  static Future<String?> getLanguage() async {
    var prefs = await SharedPreferences.getInstance();
    return prefs.getString('language');
  }

  static Future<String?> getLanguageCountry() async {
    var prefs = await SharedPreferences.getInstance();
    return prefs.getString('languageCountry');
  }

  static Future<String?> getUserLocale() async {
    return '${await UserManager.getLanguage()}_${await UserManager.getLanguageCountry()}';
  }

  static Future<List<String>?> getReportList() async {
    var prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('reportsList');
  }

  static Future<List<String>?> getImageList() async {
    var prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('imagesList');
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

  static Future<String?> getToken() async {
    return await _secureStorage.read(key: 'jwt_token');
  }

  static Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: 'jwt_refresh_token');
  }

  static Future<String?> getApiUser() async {
    return await _secureStorage.read(key: 'username');
  }

  static Future<String?> getApiPassword() async {
    return await _secureStorage.read(key: 'password');
  }
}
