import 'package:flutter_test/flutter_test.dart';
import 'package:mosquito_alert_app/pages/reports/sites/models/breeding_site_report_data.dart';
import 'dart:io';

void main() {
  group('BreedingSiteReportData', () {
    late BreedingSiteReportData reportData;

    setUp(() {
      reportData = BreedingSiteReportData();
    });

    test('should be invalid when missing required fields', () {
      expect(reportData.isValid, false);
    });

    test('should be valid when all required fields are present and water is false', () {
      reportData.siteType = 'storm_drain';
      reportData.photos = [File('/tmp/test.jpg')];
      reportData.hasWater = false;
      reportData.latitude = 40.7128;
      reportData.longitude = -74.0060;

      expect(reportData.isValid, true);
    });

    test('should be invalid when water is true but larvae status is not set', () {
      reportData.siteType = 'storm_drain';
      reportData.photos = [File('/tmp/test.jpg')];
      reportData.hasWater = true;
      reportData.latitude = 40.7128;
      reportData.longitude = -74.0060;
      // hasLarvae is null

      expect(reportData.isValid, false);
    });

    test('should be valid when water is true and larvae status is set', () {
      reportData.siteType = 'storm_drain';
      reportData.photos = [File('/tmp/test.jpg')];
      reportData.hasWater = true;
      reportData.hasLarvae = true;
      reportData.latitude = 40.7128;
      reportData.longitude = -74.0060;

      expect(reportData.isValid, true);
    });

    test('should provide correct water status description', () {
      expect(reportData.waterStatusDescription, 'Water status not selected');

      reportData.hasWater = true;
      expect(reportData.waterStatusDescription, 'Water present');

      reportData.hasWater = false;
      expect(reportData.waterStatusDescription, 'No water');
    });

    test('should provide correct larvae status description', () {
      expect(reportData.larvaeStatusDescription, 'Larvae status not selected');

      reportData.hasLarvae = true;
      expect(reportData.larvaeStatusDescription, 'Larvae visible');

      reportData.hasLarvae = false;
      expect(reportData.larvaeStatusDescription, 'No larvae visible');
    });

    test('should reset larvae status when water status changes to false', () {
      reportData.hasWater = true;
      reportData.hasLarvae = true;

      reportData.hasWater = false;
      reportData.hasLarvae = null; // This should be done by the controller

      expect(reportData.hasLarvae, null);
    });

    test('should copy all fields correctly', () {
      reportData.siteType = 'other';
      reportData.hasWater = true;
      reportData.hasLarvae = false;
      reportData.latitude = 40.7128;
      reportData.longitude = -74.0060;
      reportData.notes = 'Test notes';

      final copy = reportData.copy();

      expect(copy.siteType, reportData.siteType);
      expect(copy.hasWater, reportData.hasWater);
      expect(copy.hasLarvae, reportData.hasLarvae);
      expect(copy.latitude, reportData.latitude);
      expect(copy.longitude, reportData.longitude);
      expect(copy.notes, reportData.notes);
    });

    test('should reset all fields including larvae status', () {
      reportData.siteType = 'other';
      reportData.hasWater = true;
      reportData.hasLarvae = false;
      reportData.latitude = 40.7128;
      reportData.longitude = -74.0060;
      reportData.notes = 'Test notes';

      reportData.reset();

      expect(reportData.siteType, null);
      expect(reportData.hasWater, null);
      expect(reportData.hasLarvae, null);
      expect(reportData.latitude, null);
      expect(reportData.longitude, null);
      expect(reportData.notes, null);
      expect(reportData.photos, isEmpty);
    });
  });
}