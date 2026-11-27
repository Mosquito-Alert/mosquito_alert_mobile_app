import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mosquito_alert/mosquito_alert.dart' as sdk;
import 'package:mosquito_alert_app/core/providers/pagination_provider.dart';
import 'package:mosquito_alert_app/core/repositories/pagination_repository.dart';
import 'package:mosquito_alert_app/features/notifications/notification_repository.dart';
import 'package:mosquito_alert_app/features/notifications/presentation/state/notification_provider.dart';

import '../mocks/mock_mosquito_alert.dart';

/// A repository whose answers arrive only when the test says so.
class _SlowPaginationRepository extends PaginationRepository<int, Object> {
  _SlowPaginationRepository() : super(itemApi: Object());

  final page = Completer<(List<int>, bool)>();

  @override
  Future<(List<int> items, bool hasMore)> fetchPage({
    required int page,
    required int pageSize,
  }) => this.page.future;
}

class _TestPaginatedProvider
    extends PaginatedProvider<int, _SlowPaginationRepository> {
  _TestPaginatedProvider({required super.repository});
}

class _SlowNotificationRepository extends NotificationRepository {
  _SlowNotificationRepository() : super(apiClient: MockMosquitoAlert());

  final page = Completer<(List<sdk.Notification>, bool)>();
  final unreadCount = Completer<int>();

  @override
  Future<(List<sdk.Notification>, bool hasMore)> fetchPage({
    required int page,
    required int pageSize,
  }) => this.page.future;

  @override
  Future<int> fetchUnreadCount() => unreadCount.future;
}

void main() {
  group('a provider that is disposed while a request is in flight', () {
    test('a paginated list finishes loading without an error', () async {
      final repository = _SlowPaginationRepository();
      final provider = _TestPaginatedProvider(repository: repository);
      var notifications = 0;
      provider.addListener(() => notifications++);

      final loading = provider.loadInitial();
      expect(notifications, 1);

      provider.dispose();
      repository.page.complete(([1, 2], false));

      await loading;
      expect(notifications, 1, reason: 'nothing is notified after dispose');
    });

    test('the notifications refresh at start-up finishes without an error, '
        'as when the app is closed during it', () async {
      final repository = _SlowNotificationRepository();
      final provider = NotificationProvider(repository: repository);

      // What LayoutPage starts when the app opens.
      final refresh = provider.refresh();

      // The widget tree goes away before the server has answered.
      provider.dispose();
      repository.page.complete((<sdk.Notification>[], false));
      repository.unreadCount.complete(3);

      await refresh;
      // The list part of the refresh is not awaited by refresh() itself.
      await pumpEventQueue();
    });

    test('a failed request finishes without an error too', () async {
      final repository = _SlowNotificationRepository();
      final provider = NotificationProvider(repository: repository);

      final refresh = provider.refresh();
      provider.dispose();
      repository.page.completeError(Exception('no connection'));
      repository.unreadCount.completeError(Exception('no connection'));

      await refresh;
      await pumpEventQueue();
    });
  });

  test('a provider still notifies its listeners while it is alive', () async {
    final repository = _SlowPaginationRepository();
    final provider = _TestPaginatedProvider(repository: repository);
    var notifications = 0;
    provider.addListener(() => notifications++);

    final loading = provider.loadInitial();
    repository.page.complete(([1, 2], false));
    await loading;

    expect(notifications, 2);
    expect(provider.items, [1, 2]);
    expect(provider.isLoading, isFalse);
  });

  test('without the guard, Flutter rejects a notification after dispose', () {
    // This is the error that failed the integration test in CI:
    // "A NotificationProvider was used after being disposed."
    final plain = _PlainNotifier()..dispose();
    expect(plain.notify, throwsFlutterError);
  });
}

class _PlainNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}
