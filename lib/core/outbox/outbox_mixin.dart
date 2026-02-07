import 'package:hive_ce/hive.dart';
import 'package:mosquito_alert_app/core/data/models/requests.dart';
import 'package:mosquito_alert_app/core/outbox/outbox_item.dart';
import 'package:mosquito_alert_app/core/outbox/outbox_offline_model.dart';
import 'package:mosquito_alert_app/core/outbox/outbox_service.dart';

mixin OutboxMixin<
  T extends OfflineModel,
  TCreateRequest extends CreateRequest
> {
  final OutboxService outbox = OutboxService();

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
    } catch (error) {
      // Only runs if task.run() fails
      await schedule(task, runNow: false);
      return; // stop further execution
    }

    // Runs only if task.run() succeeded
    if (item.operation == OutBoxOperation.create) {
      final request = createRequestFactory(item.payload);
      await itemBox.delete(request.localId);
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
    try {
      await execute(task);
    } catch (_) {
      // Do nothing
    }
  }

  Future<bool> syncRepository() async {
    final items = itemBox.values
        .where((e) => e.localId != null)
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
                i.operation != OutBoxOperation.create,
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

    final pendingItemCount = itemBox.values
        .where((e) => e.localId != null)
        .length;
    final pendingOutboxCount = outbox
        .getAll()
        .where((i) => i.repository == repoName)
        .length;

    return pendingItemCount + pendingOutboxCount > 0;
  }
}
