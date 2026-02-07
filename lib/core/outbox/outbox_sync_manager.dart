import 'package:mosquito_alert_app/core/outbox/outbox_mixin.dart';

class OutboxSyncManager {
  final List<OutboxMixin> _repositories;

  OutboxSyncManager(this._repositories);

  Future<bool> syncAll() async {
    bool hasPending = false;
    for (final repo in _repositories) {
      final repoHasPending = await repo.syncRepository();
      if (repoHasPending) {
        hasPending = true;
      }
    }

    return hasPending;
  }
}
