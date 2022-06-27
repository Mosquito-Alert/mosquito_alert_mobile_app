import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mosquito_alert_app/models/report.dart';

class AggregatedPoints {
  final Report report;
  final int index;
  final LatLng location;
  final int count;
  String bitmabAssetName;

  AggregatedPoints(this.report, this.index, this.location, this.count) {
    bitmabAssetName = getBitmapDescriptor();
  }

  String getBitmapDescriptor() {
    String bitmapDescriptor;
    if (count < 10) {
      // + 2
      bitmapDescriptor = 'assets/img/maps/m1.png';
    } else if (count < 25) {
      // + 10
      bitmapDescriptor = 'assets/img/maps/m2.png';
    } else if (count < 50) {
      // + 25
      bitmapDescriptor = 'assets/img/maps/m3.png';
    } else if (count < 100) {
      // + 50
      bitmapDescriptor = 'assets/img/maps/m4.png';
    } else if (count < 500) {
      // + 100
      bitmapDescriptor = 'assets/img/maps/m5.png';
    } else if (count < 1000) {
      // +500
      bitmapDescriptor = 'assets/img/maps/m6.png';
    } else {
      // + 1k
      bitmapDescriptor = 'assets/img/maps/m7.png';
    }
    return bitmapDescriptor;
  }

  getId() {
    return location.latitude.toString() +
        '_' +
        location.longitude.toString() +
        '_$count';
  }
}
