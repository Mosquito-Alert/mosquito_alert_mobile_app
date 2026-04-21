import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';
import 'package:dio/dio.dart';
import 'package:hive_ce/hive.dart';
import 'package:mosquito_alert/mosquito_alert.dart';
import 'package:mosquito_alert_app/features/observations/data/models/observation_report_request.dart';
import 'package:mosquito_alert_app/features/observations/domain/models/observation_report.dart';
import 'package:mosquito_alert_app/features/reports/data/report_repository.dart';

class ObservationRepository
    extends
        ReportRepository<
          ObservationReport,
          Observation,
          ObservationsApi,
          ObservationCreateRequest
        > {
  ObservationRepository({required MosquitoAlert apiClient})
    : super(
        apiClient: apiClient,
        itemApi: apiClient.getObservationsApi(),
        itemFactory: (item) => ObservationReport.fromSdkObservation(item),
      );

  static const itemBoxName = 'offline_observations';

  @override
  String get repoName => 'observations';

  @override
  Box<ObservationReport> get itemBox =>
      Hive.box<ObservationReport>(itemBoxName);

  @override
  ObservationReport buildItemFromCreateRequest(
    ObservationCreateRequest request,
  ) {
    return ObservationReport.fromCreateRequest(request);
  }

  @override
  ObservationCreateRequest createRequestFactory(Map<String, dynamic> payload) {
    return ObservationCreateRequest.fromJson(payload);
  }

  @override
  ObservationCreateRequest buildCreateRequestFromItem(ObservationReport item) {
    return ObservationCreateRequest.fromModel(item);
  }

  Future<ObservationReport> sendCreateToApi({
    required ObservationCreateRequest request,
  }) async {
    final List<MultipartFile> photosMultipart = [];
    for (final photo in request.photos) {
      photosMultipart.add(await photo.toMultipartFile());
    }
    final photosRequest = BuiltList<MultipartFile>(photosMultipart);

    final event_environment_serializer =
        ObservationEventEnvironmentEnum.serializer
            as PrimitiveSerializer<ObservationEventEnvironmentEnum>;
    final event_moment_serializer =
        ObservationEventMomentEnum.serializer
            as PrimitiveSerializer<ObservationEventMomentEnum>;

    final response = await itemApi.create(
      createdAt: request.createdAt,
      sentAt: DateTime.now().toUtc(),
      location: request.location,
      photos: photosRequest,
      note: request.note,
      tags: request.tags != null ? BuiltList<String>(request.tags!) : null,
      eventEnvironment: request.eventEnvironment != null
          ? (event_environment_serializer.serialize(
                  serializers,
                  request.eventEnvironment!,
                  specifiedType: const FullType(
                    ObservationEventEnvironmentEnum,
                  ),
                )
                as String)
          : null,
      eventMoment: request.eventMoment != null
          ? (event_moment_serializer.serialize(
                  serializers,
                  request.eventMoment!,
                  specifiedType: const FullType(ObservationEventMomentEnum),
                )
                as String)
          : null,
    );
    return itemFactory(response.data!);
  }
}
