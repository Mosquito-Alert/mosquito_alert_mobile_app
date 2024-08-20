import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mosquito_alert_app/api/api.dart';
import 'package:mosquito_alert_app/models/partner.dart';
import 'package:mosquito_alert_app/pages/info_pages/info_page_webview.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';
import 'package:mosquito_alert_app/utils/Utils.dart';
import 'package:mosquito_alert_app/utils/style.dart';

class PartnersPage extends StatefulWidget {
  @override
  _PartnersPageState createState() => _PartnersPageState();
}

class _PartnersPageState extends State<PartnersPage> {
  GoogleMapController? controller;

  List<Marker> markers = [];
  StreamController<List<Marker>> markersStream =
      StreamController<List<Marker>>.broadcast();
  StreamController<bool> loadingStream = StreamController<bool>.broadcast();

  @override
  void initState() {
    super.initState();
    getInitialData();
  }

  @override
  void dispose() {
    markersStream.close();
    loadingStream.close();
    super.dispose();
  }

  getInitialData() async {
    // Set loading state to true initially
    loadingStream.add(true);

    try {
      List<Partner> partners = await ApiSingleton().getPartners();

      for (var partner in partners) {
        markers.add(Marker(
          markerId: MarkerId(partner.id.toString()),
          position: LatLng(partner.point['lat'], partner.point['long']),
          onTap: () {
            if (partner.pageUrl != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => InfoPageInWebview(partner.pageUrl)),
              );
            }
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
          body: Column(
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
