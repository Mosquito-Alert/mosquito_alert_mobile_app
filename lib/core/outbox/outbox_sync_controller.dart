import 'dart:async';

import 'package:mosquito_alert_app/core/outbox/outbox_sync_manager.dart';

class OutboxSyncController {
  final OutboxSyncManager _syncManager;
  final List<Duration> _backoffSchedule = const [
    Duration(minutes: 1),
    Duration(minutes: 5),
    Duration(minutes: 15),
    Duration(hours: 1),
  ];

  Timer? _retryTimer;
  bool _syncInProgress = false;
  int _failureCount = 0;

  OutboxSyncController(this._syncManager);

  Future<void> triggerSync() async {
    if (_syncInProgress) return;
    _retryTimer?.cancel();

    _syncInProgress = true;
    bool hasPending = false;
    try {
      hasPending = await _syncManager.syncAll();
    } finally {
      _syncInProgress = false;
    }

    if (hasPending) {
      _scheduleRetry();
    } else {
      _failureCount = 0;
    }
  }

  void _scheduleRetry() {
    final index = _failureCount < _backoffSchedule.length
        ? _failureCount
        : _backoffSchedule.length - 1;
    final delay = _backoffSchedule[index];
    _failureCount++;

    _retryTimer = Timer(delay, triggerSync);
  }

  void dispose() {
    _retryTimer?.cancel();
  }
}
