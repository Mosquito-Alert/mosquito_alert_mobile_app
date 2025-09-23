import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mosquito_alert/mosquito_alert.dart' as api;
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';

import '../models/adult_report_data.dart';

class LocationSelectionPage extends StatefulWidget {
  final AdultReportData reportData;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const LocationSelectionPage({
    Key? key,
    required this.reportData,
    required this.onNext,
    required this.onPrevious,
  }) : super(key: key);

  @override
  _LocationSelectionPageState createState() => _LocationSelectionPageState();
}

class _LocationSelectionPageState extends State<LocationSelectionPage> {
  bool _isGettingLocation = false;
  String? _locationError;
  final _latController = TextEditingController();
  final _lonController = TextEditingController();
  Set<Marker> _markers = {};
  GoogleMapController? _mapController;

  static const LatLng _defaultCenter =
      LatLng(41.3851, 2.1734); // Default: Barcelona

  @override
  void initState() {
    super.initState();
    // Pre-fill if location already exists
    if (widget.reportData.latitude != null) {
      _latController.text = widget.reportData.latitude!.toStringAsFixed(6);
    }
    if (widget.reportData.longitude != null) {
      _lonController.text = widget.reportData.longitude!.toStringAsFixed(6);
    }
    _updateMapMarkers();
  }

  void _updateMapMarkers() {
    if (widget.reportData.latitude != null &&
        widget.reportData.longitude != null) {
      setState(() {
        _markers = {
          Marker(
            markerId: MarkerId('selected_location'),
            position: LatLng(
                widget.reportData.latitude!, widget.reportData.longitude!),
            infoWindow: InfoWindow(title: 'Selected Location'),
          ),
        };
      });
    }
  }

  Future<void> _moveMapToLocation(double latitude, double longitude) async {
    if (_mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(latitude, longitude),
            zoom: 16.0,
          ),
        ),
      );
    }
  }

  void _onMapTap(LatLng position) {
    setState(() {
      widget.reportData.latitude = position.latitude;
      widget.reportData.longitude = position.longitude;
      widget.reportData.locationSource = api.LocationRequestSource_Enum.manual;
      _latController.text = position.latitude.toStringAsFixed(6);
      _lonController.text = position.longitude.toStringAsFixed(6);

      _markers = {
        Marker(
          markerId: MarkerId('selected_location'),
          position: position,
          infoWindow: InfoWindow(title: 'Selected Location'),
        ),
      };
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  @override
  void dispose() {
    _latController.dispose();
    _lonController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
      _locationError = null;
    });

    try {
      // Check location services
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permission permanently denied');
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 30),
      );

      setState(() {
        widget.reportData.latitude = position.latitude;
        widget.reportData.longitude = position.longitude;
        widget.reportData.locationSource = api.LocationRequestSource_Enum.auto;
        _latController.text = position.latitude.toStringAsFixed(6);
        _lonController.text = position.longitude.toStringAsFixed(6);
      });
      _updateMapMarkers();
      // Move map to the GPS location
      await _moveMapToLocation(position.latitude, position.longitude);
    } catch (e) {
      setState(() {
        _locationError = e.toString();
      });
    } finally {
      setState(() {
        _isGettingLocation = false;
      });
    }
  }

  bool get _canProceed =>
      widget.reportData.latitude != null && widget.reportData.longitude != null;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // GPS Location Button
          SizedBox(
            width: double.infinity,
            child: _isGettingLocation
                ? ElevatedButton(
                    onPressed: null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      disabledBackgroundColor: Colors.grey[400],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text('(HC) Getting location...'),
                      ],
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: _getCurrentLocation,
                    icon: Icon(Icons.gps_fixed),
                    label: Text('(HC) Use Current GPS Location'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
          ),

          SizedBox(height: 16),

          // Map for manual selection
          Text(
            '(HC) Or tap on the map to select location manually:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),

          // Embedded Google Map
          Container(
            height: 300,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: GoogleMap(
                onMapCreated: _onMapCreated,
                onTap: _onMapTap,
                initialCameraPosition: CameraPosition(
                  target: widget.reportData.latitude != null &&
                          widget.reportData.longitude != null
                      ? LatLng(widget.reportData.latitude!,
                          widget.reportData.longitude!)
                      : _defaultCenter,
                  zoom: 15,
                ),
                markers: _markers,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: true,
                mapToolbarEnabled: false,
              ),
            ),
          ),

          if (_locationError != null) ...[
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                border: Border.all(color: Colors.red[200]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _locationError!,
                      style: TextStyle(color: Colors.red[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],

          Spacer(),

          // Navigation buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onPrevious,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).primaryColor,
                    side: BorderSide(color: Theme.of(context).primaryColor),
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text('(HC) Back'),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _canProceed ? widget.onNext : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    disabledBackgroundColor: Colors.grey[300],
                  ),
                  child: Text(
                    MyLocalizations.of(context, 'continue_txt'),
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
