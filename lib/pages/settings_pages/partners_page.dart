import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mosquito_alert/mosquito_alert.dart';
import 'package:mosquito_alert_app/pages/info_pages/info_page_webview.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';
import 'package:mosquito_alert_app/utils/Utils.dart';
import 'package:mosquito_alert_app/utils/style.dart';
import 'package:provider/provider.dart';

class PartnersPage extends StatefulWidget {
  @override
  _PartnersPageState createState() => _PartnersPageState();
}

class _PartnersPageState extends State<PartnersPage> {
  late PartnersApi partnersApi;

  GoogleMapController? controller;

  List<Marker> markers = [];
  StreamController<List<Marker>> markersStream =
      StreamController<List<Marker>>.broadcast();
  StreamController<bool> loadingStream = StreamController<bool>.broadcast();

  @override
  void initState() {
    super.initState();
    MosquitoAlert apiClient =
        Provider.of<MosquitoAlert>(context, listen: false);
    partnersApi = apiClient.getPartnersApi();
    _logScreenView();
    getInitialData();
  }

  @override
  void dispose() {
    markersStream.close();
    loadingStream.close();
    super.dispose();
  }

  Future<void> _logScreenView() async {
    await FirebaseAnalytics.instance
        .logScreenView(screenName: '/info/partners');
  }

  getInitialData() async {
    // Set loading state to true initially
    loadingStream.add(true);
    try {
      Response<PaginatedPartnerList> response = await partnersApi.list();
      PaginatedPartnerList? partners = response.data;

      if (partners == null || partners.results == null) return;

      for (var partner in partners.results!) {
        markers.add(Marker(
          markerId: MarkerId(partner.id.toString()),
          position: LatLng(partner.point.latitude, partner.point.longitude),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                settings: RouteSettings(name: '/info/partners/${partner.id}'),
                builder: (context) => InfoPageInWebview(partner.url),
              ),
            );
          },
        ));
      }

      markersStream.add(markers);
    } catch (e) {
      print(e);
    } finally {
      loadingStream.add(false);
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    this.controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            centerTitle: true,
            title: Style.title(MyLocalizations.of(context, 'partners_txt'),
                fontSize: 16),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: StreamBuilder<List<Marker>>(
                    stream: markersStream.stream,
                    initialData: [],
                    builder: (BuildContext context,
                        AsyncSnapshot<List<Marker>> snapshot) {
                      return GoogleMap(
                        onMapCreated: _onMapCreated,
                        mapToolbarEnabled: false,
                        myLocationButtonEnabled: false,
                        initialCameraPosition: CameraPosition(
                          // Address: St 2188, 91347 Aufseß, Germany
                          target: LatLng(49.895268, 11.2773223),
                          zoom: 3.5,
                        ),
                        markers: Set<Marker>.of(snapshot.data!),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned.fill(
          child: StreamBuilder<bool>(
            stream: loadingStream.stream,
            initialData: true,
            builder: (BuildContext ctxt, AsyncSnapshot<bool> snapshot) {
              if (snapshot.hasData == false || snapshot.data == false) {
                return Container();
              }
              return Utils.loading(
                snapshot.data,
              );
            },
          ),
        )
      ],
    );
  }
}
