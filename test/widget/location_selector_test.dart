import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mosquito_alert_app/pages/reports/shared/widgets/location_selector.dart';

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
  });
}
