import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mosquito_alert_app/core/outbox/outbox_sync_error.dart';
import 'package:mosquito_alert_app/features/reports/data/report_repository.dart';

void main() {
  group('isPermanentHttpStatus', () {
    test('null status is not permanent (treat as retryable/network)', () {
      expect(isPermanentHttpStatus(null), isFalse);
    });

    test('2xx / 3xx are not permanent', () {
      expect(isPermanentHttpStatus(200), isFalse);
      expect(isPermanentHttpStatus(301), isFalse);
    });

    test('standard 4xx errors are permanent', () {
      expect(isPermanentHttpStatus(400), isTrue);
      expect(isPermanentHttpStatus(401), isTrue);
      expect(isPermanentHttpStatus(403), isTrue);
      expect(isPermanentHttpStatus(404), isTrue);
      expect(isPermanentHttpStatus(422), isTrue);
    });

    test('408 Request Timeout and 429 Too Many Requests are retryable', () {
      expect(isPermanentHttpStatus(408), isFalse);
      expect(isPermanentHttpStatus(429), isFalse);
    });

    test('5xx errors are not permanent', () {
      expect(isPermanentHttpStatus(500), isFalse);
      expect(isPermanentHttpStatus(502), isFalse);
      expect(isPermanentHttpStatus(503), isFalse);
    });
  });

  group('OutboxErrorStore', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('outbox_err_test');
      Hive.init(tempDir.path);
      await OutboxErrorStore.init();
      // Ensure a clean slate between tests.
      await Hive.box<String>(OutboxErrorStore.boxName).clear();
    });

    tearDown(() async {
      await Hive.close();
      await tempDir.delete(recursive: true);
    });

    test('hasError is false for unknown localId', () {
      expect(OutboxErrorStore().hasError('nope'), isFalse);
      expect(OutboxErrorStore().get('nope'), isNull);
    });

    test('put then get returns the stored message', () async {
      await OutboxErrorStore().put('abc', 'HTTP 422: bad data');
      expect(OutboxErrorStore().hasError('abc'), isTrue);
      expect(OutboxErrorStore().get('abc'), 'HTTP 422: bad data');
    });

    test('put overwrites an existing message for the same localId', () async {
      await OutboxErrorStore().put('abc', 'first');
      await OutboxErrorStore().put('abc', 'second');
      expect(OutboxErrorStore().get('abc'), 'second');
    });

    test('remove clears the stored error', () async {
      await OutboxErrorStore().put('abc', 'boom');
      await OutboxErrorStore().remove('abc');
      expect(OutboxErrorStore().hasError('abc'), isFalse);
      expect(OutboxErrorStore().get('abc'), isNull);
    });

    test('entries persist across reopening the box', () async {
      await OutboxErrorStore().put('abc', 'persisted');
      await Hive.close();
      Hive.init(tempDir.path);
      await OutboxErrorStore.init();
      expect(OutboxErrorStore().get('abc'), 'persisted');
    });
  });

  group('PermanentOutboxException', () {
    test('toString includes status code and message', () {
      final e = PermanentOutboxException('bad data', statusCode: 422);
      expect(e.toString(), contains('422'));
      expect(e.toString(), contains('bad data'));
    });

    test('toString works without a status code', () {
      final e = PermanentOutboxException('boom');
      expect(e.toString(), contains('boom'));
    });
  });
}
