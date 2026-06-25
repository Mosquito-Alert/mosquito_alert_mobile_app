import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  static const String _hashtagsKey = 'hashtags';

  SettingsRepository() {
    _init();
  }

  Future<void> _init() async {
    await _migrateHashtags();
  }

  Future<List<String>> getHashtags() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_hashtagsKey) ?? [];
  }

  Future<void> setHashtags(List<String> hashtags) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_hashtagsKey, hashtags);
  }

  Future<void> _migrateHashtags() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('hashtag')) {
      String? oldHashtag = prefs.getString('hashtag');
      if (oldHashtag != null) {
        // Users were adding the hashtag manually to the strings
        if (oldHashtag.startsWith('#')) {
          oldHashtag = oldHashtag.substring(1);
        }
        await prefs.remove('hashtag');
        await prefs.setStringList(_hashtagsKey, [oldHashtag]);
      }
    }
  }
}
