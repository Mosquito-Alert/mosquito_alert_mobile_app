import 'package:built_collection/built_collection.dart';
import 'package:dio/dio.dart';
import 'package:mosquito_alert/mosquito_alert.dart' as sdk;

class MockNotificationsApi extends sdk.NotificationsApi {
  List<sdk.Notification> _notifications = [];
  static const int _pageSize = 20;

  MockNotificationsApi(super.dio, super.serializers);

  void setNotifications(List<sdk.Notification> notifications) {
    _notifications = notifications;
  }

  @override
  Future<Response<sdk.PaginatedNotificationList>> listMine({
    bool? isRead,
    BuiltList<String>? orderBy,
    int? page,
    int? pageSize,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final currentPage = page ?? 1;
    final size = pageSize ?? _pageSize;
    final startIndex = (currentPage - 1) * size;
    final endIndex = startIndex + size;

    final pageNotifications = _notifications.sublist(startIndex,
        endIndex > _notifications.length ? _notifications.length : endIndex);

    final hasNext = endIndex < _notifications.length;
    final nextUrl =
        hasNext ? 'http://example.com/?page=${currentPage + 1}' : null;

    final paginatedList = sdk.PaginatedNotificationList((b) => b
      ..results = ListBuilder<sdk.Notification>(pageNotifications)
      ..next = nextUrl
      ..count = _notifications.length);

    return Response<sdk.PaginatedNotificationList>(
      data: paginatedList,
      statusCode: 200,
      requestOptions: RequestOptions(path: '/me/notifications/'),
    );
  }

  @override
  Future<Response<sdk.Notification>> retrieve({
    required int id,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final notification = _notifications.firstWhere((n) => n.id == id,
        orElse: () => throw Exception('Notification not found'));

    return Response<sdk.Notification>(
      data: notification,
      statusCode: 200,
      requestOptions: RequestOptions(path: '/notifications/$id/'),
    );
  }

  @override
  Future<Response<sdk.Notification>> partialUpdate({
    required int id,
    sdk.PatchedNotificationRequest? patchedNotificationRequest,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index == -1) throw Exception('Notification not found');

    final updatedNotification = _notifications[index].rebuild(
        (b) => b..isRead = patchedNotificationRequest?.isRead ?? b.isRead);

    _notifications[index] = updatedNotification;

    return Response<sdk.Notification>(
      data: updatedNotification,
      statusCode: 200,
      requestOptions: RequestOptions(path: '/notifications/$id/'),
    );
  }
}
