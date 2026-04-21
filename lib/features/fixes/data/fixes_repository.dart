import 'package:dio/dio.dart';
import 'package:hive_ce/hive.dart';
import 'package:mosquito_alert/mosquito_alert.dart' as sdk;
import 'package:mosquito_alert_app/core/outbox/outbox_item.dart';
import 'package:mosquito_alert_app/core/outbox/outbox_mixin.dart';
import 'package:mosquito_alert_app/features/fixes/data/models/fix_request.dart';
import 'package:mosquito_alert_app/features/fixes/domain/models/fix.dart';

class FixesRepository with OutboxMixin<FixModel, FixCreateRequest> {
  late final sdk.FixesApi itemApi;

  FixesRepository({required sdk.MosquitoAlert apiClient}) {
    itemApi = apiClient.getFixesApi();
  }

  static const itemBoxName = 'offline_fixes';

  @override
  bool get requiresAuth => true;

  @override
  String get repoName => 'fixes';

  @override
  Box<FixModel> get itemBox => Hive.box<FixModel>(itemBoxName);

  @override
  FixModel buildItemFromCreateRequest(FixCreateRequest request) {
    return FixModel.fromCreateRequest(request);
  }

  @override
  FixCreateRequest createRequestFactory(Map<String, dynamic> payload) {
    return FixCreateRequest.fromJson(payload);
  }

  @override
  FixCreateRequest buildCreateRequestFromItem(FixModel item) {
    return FixCreateRequest.fromModel(item);
  }

  @override
  OutboxTask buildOutboxTaskFromItem({required OutboxItem item}) {
    return OutboxTask(
      item: item,
      action: () async {
        switch (item.operation) {
          case OutBoxOperation.create:
            final request = createRequestFactory(item.payload);
            try {
              final fixRequest = sdk.FixRequest(
                (f) => f
                  ..coverageUuid = request.coverageUuid
                  ..createdAt = request.createdAt.toUtc()
                  ..sentAt = DateTime.now().toUtc()
                  ..point = request.point.toBuilder()
                  ..power = request.power,
              );

              await itemApi.create(fixRequest: fixRequest);
            } on DioException catch (e) {
              if (e.response?.statusCode != null &&
                  e.response!.statusCode! < 500) {
                break;
              }
              rethrow;
            }
            break;
          default:
            throw Exception("Unknown op: ${item.operation}");
        }
      },
    );
  }

  Future<void> create({required FixCreateRequest request}) async {
    final createTask = buildOutboxTaskFromItem(
      item: OutboxItem(
        id: request.localId,
        repository: repoName,
        operation: OutBoxOperation.create,
        payload: request.toJson(),
      ),
    );
    await schedule(createTask);
  }
}
