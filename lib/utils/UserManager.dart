import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mosquito_alert_app/pages/settings_pages/consent_form.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserManager {
  static Future<void> startFirstTime(context) async {
    var prefs = await SharedPreferences.getInstance();
    var firstTime = prefs.getBool('firstTime');

    if (firstTime == null || !firstTime) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ConsentForm(),
        ),
      );
      await prefs.setBool('firstTime', true);
    }
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
