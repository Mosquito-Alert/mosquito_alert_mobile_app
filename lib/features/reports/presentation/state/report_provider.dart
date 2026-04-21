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
}
