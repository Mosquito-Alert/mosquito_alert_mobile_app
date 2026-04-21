import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mosquito_alert_app/features/reports/domain/models/base_report.dart';

class ReportMap<TReport extends BaseReportModel> extends StatelessWidget {
  final TReport report;
  final LatLng location;

  ReportMap({super.key, required this.report})
    : location = LatLng(
        report.location.point.latitude,
        report.location.point.longitude,
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
      child: GestureDetector(
        onVerticalDragUpdate: (_) {}, // Absorb vertical drag to prevent scroll
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: GoogleMap(
            initialCameraPosition: CameraPosition(target: location, zoom: 9),
            markers: {
              Marker(
                markerId: const MarkerId('report_location'),
                position: location,
              ),
            },
            gestureRecognizers: {
              Factory<OneSequenceGestureRecognizer>(
                () => EagerGestureRecognizer(),
              ),
            },
            zoomControlsEnabled: false,
            zoomGesturesEnabled: true,
            scrollGesturesEnabled: true,
            rotateGesturesEnabled: true,
          ),
        ),
      ),
    );
  }
}
