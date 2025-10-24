import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mosquito_alert/mosquito_alert.dart';

class LocationSelector extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final Function(
          double latitude, double longitude, LocationRequestSource_Enum source)
      onLocationSelected;
  final bool autoGetLocation;

  const LocationSelector({
    Key? key,
    this.initialLatitude,
    this.initialLongitude,
    required this.onLocationSelected,
    this.autoGetLocation = true,
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
  LatLng? _currentMapCenter;

  @override
  void initState() {
    super.initState();
    _initializeMapCenter();
    _updateMapMarkers();

    if (widget.autoGetLocation &&
        widget.initialLatitude == null &&
        widget.initialLongitude == null) {
      _tryAutoGetLocation();
    }
  }

  void _initializeMapCenter() {
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _currentMapCenter =
          LatLng(widget.initialLatitude!, widget.initialLongitude!);
    }
  }

  Future<void> _tryAutoGetLocation() async {
    await _fetchLocation(
      showLoading: false,
      requestPermission: false,
      timeout: const Duration(seconds: 10),
      fallbackCenterOnError: true,
    );
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

    widget.onLocationSelected(
      position.latitude,
      position.longitude,
      LocationRequestSource_Enum.manual,
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  Future<void> _fetchLocation({
    bool showLoading = false,
    bool requestPermission = false,
    Duration timeout = const Duration(seconds: 10),
    bool fallbackCenterOnError = false,
  }) async {
    if (showLoading) {
      setState(() {
        _isGettingLocation = true;
        _locationError = null;
      });
    }

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (showLoading) throw Exception('Location services are disabled.');
        return;
      }

      // Check or request permissions if necessary
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && requestPermission) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (showLoading) throw Exception('Location permission denied.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (showLoading)
          throw Exception('Location permission permanently denied.');
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: timeout,
      );

      if (!mounted) return;

      setState(() {
        _currentMapCenter = LatLng(position.latitude, position.longitude);
        _latController.text = position.latitude.toStringAsFixed(6);
        _lonController.text = position.longitude.toStringAsFixed(6);
        _markers = {
          Marker(
            markerId: const MarkerId('selected_location'),
            position: LatLng(position.latitude, position.longitude),
            infoWindow: const InfoWindow(title: '(HC) Selected Location'),
          )
        };
      });

      widget.onLocationSelected(
        position.latitude,
        position.longitude,
        LocationRequestSource_Enum.auto,
      );

      await _moveMapToLocation(position.latitude, position.longitude);
    } catch (e) {
      debugPrint('Location fetch failed: $e');
      if (showLoading) {
        setState(() => _locationError = e.toString());
      }
      if (fallbackCenterOnError && mounted && _currentMapCenter == null) {
        setState(() => _currentMapCenter = const LatLng(0, 0));
      }
    } finally {
      if (showLoading) {
        setState(() => _isGettingLocation = false);
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    await _fetchLocation(
      showLoading: true,
      requestPermission: true,
      timeout: const Duration(seconds: 30),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildGoogleMap(),
        _buildLocationButton(),
        _buildErrorOverlay(),
      ],
    );
  }

  Widget _buildGoogleMap() {
    return GoogleMap(
      onMapCreated: _onMapCreated,
      onTap: _onMapTap,
      initialCameraPosition: CameraPosition(
        target: _currentMapCenter ?? LatLng(0, 0),
        zoom: 15,
      ),
      markers: _markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: true,
      rotateGesturesEnabled: true,
      scrollGesturesEnabled: true,
      tiltGesturesEnabled: true,
      zoomGesturesEnabled: true,
    );
  }

  Widget _buildLocationButton() {
    return Positioned(
      top: 16,
      right: 16,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isGettingLocation ? null : _getCurrentLocation,
            borderRadius: BorderRadius.circular(30),
            child: Container(
              width: 48,
              height: 48,
              child: _isGettingLocation
                  ? Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.grey[600]!),
                        ),
                      ),
                    )
                  : Icon(
                      Icons.my_location,
                      color: Colors.grey[700],
                      size: 24,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorOverlay() {
    if (_locationError == null) {
      return SizedBox.shrink();
    }

    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red[50],
          border: Border.all(color: Colors.red[200]!),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
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
            IconButton(
              icon: Icon(Icons.close, color: Colors.red),
              onPressed: () {
                setState(() {
                  _locationError = null;
                });
              },
              constraints: BoxConstraints(),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _latController.dispose();
    _lonController.dispose();
    super.dispose();
  }
}
