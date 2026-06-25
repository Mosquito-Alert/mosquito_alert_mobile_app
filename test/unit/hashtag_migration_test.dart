import 'package:flutter_test/flutter_test.dart';
import 'package:mosquito_alert_app/features/settings/presentation/state/settings_provider.dart';
import 'package:mosquito_alert_app/features/settings/data/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final testCases = [
    {'input': 'myTag1', 'expectedHashtag': 'myTag1'},
    {'input': '#myTag2', 'expectedHashtag': 'myTag2'},
  ];

  test('Migration from hashtag to hashtags via SettingsProvider', () async {
    for (final testCase in testCases) {
      // Reset mock storage for each test case
      SharedPreferences.setMockInitialValues({});

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('hashtag', testCase['input']!);

      // Create repository and allow its migration to complete
      final repository = SettingsRepository();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Instantiate provider (this loads hashtags after migration)
      final provider = SettingsProvider(repository);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Verify that 'hashtag' is removed
      expect(prefs.containsKey('hashtag'), false);

      // Verify that the expected hashtag is added
      expect(provider.hashtags, contains(testCase['expectedHashtag']));
      expect(
        prefs.getStringList('hashtags'),
        contains(testCase['expectedHashtag']),
      );
    }
  });
}
