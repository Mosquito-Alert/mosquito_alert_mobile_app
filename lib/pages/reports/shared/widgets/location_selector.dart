import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mosquito_alert/mosquito_alert.dart';
import 'package:mosquito_alert_app/utils/style.dart';

class LocationSelector extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final Function(double latitude, double longitude,
      LocationRequestSource_Enum source) onLocationSelected;

  const LocationSelector({
    Key? key,
    this.initialLatitude,
    this.initialLongitude,
    required this.onLocationSelected,
  }) : super(key: key);

  @override
  _LocationSelectorState createState() => _LocationSelectorState();
}

class _LocationSelectorState extends State<LocationSelector> {
  GoogleMapController? _mapController;
  bool _isGettingLocation = false;
  String? _locationError;
  final _latController = TextEditingController();
  final _lonController = TextEditingController();
  Set<Marker> _markers = {};

  // Default center (can be customized based on app needs)
  static const LatLng _defaultCenter = LatLng(41.3874, 2.1686); // Barcelona

  @override
  void initState() {
    super.initState();
    _updateMapMarkers();
  }

  void _updateMapMarkers() {
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      setState(() {
        _latController.text = widget.initialLatitude!.toStringAsFixed(6);
        _lonController.text = widget.initialLongitude!.toStringAsFixed(6);
        _markers = {
          Marker(
            markerId: MarkerId('selected_location'),
            position: LatLng(widget.initialLatitude!, widget.initialLongitude!),
            infoWindow: InfoWindow(title: '(HC) Selected Location'),
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
      _latController.text = position.latitude.toStringAsFixed(6);
      _lonController.text = position.longitude.toStringAsFixed(6);

      _markers = {
        Marker(
          markerId: MarkerId('selected_location'),
          position: position,
          infoWindow: InfoWindow(title: '(HC) Selected Location'),
        ),
      };
    });

    // Notify parent of location selection
    widget.onLocationSelected(
      position.latitude,
      position.longitude,
      LocationRequestSource_Enum.manual,
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
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
        _latController.text = position.latitude.toStringAsFixed(6);
        _lonController.text = position.longitude.toStringAsFixed(6);
        _markers = {
          Marker(
            markerId: MarkerId('selected_location'),
            position: LatLng(position.latitude, position.longitude),
            infoWindow: InfoWindow(title: '(HC) Current Location'),
          ),
        };
      });

      // Notify parent of location selection
      widget.onLocationSelected(
        position.latitude,
        position.longitude,
        LocationRequestSource_Enum.auto,
      );

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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // GPS Location Button
        SizedBox(
          width: double.infinity,
          child: _isGettingLocation
              ? Style.button(
                  '(HC) Getting location...',
                  null,
                )
              : Style.button(
                  '(HC) Use Current GPS Location',
                  _getCurrentLocation,
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
                target: widget.initialLatitude != null &&
                        widget.initialLongitude != null
                    ? LatLng(widget.initialLatitude!, widget.initialLongitude!)
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
      ],
    );
  }

  @override
  void dispose() {
    _latController.dispose();
    _lonController.dispose();
    super.dispose();
  }
}
