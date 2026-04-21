import 'package:dio/dio.dart';
import 'package:mosquito_alert/mosquito_alert.dart' as sdk;

import 'mock_notifications_api.dart';
import 'mock_bites_api.dart';

class MockMosquitoAlert extends sdk.MosquitoAlert {
  final MockNotificationsApi _notificationsApi;
  final MockBitesApi _bitesApi;

  MockMosquitoAlert()
    : _notificationsApi = MockNotificationsApi(Dio(), sdk.serializers),
      _bitesApi = MockBitesApi();

  @override
  sdk.NotificationsApi getNotificationsApi() => _notificationsApi;

  @override
  sdk.BitesApi getBitesApi() => _bitesApi;

  // Getters to access the APIs for testing
  MockNotificationsApi get notificationsApi => _notificationsApi;
  MockBitesApi get bitesApi => _bitesApi;
}
