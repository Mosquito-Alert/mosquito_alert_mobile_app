import 'package:dio/dio.dart';
import 'package:mosquito_alert/mosquito_alert.dart' as sdk;

/// Mock BitesApi implementation that captures API calls
class MockBitesApi extends sdk.BitesApi {
  bool createCalled = false;
  sdk.BiteRequest? lastBiteRequest;
  bool shouldFail = false;

  MockBitesApi() : super(Dio(), sdk.serializers);

  @override
  Future<Response<sdk.Bite>> create({
    required sdk.BiteRequest biteRequest,
    CancelToken? cancelToken,
    Map<String, dynamic>? extra,
    Map<String, dynamic>? headers,
    void Function(int, int)? onReceiveProgress,
    void Function(int, int)? onSendProgress,
    bool Function(int?)? validateStatus,
  }) async {
    createCalled = true;
    lastBiteRequest = biteRequest;

    await Future.delayed(Duration(milliseconds: 100));

    if (shouldFail) {
      throw Exception('Network error');
    }

    return Response<sdk.Bite>(
      statusCode: 201,
      requestOptions: RequestOptions(path: '/bites/'),
      data: sdk.Bite((b) => b
        ..uuid = 'test-uuid-123'
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now()),
    );
  }
}
