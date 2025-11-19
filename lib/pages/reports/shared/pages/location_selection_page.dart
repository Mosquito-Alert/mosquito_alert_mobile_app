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
  final LocationRequestSource_Enum? initialSource;
  final Function(
          double latitude, double longitude, LocationRequestSource_Enum source)
      onNext;

  const LocationSelectionPage({
    Key? key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialSource,
    required this.onNext,
  }) : super(key: key);

  @override
  _LocationSelectionPageState createState() => _LocationSelectionPageState();
}

class _LocationSelectionPageState extends State<LocationSelectionPage> {
  late double? _latitude;
  late double? _longitude;
  late LocationRequestSource_Enum? _source;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _latitude = widget.initialLatitude;
    _longitude = widget.initialLongitude;
    _source = widget.initialSource;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Full-screen map background
          LocationSelector(
            initialLatitude: widget.initialLatitude,
            initialLongitude: widget.initialLongitude,
            onLocationChanged: (latitude, longitude, source) {
              setState(() {
                _latitude = latitude;
                _longitude = longitude;
                _source = source;
              });
            },
            onLoadingChanged: (isLoading) {
              setState(() {
                _isLoading = isLoading;
              });
            },
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
                    _isLoading ||
                            (_latitude == null ||
                                _longitude == null ||
                                _source == null)
                        ? null
                        : () {
                            widget.onNext(_latitude!, _longitude!, _source!);
                          },
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
