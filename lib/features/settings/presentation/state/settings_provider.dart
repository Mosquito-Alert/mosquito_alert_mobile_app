import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  List<String> _hashtags = [];

  List<String> get hashtags => _hashtags;
  set hashtags(List<String> value) {
    _hashtags = value;
    notifyListeners();
  }

  SettingsProvider() {
    _init();
  }

  Future<void> _init() async {
    hashtags = await _loadHashtags();
  }

  Future<List<String>> _loadHashtags() async {
    // Load hashtags from persistent storage
    var prefs = await SharedPreferences.getInstance();

    // Migrate old hashtag to hashtags if necessary
    if (prefs.containsKey('hashtag')) {
      String? oldHashtag = prefs.getString('hashtag');
      if (oldHashtag != null) {
        // Users were adding the hashtag manually to the strings
        if (oldHashtag.startsWith('#')) {
          oldHashtag = oldHashtag.substring(1);
        }
        ;
        await prefs.remove('hashtag');
        await prefs.setStringList('hashtags', [oldHashtag]);
      }
    }
    return prefs.getStringList('hashtags') ?? [];
  }
}
