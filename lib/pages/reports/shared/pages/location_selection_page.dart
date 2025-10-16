import 'package:flutter/material.dart';
import 'package:mosquito_alert/mosquito_alert.dart';
import 'package:mosquito_alert_app/pages/reports/shared/widgets/location_selector.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';
import 'package:mosquito_alert_app/utils/style.dart';

/// Shared location selection page that can be used by any report workflow
/// Configurable title, subtitle, and location handling through callbacks
class LocationSelectionPage extends StatefulWidget {
  final String title;
  final String subtitle;
  final double? initialLatitude;
  final double? initialLongitude;
  final Function(
          double latitude, double longitude, LocationRequestSource_Enum source)
      onLocationSelected;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final bool canProceed;
  final String? locationDescription;
  final LocationRequestSource_Enum? locationSource;

  const LocationSelectionPage({
    Key? key,
    required this.title,
    required this.subtitle,
    this.initialLatitude,
    this.initialLongitude,
    required this.onLocationSelected,
    required this.onNext,
    required this.onPrevious,
    required this.canProceed,
    this.locationDescription,
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

          // Header overlay with title and subtitle
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                margin: EdgeInsets.all(16),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom overlay with location info and navigation
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                margin: EdgeInsets.all(16),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Current location info
                    if (widget.canProceed) ...[
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          border: Border.all(color: Colors.green[200]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.location_on, color: Colors.green[700]),
                            SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '(HC) Location Selected',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                  if (widget.locationDescription != null)
                                    Text(
                                      widget.locationDescription!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green[600],
                                      ),
                                    ),
                                  if (widget.locationSource != null)
                                    Text(
                                      widget.locationSource ==
                                              LocationRequestSource_Enum.auto
                                          ? '(HC) GPS Location'
                                          : '(HC) Manual Selection',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green[600],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                    ] else ...[
                      // Instruction text when no location selected
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          border: Border.all(color: Colors.blue[200]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue[700]),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '(HC) Tap on the map to select a location or use the location button',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                    ],

                    // Navigation button
                    SizedBox(
                      width: double.infinity,
                      child: Style.button(
                        MyLocalizations.of(context, 'continue_txt'),
                        widget.canProceed ? widget.onNext : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
