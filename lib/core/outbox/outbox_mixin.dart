import 'package:hive_ce/hive.dart';
import 'package:synchronized/extension.dart';
import 'package:mosquito_alert_app/core/data/models/requests.dart';
import 'package:mosquito_alert_app/core/outbox/outbox_backoff.dart';
import 'package:mosquito_alert_app/core/outbox/outbox_item.dart';
import 'package:mosquito_alert_app/core/outbox/outbox_offline_model.dart';
import 'package:mosquito_alert_app/core/outbox/outbox_service.dart';
import 'package:mosquito_alert_app/core/outbox/outbox_sync_error.dart';

mixin OutboxMixin<
  T extends OfflineModel,
  TCreateRequest extends CreateRequest
> {
  final OutboxService outbox = OutboxService();
  final OutboxErrorStore _errorStore = OutboxErrorStore();
  final OutboxBackoffStore _backoffStore = OutboxBackoffStore();

  bool get requiresAuth;

  /// Each repository must return a unique name
  String get repoName;

  // NOTE: Hive box to store offline items. This is replacing the OutboxItem
  // when creating new reports in order to avoid desynchronization issues.
  // Main issue: a items is stored in the box and the corresponding OutboxItem is lost.
  Box<T> get itemBox;

  T buildItemFromCreateRequest(TCreateRequest request);
  TCreateRequest createRequestFactory(Map<String, dynamic> payload);
  TCreateRequest buildCreateRequestFromItem(T item);
  OutboxTask buildOutboxTaskFromItem({required OutboxItem item});

  /// Repository must implement method dispatcher
  Future<void> execute(OutboxTask task) async {
    final item = task.item;
    await outbox.remove(item.id);
    try {
      await task.run();
    } on PermanentOutboxException catch (e) {
      // Server permanently rejected this operation. Keep the local item
      // around so the user can see it, retry manually, or delete it; do NOT
      // reschedule and do NOT delete the local copy.
      if (item.operation == OutBoxOperation.create) {
        final request = createRequestFactory(item.payload);
        await _errorStore.put(request.localId, e.message);
      } else {
        // TODO(outbox): permanent failures on non-create operations (update,
        // delete) are currently dropped silently. They have no `localId` in
        // the UI to attach an error to, so surfacing them requires a
        // separate mechanism (e.g. a "sync problems" tray). Track with the
        // broader offline-first followups.
      }
      // Permanent failures are terminal: clear any prior backoff so an
      // explicit user retry starts from a clean slate.
      await _backoffStore.clear(_backoffKey(item));
      return;
    } catch (error) {
      // Retryable failure (network error, 5xx, etc.): reschedule with
      // exponential backoff so we don't hot-loop on every sync tick.
      _backoffStore.recordFailure(_backoffKey(item));
      await schedule(task, runNow: false);
      return; // stop further execution
    }

    // Runs only if task.run() succeeded
    await _backoffStore.clear(_backoffKey(item));
    if (item.operation == OutBoxOperation.create) {
      final request = createRequestFactory(item.payload);
      await itemBox.delete(request.localId);
      // Clear any previous permanent error now that the item is synced.
      await _errorStore.remove(request.localId);
    }
  }

  Future<void> schedule(OutboxTask task, {bool runNow = true}) async {
    final item = task.item;
    if (item.operation == OutBoxOperation.create) {
      final request = createRequestFactory(item.payload);
      final newItem = buildItemFromCreateRequest(request);
      await itemBox.put(request.localId, newItem);
    }
    await outbox.add(item);
    if (!runNow) return;
    // Explicit user/code-driven runNow honors the request immediately and
    // resets backoff so retry isn't blocked by an in-progress wait.
    await _backoffStore.clear(_backoffKey(item));
    try {
      await execute(task);
    } catch (_) {
      // Do nothing
    }
  }

  Future<void> syncRepository() async {
    return synchronized(() async {
      final items = itemBox.values
          .where((e) => e.localId != null)
          // Skip items that previously failed permanently: the user must
          // explicitly retry or delete them from the UI.
          .where((e) => !_errorStore.hasError(e.localId!))
          // Skip items still inside their backoff window.
          .where((e) => !_backoffStore.isBackedOff(e.localId!))
          .map(
            (e) => OutboxItem(
              id: e.localId,
              repository: repoName,
              operation: OutBoxOperation.create,
              payload: buildCreateRequestFromItem(e).toJson(),
            ),
          )
          .toList();

      items.addAll(
        outbox
            .getAll()
            .where(
              (i) =>
                  i.repository == repoName &&
                  i.operation != OutBoxOperation.create &&
                  !_backoffStore.isBackedOff(i.id),
            )
            .toList(),
      );

      for (final item in items) {
        try {
          await execute(buildOutboxTaskFromItem(item: item));
        } catch (_) {
          // Do nothing
        }
      }
    });
  }

  /// Returns the recorded permanent sync error for a locally-queued create,
  /// or null if there is none.
  ///
  /// NOTE: Errors are only recorded for `create` operations, because only
  /// creates have a local copy visible in the UI (keyed by `localId`).
  /// Permanent failures on other operations (e.g. a 403 on delete) are
  /// currently dropped silently by [execute].
  String? getSyncError(String localId) => _errorStore.get(localId);

  /// Clear any previous permanent sync error and attempt to send the locally
  /// stored create again. Has no effect if [localId] is not in the local
  /// item box.
  Future<void> retryCreate(String localId) async {
    final item = itemBox.get(localId);
    if (item == null) return;
    await _errorStore.remove(localId);
    // User-initiated retry should bypass any pending backoff.
    await _backoffStore.clear(localId);
    final request = buildCreateRequestFromItem(item);
    final outboxItem = OutboxItem(
      id: request.localId,
      repository: repoName,
      operation: OutBoxOperation.create,
      payload: request.toJson(),
    );
    final task = buildOutboxTaskFromItem(item: outboxItem);
    await schedule(task, runNow: true);
  }

  /// Remove a locally-queued item (and any pending outbox/error state) without
  /// contacting the server. Used when the user gives up on a permanently
  /// failed create.
  Future<void> deleteLocal(String localId) async {
    await outbox.remove(localId);
    await itemBox.delete(localId);
    await _errorStore.remove(localId);
    await _backoffStore.clear(localId);
  }

  /// Backoff is keyed by the OutboxItem id, which matches `localId` for
  /// creates and is the random uuid for non-create ops. Wrapped in a tiny
  /// helper so callers don't have to know about that.
  String _backoffKey(OutboxItem item) => item.id;
}
