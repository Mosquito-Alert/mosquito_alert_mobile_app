import 'package:flutter_test/flutter_test.dart';
import 'package:mosquito_alert_app/utils/UserManager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final testCases = [
    {'input': 'myTag1', 'expectedHashtag': 'myTag1'},
    {'input': '#myTag2', 'expectedHashtag': 'myTag2'},
  ];

  testWidgets('Migration from hashtag to hashtags', (tester) async {
    // Set mock initial values for SharedPreferences
    SharedPreferences.setMockInitialValues({});

    // Create a mock instance of SharedPreferences
    final prefs = await SharedPreferences.getInstance();

    for (final testCase in testCases) {
      await prefs.setString('hashtag', testCase['input'] ?? '');

      // Call the migration function
      await UserManager.migrateHashtagToHashtags();

      // Verify that 'hashtag' is removed
      expect(prefs.containsKey('hashtag'), false);

      // Verify that the expected hashtag is added to 'hashtags'
      final hashtags = prefs.getStringList('hashtags');
      expect(hashtags, contains(testCase['expectedHashtag']));
    }
  });
}