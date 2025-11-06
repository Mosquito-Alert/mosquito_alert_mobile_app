import 'package:flutter/material.dart';
import 'package:mosquito_alert/mosquito_alert.dart';
import 'package:mosquito_alert_app/pages/reports/shared/widgets/location_selector.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';
import 'package:mosquito_alert_app/utils/style.dart';

/// Shared location selection page that can be used by any report workflow
/// Configurable location handling through callbacks
class LocationSelectionPage extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final Function(
          double latitude, double longitude, LocationRequestSource_Enum source)
      onLocationSelected;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final bool canProceed;
  final LocationRequestSource_Enum? locationSource;

  const LocationSelectionPage({
    Key? key,
    this.initialLatitude,
    this.initialLongitude,
    required this.onLocationSelected,
    required this.onNext,
    required this.onPrevious,
    required this.canProceed,
    this.locationSource,
  }) : super(key: key);

  @override
  _LocationSelectionPageState createState() => _LocationSelectionPageState();
}

class _LocationSelectionPageState extends State<LocationSelectionPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Full-screen map background (WhatsApp style)
          LocationSelector(
            initialLatitude: widget.initialLatitude,
            initialLongitude: widget.initialLongitude,
            onLocationSelected: widget.onLocationSelected,
            autoGetLocation: true, // Enable auto-location by default
          ),

          // Bottom overlay with location info and navigation
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: Style.button(
                    MyLocalizations.of(context, 'continue_txt'),
                    widget.canProceed ? widget.onNext : null,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
