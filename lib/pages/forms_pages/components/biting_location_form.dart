import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mosquito_alert_app/pages/forms_pages/components/small_question_option_widget.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';
import 'package:mosquito_alert_app/utils/Utils.dart';
import 'package:mosquito_alert_app/utils/style.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

class BitingLocationForm extends StatefulWidget {
  final Function setValid;
  final String? displayQuestion;

  BitingLocationForm(this.setValid, this.displayQuestion);

  @override
  _BitingLocationFormState createState() => _BitingLocationFormState();
}

enum LocationType { current, selected, missing }

class _BitingLocationFormState extends State<BitingLocationForm> {
  late GoogleMapController controller;
  List<Marker> markers = [];

  LatLng? currentLocation;

  Set<Circle>? circles;

  StreamController<LocationType> streamType =
      StreamController<LocationType>.broadcast();

  @override
  void initState() {
    super.initState();

    if (Utils.report != null) {
      switch (Utils.report!.location_choice) {
        case 'selected':
          streamType.add(LocationType.selected);
          markers.add(Marker(
              markerId: MarkerId('mk_${markers.length}'),
              position: LatLng(Utils.report!.selected_location_lat!,
                  Utils.report!.selected_location_lon!)));
          currentLocation = LatLng(Utils.report!.selected_location_lat!, Utils.report!.selected_location_lon!);
          widget.setValid(true);
          break;
        case 'current':
          streamType.add(LocationType.current);
          markers.add(Marker(
              markerId: MarkerId('mk_${markers.length}'),
              position: LatLng(Utils.report!.current_location_lat!,
                  Utils.report!.current_location_lon!)));
          currentLocation = LatLng(Utils.report!.current_location_lat!, Utils.report!.current_location_lon!);
          widget.setValid(true);
          break;
        default:
          streamType.add(LocationType.missing);
      }
    } else {
      _getCurrentLocation();
    }
  }

  void _getCurrentLocation() async {
    updateType(LocationType.current, context: context);
  }

  void _onMapCreated(GoogleMapController controller) {
    this.controller = controller;
    currentLocation == null ? _getCurrentLocation() : null;
  }

  void updateMarker(LatLng markerPosition) {
    var mk = Marker(
        markerId: MarkerId('mk${markers.length}'), position: markerPosition);
    Utils.setSelectedLocation(mk.position.latitude, mk.position.longitude);
    widget.setValid(true);

    setState(() {
      markers = [mk];
    });
  }

