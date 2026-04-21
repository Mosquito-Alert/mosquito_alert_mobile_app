import 'package:firebase_analytics/firebase_analytics.dart';

/// Abstract analytics service to enable mocking in tests
abstract class AnalyticsService {
  Future<void> logScreenView({required String screenName});
  Future<void> logSelectContent({
    required String contentType,
    required String itemId,
  });
}

/// Firebase Analytics implementation
class FirebaseAnalyticsService implements AnalyticsService {
  @override
  Future<void> logScreenView({required String screenName}) async {
    try {
      await FirebaseAnalytics.instance.logScreenView(screenName: screenName);
    } catch (e) {
      // Handle Firebase errors gracefully
      print('Analytics error: $e');
    }
  }

  @override
  Future<void> logSelectContent({
    required String contentType,
    required String itemId,
  }) async {
    try {
      await FirebaseAnalytics.instance.logSelectContent(
        contentType: contentType,
        itemId: itemId,
      );
    } catch (e) {
      // Handle Firebase errors gracefully
      print('Analytics error: $e');
    }
  }
}

/// Mock analytics service for testing
class MockAnalyticsService implements AnalyticsService {
  @override
  Future<void> logScreenView({required String screenName}) async {
    // Do nothing in tests
  }

  @override
  Future<void> logSelectContent({
    required String contentType,
    required String itemId,
  }) async {
    // Do nothing in tests
  }
}
