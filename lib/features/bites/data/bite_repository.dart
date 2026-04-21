import 'package:built_collection/built_collection.dart';
import 'package:hive_ce/hive.dart';
import 'package:mosquito_alert/mosquito_alert.dart';
import 'package:mosquito_alert_app/features/bites/data/models/bite_report_request.dart';
import 'package:mosquito_alert_app/features/bites/domain/models/bite_report.dart';
import 'package:mosquito_alert_app/features/reports/data/report_repository.dart';

class BiteRepository
    extends ReportRepository<BiteReport, Bite, BitesApi, BiteCreateRequest> {
  BiteRepository({required MosquitoAlert apiClient})
    : super(
        apiClient: apiClient,
        itemApi: apiClient.getBitesApi(),
        itemFactory: (item) => BiteReport.fromSdkBite(item),
      );

  static const itemBoxName = 'offline_bites';

  @override
  String get repoName => 'bites';

  @override
  Box<BiteReport> get itemBox => Hive.box<BiteReport>(itemBoxName);

  @override
  BiteReport buildItemFromCreateRequest(BiteCreateRequest request) {
    return BiteReport.fromCreateRequest(request);
  }

  @override
  BiteCreateRequest createRequestFactory(Map<String, dynamic> payload) {
    return BiteCreateRequest.fromJson(payload);
  }

  @override
  BiteCreateRequest buildCreateRequestFromItem(BiteReport item) {
    return BiteCreateRequest.fromModel(item);
  }

  @override
  Future<BiteReport> sendCreateToApi({
    required BiteCreateRequest request,
  }) async {
    final biteRequest = BiteRequest(
      (b) => b
        ..createdAt = request.createdAt
        ..sentAt = DateTime.now().toUtc()
        ..location = request.location.toBuilder()
        ..note = request.note
        ..tags = request.tags != null
            ? BuiltList<String>(request.tags!).toBuilder()
            : null
        ..eventEnvironment = request.eventEnvironment
        ..eventMoment = request.eventMoment
        ..counts = request.counts.toBuilder(),
    );

    final response = await itemApi.create(biteRequest: biteRequest);
    return itemFactory(response.data!);
  }
}
