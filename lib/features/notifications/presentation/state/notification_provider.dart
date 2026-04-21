import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mosquito_alert/mosquito_alert.dart' as sdk;
import 'package:mosquito_alert_app/core/providers/pagination_provider.dart';
import 'package:mosquito_alert_app/features/notifications/notification_repository.dart';

class NotificationProvider
    extends PaginatedProvider<sdk.Notification, NotificationRepository> {
  NotificationProvider({required super.repository});

  bool _isFetchingUnread = false;

  int _unreadNotificationsCount = 0;
  int get unreadNotificationsCount => _unreadNotificationsCount;

  Future<sdk.Notification?> getById({required int id}) async {
    // Check in the cached list first
    try {
      return items.firstWhere((n) => n.id == id);
    } catch (e) {
      // If not found, continue to fetch from API
    }

    final fetched = await repository.fetchById(id: id);

    return fetched;
  }

  Future<void> markAsRead({required sdk.Notification notification}) async {
    if (notification.isRead) return;

    final updatedNotification = await repository.markAsRead(
      notification: notification,
    );

    int index = items.indexWhere((n) => n.id == notification.id);
    if (index != -1) {
      items[index] = updatedNotification;
      _unreadNotificationsCount = max(0, (_unreadNotificationsCount - 1));
      notifyListeners();
    }
  }

  Future<void> fetchUnreadNotificationsCount() async {
    if (_isFetchingUnread) {
      debugPrint("Skipping fetchUnreadNotificationsCount — already loading");
      return;
    }
    _isFetchingUnread = true;
    notifyListeners();
    try {
      _unreadNotificationsCount = await repository.fetchUnreadCount();
    } catch (_) {
      // Optionally handle/log
    } finally {
      _isFetchingUnread = false;
      notifyListeners();
    }
  }

  @override
  Future<void> refresh() async {
    super.refresh();
    await fetchUnreadNotificationsCount();
  }
}
