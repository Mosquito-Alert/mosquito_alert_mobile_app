import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mosquito_alert_app/features/reports/presentation/widgets/location_selector.dart';

import '../mocks/mocks.dart';

void main() {
  group('LocationSelector Widget Tests', () {
    testWidgets('should render location selector with map', (tester) async {
      bool locationSelected = false;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [MockMyLocalizationsDelegate()],
          supportedLocales: const [Locale('en')],
          home: Scaffold(
            body: LocationSelector(
              onLocationChanged: (lat, lng, source) {
                locationSelected = true;
              },
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(GoogleMap), findsOneWidget);
      final myLocationButton = find.byKey(Key("myLocationButton"));
      expect(myLocationButton, findsOneWidget);
      expect(locationSelected, false);
    });

    // Geolocator has no platform implementation in widget tests, so the
    // automatic fetch fails here -- the same path as a phone without location
    // permission, with location services off, or with no fix in time (#790).
    Widget selector({
      double? lat,
      double? lng,
      required void Function(double?, double?, Object?) onChanged,
    }) => MaterialApp(
      localizationsDelegates: const [MockMyLocalizationsDelegate()],
      supportedLocales: const [Locale('en')],
      home: Scaffold(
        body: LocationSelector(
          initialLatitude: lat,
          initialLongitude: lng,
          onLocationChanged: onChanged,
        ),
      ),
    );

    testWidgets('never reports a location when no GPS fix is available', (
      tester,
    ) async {
      final reported = <List<Object?>>[];
      await tester.pumpWidget(
        selector(onChanged: (lat, lng, src) => reported.add([lat, lng, src])),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      final map = tester.widget<GoogleMap>(find.byType(GoogleMap));
      map.onMapCreated!(_FakeMapController());
      await tester.pump();

      expect(reported.where((r) => r[0] != null || r[1] != null), isEmpty);
    });

    testWidgets('starts zoomed out when there is no fix', (tester) async {
      await tester.pumpWidget(selector(onChanged: (_, _, _) {}));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      final map = tester.widget<GoogleMap>(find.byType(GoogleMap));
      expect(map.initialCameraPosition.zoom, lessThan(5));
    });

    testWidgets('keeps the close zoom when re-entering with a location', (
      tester,
    ) async {
      await tester.pumpWidget(
        selector(lat: 41.38, lng: 2.17, onChanged: (_, _, _) {}),
      );
      await tester.pump();

      final map = tester.widget<GoogleMap>(find.byType(GoogleMap));
      expect(map.initialCameraPosition.target, const LatLng(41.38, 2.17));
      expect(map.initialCameraPosition.zoom, 15);
    });
  });
}

class _FakeMapController implements GoogleMapController {
  @override
  void dispose() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
