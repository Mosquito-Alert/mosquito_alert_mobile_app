import 'package:hive_ce/hive.dart';

/// Thrown from an [OutboxTask.action] to signal that the server permanently
/// rejected the request (e.g. HTTP 4xx other than 408/429) and there is no
/// point in retrying automatically.
///
/// When the [OutboxMixin] sees this exception it will:
///   * keep the corresponding local item (no silent data loss),
///   * store [message] in [OutboxErrorStore] keyed by the item's `localId`,
///   * remove the item from the outbox queue so it is not auto-retried.
///
/// The user can then explicitly retry or delete the local copy from the UI.
class PermanentOutboxException implements Exception {
  final String message;
  final int? statusCode;

  PermanentOutboxException(this.message, {this.statusCode});

  @override
  String toString() =>
      'PermanentOutboxException(${statusCode ?? '-'}): $message';
}

/// Persists a short human-readable error message for items whose sync has
/// permanently failed, keyed by their `localId`.
///
/// Stored separately from the item models so that we don't need to touch the
/// Hive adapters of every domain model just to carry an error field.
class OutboxErrorStore {
  // ---- Singleton boilerplate ----
  OutboxErrorStore._internal();
  static final OutboxErrorStore _instance = OutboxErrorStore._internal();
  factory OutboxErrorStore() => _instance;

  // ---- Class implementation ----
  static const boxName = 'outbox_sync_errors';

  Box<String> get _box => Hive.box<String>(boxName);

  /// Open the backing box. Safe to call multiple times.
  static Future<void> init() async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox<String>(boxName);
    }
  }

  /// Record [message] as the latest permanent sync error for [localId].
  Future<void> put(String localId, String message) async {
    await _box.put(localId, message);
  }

  /// Returns the last recorded permanent sync error for [localId], or null.
  String? get(String localId) => _box.get(localId);

  /// Clear the recorded error for [localId] (e.g. on retry or on deletion).
  Future<void> remove(String localId) async {
    await _box.delete(localId);
  }

  /// True iff [localId] has a recorded permanent sync error.
  bool hasError(String localId) => _box.containsKey(localId);
}
