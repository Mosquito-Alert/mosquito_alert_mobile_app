import 'package:built_collection/built_collection.dart';
import 'package:mosquito_alert/mosquito_alert.dart' as sdk;
import 'package:mosquito_alert_app/core/repositories/pagination_repository.dart';

class NotificationRepository
    extends PaginationRepository<sdk.Notification, sdk.NotificationsApi> {
  NotificationRepository({required sdk.MosquitoAlert apiClient})
    : super(itemApi: apiClient.getNotificationsApi());

  Future<sdk.Notification> fetchById({required int id}) {
    // TODO: Handle errors
    return itemApi.retrieve(id: id).then((response) {
      return response.data!;
    });
  }

  Future<sdk.Notification> markAsRead({
    required sdk.Notification notification,
  }) {
    final request = sdk.PatchedNotificationRequest((b) => b..isRead = true);
    return itemApi
        .partialUpdate(id: notification.id, patchedNotificationRequest: request)
        .then((response) {
          return response.data!;
        });
  }

  Future<int> fetchUnreadCount() {
    return itemApi.listMine(isRead: false, pageSize: 1).then((response) {
      return response.data?.count ?? 0;
    });
  }

  @override
  Future<(List<sdk.Notification>, bool hasMore)> fetchPage({
    required int page,
    required int pageSize,
  }) async {
    final response = await itemApi.listMine(
      page: page,
      pageSize: pageSize,
      orderBy: BuiltList<String>(["-created_at"]),
    );

    return (response.data!.results.toList(), response.data!.next != null);
  }
}
