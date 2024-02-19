import 'dart:async';
import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;
import 'package:flutter_svg/svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mosquito_alert_app/api/api.dart';
import 'package:mosquito_alert_app/pages/forms_pages/adult_report_page.dart';
import 'package:mosquito_alert_app/pages/forms_pages/biting_report_page.dart';
import 'package:mosquito_alert_app/pages/forms_pages/breeding_report_page.dart';
import 'package:mosquito_alert_app/pages/info_pages/info_page.dart';
import 'package:mosquito_alert_app/pages/main/components/custom_card_widget.dart';
import 'package:mosquito_alert_app/pages/my_reports_pages/my_reports_page.dart';
import 'package:mosquito_alert_app/pages/notification_pages/notifications_page.dart';
import 'package:mosquito_alert_app/pages/settings_pages/campaign_tutorial_page.dart';
import 'package:mosquito_alert_app/pages/settings_pages/settings_page.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';
import 'package:mosquito_alert_app/utils/UserManager.dart';
import 'package:mosquito_alert_app/utils/Utils.dart';
import 'package:mosquito_alert_app/utils/style.dart';
import 'package:mosquito_alert_app/utils/version_control.dart';

class MainVC extends StatefulWidget {
  @override
  _MainVCState createState() => _MainVCState();
}

class _MainVCState extends State<MainVC> {
  String? userName;

  StreamController<String?> nameStream = StreamController<String?>.broadcast();
  String? userUuid;
  StreamController<bool> loadingStream = StreamController<bool>.broadcast();

  @override
  void initState() {
    super.initState();
    initAuthStatus();
  }

  @override
  void dispose() {
    nameStream.close();
    loadingStream.close();
    super.dispose();
  }

  void initAuthStatus() async {
    loadingStream.add(true);

    if (Platform.isIOS) {
      await AppTrackingTransparency.requestTrackingAuthorization();
    }
    VersionControl.getInstance().packageApiKey =
        'uqFb4yrdZCPFXsvXrJHBbJg5B5TqvSCYmxR7aPuN2uCcCKyu9FDVWettvbtNV9HKm';
    VersionControl.getInstance().packageLanguageCode = 'es';
    var check = await VersionControl.getInstance().checkVersion(context);
    if (check != null && check) {
      _getData();
    }

    loadingStream.add(false);
  }

  void _getData() async {
    await UserManager.startFirstTime(context);
    userUuid = await UserManager.getUUID();
    UserManager.userScore = await ApiSingleton().getUserScores();
    await UserManager.setUserScores(UserManager.userScore);
    await Utils.loadFirebase();

    await Utils.getLocation(context);
    if (UserManager.user != null) {
      nameStream.add(UserManager.user!.email);
      setState(() {
        userName = UserManager.user!.email;
      });
    }

    if (Platform.isAndroid) {
      _bgTracking();
    }
  }

  void _bgTracking() async {
    bool? trackingDisabled = await UserManager.getTracking();
    if (trackingDisabled == null || !trackingDisabled) {
      // 1.  Listen to events (See docs for all 12 available events).

      // Fired whenever a location is recorded
      bg.BackgroundGeolocation.onLocation(_onLocation);

      // 2.  Configure the plugin
      await bg.BackgroundGeolocation.ready(bg.Config(
        desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH,
        distanceFilter: 0,
        stopOnTerminate: false,
        startOnBoot: true,
        debug: false,
        disableElasticity: true,
        allowIdenticalLocations: true,
        // deferTime: 17280000, // 4.8h
        locationUpdateInterval: 17280000, // 4.8h
        // logLevel: bg.Config.LOG_LEVEL_VERBOSE,
      )).then((bg.State state) {
        if (!state.enabled) {
          // 3.  Start the plugin.
          bg.BackgroundGeolocation.start().then((bg.State bgState) {
            print('[start] success - $bgState');
          });
        }
      });
    }
  }

