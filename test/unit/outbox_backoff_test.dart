import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mosquito_alert_app/core/outbox/outbox_backoff.dart';

void main() {
  group('computeBackoff', () {
    // Use a seeded Random so tests are deterministic.
    Random seeded() => Random(42);

    test('attempt 1 is approximately base ± jitter', () {
      final d = computeBackoff(
        attempt: 1,
        base: const Duration(seconds: 30),
        cap: const Duration(hours: 1),
        jitterFraction: 0.2,
        random: seeded(),
      );
      expect(d.inMilliseconds, greaterThanOrEqualTo(30 * 1000));
      // 30s + 20% jitter upper bound = 36s
      expect(d.inMilliseconds, lessThanOrEqualTo(36 * 1000));
    });

    test('grows exponentially up to the cap', () {
      const base = Duration(seconds: 30);
      const cap = Duration(hours: 1);
      Duration call(int attempt) => computeBackoff(
        attempt: attempt,
        base: base,
        cap: cap,
        jitterFraction: 0.0, // disable jitter for deterministic check
      );
      expect(call(1), const Duration(seconds: 30));
      expect(call(2), const Duration(seconds: 60));
      expect(call(3), const Duration(seconds: 120));
      expect(call(4), const Duration(seconds: 240));
      // attempt 8 → 30 * 128 = 3840s = ~64 min, capped at 1h
      expect(call(8), cap);
      expect(call(20), cap);
      expect(call(1000), cap);
    });

    test('never returns less than base', () {
      // Even with worst-case negative jitter, the result is clamped to base.
      for (var attempt = 1; attempt <= 10; attempt++) {
        final d = computeBackoff(
          attempt: attempt,
          base: const Duration(seconds: 30),
          cap: const Duration(hours: 1),
          jitterFraction: 0.99,
          random: Random(attempt),
        );
        expect(
          d.inMilliseconds,
          greaterThanOrEqualTo(30 * 1000),
          reason: 'attempt $attempt produced $d (< base)',
        );
      }
    });
  });

  group('OutboxBackoffStore', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('outbox_backoff_test');
      Hive.init(tempDir.path);
      await OutboxBackoffStore.init();
      await Hive.box<int>(OutboxBackoffStore.boxName).clear();
    });

    tearDown(() async {
      await Hive.close();
      await tempDir.delete(recursive: true);
    });

    test('isBackedOff is false for unknown id', () {
      expect(OutboxBackoffStore().isBackedOff('nope'), isFalse);
      expect(OutboxBackoffStore().nextAttemptAt('nope'), isNull);
      expect(OutboxBackoffStore().attemptCount('nope'), 0);
    });

    test('recordFailure schedules a future attempt and bumps counter', () {
      final now = DateTime(2026, 1, 1, 12, 0, 0);
      final next = OutboxBackoffStore().recordFailure(
        'abc',
        now: now,
        random: Random(0),
      );
      expect(next.isAfter(now), isTrue);
      expect(OutboxBackoffStore().isBackedOff('abc', now: now), isTrue);
      expect(OutboxBackoffStore().attemptCount('abc'), 1);
    });

    test('isBackedOff returns false once the window has elapsed', () {
      final now = DateTime(2026, 1, 1, 12, 0, 0);
      OutboxBackoffStore().recordFailure(
        'abc',
        now: now,
        random: Random(0),
      );
      final later = now.add(const Duration(hours: 2));
      expect(OutboxBackoffStore().isBackedOff('abc', now: later), isFalse);
    });

    test('attemptCount accumulates across recordFailure calls', () {
      final now = DateTime(2026, 1, 1, 12, 0, 0);
      for (var i = 0; i < 4; i++) {
        OutboxBackoffStore().recordFailure(
          'abc',
          now: now,
          random: Random(i),
        );
      }
      expect(OutboxBackoffStore().attemptCount('abc'), 4);
    });

    test('clear resets both timestamp and counter', () async {
      final now = DateTime(2026, 1, 1, 12, 0, 0);
      OutboxBackoffStore().recordFailure(
        'abc',
        now: now,
        random: Random(0),
      );
      await OutboxBackoffStore().clear('abc');
      expect(OutboxBackoffStore().isBackedOff('abc'), isFalse);
      expect(OutboxBackoffStore().nextAttemptAt('abc'), isNull);
      expect(OutboxBackoffStore().attemptCount('abc'), 0);
    });

    test('entries persist across reopening the box', () async {
      final now = DateTime(2026, 1, 1, 12, 0, 0);
      OutboxBackoffStore().recordFailure(
        'abc',
        now: now,
        random: Random(0),
      );
      await Hive.close();
      Hive.init(tempDir.path);
      await OutboxBackoffStore.init();
      expect(OutboxBackoffStore().isBackedOff('abc', now: now), isTrue);
      expect(OutboxBackoffStore().attemptCount('abc'), 1);
    });
  });
}
