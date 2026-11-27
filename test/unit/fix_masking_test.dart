import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mosquito_alert/mosquito_alert.dart' as sdk;
import 'package:mosquito_alert_app/features/fixes/data/models/fix_request.dart';
import 'package:mosquito_alert_app/features/fixes/domain/fix_masking.dart';
import 'package:mosquito_alert_app/features/fixes/domain/models/fix.dart';

/// Tolerance when comparing a masked coordinate with its decimal value. A
/// multiple of 0.025 is not exact in floating point: 45.15 comes out as
/// 45.150000000000006.
const _tolerance = 1e-9;

/// Rounding down without the guard, to show what the guard is for.
double _plainFloor(double value) => (value / 0.025).floor() * 0.025;

/// Floor division on integers, also for negative numbers.
int _floorDiv(int a, int b) {
  final quotient = a ~/ b;
  return (a % b != 0 && a < 0) ? quotient - 1 : quotient;
}

FixCreateRequest _request(double latitude, double longitude) {
  return FixCreateRequest(
    localId: 'local-id',
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
  group('maskCoordinate', () {
    // From issue #801: a position, and the south-west corner of its cell.
    const vectors = <List<double>>[
      // latitude, longitude, masked latitude, masked longitude
      [41.39, 2.17, 41.375, 2.15],
      [41.38, 2.155, 41.375, 2.15],
      [40.4168, -3.7038, 40.4, -3.725],
      [-34.6037, -58.3816, -34.625, -58.4],
      [-0.001, -0.001, -0.025, -0.025],
      [0.001, 0.001, 0, 0],
      [41.4, 2.175, 41.4, 2.175],
    ];

    test('rounds down to the south-west corner of the 0.025 degree cell', () {
      for (final v in vectors) {
        expect(maskCoordinate(v[0]), closeTo(v[2], _tolerance), reason: '$v');
        expect(maskCoordinate(v[1]), closeTo(v[3], _tolerance), reason: '$v');
      }
    });

    test('rounds towards minus infinity, not towards zero', () {
      // West of Greenwich and south of the equator the south-west corner is
      // the more negative grid value.
      expect(maskCoordinate(-3.7038), closeTo(-3.725, _tolerance));
      expect(maskCoordinate(-58.3816), closeTo(-58.4, _tolerance));
      expect(maskCoordinate(-0.001), closeTo(-0.025, _tolerance));
    });

    test('does not round to the nearest grid point', () {
      // 41.39 is nearer to 41.4 than to 41.375. Versions 4.3.0 to 4.4.0 sent
      // 41.4, which is the cell to the north.
      expect(maskCoordinate(41.39), closeTo(41.375, _tolerance));
      expect(maskCoordinate(2.17), closeTo(2.15, _tolerance));
    });

    test('leaves a value that is on the grid where it is', () {
      expect(maskCoordinate(41.4), closeTo(41.4, _tolerance));
      expect(maskCoordinate(2.175), closeTo(2.175, _tolerance));
      expect(maskCoordinate(0), 0);
      expect(maskCoordinate(-0.025), closeTo(-0.025, _tolerance));
    });

    test('masking again, and a third time, changes nothing', () {
      // From issue #801: a position, and its masked value.
      const repeated = <List<double>>[
        [2.16, 2.15],
        [35.03, 35.025],
        [35.41, 35.4],
        [45.16, 45.15],
        [51.52, 51.5],
        [-3.7038, -3.725],
        [-58.3816, -58.4],
      ];
      for (final v in repeated) {
        final once = maskCoordinate(v[0]);
        final twice = maskCoordinate(once);
        final thrice = maskCoordinate(twice);
        expect(once, closeTo(v[1], _tolerance), reason: '${v[0]}');
        expect(twice, once, reason: '${v[0]} masked twice');
        expect(thrice, once, reason: '${v[0]} masked three times');
      }
    });

    test('a plain floor would drift a cell on the second pass', () {
      // This is why maskCoordinate has a guard. If this ever stops failing
      // for a plain floor, the guard is still harmless.
      for (final v in [2.16, 35.03, 35.41]) {
        final once = _plainFloor(v);
        final twice = _plainFloor(once);
        expect(twice, closeTo(once - 0.025, _tolerance), reason: '$v');
        expect(maskCoordinate(maskCoordinate(v)), maskCoordinate(v));
      }
    });

    test('every grid value from -180 to 180 survives repeated masking', () {
      for (var k = -7200; k <= 7200; k++) {
        // The same grid value as the app computes it and as it is written in
        // decimal (the two can differ in the last bit).
        final computed = k * 0.025;
        final decimal = double.parse((k * 25 / 1000).toStringAsFixed(3));
        for (final value in [computed, decimal]) {
          final once = maskCoordinate(value);
          expect(once, closeTo(computed, _tolerance), reason: 'k=$k');
          expect(maskCoordinate(once), once, reason: 'k=$k, second pass');
          expect(
            maskCoordinate(maskCoordinate(once)),
            once,
            reason: 'k=$k, third pass',
          );
        }
      }
    });

    test('agrees with exact arithmetic for positions at 1e-7 degrees', () {
      // Positions as whole numbers of 1e-7 degrees (about a centimetre), so
      // that the expected cell can be worked out without floating point.
      const unitsPerDegree = 10000000;
      const unitsPerCell = 250000; // 0.025 degrees

      void check(int units) {
        final cell = _floorDiv(units, unitsPerCell);
        expect(
          maskCoordinate(units / unitsPerDegree),
          closeTo(cell * 0.025, _tolerance),
          reason: 'position ${units / unitsPerDegree}',
        );
      }

      // On every grid line, and one step on either side of it.
      for (var k = -7200; k <= 7200; k++) {
        check(k * unitsPerCell - 1);
        check(k * unitsPerCell);
        check(k * unitsPerCell + 1);
      }

      // Positions spread over the whole range of longitudes.
      final random = Random(801);
      for (var i = 0; i < 200000; i++) {
        check(random.nextInt(360 * unitsPerDegree) - 180 * unitsPerDegree);
      }
    });
  });

  group('FixCreateRequest', () {
    test('masks the position it is given', () {
      final request = _request(41.39, 2.17);
      expect(request.point.latitude, closeTo(41.375, _tolerance));
      expect(request.point.longitude, closeTo(2.15, _tolerance));
    });

    test('masks towards the south-west in every hemisphere', () {
      final south = _request(-34.6037, -58.3816);
      expect(south.point.latitude, closeTo(-34.625, _tolerance));
      expect(south.point.longitude, closeTo(-58.4, _tolerance));

      final west = _request(40.4168, -3.7038);
      expect(west.point.latitude, closeTo(40.4, _tolerance));
      expect(west.point.longitude, closeTo(-3.725, _tolerance));
    });

    // Positions whose masked values a plain floor would move on a second
    // pass, with the south-west corner of their cell.
    const fragile = <List<double>>[
      [35.03, 2.16, 35.025, 2.15],
      [35.41, 45.16, 35.4, 45.15],
      [51.52, -3.7038, 51.5, -3.725],
      [-34.6037, -58.3816, -34.625, -58.4],
    ];

    test('keeps its point when rebuilt from the outbox payload', () {
      for (final v in fragile) {
        final request = _request(v[0], v[1]);
        var rebuilt = request;
        for (var pass = 0; pass < 5; pass++) {
          final payload =
              jsonDecode(jsonEncode(rebuilt.toJson())) as Map<String, dynamic>;
          rebuilt = FixCreateRequest.fromJson(payload);
          expect(rebuilt.point, request.point, reason: '$v, pass $pass');
        }
        expect(rebuilt.point.latitude, closeTo(v[2], _tolerance));
        expect(rebuilt.point.longitude, closeTo(v[3], _tolerance));
      }
    });

    test('keeps its point when rebuilt from a stored model', () {
      for (final v in fragile) {
        final request = _request(v[0], v[1]);
        var rebuilt = request;
        for (var pass = 0; pass < 5; pass++) {
          final model = FixModel.fromCreateRequest(rebuilt);
          expect(model.point.latitude, request.point.latitude);
          expect(model.point.longitude, request.point.longitude);
          rebuilt = FixCreateRequest.fromModel(model);
          expect(rebuilt.point, request.point, reason: '$v, pass $pass');
        }
        expect(rebuilt.point.latitude, closeTo(v[2], _tolerance));
        expect(rebuilt.point.longitude, closeTo(v[3], _tolerance));
      }
    });
  });
}
