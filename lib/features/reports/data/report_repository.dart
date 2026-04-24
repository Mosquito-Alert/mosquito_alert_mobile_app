import 'package:built_collection/built_collection.dart';
import 'package:dio/dio.dart';
import 'package:mosquito_alert/mosquito_alert.dart';
import 'package:mosquito_alert_app/core/outbox/outbox_item.dart';
import 'package:mosquito_alert_app/core/outbox/outbox_mixin.dart';
import 'package:mosquito_alert_app/features/reports/data/models/base_report_request.dart';
import 'package:mosquito_alert_app/features/reports/domain/models/base_report.dart';
import 'package:mosquito_alert_app/core/repositories/pagination_repository.dart';

abstract class ReportRepository<
  TReport extends BaseReportModel,
  TSdkModel,
  TApi,
  TCreateReportRequest extends BaseCreateReportRequest
>
    extends PaginationRepository<TReport, TApi>
    with OutboxMixin<TReport, TCreateReportRequest> {
  final MosquitoAlert apiClient;
  final TReport Function(TSdkModel) itemFactory;

  ReportRepository({
    required this.apiClient,
    required this.itemFactory,
    required super.itemApi,
  });

  Future<TReport> sendCreateToApi({required TCreateReportRequest request});

  @override
  bool get requiresAuth => true;

  @override
  Future<(List<TReport> items, bool hasMore)> fetchPage({
    required int page,
    required int pageSize,
  }) async {
    List<TReport> items = [];
    if (page == 1) {
      // Load offline items only on first page
      items = itemBox.values.toList();
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    try {
      final response = await (itemApi as dynamic).listMine(
        page: page,
        pageSize: pageSize,
        orderBy: BuiltList<String>(["-created_at"]),
      );

      for (final item in response.data?.results ?? []) {
        items.add(itemFactory(item));
      }
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return (items, response.data?.next != null);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return (items, false);
      } else {
        rethrow;
      }
    }
  }

  Future<int> getCount() async {
    int count = itemBox.length;
    try {
      final response = await (itemApi as dynamic).listMine(
        page: 1,
        pageSize: 1,
      );
      count += response.data?.count as int;
    } catch (_) {
      // Ignore
    }
    return count;
  }

  @override
  OutboxTask buildOutboxTaskFromItem({required OutboxItem item}) {
    return OutboxTask(
      item: item,
      action: () async {
        switch (item.operation) {
          case OutBoxOperation.create:
            final request = createRequestFactory(item.payload);
            // Let any exception propagate so the outbox can reschedule the
            // task. Previously this block swallowed all errors and allowed
            // `execute()` to treat the attempt as a success, which silently
            // deleted the local report without it ever reaching the server.
            final newReport = await _createApiOrLocal(request: request);
            if (newReport.localId != null) {
              // Still offline / server unreachable; signal a retry.
              throw Exception("Failed to create report");
            }
            break;
          case OutBoxOperation.delete:
            final request = DeleteReportRequest.fromJson(item.payload);
            try {
              await (itemApi as dynamic).destroy(uuid: request.uuid);
            } on DioException catch (e) {
              if (e.response?.statusCode == 404) {
                // Already deleted
                break;
              }
              rethrow;
            }
            break;
          default:
            break;
        }
      },
    );
  }

  Future<TReport> create({required TCreateReportRequest request}) async {
    final newReport = await _createApiOrLocal(request: request);
    if (newReport.localId != null) {
      final createItem = OutboxItem(
        id: request.localId,
        repository: repoName,
        operation: OutBoxOperation.create,
        payload: request.toJson(),
      );
      final createTask = buildOutboxTaskFromItem(item: createItem);
      await schedule(createTask, runNow: false);
    }
    return newReport;
  }

  Future<TReport> _createApiOrLocal({
    required TCreateReportRequest request,
  }) async {
    TReport newReport;
    try {
      newReport = await sendCreateToApi(request: request);
      await itemBox.delete(request.localId);
    } on DioException catch (e) {
      if (e.response?.statusCode != null && e.response!.statusCode! < 500) {
        rethrow;
      }
      newReport = buildItemFromCreateRequest(request);
    }
    return newReport;
  }

  Future<void> delete({required String uuid}) async {
    final deleteTask = buildOutboxTaskFromItem(
      item: OutboxItem(
        repository: repoName,
        operation: OutBoxOperation.delete,
        payload: DeleteReportRequest(uuid: uuid).toJson(),
      ),
    );
    await schedule(deleteTask);
  }
}
