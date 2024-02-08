import 'dart:typed_data';
import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mosquito_alert_app/models/report.dart';
import 'package:mosquito_alert_app/utils/UserManager.dart';
import 'package:mosquito_alert_app/utils/clustering/aggregated_points.dart';
import 'package:mosquito_alert_app/utils/clustering/aggregation_setup.dart';
import 'package:mosquito_alert_app/utils/clustering/report_geohash.dart';
import 'package:mosquito_alert_app/utils/style.dart';

class ClusteringHelper {
  ClusteringHelper.forMemory({
    required this.list,
    required this.updateMarkers,
    required this.aggregationSetup,
    required this.onClick,
    this.maxZoomForAggregatePoints = 12,
    this.bitmapAssetPathForSingleMarker,
  })  : assert(list != null),
        assert(aggregationSetup != null);

  //After this value the map show the single points without aggregation
  final double maxZoomForAggregatePoints;

  //Name of table of the databasa SQLite where are stored the latitude, longitude and geoahash value
  String? dbTable;

  //Name of column where is stored the latitude
  String? dbLatColumn;

  //Name of column where is stored the longitude
  String? dbLongColumn;

  //Name of column where is stored the geohash value
  String? dbGeohashColumn;

  //Custom bitmap: string of assets position
  final String? bitmapAssetPathForSingleMarker;

  //Custom bitmap: string of assets position
  final AggregationSetup aggregationSetup;

  //Where clause for query db
  String? whereClause;

  late GoogleMapController mapController;

  //Variable for save the last zoom
  double currentZoom = 15;

  //Function called when the map must show single point without aggregation
  // if null the class use the default function
  Function? showSinglePoint;

  //Function for update Markers on Google Map
  Function updateMarkers;

  //List of points for memory clustering
  List<ReportAndGeohash> list;

  //Index
  int _selectedIndex = -1;

  //Onclick
  final ValueChanged<int> onClick;
  bool aggregationChanged = true;

  //Call during the editing of CameraPosition
  //If you want updateMap during the zoom in/out set forceUpdate to true
  //this is NOT RECCOMENDED
  void onCameraMove(CameraPosition position, {forceUpdate = false}) {
    currentZoom = position.zoom;

    if (currentZoom > maxZoomForAggregatePoints && aggregationChanged) {
      aggregationChanged = false;
      updatePoints(currentZoom);
    }

    if (currentZoom < maxZoomForAggregatePoints - 1) {
      onClick(-2);
    }
  }

  Future<void> onMapIdle() async {
    updateMap();
  }

  void updateMap() {
    getDescriptors().then((_) {
      if (currentZoom < maxZoomForAggregatePoints) {
        aggregationChanged = true;
        updateAggregatedPoints(zoom: currentZoom);
      } else {
        updatePoints(currentZoom);
      }
    });
  }

  void updateData(List<ReportAndGeohash> newList) {
    list = newList;
    forceUpdateMap();
  }

  void forceUpdateMap() {
    getDescriptors().then((_) {
      updatePoints(currentZoom);
    });
  }

  void readyToProcessData() {
    updateMap();
  }

  void setSelectedIndex(index) {
    _selectedIndex = index;
    updateMap();
  }

  BitmapDescriptor? _iconAdultYours;
  BitmapDescriptor? _iconBitesYours;
  BitmapDescriptor? _iconBreedingYours;
  BitmapDescriptor? _iconAdultOthers;

