import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoder/geocoder.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:material_segmented_control/material_segmented_control.dart';
import 'package:mosquito_alert_app/api/api.dart';
import 'package:mosquito_alert_app/models/owcampaing.dart';
import 'package:mosquito_alert_app/models/report.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';
import 'package:mosquito_alert_app/utils/UserManager.dart';
import 'package:mosquito_alert_app/utils/Utils.dart';
import 'package:mosquito_alert_app/utils/clustering/aggregation_setup.dart';
import 'package:mosquito_alert_app/utils/clustering/clustering_helper.dart';
import 'package:mosquito_alert_app/utils/clustering/report_geohash.dart';
import 'package:mosquito_alert_app/utils/customModalBottomSheet.dart';
import 'package:mosquito_alert_app/utils/style.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

import 'components/reports_list_widget.dart';

class MyReportsPage extends StatefulWidget {
  MyReportsPage({Key key}) : super(key: key);

  @override
  _MyReportsPageState createState() => _MyReportsPageState();
}

class _MyReportsPageState extends State<MyReportsPage> {
  Position location = Position(
      latitude: Utils.defaultLocation.latitude,
      longitude: Utils.defaultLocation.longitude);

  //Map
  ClusteringHelper clusteringHelper;
  List<ReportAndGeohash> _listMarkers = List();
  Set<Marker> markers = Set();
  BitmapDescriptor iconAdultYours;
  BitmapDescriptor iconBitesYours;
  BitmapDescriptor iconBreedingYours;
  BitmapDescriptor iconAdultOthers;

  //My reports
  List<Report> _myData = [];

  //Data
  Position _locationData;
  double _zoomData;

  final _pagesController = PageController();

  StreamController<List<Report>> dataMarkersStream =
      new StreamController<List<Report>>.broadcast();
  StreamController<List<Report>> dataStream =
      new StreamController<List<Report>>.broadcast();

  StreamController<bool> loadingStream = new StreamController<bool>.broadcast();

  int _currentIndex = 0;
  Map<int, Widget> _children;

  GoogleMapController mapController;
  GoogleMapController miniMapController;
  List<Report> data = [];

  @override
  initState() {
    super.initState();
    _initLocation();
    _initMemoryClustering();
    _getData();
  }

  _initLocation() {
    if (Utils.location != null) {
      location = Utils.location;
    }
  }

  _initMemoryClustering() {
    clusteringHelper = ClusteringHelper.forMemory(
        list: _listMarkers,
        updateMarkers: updateMarkers,
        aggregationSetup: AggregationSetup(markerSize: 150),
        onClick: ((index) {
          _reportBottomSheet(_listMarkers[index].report);
        }));
  }