  void _onLocation(bg.Location location) {
    Utils.location =
        LatLng(location.coords.latitude, location.coords.longitude);

    if ((location.coords.latitude).abs() <= 66.5) {
      double lat = (location.coords.latitude / Utils.maskCoordsValue).floor() *
          Utils.maskCoordsValue;
      double lon = (location.coords.longitude / Utils.maskCoordsValue).floor() *
          Utils.maskCoordsValue;

      ApiSingleton()
          .sendFixes(lat, lon, location.timestamp, location.battery.level);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.white,
              centerTitle: true,
              leading: IconButton(
                icon: Icon(
                  Icons.settings,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            SettingsPage(enableTracking: _bgTracking)),
                  );
                },
              ),
              title: Image.asset(
                'assets/img/ic_logo.png',
                height: 40,
              ),
              actions: <Widget>[
                IconButton(
                  icon: SvgPicture.asset(
                    'assets/img/sendmodule/ic_adn.svg',
                    height: 26,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => CampaignTutorialPage()),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.notifications),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => NotificationsPage()),
                    );
                  },
                )
              ],
            ),
            body: LayoutBuilder(
              builder:
                  (BuildContext context, BoxConstraints viewportConstraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: viewportConstraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Stack(
                        children: <Widget>[
                          Container(
                            alignment: Alignment.bottomCenter,
                            child: Image.asset(
                              'assets/img/bottoms/bottom_main.png',
                              width: double.infinity,
                              fit: BoxFit.fitWidth,
                              alignment: Alignment.bottomCenter,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: SingleChildScrollView(
                              child: Column(
                                children: <Widget>[
                                  SizedBox(
                                    height: 24,
                                  ),
                                  Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: <Widget>[
                                        Expanded(
                                          flex: 2,
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: <Widget>[
                                                StreamBuilder<String?>(
                                                    stream: nameStream.stream,
                                                    initialData: userName,
                                                    builder: (context,
                                                        AsyncSnapshot<String?>
                                                            snapshot) {
                                                      if (snapshot.hasData) {
                                                        print(snapshot.data);
                                                        return Style.title(
                                                            "${MyLocalizations.of(context, "welcome_text")}, ${snapshot.data}.",
                                                            fontSize: 20);
                                                      } else {
                                                        return Style.title(
                                                            "${MyLocalizations.of(context, "welcome_text")}",
                                                            fontSize: 20);
                                                      }
                                                    }),
                                                SizedBox(
                                                  height: 4,
                                                ),
                                                Style.body(
                                                    MyLocalizations.of(context,
                                                        'what_to_do_txt'),
                                                    fontSize: 14),
                                              ]),
                                        ),
                                        SizedBox(
                                          width: 12,
                                        ),
                                        InkWell(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) => InfoPage(
                                                      "${MyLocalizations.of(context, 'url_point_1')}$userUuid")),
                                            );
                                          },
                                          child: Container(
                                            height: 60,
                                            width: 60,
                                            decoration: BoxDecoration(
                                              image: DecorationImage(
                                                image: AssetImage(
                                                    'assets/img/points_box.png'),
                                              ),
                                            ),
                                            child: StreamBuilder<int?>(
                                                stream: Utils
                                                    .userScoresController
                                                    .stream,
                                                initialData:
                                                    UserManager.userScore,
                                                builder: (context, snapshot) {
                                                  return Center(
                                                      child: AutoSizeText(
                                                    snapshot.data != null &&
                                                            snapshot.hasData
                                                        ? snapshot.data
                                                            .toString()
                                                        : '',
                                                    maxLines: 1,
                                                    maxFontSize: 26,
                                                    minFontSize: 16,
                                                    style: TextStyle(
                                                        color:
                                                            Color(0xFF4B3D04),
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        fontSize: 24),
                                                  ));
                                                }),
                                          ),
                                        ),
                                      ]),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 6.0),
                                    child: Divider(),
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: <Widget>[
                                      GestureDetector(
                                        onTap: () {
                                          loadingStream.add(true);
                                          _createBiteReport();
                                        },
                                        child: Container(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.45,
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.5,
                                          child: CustomCard(
                                            img:
                                                'assets/img/ic_bite_report.png',
                                            title: MyLocalizations.of(
                                                context, 'report_biting_txt'),
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          loadingStream.add(true);
                                          _createAdultReport();
                                        },
                                        child: Container(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.45,
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.5,
                                          child: CustomCard(
                                            img:
                                                'assets/img/ic_mosquito_report.png',
                                            title: MyLocalizations.of(
                                                context, 'report_adults_txt'),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    height: 5,
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: <Widget>[
                                      Container(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.45,
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.5,
                                          child: GestureDetector(
                                            onTap: () {
                                              loadingStream.add(true);
                                              _createSiteReport();
                                            },
                                            child: CustomCard(
                                              img:
                                                  'assets/img/ic_breeding_report.png',
                                              title: MyLocalizations.of(
                                                  context, 'report_nest_txt'),
                                            ),
                                          )),
                                      Container(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.45,
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.5,
                                          child: GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        MyReportsPage()),
                                              );
                                            },
                                            child: CustomCard(
                                              img:
                                                  'assets/img/ic_my_reports.png',
                                              title: MyLocalizations.of(
                                                  context, 'your_reports_txt'),
                                            ),
                                          )),
                                    ],
                                  ),
                                  SizedBox(
                                    height: 10,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            )),
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

  _createBiteReport() async {
    bool createReport = await Utils.createNewReport('bite');
    loadingStream.add(false);
    if (createReport) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => BitingReportPage()),
      );
    } else {
      print('Bite report was not created');
      loadingStream.add(false);
      await Utils.showAlert(MyLocalizations.of(context, 'app_name'),
          MyLocalizations.of(context, 'server_down'), context);
    }
  }

  _createAdultReport() async {
    bool createReport = await Utils.createNewReport('adult');
    loadingStream.add(false);
    if (createReport) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AdultReportPage()),
      );
    } else {
      print('Adult report was not created');
      loadingStream.add(false);
      await Utils.showAlert(MyLocalizations.of(context, 'app_name'),
          MyLocalizations.of(context, 'server_down'), context);
    }
  }

  _createSiteReport() async {
    bool createReport = await Utils.createNewReport('site');
    loadingStream.add(false);
    if (createReport) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => BreedingReportPage()),
      );
    } else {
      print('Site report was not created');
      loadingStream.add(false);
      await Utils.showAlert(MyLocalizations.of(context, 'app_name'),
          MyLocalizations.of(context, 'server_down'), context);
    }
  }
}
