import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mosquito_alert/mosquito_alert.dart' as sdk;
import 'package:mosquito_alert_app/core/outbox/outbox_item.dart';
import 'package:mosquito_alert_app/core/outbox/outbox_service.dart';
import 'package:mosquito_alert_app/features/fixes/data/fixes_repository.dart';
import 'package:mosquito_alert_app/features/fixes/data/models/fix_request.dart';
import 'package:mosquito_alert_app/features/fixes/domain/models/fix.dart';
import 'package:mosquito_alert_app/hive/hive_adapters.dart';
import 'package:mosquito_alert_app/hive/hive_registrar.g.dart';

const _tolerance = 1e-9;

/// Stands in for the server: records the fixes it is sent, or refuses them
/// while [offline] is set.
class _RecordingFixesApi extends sdk.FixesApi {
  _RecordingFixesApi() : super(Dio(), sdk.serializers);

  final List<sdk.FixRequest> sent = [];
  bool offline = false;

  @override
  Future<Response<sdk.Fix>> create({
    required sdk.FixRequest fixRequest,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final options = RequestOptions(path: '/fixes/');
    if (offline) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'offline',
      );
    }
    sent.add(fixRequest);
    return Response<sdk.Fix>(requestOptions: options, statusCode: 201);
  }
}

class _FakeMosquitoAlert extends sdk.MosquitoAlert {
  _FakeMosquitoAlert(this.fixesApi);

  final _RecordingFixesApi fixesApi;

  @override
  sdk.FixesApi getFixesApi() => fixesApi;
}

FixCreateRequest _request(String localId, double latitude, double longitude) {
  return FixCreateRequest(
    localId: localId,
    coverageUuid: 'coverage-uuid',
    createdAt: DateTime.utc(2026, 11, 27, 12),
    point: sdk.FixLocationRequest(
      (p) => p
        ..latitude = latitude
        ..longitude = longitude,
    ),
    power: 0.5,
  );
}

void main() {
  // Positions as the phone reports them, with the south-west corner of their
  // cell. The first three are ones whose masked values a rounding-down without
  // a guard would move a further cell each time the fix is retried.
  const positions = <List<double>>[
    // latitude, longitude, masked latitude, masked longitude
    [35.03, 2.16, 35.025, 2.15],
    [35.41, 45.16, 35.4, 45.15],
    [51.52, -3.7038, 51.5, -3.725],
    [41.39, 2.17, 41.375, 2.15],
    [-34.6037, -58.3816, -34.625, -58.4],
  ];

  late Directory directory;
  late _RecordingFixesApi api;
  late FixesRepository repository;

  Box<FixModel> fixBox() => Hive.box<FixModel>(FixesRepository.itemBoxName);

  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('fixes_masking_test');
    Hive.init(directory.path);
    Hive
      ..registerAdapter(FixLocationAdapter())
      ..registerAdapters();
    await Hive.openBox<FixModel>(FixesRepository.itemBoxName);
    await OutboxService().init();
  });

  setUp(() async {
    await fixBox().clear();
    await Hive.box<OutboxItem>('outbox').clear();
    api = _RecordingFixesApi();
    repository = FixesRepository(apiClient: _FakeMosquitoAlert(api));
  });

  tearDownAll(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test('a fix sent straight away carries the south-west corner', () async {
    for (final (index, p) in positions.indexed) {
      await repository.create(request: _request('fix-$index', p[0], p[1]));
    }

    expect(api.sent, hasLength(positions.length));
    for (final (index, p) in positions.indexed) {
      final point = api.sent[index].point;
      expect(point.latitude, closeTo(p[2], _tolerance), reason: '$p');
      expect(point.longitude, closeTo(p[3], _tolerance), reason: '$p');
    }
    expect(fixBox().isEmpty, isTrue);
  });

  test('a fix kept while offline is stored masked, never as the '
      'position itself', () async {
    api.offline = true;
    for (final (index, p) in positions.indexed) {
      await repository.create(request: _request('fix-$index', p[0], p[1]));
    }

    expect(api.sent, isEmpty);
    expect(fixBox().length, positions.length);
    for (final (index, p) in positions.indexed) {
      final stored = fixBox().get('fix-$index')!;
      expect(stored.point.latitude, closeTo(p[2], _tolerance), reason: '$p');
      expect(stored.point.longitude, closeTo(p[3], _tolerance), reason: '$p');
    }
  });

  test('a fix retried several times, across a restart, still carries the '
      'south-west corner', () async {
    api.offline = true;
    for (final (index, p) in positions.indexed) {
      await repository.create(request: _request('fix-$index', p[0], p[1]));
    }
    // Each failed attempt rebuilds the request from the stored model and
    // masks it again.
    await repository.syncRepository();
    await repository.syncRepository();
    await repository.syncRepository();
    expect(api.sent, isEmpty);

    // Close and reopen the store, as when the app is started again.
    await fixBox().close();
    await Hive.openBox<FixModel>(FixesRepository.itemBoxName);
    expect(fixBox().length, positions.length);

    api.offline = false;
    await repository.syncRepository();

    expect(api.sent, hasLength(positions.length));
    for (final (index, p) in positions.indexed) {
      final point = api.sent
          .singleWhere(
            (fix) =>
                (fix.point.latitude - p[2]).abs() < 0.0125 &&
                (fix.point.longitude - p[3]).abs() < 0.0125,
            orElse: () => fail('no fix was sent for the cell of $p (#$index)'),
          )
          .point;
      expect(point.latitude, closeTo(p[2], _tolerance), reason: '$p');
      expect(point.longitude, closeTo(p[3], _tolerance), reason: '$p');
    }
    expect(fixBox().isEmpty, isTrue);
  });
}