  updateMarkers(Set<Marker> markers) {
    setState(() {
      this.markers = markers;
    });
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))
        .buffer
        .asUint8List();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    clusteringHelper.mapController = controller;
    clusteringHelper.updateMap();
  }

  void _onMiniMapCreated(GoogleMapController controller) async {
    miniMapController = controller;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _children = {
      0: Container(
        child: Text(MyLocalizations.of(context, "map_txt")),
      ),
      1: Container(
        child: Text(MyLocalizations.of(context, "list_txt")),
      ),
    };

    return Scaffold(
      body: Stack(
        children: <Widget>[
          Container(
              margin: EdgeInsets.only(top: 100),
              child: PageView.builder(
                  controller: _pagesController,
                  itemCount: 2,
                  physics: NeverScrollableScrollPhysics(),
                  itemBuilder: (BuildContext context, int index) {
                    if (index == 0.0) {
                      return Stack(
                        alignment: Alignment.bottomLeft,
                        children: <Widget>[
                          StreamBuilder<List<Report>>(
                            stream: dataMarkersStream.stream,
                            builder: (BuildContext context,
                                AsyncSnapshot<List<Report>> snapshot) {
                              return GoogleMap(
                                onMapCreated: _onMapCreated,
                                mapType: MapType.normal,
                                mapToolbarEnabled: false,
                                myLocationButtonEnabled: false,
                                // minMaxZoomPreference:
                                //     MinMaxZoomPreference(14, 20),
                                onCameraMove: (newPosition) {
                                  location = Position(
                                      latitude: newPosition.target.latitude,
                                      longitude: newPosition.target.longitude);
                                  /*clusteringHelper.onCameraMove(newPosition,
                                      forceUpdate: false)*/
                                },
                                // onCameraIdle: () {
                                //   _getData();
                                // },
                                initialCameraPosition: CameraPosition(
                                  target: location != null
                                      ? LatLng(
                                          location.latitude, location.longitude)
                                      : Utils.defaultLocation,
                                  zoom: 12,
                                ),
                                markers: markers,
                              );
                            },
                          ),
                          SafeArea(
                            child: Container(
                                width: 50,
                                height: 50,
                                margin: EdgeInsets.only(left: 12, bottom: 12),
                                child: RaisedButton(
                                    onPressed: () {
                                      _infoBottom(context);
                                    },
                                    elevation: 0,
                                    highlightElevation: 0,
                                    hoverElevation: 0,
                                    highlightColor:
                                        Style.colorPrimary.withOpacity(0.5),
                                    padding: EdgeInsets.symmetric(vertical: 2),
                                    color: Color(0xffffffff),
                                    disabledColor:
                                        Style.colorPrimary.withOpacity(0.3),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(3),
                                        side: BorderSide(
                                            color:
                                                Colors.black.withOpacity(0.2),
                                            width: 1.0)),
                                    child: Icon(Icons.info_outline))),
                          )
                        ],
                      );
                    }

                    return StreamBuilder<List<Report>>(
                      stream: dataStream.stream,
                      initialData: _myData,
                      builder: (BuildContext context,
                          AsyncSnapshot<List<Report>> snapshot) {
                        return ReportsList(
                            snapshot.data != null
                                ? snapshot.data.map((e) => e).toList()
                                : [],
                            _reportBottomSheet);
                      },
                    );
                  })),
          StreamBuilder<bool>(
              stream: loadingStream.stream,
              initialData: true,
              builder: (BuildContext context, AsyncSnapshot<bool> snapLoading) {
                if (snapLoading.data == true) {
                  return Container(
                    child: Center(
                      child: Utils.loading(true),
                    ),
                  );
                }
                return Container();
              }),
          Container(
            child: Card(
              margin: EdgeInsets.all(0),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(0)),
              color: Colors.white,
              elevation: 2,
              child: SafeArea(
                bottom: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: Style.iconBack,
                        ),
                        Style.title(
                            MyLocalizations.of(context, 'your_reports_txt'),
                            fontSize: 16.0),
                        SizedBox(
                          width: 40,
                        )
                      ],
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 15, bottom: 16),
                      width: double.infinity,
                      child: MaterialSegmentedControl(
                        children: _children,
                        selectionIndex: _currentIndex,
                        borderColor: Style.colorPrimary,
                        selectedColor: Style.colorPrimary,
                        unselectedColor: Colors.white,
                        borderRadius: 5.0,
                        onSegmentChosen: (index) {
                          _onItemTapped(index);
                        },
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

  void _infoBottom(BuildContext context) {
    CustomShowModalBottomSheet.customShowModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return Container(
            color: Colors.white,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    SizedBox(
                      height: 30,
                    ),
                    ListTile(
                      leading: Image.asset(
                        'assets/img/maps/ic_red_marker.png',
                        height: 36,
                      ),
                      title: Style.body(
                          MyLocalizations.of(context, 'your_reports_bites_txt'),
                          textAlign: TextAlign.left),
                    ),
                    ListTile(
                      leading: Image.asset(
                        'assets/img/maps/ic_yellow_marker.png',
                        height: 36,
                      ),
                      title: Style.body(
                          MyLocalizations.of(
                              context, 'your_reports_adults_txt'),
                          textAlign: TextAlign.left),
                    ),
                    ListTile(
                      leading: Image.asset(
                        'assets/img/maps/ic_blue_marker.png',
                        height: 36,
                      ),
                      title: Style.body(
                          MyLocalizations.of(
                              context, 'your_reports_breeding_txt'),
                          textAlign: TextAlign.left),
                    ),
                    ListTile(
                      leading: Image.asset(
                        'assets/img/maps/ic_green_marker.png',
                        height: 36,
                      ),
                      title: Style.body(
                          MyLocalizations.of(context, 'other_reports_txt'),
                          textAlign: TextAlign.left),
                    ),
                    SizedBox(
                      height: 30,
                    ),
                  ],
                ),
              ),
            ),
          );
        });
  }

  _reportBottomSheet(Report report) async {
    bool isMine = UserManager.profileUUIDs.any((id) => id == report.user);
    Coordinates coord;
    if (report.location_choice == 'current') {
      coord =
          Coordinates(report.current_location_lat, report.current_location_lon);
    } else if (report.location_choice == 'selected') {
      coord = Coordinates(
          report.selected_location_lat, report.selected_location_lon);
    }
    var address = await Geocoder.local.findAddressesFromCoordinates(coord);
    CustomShowModalBottomSheet.customShowModalBottomSheet(
        context: context,
        dismissible: true,
        builder: (BuildContext bc) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: isMine
                  ? MediaQuery.of(context).size.height * 0.85
                  : MediaQuery.of(context).size.height * 0.45,
              minHeight: isMine
                  ? MediaQuery.of(context).size.height * 0.55
                  : MediaQuery.of(context).size.height * 0.45,
            ),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                )),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: isMine
                    ? MediaQuery.of(context).size.height * 0.9
                    : MediaQuery.of(context).size.height * 0.45,
              ),
              // height: double.infinity,
              margin: EdgeInsets.symmetric(horizontal: 15),
              child: SingleChildScrollView(
                physics: ClampingScrollPhysics(),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SizedBox(
                        height: 15,
                      ),
                      Container(
                        height: MediaQuery.of(context).size.height * 0.25,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: GoogleMap(
                            rotateGesturesEnabled: false,
                            mapToolbarEnabled: false,
                            scrollGesturesEnabled: false,
                            zoomControlsEnabled: false,
                            zoomGesturesEnabled: false,
                            myLocationButtonEnabled: false,
                            onMapCreated: _onMiniMapCreated,
                            initialCameraPosition: _getPosition(report),
                            markers: _getMarker(report),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Style.titleMedium(
                          MyLocalizations.of(context, 'report_of_the_day_txt') +
                              DateFormat('dd-MM-yyyy')
                                  .format(DateTime.parse(report.creation_time))
                                  .toString()),
                      SizedBox(
                        height: 20,
                      ),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Style.titleMedium(
                                    MyLocalizations.of(
                                        context, 'registered_location_txt'),
                                    fontSize: 14),
                                Style.body(
                                    report.location_choice == 'current'
                                        ? '(' +
                                            report.current_location_lat
                                                .toStringAsFixed(5) +
                                            ', ' +
                                            report.current_location_lon
                                                .toStringAsFixed(5) +
                                            ')'
                                        : '(' +
                                            report.selected_location_lat
                                                .toStringAsFixed(5) +
                                            ', ' +
                                            report.selected_location_lon
                                                .toStringAsFixed(5) +
                                            ')',
                                    fontSize: 12),
                                Style.body(
                                    ' ${MyLocalizations.of(context, "near_from_txt")} ${address[0].locality} (${address[0].subAdminArea})',
                                    fontSize: 12),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: <Widget>[
                                Style.titleMedium(
                                    MyLocalizations.of(
                                        context, 'exact_time_register_txt'),
                                    fontSize: 14),
                                Style.body(
                                    DateFormat('EEEE, dd MMMM yyyy',
                                            Utils.language.languageCode)
                                        .format(DateTime.parse(
                                            report.creation_time))
                                        .toString(),
                                    fontSize: 12),
                                Style.body(
                                    "${MyLocalizations.of(context, "at_time_txt")} ${DateFormat.Hms().format(DateTime.parse(report.creation_time))} ${MyLocalizations.of(context, 'hours')}",
                                    fontSize: 12),
                              ],
                            ),
                          ),
                        ],
                      ),
                      isMine
                          ? Column(
                              children: <Widget>[
                                report.type == 'adult'
                                    ? Column(
                                        children: [
                                          SizedBox(
                                            height: 15,
                                          ),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Container(
                                                    color: Style.colorPrimary,
                                                    child: Style.titleMedium(
                                                        'ID: ' +
                                                            report.report_id)),
                                              ),
                                              Expanded(
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.end,
                                                  children: [
                                                    IconButton(
                                                        icon: Icon(Icons.mail),
                                                        onPressed: () {
                                                          _checkCampaign(
                                                              report);
                                                        }),
                                                    IconButton(
                                                        icon: Icon(
                                                            Icons.find_in_page),
                                                        onPressed: () {})
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      )
                                    : Container(),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10.0),
                                  child: Divider(),
                                ),
                                report.photos.isNotEmpty
                                    ? Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Style.titleMedium(
                                              MyLocalizations.of(context,
                                                  'reported_images_txt'),
                                              fontSize: 14),
                                          SizedBox(
                                            height: 10,
                                          ),
                                          Container(
                                            height: 60,
                                            child: ListView.builder(
                                                scrollDirection:
                                                    Axis.horizontal,
                                                itemCount: report.photos.length,
                                                itemBuilder: (context, index) {
                                                  return Container(
                                                    margin: EdgeInsets.only(
                                                        right: 5),
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              15),
                                                      child: Image.network(
                                                        ApiSingleton.baseUrl +
                                                            report.photos[index]
                                                                .photo,
                                                        height: 60,
                                                        width: 60,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                  );
                                                }),
                                          ),
                                          SizedBox(
                                            height: 20,
                                          ),
                                        ],
                                      )
                                    : Container(),
                                ListView.builder(
                                    shrinkWrap: true,
                                    physics: NeverScrollableScrollPhysics(),
                                    itemCount: report.responses.length,
                                    itemBuilder: (context, index) {
                                      return Column(
                                        children: <Widget>[
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 10.0),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: <Widget>[
                                                report.responses[index]
                                                            .question !=
                                                        null
                                                    ? Expanded(
                                                        flex: 3,
                                                        child: Style.titleMedium(
                                                            report
                                                                    .responses[
                                                                        index]
                                                                    .question
                                                                    .startsWith(
                                                                        'question')
                                                                ? MyLocalizations.of(
                                                                    context,
                                                                    report
                                                                        .responses[
                                                                            index]
                                                                        .question)
                                                                : report
                                                                    .responses[
                                                                        index]
                                                                    .question,
                                                            fontSize: 14),
                                                      )
                                                    : Container(),
                                                Expanded(
                                                  flex: 2,
                                                  child: Style.body(
                                                      report.responses[index]
                                                                  .answer !=
                                                              'N/A'
                                                          ? report
                                                                  .responses[
                                                                      index]
                                                                  .answer
                                                                  .startsWith(
                                                                      'question')
                                                              ? MyLocalizations.of(
                                                                  context,
                                                                  report
                                                                      .responses[
                                                                          index]
                                                                      .answer)
                                                              : report
                                                                  .responses[
                                                                      index]
                                                                  .answer
                                                          : report
                                                              .responses[index]
                                                              .answer_value,
                                                      textAlign: TextAlign.end),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      );
                                    }),
                                report.note != null && report.note != 'null'
                                    ? Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 10.0),
                                            child: Divider(),
                                          ),
                                          Style.titleMedium(
                                              MyLocalizations.of(
                                                  context, 'comments_txt'),
                                              fontSize: 14),
                                          Style.body(
                                            report.note,
                                          ),
                                        ],
                                      )
                                    : Container(),
                                SizedBox(
                                  height: 10,
                                ),
                                Row(
                                  children: <Widget>[
                                    // Expanded(
                                    //     child: Style.noBgButton(
                                    //         MyLocalizations.of(context, "edit"),
                                    //         () {
                                    //   Navigator.pop(context);
                                    //   if (report.type == "bite") {
                                    //     Navigator.push(
                                    //       context,
                                    //       MaterialPageRoute(
                                    //           builder: (context) =>
                                    //               BitingReportPage(
                                    //                 editReport: report,
                                    //                 loadData: _updateReport,
                                    //               )),
                                    //     );
                                    //   } else if (report.type == "adult") {
                                    //     Navigator.push(
                                    //       context,
                                    //       MaterialPageRoute(
                                    //           builder: (context) =>
                                    //               AdultReportPage(
                                    //                 editReport: report,
                                    //                 loadData: _updateReport,
                                    //               )),
                                    //     );
                                    //   } else {
                                    //     Navigator.push(
                                    //       context,
                                    //       MaterialPageRoute(
                                    //           builder: (context) =>
                                    //               BreedingReportPage(
                                    //                 editReport: report,
                                    //                 loadData: _updateReport,
                                    //               )),
                                    //     );
                                    //   }
                                    // })),
                                    Expanded(
                                        child: Style.noBgButton(
                                            MyLocalizations.of(
                                                context, 'delete'), () {
                                      Utils.showAlertYesNo(
                                          MyLocalizations.of(
                                              context, 'delete_report_title'),
                                          MyLocalizations.of(
                                              context, 'delete_report_txt'),
                                          () {
                                        _deleteReport(report);
                                      }, context);
                                      //
                                    }, textColor: Colors.red))
                                  ],
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                              ],
                            )
                          : Container(),
                      SizedBox(
                        height: 10,
                      ),
                    ]),
              ),
            ),
          );
        });
  }

  _getData({bool letReturn = true, bool fromMap = true}) async {
    try {
      loadingStream.add(true);
      double distance;
      // if (fromMap) {
      //   double zoomLevel = await mapController.getZoomLevel();
      //   if (_locationData != null && _zoomData != null) {
      //     double distance = await Geolocator().distanceBetween(
      //         _locationData.latitude,
      //         _locationData.longitude,
      //         location.latitude,
      //         location.longitude);
      //     if (distance < 750 && zoomLevel == _zoomData) {
      //       if (letReturn) return;
      //     }
      //   }

      //   _locationData = location;
      //   _zoomData = await mapController.getZoomLevel();

      //   LatLngBounds bounds = await mapController.getVisibleRegion();
      //   distance = await Geolocator().distanceBetween(
      //       bounds.northeast.latitude,
      //       bounds.northeast.longitude,
      //       bounds.southwest.latitude,
      //       bounds.southwest.longitude);
      // }

      List<Report> list = await ApiSingleton().getReportsList(
          location.latitude, location.longitude,
          radius: (distance != null ? distance : 1000 / 2).round());

      if (list == null) {
        list = [];
      }

      List<ReportAndGeohash> listMarkers = List();
      for (int i = 0; i < list.length; i++) {
        if (list[i].location_choice != "missing" &&
                list[i].current_location_lat != null &&
                list[i].current_location_lon != null ||
            list[i].selected_location_lat != null &&
                list[i].selected_location_lon != null) {
          data.add(list[i]);

          listMarkers.add(ReportAndGeohash(
              list[i],
              list[i].location_choice == 'current'
                  ? LatLng(list[i].current_location_lat,
                      list[i].current_location_lon)
                  : LatLng(list[i].selected_location_lat,
                      list[i].selected_location_lon),
              i));
        }
      }

      List<Report> myData = list
          .where((element) =>
              UserManager.profileUUIDs.any((id) => id == element.user))
          .toList();

      myData
          .map((element) async => element.displayCity = await getCity(element))
          .toList();

      dataStream.add(myData);
      _myData = myData;
      if (myData != null && myData.isNotEmpty) {
        var location = myData[0].location_choice == 'current'
            ? LatLng(
                myData[0].current_location_lat, myData[0].current_location_lon)
            : LatLng(myData[0].selected_location_lat,
                myData[0].selected_location_lon);
        mapController.animateCamera(CameraUpdate.newCameraPosition(
            CameraPosition(target: location, zoom: 15)));
      }

      clusteringHelper.updateData(listMarkers);
      _listMarkers = listMarkers;

      loadingStream.add(false);
    } catch (e) {
      print(e);
    }
  }

  Future<String> getCity(report) async {
    Coordinates coord;
    if (report.location_choice == 'current') {
      coord =
          Coordinates(report.current_location_lat, report.current_location_lon);
    } else if (report.location_choice == 'selected') {
      coord = Coordinates(
          report.selected_location_lat, report.selected_location_lon);
    }
    var address = await Geocoder.local.findAddressesFromCoordinates(coord);
    return address[0].locality;
  }

  void _deleteReport(Report report) async {
    Navigator.pop(context);
    loadingStream.add(true);
    var res = await Utils.deleteReport(report);
    if (res) {
      loadingStream.add(false);
      _myData.removeWhere((element) => element.report_id == report.report_id);
      dataStream.add(_myData);

      _listMarkers.removeWhere(
          (element) => element.report.report_id == report.report_id);
      clusteringHelper.updateData(_listMarkers);
    } else {
      loadingStream.add(false);
      await Utils.showAlert(
        MyLocalizations.of(context, 'app_name'),
        MyLocalizations.of(context, 'save_report_ko_txt'),
        context,
      );
    }
  }

  _updateReport() async {
    //refresh all markers because it has not get image object
    await _getData(letReturn: false, fromMap: false);
    /*
    int index =
        _myData.indexWhere((r) => r.report_id == Utils.report.report_id);
    _myData[index] = Utils.report;

    int indexMarker = _listMarkers
        .indexWhere((r) => r.report.report_id == Utils.report.report_id);

    _listMarkers[indexMarker] = (ReportAndGeohash(
        Utils.report,
        LatLng(
            Utils.report.current_location_lat != null
                ? Utils.report.current_location_lat
                : Utils.report.selected_location_lat,
            Utils.report.current_location_lon != null
                ? Utils.report.current_location_lon
                : Utils.report.selected_location_lon),
        indexMarker));

    clusteringHelper.updateData(_listMarkers);
*/
  }

  _getPosition(Report report) {
    var _target;

    if (report.location_choice == 'current') {
      _target =
          LatLng(report.current_location_lat, report.current_location_lon);
    } else {
      _target =
          LatLng(report.selected_location_lat, report.selected_location_lon);
    }

    return CameraPosition(
      target: _target,
      zoom: 15.0,
    );
  }

  _getMarker(Report report) {
    var marker;
    var icon = setIconMarker(report.type, report.user);
    if (report.location_choice == 'current') {
      marker = Marker(
          markerId: MarkerId('currentMarker'),
          position: LatLng(
            report.current_location_lat,
            report.current_location_lon,
          ),
          icon: icon);
    } else {
      marker = Marker(
          markerId: MarkerId('selectedtMarker'),
          position: LatLng(
            report.selected_location_lat,
            report.selected_location_lon,
          ),
          icon: icon);
    }

    return <Marker>[marker].toSet();
  }

  BitmapDescriptor setIconMarker(type, user) {
    if (UserManager.profileUUIDs != null &&
        UserManager.profileUUIDs.any((id) => id == user)) {
      switch (type) {
        case 'adult':
          // return
          return iconAdultYours;
          break;
        case 'bite':
          return iconBitesYours;
          break;
        case 'site':
          return iconBreedingYours;
          break;
        default:
          break;
      }
    } else {
      return iconAdultOthers;
    }
  }

  _onItemTapped(index) {
    setState(() {
      _currentIndex = index;
    });
    _pagesController.animateToPage(index,
        duration: Duration(milliseconds: 300), curve: Curves.ease);
  }

  void _checkCampaign(Report report) async {
    loadingStream.add(true);
    List<Campaign> campaingsList =
        await ApiSingleton().getCampaigns(report.country);
    var now = DateTime.now();
    loadingStream.add(false);
    if (campaingsList.any((element) =>
        DateTime.parse(element.startDate).isBefore(now) &&
        DateTime.parse(element.endDate).isAfter(now))) {
      var activeCampaign = campaingsList.firstWhere((element) =>
          DateTime.parse(element.startDate).isBefore(now) &&
          DateTime.parse(element.endDate).isAfter(now));
      await Utils.showCustomAlert(
          MyLocalizations.of(context, 'alert_campaing_found_title'),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Style.titleMedium('Id: ' + report.report_id),
              Style.body(activeCampaign.postingAddress),
            ],
          ),
          context);
    } else {
      await Utils.showAlert(
          MyLocalizations.of(context, 'campaign_not_fount_title'),
          MyLocalizations.of(context, 'campaign_not_fount_text'),
          context);
    }
  }
}
