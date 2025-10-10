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
    return SafeArea(
      child: Column(
        children: [
          // Fixed header section
          Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 8),

                // Subtitle
                Text(
                  widget.subtitle,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Scrollable content area
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Column(
                    children: [
                      SizedBox(height: 16),

                      // Location selector - flexible height
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: LocationSelector(
                            initialLatitude: widget.initialLatitude,
                            initialLongitude: widget.initialLongitude,
                            onLocationSelected: widget.onLocationSelected,
                          ),
                        ),
                      ),

                      // Bottom section that can scroll if needed
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Current location info
                            if (widget.canProceed)
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  border: Border.all(color: Colors.green[200]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.location_on,
                                        color: Colors.green[700]),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '(HC) Location Selected',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              color: Colors.green[700],
                                            ),
                                          ),
                                          if (widget.locationDescription !=
                                              null)
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
                                                      LocationRequestSource_Enum
                                                          .auto
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

                            // Navigation buttons
                            Row(
                              children: [
                                Expanded(
                                  child: Style.outlinedButton(
                                    '(HC) Back',
                                    widget.onPrevious,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: Style.button(
                                    MyLocalizations.of(context, 'continue_txt'),
                                    widget.canProceed ? widget.onNext : null,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
