import 'package:built_collection/built_collection.dart';
import 'package:dio/dio.dart';
import 'package:mosquito_alert/mosquito_alert.dart';
import 'package:mosquito_alert_app/core/outbox/outbox_item.dart';
import 'package:mosquito_alert_app/core/outbox/outbox_mixin.dart';
import 'package:mosquito_alert_app/core/outbox/outbox_sync_error.dart';
import 'package:mosquito_alert_app/features/reports/data/models/base_report_request.dart';
import 'package:mosquito_alert_app/features/reports/domain/models/base_report.dart';
import 'package:mosquito_alert_app/core/repositories/pagination_repository.dart';

/// True iff [statusCode] represents a permanent (non-retryable) HTTP failure.
///
/// We treat any 4xx as permanent except 408 (Request Timeout) and 429 (Too
/// Many Requests), which are transient by spec and should be retried.
bool isPermanentHttpStatus(int? statusCode) {
  if (statusCode == null) return false;
  if (statusCode < 400 || statusCode >= 500) return false;
  if (statusCode == 408 || statusCode == 429) return false;
  return true;
}

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
            TReport newReport;
            try {
              newReport = await _createApiOrLocal(request: request);
            } on DioException catch (e) {
              if (isPermanentHttpStatus(e.response?.statusCode)) {
                // Server permanently rejected this report (e.g. 400/422).
                // Surface it to the OutboxMixin so the local copy is kept
                // and the user can retry manually or delete it.
                throw PermanentOutboxException(
                  _describeDioError(e),
                  statusCode: e.response?.statusCode,
                );
              }
              // Retryable (network error, 5xx, 408, 429): reschedule.
              rethrow;
            }
            if (newReport.localId != null) {
              // Throw exception to re-schedule
              throw Exception("Failed to create report");
            }
            break;
          case OutBoxOperation.delete:
            final request = DeleteReportRequest.fromJson(item.payload);
            try {
              await (itemApi as dynamic).destroy(uuid: request.uuid);
            } on DioException catch (e) {
              if (e.response?.statusCode == 404) {
                // TODO(C2): Revisit whether treating a 404 on delete as
                // success is always correct. Current assumption: the report
                // is already gone server-side, so the queued delete can be
                // dropped. If the server ever returns 404 for transient
                // reasons (e.g. sharded reads during a failover) we would
                // lose the delete intent. Re-evaluate when we have more
                // telemetry on delete failures.
                break;
              }
              if (isPermanentHttpStatus(e.response?.statusCode)) {
                throw PermanentOutboxException(
                  _describeDioError(e),
                  statusCode: e.response?.statusCode,
                );
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

String _describeDioError(DioException e) {
  final code = e.response?.statusCode;
  final body = e.response?.data;
  final detail = body is Map && body['detail'] is String
      ? body['detail'] as String
      : (body?.toString() ?? e.message ?? 'Unknown error');
  return code != null ? 'HTTP $code: $detail' : detail;
}
