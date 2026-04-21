import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class MockFirebaseAnalytics {
  static void setMockMethodCallHandler() {
    TestWidgetsFlutterBinding.ensureInitialized();

    // Mock Firebase Core - ensure DEFAULT app exists
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/firebase_core'),
          (MethodCall methodCall) async {
            switch (methodCall.method) {
              case 'Firebase#initializeCore':
                return [
                  {
                    'name': '[DEFAULT]',
                    'options': {
                      'apiKey': 'test-api-key',
                      'appId': 'test-app-id',
                      'messagingSenderId': 'test-sender-id',
                      'projectId': 'test-project-id',
                    },
                    'pluginConstants': {},
                  },
                ];
              case 'Firebase#initializeApp':
                return {
                  'name': methodCall.arguments['appName'] ?? '[DEFAULT]',
                  'options': methodCall.arguments['options'],
                  'pluginConstants': {},
                };
              default:
                return null;
            }
          },
        );

    // Mock Firebase Analytics
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/firebase_analytics'),
          (MethodCall methodCall) async {
            return null;
          },
        );
  }
}
