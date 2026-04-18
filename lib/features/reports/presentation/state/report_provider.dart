import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:mosquito_alert_app/features/reports/domain/models/base_report.dart';
import 'package:mosquito_alert_app/features/reports/data/report_repository.dart';
import 'package:mosquito_alert_app/core/providers/pagination_provider.dart';

abstract class ReportProvider<
  TReport extends BaseReportModel,
  TRepository extends ReportRepository<TReport, dynamic, dynamic, dynamic>
>
    extends PaginatedProvider<TReport, TRepository> {
  ReportProvider({required super.repository})
    : super(
        orderFunction: (items) {
          items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return items;
        },
      );

  Future<void> delete({required TReport item}) async {
    if (item.uuid == null) {
      throw Exception('Cannot delete report that is pending to sync');
    }
    await repository.delete(uuid: item.uuid!);

    deleteItem(item);

    // Analytics logging
    await FirebaseAnalytics.instance.logEvent(
      name: 'delete_report',
      parameters: {'report_uuid': item.uuid!},
    );
  }

  /// Retry uploading a locally-stored report that previously failed
  /// permanently (e.g. the server returned 400/422). Clears the stored error
  /// and re-enqueues the create.
  Future<void> retrySync({required TReport item}) async {
    if (item.localId == null) return;
    await repository.retryCreate(item.localId!);
    // After retry the report may have been replaced in the item box by a
    // server-backed version (on success) or left in place (on further
    // failure). Notify listeners so the UI re-reads any sync error state.
    notifyListeners();
  }

  /// Remove a locally-queued report without contacting the server. Used when
  /// a queued create has permanently failed and the user chooses to discard
  /// it.
  Future<void> deleteLocal({required TReport item}) async {
    if (item.localId == null) return;
    await repository.deleteLocal(item.localId!);
    deleteItem(item);
  }

  /// Returns the recorded permanent sync error for [item], or null.
  String? getSyncError(TReport item) {
    final localId = item.localId;
    if (localId == null) return null;
    return repository.getSyncError(localId);
  }
}