  void updateType(type, {context}) async {
    streamType.add(type);

    var currentMarkers = <Marker>[];
    switch (type) {
      case LocationType.current:
        var geolocationEnabled = await Geolocator.isLocationServiceEnabled();
        streamType.add(type);

        if (geolocationEnabled) {
          var currentPosition = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high);
          Utils.setCurrentLocation(
              currentPosition.latitude, currentPosition.longitude);
          await controller.moveCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                  target: LatLng(
                      currentPosition.latitude, currentPosition.longitude),
                  zoom: 15.0),
            ),
          );
          currentMarkers = [
            Marker(
                markerId: MarkerId('mk${markers.length}'),
                position:
                    LatLng(currentPosition.latitude, currentPosition.longitude))
          ];
          widget.setValid(true);
        } else {
          await Utils.showAlert(
              MyLocalizations.of(context, 'location_not_active_title'),
              MyLocalizations.of(context, 'location_not_active_txt'),
              context, onPressed: () {
            Navigator.pop(context);
          });
          streamType.add(LocationType.selected);
        }

        break;
      case LocationType.selected:
        currentMarkers = [];
        // get saved marker
        if (Utils.report!.selected_location_lat != null &&
            Utils.report!.selected_location_lon != null) {
          await controller.moveCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                  target: LatLng(Utils.report!.selected_location_lat!,
                      Utils.report!.selected_location_lon!),
                  zoom: 15.0),
            ),
          );
          Utils.setSelectedLocation(Utils.report!.selected_location_lat,
              Utils.report!.selected_location_lon);
          currentMarkers.add(Marker(
            markerId: MarkerId('selected'),
            position: LatLng(Utils.report!.selected_location_lat!,
                Utils.report!.selected_location_lon!),
          ));
          widget.setValid(true);
        }
        //get markers in responses
        try {
          if (Utils.report!.responses!.any((r) => r!.question_id == 5)) {
            var i = 0;
            Utils.report!.responses!.forEach((q) {
              i++;
              if (q!.question_id == 5) {
                print(q.answer_value);

                var res = q.answer_value!
                    .substring(q.answer_value!.indexOf('( ') + 2,
                        q.answer_value!.indexOf(')'))
                    .split(', ');
                currentMarkers.add(Marker(
                    markerId: MarkerId('mk_$i'),
                    position:
                        LatLng(double.parse(res[0]), double.parse(res[1]))));
              }
            });
          }
        } catch (e) {
          print(e);
        }

        break;
      default:
        streamType.add(LocationType.missing);
        break;
    }
    setState(() {
      markers = currentMarkers;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(
                  height: 35,
                ),
                Style.title(
                    MyLocalizations.of(context, widget.displayQuestion)),
                Style.body(MyLocalizations.of(context, 'chose_option_txt')),
                Container(
                  margin: EdgeInsets.symmetric(vertical: 30),
                  child: StreamBuilder(
                    stream: streamType.stream,
                    initialData: Utils.report!.location_choice != null
                        ? Utils.report!.location_choice == 'selected'
                            ? LocationType.selected
                            : LocationType.current
                        : LocationType.current,
                    builder: (BuildContext context,
                        AsyncSnapshot<LocationType> snapshot) {
                      return Column(
                        children: <Widget>[
                          Container(
                            height: MediaQuery.of(context).size.height * 0.08,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Expanded(
                                    child: GestureDetector(
                                        onTap: () {
                                          updateType(LocationType.current,
                                              context: context);
                                        },
                                        child: SmallQuestionOption(
                                          'current_location_txt',
                                          selected: snapshot.data ==
                                              LocationType.current,
                                        ))),
                                SizedBox(
                                  width: 10,
                                ),
                                Expanded(
                                    child: GestureDetector(
                                  onTap: () {
                                    widget.setValid(false);
                                    updateType(LocationType.selected);
                                  },
                                  child: SmallQuestionOption(
                                    'select_location_txt',
                                    selected:
                                        snapshot.data == LocationType.selected,
                                  ),
                                )),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Container(
                            margin: EdgeInsets.symmetric(vertical: 5),
                            height: MediaQuery.of(context).size.height * 0.4,
                            child: ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: GoogleMap(
                                  onMapCreated: _onMapCreated,
                                  rotateGesturesEnabled: false,
                                  myLocationButtonEnabled: false,
                                  zoomControlsEnabled: false,
                                  minMaxZoomPreference:
                                      MinMaxZoomPreference(5, 18),
                                  mapToolbarEnabled: false,
                                  onTap: (LatLng pos) {
                                    if (snapshot.data ==
                                        LocationType.selected) {
                                      updateMarker(pos);
                                    }
                                  },
                                  initialCameraPosition: CameraPosition(
                                    target: currentLocation != null
                                        ? LatLng(currentLocation!.latitude,
                                            currentLocation!.longitude)
                                        : Utils.location != null
                                            ? LatLng(Utils.location!.latitude,
                                                Utils.location!.longitude)
                                            : LatLng(
                                                Utils.defaultLocation.latitude,
                                                Utils
                                                    .defaultLocation.longitude),
                                    zoom: 7.0,
                                  ),
                                  markers: markers.isNotEmpty
                                      ? Set.from(markers.cast<
                                          Marker>()) // Cast elements to Marker
                                      : <Marker>{},
                                  gestureRecognizers: <Factory<
                                      OneSequenceGestureRecognizer>>{
                                    Factory<OneSequenceGestureRecognizer>(
                                      () => EagerGestureRecognizer(),
                                    ),
                                  },
                                )),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Style.button(
                            MyLocalizations.of(context, 'reset'),
                            () {
                              resetLocations();
                            },
                          )
                        ],
                      );
                    },
                  ),
                ),
                Style.bottomOffset,
              ],
            ),
          ),
        ),
      ),
    );
  }

  void resetLocations() {
    Utils.report!.selected_location_lat = null;
    Utils.report!.selected_location_lon = null;
    Utils.report!.current_location_lat = null;
    Utils.report!.current_location_lon = null;

    if (Utils.report!.type == 'bite') {
      Utils.report!.responses!
          .removeWhere((question) => question!.question_id == 5);
    }
    print(Utils.report!.responses);

    widget.setValid(false);

    setState(() {
      markers = [];
    });
  }
}