  Future getDescriptors() async {
    if (_iconAdultYours != null &&
        _iconBitesYours != null &&
        _iconBreedingYours != null &&
        _iconAdultOthers != null) {
      return;
    }

    // ImageConfiguration imageConfig = ImageConfiguration(devicePixelRatio: 1.0);

    final Uint8List imageAdult =
        await getBytesFromAsset('assets/img/maps/ic_yellow_marker.png', 100);
    final Uint8List imageOthers =
        await getBytesFromAsset('assets/img/maps/ic_green_marker.png', 100);
    final Uint8List imageBites =
        await getBytesFromAsset('assets/img/maps/ic_red_marker.png', 100);
    final Uint8List imageBreeding =
        await getBytesFromAsset('assets/img/maps/ic_blue_marker.png', 100);
    // final Marker marker = Marker(icon: BitmapDescriptor.fromBytes(markerIcon));

    _iconAdultYours = BitmapDescriptor.fromBytes(imageAdult);
    _iconAdultOthers = BitmapDescriptor.fromBytes(imageOthers);
    _iconBitesYours = BitmapDescriptor.fromBytes(imageBites);
    _iconBreedingYours = BitmapDescriptor.fromBytes(imageBreeding);
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

  BitmapDescriptor? getIcon(Report report, selected) {
    if (UserManager.profileUUIDs != null &&
        UserManager.profileUUIDs.any((id) => id == report.user)) {
      switch (report.type) {
        case 'adult':
          // return
          return _iconAdultYours;
          break;
        case 'bite':
          return _iconBitesYours;
          break;
        case 'site':
          return _iconBreedingYours;
          break;
        default:
          break;
      }
    } else {
      return _iconAdultOthers;
    }
  }

  Future<List<AggregatedPoints>> getAggregatedPoints(double zoom) async {
    int level = 5;

    if (zoom <= aggregationSetup.maxZoomLimits[0]) {
      level = 1;
    } else if (zoom < aggregationSetup.maxZoomLimits[1]) {
      level = 2;
    } else if (zoom < aggregationSetup.maxZoomLimits[2]) {
      level = 3;
    } else if (zoom < aggregationSetup.maxZoomLimits[3]) {
      level = 4;
    } else if (zoom < aggregationSetup.maxZoomLimits[4]) {
      level = 5;
    } else if (zoom < aggregationSetup.maxZoomLimits[5]) {
      level = 6;
    } else if (zoom < aggregationSetup.maxZoomLimits[6]) {
      level = 7;
    }

    try {
      List<AggregatedPoints> aggregatedPoints;
      final latLngBounds = await mapController.getVisibleRegion();
      final listBounds = list.where((p) {
        final double leftTopLatitude = latLngBounds.northeast.latitude;
        final double leftTopLongitude = latLngBounds.southwest.longitude;
        final double rightBottomLatitude = latLngBounds.southwest.latitude;
        final double rightBottomLongitude = latLngBounds.northeast.longitude;

        final bool latQuery = (leftTopLatitude > rightBottomLatitude)
            ? p.location.latitude <= leftTopLatitude &&
                p.location.latitude >= rightBottomLatitude
            : p.location.latitude <= leftTopLatitude ||
                p.location.latitude >= rightBottomLatitude;

        final bool longQuery = (leftTopLongitude < rightBottomLongitude)
            ? p.location.longitude >= leftTopLongitude &&
                p.location.longitude <= rightBottomLongitude
            : p.location.longitude >= leftTopLongitude ||
                p.location.longitude <= rightBottomLongitude;
        return latQuery && longQuery;
      }).toList();

      aggregatedPoints = _retrieveAggregatedPoints(listBounds, [], level);
      return aggregatedPoints;
    } catch (e) {
      return <AggregatedPoints>[];
    }
  }

  final List<AggregatedPoints> aggList = [];

  List<AggregatedPoints> _retrieveAggregatedPoints(
      List<ReportAndGeohash> inputList,
      List<AggregatedPoints> resultList,
      int level) {
    if (inputList.isEmpty) {
      return resultList;
    }
    final List<ReportAndGeohash> newInputList = List.from(inputList);
    List<ReportAndGeohash> tmp;
    final t = newInputList[0].geohash.substring(0, level);
    tmp =
        newInputList.where((p) => p.geohash.substring(0, level) == t).toList();
    newInputList.removeWhere((p) => p.geohash.substring(0, level) == t);
    double latitude = 0;
    double longitude = 0;
    tmp.forEach((l) {
      latitude += l.location.latitude;
      longitude += l.location.longitude;
    });
    final count = tmp.length;
    final a = AggregatedPoints(inputList[0].report, inputList[0].index,
        LatLng(latitude / count, longitude / count), count);
    resultList.add(a);
    return _retrieveAggregatedPoints(newInputList, resultList, level);
  }

  Future<void> updateAggregatedPoints({double zoom = 0.0}) async {
    List<AggregatedPoints> aggregation = await getAggregatedPoints(zoom);
    final Set<Marker> markers = Set<Marker>();

    for (var i = 0; i < aggregation.length; i++) {
      final a = aggregation[i];
      BitmapDescriptor? bitmapDescriptor;

      if (a.count == 1) {
        bitmapDescriptor = getIcon(a.report, a.index == _selectedIndex);
      } else {
        final Uint8List markerIcon =
            await getBytesFromCanvas(a.count.toString());
        bitmapDescriptor = BitmapDescriptor.fromBytes(markerIcon);
      }
      final marker = Marker(
        markerId: MarkerId(a.getId()),
        position: a.location,
        icon: bitmapDescriptor!,
        onTap: () {
          onClick(-1);
        },
      );
      markers.add(marker);
    }

    updateMarkers(markers);
  }

  updatePoints(double zoom) async {
    try {
      final Set<Marker> markers = list.map((p) {
        final MarkerId markerId = MarkerId(p.getId());
        return Marker(
          markerId: markerId,
          position: p.location,
          icon: getIcon(p.report, p.index == _selectedIndex)!,
          onTap: () {
            onClick(p.index);
          },
        );
      }).toSet();
      updateMarkers(markers);
    } catch (ex) {}
  }

  Future<Uint8List> getBytesFromCanvas(String text) async {
    final String clusterSize = text;
    final int size = clusterSize.length == 1
        ? 110
        : clusterSize.length == 2 ? 130 : clusterSize.length == 3 ? 140 : 150;
    final double width = 18;

    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint1 = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    final Paint paint2 = Paint()..color = Style.colorPrimary;
    canvas
      ..drawRect(
          Rect.fromLTRB(0.0, 0.0, size.toDouble(), size.toDouble()), paint1)
      ..drawRect(
          Rect.fromLTRB(width / 2, width / 2, size - width / 2,
              size.toDouble() - width / 2),
          paint2);
    TextPainter painter = TextPainter(textDirection: TextDirection.ltr);
    painter.text = TextSpan(
      text: clusterSize,
      style: TextStyle(
        fontSize: clusterSize.length == 1
            ? 50
            : clusterSize.length == 2 ? 60 : clusterSize.length == 3 ? 55 : 45,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
    painter.layout();
    painter.paint(
      canvas,
      Offset(size / 2 - painter.width / 2, size / 2 - painter.height / 2),
    );

    final img = await pictureRecorder.endRecording().toImage(size, size);
    final data = await (img.toByteData(format: ui.ImageByteFormat.png)
        as FutureOr<ByteData>);
    return data.buffer.asUint8List();
  }
}
