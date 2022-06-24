import 'dart:math';
import 'package:geohash/geohash.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mosquito_alert_app/models/report.dart';

class ReportAndGeohash {
  final Report report;
  final LatLng location;
  final int index;

  String geohash;

  ReportAndGeohash(this.report, this.location, this.index) {
    geohash = Geohash.encode(location.latitude, location.longitude);
  }

  getId() {
    return location.latitude.toString() +
        "_" +
        location.longitude.toString() +
        "_${Random().nextInt(10000)}";
  }
}
