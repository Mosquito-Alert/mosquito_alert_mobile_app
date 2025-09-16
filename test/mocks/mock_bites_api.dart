import 'package:built_collection/built_collection.dart';
import 'package:dio/dio.dart';
import 'package:mosquito_alert/mosquito_alert.dart' as sdk;

/// Mock BitesApi implementation that captures API calls
class MockBitesApi extends sdk.BitesApi {
  bool createCalled = false;
  sdk.BiteRequest? lastBiteRequest;
  bool shouldFail = false;
  bool destroyCalled = false;
  String? lastDestroyedUuid;
  bool shouldFailDestroy = false;
  List<sdk.Bite> _bites = [];

  MockBitesApi() : super(Dio(), sdk.serializers);

  void setBites(List<sdk.Bite> bites) {
    _bites = bites;
  }

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

  @override
  Future<Response<sdk.PaginatedBiteList>> listMine({
    int? page,
    int? pageSize,
    BuiltList<String>? orderBy,
    int? countryId,
    DateTime? createdAtAfter,
    DateTime? createdAtBefore,
    DateTime? receivedAtAfter,
    DateTime? receivedAtBefore,
    String? shortId,
    DateTime? updatedAtAfter,
    DateTime? updatedAtBefore,
    String? userUuid,
    CancelToken? cancelToken,
    Map<String, dynamic>? extra,
    Map<String, dynamic>? headers,
    void Function(int, int)? onReceiveProgress,
    void Function(int, int)? onSendProgress,
    bool Function(int?)? validateStatus,
  }) async {
    await Future.delayed(Duration(milliseconds: 100));

    if (shouldFail) {
      throw Exception('Network error');
    }

    final currentPage = page ?? 1;
    final size = pageSize ?? 20;
    final startIndex = (currentPage - 1) * size;
    final endIndex = startIndex + size;

    final paginatedResults = _bites.length > startIndex
        ? _bites.sublist(startIndex, endIndex.clamp(0, _bites.length))
        : <sdk.Bite>[];

    final hasNext = endIndex < _bites.length;

    return Response<sdk.PaginatedBiteList>(
      statusCode: 200,
      requestOptions: RequestOptions(path: '/bites/'),
      data: sdk.PaginatedBiteList((b) => b
        ..count = _bites.length
        ..next = hasNext ? 'next-page-url' : null
        ..previous = currentPage > 1 ? 'previous-page-url' : null
        ..results = BuiltList<sdk.Bite>(paginatedResults).toBuilder()),
    );
  }

  @override
  Future<Response<dynamic>> destroy({
    required String uuid,
    CancelToken? cancelToken,
    Map<String, dynamic>? extra,
    Map<String, dynamic>? headers,
    void Function(int, int)? onReceiveProgress,
    void Function(int, int)? onSendProgress,
    bool Function(int?)? validateStatus,
  }) async {
    destroyCalled = true;
    lastDestroyedUuid = uuid;

    await Future.delayed(Duration(milliseconds: 100));

    if (shouldFailDestroy) {
      throw Exception('Delete failed');
    }

    // Remove the bite from the mock data
    _bites.removeWhere((bite) => bite.uuid == uuid);

    return Response<dynamic>(
      statusCode: 204, // No Content - standard for successful delete
      requestOptions: RequestOptions(path: '/bites/$uuid/'),
    );
  }
}
