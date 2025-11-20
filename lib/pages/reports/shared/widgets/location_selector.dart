import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mosquito_alert/mosquito_alert.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';

class LocationSelector extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final Function(double? latitude, double? longitude,
      LocationRequestSource_Enum? source) onLocationChanged;
  final Function(bool isLoading)? onLoadingChanged;

  const LocationSelector(
      {Key? key,
      required this.onLocationChanged,
      this.initialLatitude,
      this.initialLongitude,
      this.onLoadingChanged})
      : super(key: key);

  @override
  _LocationSelectorState createState() => _LocationSelectorState();
}

class _LocationSelectorState extends State<LocationSelector> {
  GoogleMapController? _mapController;
  bool _isGettingLocation = false;
  String? _locationError;
  LatLng? position;
  LocationRequestSource_Enum? _locationSource;
  static const LatLng defaultPosition = LatLng(0, 0);
  Position? phonePosition;
  static const double minDistanceLocationManual = 50.0; // in meters

  bool _isUserGesture = false;
  bool _ignoreNextCameraEvent = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      position = LatLng(widget.initialLatitude!, widget.initialLongitude!);
      _locationSource = LocationRequestSource_Enum.manual;
    } else {
      _tryAutoGetLocation();
    }
  }

  Future<void> _tryAutoGetLocation() async {
    await _fetchLocation(
      showLoading: true,
      requestPermission: false,
      timeout: const Duration(seconds: 10),
      fallbackCenterOnError: true,
    );
  }

  Future<void> _fetchLocation({
    bool showLoading = false,
    bool showError = false,
    bool requestPermission = false,
    Duration timeout = const Duration(seconds: 10),
    bool fallbackCenterOnError = false,
  }) async {
    if (showLoading) {
      setState(() {
        _isGettingLocation = true;
        _locationError = null;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onLoadingChanged?.call(_isGettingLocation);
      });
    }

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      // Check or request permissions if necessary
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && requestPermission) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permission permanently denied.');
      }

      // Get current position && update state variable
      phonePosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: timeout,
      );

      // Update state variables.
      position = LatLng(phonePosition!.latitude, phonePosition!.longitude);
      _locationSource = LocationRequestSource_Enum.auto;

      if (_mapController != null) {
        _ignoreNextCameraEvent = true; // Mark next camera move as programmatic
        await _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: position!,
              zoom: 16.0,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Location fetch failed: $e');
      if (showError) {
        setState(() => _locationError = e.toString());
      }
    } finally {
      if (showLoading) {
        setState(() {
          _isGettingLocation = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onLoadingChanged?.call(_isGettingLocation);
        });
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    await _fetchLocation(
      showLoading: true,
      showError: true,
      requestPermission: true,
      timeout: const Duration(seconds: 30),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildGoogleMap(),
        _buildCenterMarker(),
        _buildLocationButton(),
        _buildErrorOverlay(),
      ],
    );
  }

  Widget _buildGoogleMap() {
    return GoogleMap(
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
        if (position == null) {
          widget.onLocationChanged(defaultPosition.latitude,
              defaultPosition.longitude, LocationRequestSource_Enum.manual);
        }
      },
      initialCameraPosition: CameraPosition(
        target: position ?? defaultPosition,
        zoom: 15,
      ),
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: true,
      rotateGesturesEnabled: false,
      scrollGesturesEnabled: true,
      tiltGesturesEnabled: false,
      zoomGesturesEnabled: true,
      onCameraMoveStarted: () {
        _isUserGesture = !_ignoreNextCameraEvent;
        widget.onLocationChanged(null, null, null);
      },
      onCameraMove: (newPosition) {
        position = newPosition.target;
        if (_isUserGesture) {
          _locationSource = LocationRequestSource_Enum.manual;
        }
      },
      onCameraIdle: () {
        _ignoreNextCameraEvent = false;
        if (position != null) {
          // If user moved manually, check if final position is still close to GPS
          if (_isUserGesture && phonePosition != null) {
            final distance = Geolocator.distanceBetween(
              phonePosition!.latitude,
              phonePosition!.longitude,
              position!.latitude,
              position!.longitude,
            );

            if (distance <= minDistanceLocationManual) {
              _locationSource = LocationRequestSource_Enum.auto;
            }
          }

          widget.onLocationChanged(
            position!.latitude,
            position!.longitude,
            _locationSource,
          );
        }
      },
    );
  }

  Widget _buildCenterMarker() {
    return const Center(
      child: FractionalTranslation(
        translation: Offset(0, -0.5),
        child: Icon(Icons.place, size: 48, color: Colors.red),
      ),
    );
  }

  Widget _buildLocationButton() {
    return Positioned(
      top: 16,
      right: 16,
      child: Material(
        key: Key("myLocationButton"),
        color: Colors.transparent,
        child: InkWell(
          onTap: _isGettingLocation ? null : _getCurrentLocation,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: _isGettingLocation
                      ? CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.grey[600]!),
                        )
                      : Icon(
                          Icons.my_location,
                          color: Colors.grey[700],
                          size: 24,
                        ),
                ),
                SizedBox(width: 8),
                Text(
                  MyLocalizations.of(context, "current_location_txt"),
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
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
      top: 16,
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
    _mapController?.dispose();
    super.dispose();
  }
}
