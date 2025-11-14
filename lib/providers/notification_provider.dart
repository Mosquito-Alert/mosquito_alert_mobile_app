import 'dart:math';

import 'package:built_collection/built_collection.dart';

import 'package:flutter/material.dart';
import 'package:mosquito_alert/mosquito_alert.dart' as sdk;

class NotificationProvider extends ChangeNotifier {
  late final sdk.NotificationsApi notificationsApi;
  static const _pageSize = 20;

  NotificationProvider({required sdk.MosquitoAlert apiClient}) {
    notificationsApi = apiClient.getNotificationsApi();
  }

  List<sdk.Notification> _notifications = [];
  List<sdk.Notification> get notifications => _notifications;

  int _lastFetchedPage = 0;

  bool _hasMoreNotifications = true;
  bool get hasMoreNotifications => _hasMoreNotifications;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isFetchingUnread = false;

  int _unreadNotificationsCount = 0;
  int get unreadNotificationsCount => _unreadNotificationsCount;

  Future<sdk.Notification?> getById({required int id}) async {
    // Check in the cached list first
    final sdk.Notification? cached =
        _notifications.where((n) => n.id == id).firstOrNull;
    if (cached != null) return cached;

    // Otherwise, fetch from API
    try {
      final response = await notificationsApi.retrieve(id: id);
      return response.data!;
    } catch (e) {
      debugPrint('Error fetching notification by id: $e');
      return null;
    }
  }

  Future<void> markAsRead({required sdk.Notification notification}) async {
    if (notification.isRead) return;

    try {
      final request = sdk.PatchedNotificationRequest((b) => b..isRead = true);
      await notificationsApi.partialUpdate(
          id: notification.id, patchedNotificationRequest: request);
      // Update local cache
      final index = _notifications.indexWhere((n) => n.id == notification.id);
      if (index != -1) {
        final updatedNotification =
            _notifications[index].rebuild((b) => b..isRead = true);
        _notifications[index] = updatedNotification;
        _unreadNotificationsCount = max(0, (_unreadNotificationsCount - 1));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> fetchNextPage({bool clear = false}) async {
    if (_isLoading || !_hasMoreNotifications) return;

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      int nextPage = _lastFetchedPage + 1;
      final response = await notificationsApi.listMine(
        page: nextPage,
        pageSize: _pageSize,
        orderBy: BuiltList<String>([
          "-created_at",
        ]),
      );

      final newNotifications = response.data?.results?.toList() ?? [];
      _hasMoreNotifications = response.data?.next != null;
      _lastFetchedPage = nextPage;

      if (clear) {
        _notifications = newNotifications;
      } else {
        _notifications.addAll(newNotifications);
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUnreadNotificationsCount() async {
    if (_isFetchingUnread) {
      debugPrint("Skipping fetchUnreadNotificationsCount — already loading");
      return;
    }
    try {
      _isFetchingUnread = true;
      final response = await notificationsApi.listMine(
        pageSize: 1,
        isRead: false,
      );
      _unreadNotificationsCount = response.data?.count ?? 0;
    } catch (_) {
      // Optionally handle/log
    } finally {
      _isFetchingUnread = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    _lastFetchedPage = 0;
    _hasMoreNotifications = true;
    await fetchNextPage(clear: true);
    await fetchUnreadNotificationsCount();
  }
}
