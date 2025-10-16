import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mosquito_alert_app/pages/reports/shared/widgets/location_selector.dart';

void main() {
  group('LocationSelector Widget Tests', () {
    testWidgets('should render location selector with map', (tester) async {
      bool locationSelected = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationSelector(
              autoGetLocation: false,
              onLocationSelected: (lat, lng, source) {
                locationSelected = true;
              },
            ),
          ),
        ),
      );

      expect(find.byType(GoogleMap), findsOneWidget);
      expect(find.byIcon(Icons.my_location), findsOneWidget);
      expect(find.byIcon(Icons.center_focus_strong), findsOneWidget);
      expect(locationSelected, false);
    });
  });
}
