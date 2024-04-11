import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mosquito_alert_app/api/api.dart';
import 'package:mosquito_alert_app/pages/settings_pages/consent_form.dart';
import 'package:mosquito_alert_app/utils/Utils.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'Application.dart';

class UserManager {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static User? user;
  static var profileUUIDs;
  static int? userScore;

  static Future<bool> startFirstTime(context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? firstTime = prefs.getBool('firstTime');

    if (firstTime == null || !firstTime) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ConsentForm(),
        ),
      );

      prefs.setBool('firstTime', true);
      var uuid = Uuid().v4();
      var trackingUuid = Uuid().v4();
      prefs.setString('uuid', uuid);
      prefs.setString('trackingUUID', trackingUuid);
      prefs.setBool('trackingEnabled', true);

      Utils.initializedCheckData['userCreated']['required'] = true;

      await ApiSingleton().createUser(uuid);
      setLanguage(Utils.language.languageCode);
      setLanguageCountry(Utils.language.countryCode);
    } else {
      String? languageCode = await getLanguage();
      String? countryCode = await getLanguageCountry();
      if (languageCode != null && countryCode != null) {
        Utils.language = Locale(languageCode, countryCode);
      } else {
        Utils.getLanguage();
      }
    }

    application.onLocaleChanged(Utils.language);
    fetchUser();
    userScore = await ApiSingleton().getUserScores();
    await setUserScores(userScore);

    return true;
  }

  static fetchUser() async {
    user = _auth
        .currentUser;

    if (user == null) {
      return null;
    }

    Utils.initializedCheckData['user'] = true;
    return user;
  }

  //set
  static Future<void> setFrirebaseId(id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('firebaseId', id);
  }

  static Future<void> setUserScores(scores) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('userScores', scores);
  }

  static Future<void> setTracking(bool new_value) async {
    var prefs = await SharedPreferences.getInstance();

    if (new_value == true){
      print('enable bg tracking');
      var status = await Permission.locationAlways.status;
      if (!status.isGranted){
        status = await Permission.locationAlways.request();
      }

      if (status.isGranted){
        await prefs.setBool('trackingEnabled', true);
      }
    } else {
        print('disable bg tracking');
        await prefs.setBool('trackingEnabled', false);
    }
  }

  static Future<void> setSowInfoAdult(show) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('infoCameraAdult', show);
  }

  static Future<void> setSowInfoBreeding(show) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('infoCameraBreeding', show);
  }

  static Future<void> setLanguage(language) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('language', language);
  }

  static Future<void> setLanguageCountry(lngCountry) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('languageCountry', lngCountry);
  }

  static Future<void> setReportList(reportList) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList('reportsList', reportList);
  }

  static Future<void> setImageList(imageList) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList('imagesList', imageList);
  }

  static Future<bool> setHashtag(String? hashtag) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (hashtag == null) {
      return prefs.remove('hashtag');
    }
    return prefs.setString('hashtag', hashtag);
  }

  static Future<void> setServerUrl(String serverUrl) async {
    var prefs = await SharedPreferences.getInstance();
    await prefs.setString('serverUrl', serverUrl);
  }

  //get
  static Future<String?> getUUID() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.get('uuid') as FutureOr<String?>;
  }

  static Future<String?> getTrackingId() async {
    var prefs = await SharedPreferences.getInstance();
    return prefs.get('trackingUUID') as FutureOr<String?>;
  }

  static Future<String?> getFirebaseId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('firebaseId');
  }

  static Future<int?> getUserScores() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userScores');
  }

  static Future<bool> getTracking() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('trackingEnabled') ?? false;
  }

  static Future<bool?> getShowInfoAdult() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('infoCameraAdult');
  }

  static Future<bool?> getShowInfoBreeding() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('infoCameraBreeding');
  }

  static Future<String?> getLanguage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('language');
  }

  static Future<String?> getLanguageCountry() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('languageCountry');
  }

  static Future<String?> getUserLocale() async {
    return '${await UserManager.getLanguage()}_${await UserManager.getLanguageCountry()}';
  }

  static Future<List<String>?> getReportList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('reportsList');
  }

  static Future<List<String>?> getImageList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('imagesList');
  }

  static Future<String?> getHashtag() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('hashtag');
  }

  static Future<String> getServerUrl() async {
    var prefs = await SharedPreferences.getInstance();
    return prefs.getString('serverUrl') ?? '';
  }

  static signOut() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('userName');
    prefs.remove('firebaseId');
    user = null;
  }
}
