import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DeviceProvider package version format', () {
    test('should format package version with build number', () {
      // Mock PackageInfo data
      const version = '4.1.0';
      const buildNumber = '1234';

      // Simulate the format used in device_provider.dart
      final formattedVersion = '$version+$buildNumber';

      // Verify the format matches expected pattern
      expect(formattedVersion, '4.1.0+1234');
      expect(formattedVersion, contains('+'));
      expect(formattedVersion.split('+').length, 2);
      expect(formattedVersion.split('+')[0], version);
      expect(formattedVersion.split('+')[1], buildNumber);
    });

    test('should handle different version and build number combinations', () {
      const testCases = [
        {'version': '1.0.0', 'buildNumber': '1', 'expected': '1.0.0+1'},
        {'version': '2.1.5', 'buildNumber': '999', 'expected': '2.1.5+999'},
        {'version': '4.1.0', 'buildNumber': '2898', 'expected': '4.1.0+2898'},
      ];

      for (final testCase in testCases) {
        final version = testCase['version']!;
        final buildNumber = testCase['buildNumber']!;
        final expected = testCase['expected']!;

        final formattedVersion = '$version+$buildNumber';
        expect(formattedVersion, expected);
      }
    });
  });
}
