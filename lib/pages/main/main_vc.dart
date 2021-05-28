import 'dart:async';
import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geolocator/geolocator.dart';
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
import 'package:mosquito_alert_app/utils/PushNotificationsManager.dart';
import 'package:mosquito_alert_app/utils/UserManager.dart';
import 'package:mosquito_alert_app/utils/Utils.dart';
import 'package:mosquito_alert_app/utils/style.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;
//import 'package:connectivity_widget/connectivity_widget.dart';

class MainVC extends StatefulWidget {
  @override
  _MainVCState createState() => _MainVCState();
}

class _MainVCState extends State<MainVC> {
  String userName;

  StreamController<String> nameStream =
      new StreamController<String>.broadcast();
  String userUuid;
  StreamController<bool> loadingStream = new StreamController<bool>.broadcast();

  @override
  void initState() {
    super.initState();
    _getData();
    loadingStream.add(true);
  }

  _getData() async {
    await UserManager.startFirstTime(context);
    var user = await UserManager.fetchUser();
    userUuid = await UserManager.getUUID();
    await ApiSingleton().getUserScores();
    await _loadFirebase();

    if (user != null) {
      nameStream.add(user.email);
      setState(() {
        userName = UserManager.user.email;
      });
    }

    if (Platform.isAndroid) {
      _bgTracking();
    }

    loadingStream.add(false);
  }

  _loadFirebase() async {
    print('Load Firebase');
    await PushNotificationsManager.init();
    // PushNotificationsManager.subscribeToGlobal();
    PushNotificationsManager.subscribeToLanguage();
  }

  _bgTracking() async {
    bool trackingDisabled = await UserManager.getTracking();
    if (trackingDisabled == null || !trackingDisabled) {
      // 1.  Listen to events (See docs for all 12 available events).

      // Fired whenever a location is recorded
      bg.BackgroundGeolocation.onLocation(_onLocation);

      // 2.  Configure the plugin
      bg.BackgroundGeolocation.ready(bg.Config(
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
            print('[start] success - ${bgState}');
          });
        }
      });
    }
  }

  void _onLocation(bg.Location location) {
    Utils.location = Position(
        latitude: location.coords.latitude,
        longitude: location.coords.longitude);

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
                    "assets/img/sendmodule/ic_adn.svg",
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
                        // alignment: Alignment.bottomCenter,
                        // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Container(
                            alignment: Alignment.bottomCenter,
                            // margin: EdgeInsets.only(top: 20),
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
                                                StreamBuilder<String>(
                                                    stream: nameStream.stream,
                                                    initialData: userName,
                                                    builder: (context,
                                                        AsyncSnapshot<String>
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
                                                        "what_to_do_txt"),
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
                                                    "assets/img/points_box.png"),
                                              ),
                                            ),
                                            child: StreamBuilder<int>(
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
                                      // SizedBox(
                                      //   width: 5,
                                      // ),
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
                                  // Card(
                                  //   elevation: 2,
                                  //   shape: RoundedRectangleBorder(
                                  //       borderRadius: BorderRadius.circular(20)),
                                  //   child: Container(
                                  //     padding: EdgeInsets.only(left: 20, right: 10, top: 15, bottom: 15),
                                  //     child: Row(
                                  //       children: <Widget>[
                                  //         Image.asset(
                                  //           'assets/img/ic_validate_photos.png',
                                  //           width: 55,
                                  //           fit: BoxFit.fitWidth,
                                  //         ),
                                  //         SizedBox(width: 15,),
                                  //         Expanded(
                                  //           flex: 2,
                                  //           child: Column(
                                  //             children: <Widget>[
                                  //               Style.titleMedium(
                                  //                   MyLocalizations.of(context,
                                  //                       'help_validating_other_photos_txt'),
                                  //                   fontSize: 16),
                                  //               SizedBox(
                                  //                 height: 5,
                                  //               ),
                                  //               Style.bodySmall(MyLocalizations.of(
                                  //                   context, 'we_need_help_txt')),
                                  //               SizedBox(
                                  //                 height: 5,
                                  //               ),
                                  //             ],
                                  //           ),
                                  //         )
                                  //       ],
                                  //     ),
                                  //   ),
                                  // ),
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
            ) /*ConnectivityWidget(
                offlineBanner: SafeArea(
                  child: Container(
                      padding: EdgeInsets.all(8),
                      margin: EdgeInsets.all(8),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(4),  color: Colors.red.withOpacity(0.95),),
                      width: double.infinity,

                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.wifi_off,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(
                                width: 12,
                              ),
                              Text(
                                "no_internet_connection",
                                style: TextStyle(fontSize: 14, color: Colors.white),
                                textAlign: TextAlign.center,
                              )
                            ],
                          ),
                          SizedBox(
                            height: 4,
                          ),
                          Text(
                            "app_may_not_work_as_expected",
                            style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.9)),
                            textAlign: TextAlign.center,
                          )
                        ],
                      )),
                ),
                onlineCallback: () {
                  print('test');
                },
                builder: (context, isOnline) => LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints viewportConstraints) {
                        return SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: viewportConstraints.maxHeight,
                            ),
                            child: IntrinsicHeight(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 12),
                                    child: Column(
                                      children: <Widget>[
                                        SizedBox(
                                          height: 24,
                                        ),
                                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
                                          Expanded(
                                            flex: 2,
                                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                                              StreamBuilder<String>(
                                                  stream: nameStream.stream,
                                                  initialData: userName,
                                                  builder: (context, AsyncSnapshot<String> snapshot) {
                                                    if (snapshot.hasData) {
                                                      print(snapshot.data);
                                                      return Style.title("${MyLocalizations.of(context, "welcome_text")}, ${snapshot.data}.", fontSize: 20);
                                                    } else {
                                                      return Style.title("${MyLocalizations.of(context, "welcome_text")}", fontSize: 20);
                                                    }
                                                  }),
                                              SizedBox(
                                                height: 4,
                                              ),
                                              Style.body(MyLocalizations.of(context, "what_to_do_txt"), fontSize: 14),
                                            ]),
                                          ),
                                          SizedBox(
                                            width: 12,
                                          ),
                                          InkWell(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(builder: (context) => InfoPage("${MyLocalizations.of(context, 'url_point_1')}$userUuid")),
                                              );
                                            },
                                            child: Container(
                                              height: 60,
                                              width: 60,
                                              decoration: BoxDecoration(
                                                image: DecorationImage(
                                                  image: AssetImage("assets/img/points_box.png"),
                                                ),
                                              ),
                                              child: StreamBuilder<int>(
                                                  stream: Utils.userScoresController.stream,
                                                  initialData: UserManager.userScore,
                                                  builder: (context, snapshot) {
                                                    return Center(
                                                        child: AutoSizeText(
                                                      snapshot.data != null && snapshot.hasData ? snapshot.data.toString() : '',
                                                      maxLines: 1,
                                                      maxFontSize: 26,
                                                      minFontSize: 16,
                                                      style: TextStyle(color: Color(0xFF4B3D04), fontWeight: FontWeight.w500, fontSize: 24),
                                                    ));
                                                  }),
                                            ),
                                          ),
                                        ]),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                                          child: Divider(),
                                        ),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                                          children: <Widget>[
                                            GestureDetector(
                                              onTap: () {
                                                loadingStream.add(true);
                                                _createBiteReport();
                                              },
                                              child: Container(
                                                width: MediaQuery.of(context).size.width * 0.45,
                                                height: MediaQuery.of(context).size.width * 0.5,
                                                child: CustomCard(
                                                  img: 'assets/img/ic_bite_report.png',
                                                  title: MyLocalizations.of(context, 'report_biting_txt'),
                                                ),
                                              ),
                                            ),
                                            // SizedBox(
                                            //   width: 5,
                                            // ),
                                            GestureDetector(
                                              onTap: () {
                                                loadingStream.add(true);
                                                _createAdultReport();
                                              },
                                              child: Container(
                                                width: MediaQuery.of(context).size.width * 0.45,
                                                height: MediaQuery.of(context).size.width * 0.5,
                                                child: CustomCard(
                                                  img: 'assets/img/ic_mosquito_report.png',
                                                  title: MyLocalizations.of(context, 'report_adults_txt'),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(
                                          height: 5,
                                        ),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                                          children: <Widget>[
                                            Container(
                                                width: MediaQuery.of(context).size.width * 0.45,
                                                height: MediaQuery.of(context).size.width * 0.5,
                                                child: GestureDetector(
                                                  onTap: () {
                                                    loadingStream.add(true);
                                                    _createSiteReport();
                                                  },
                                                  child: CustomCard(
                                                    img: 'assets/img/ic_breeding_report.png',
                                                    title: MyLocalizations.of(context, 'report_nest_txt'),
                                                  ),
                                                )),
                                            Container(
                                                width: MediaQuery.of(context).size.width * 0.45,
                                                height: MediaQuery.of(context).size.width * 0.5,
                                                child: GestureDetector(
                                                  onTap: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(builder: (context) => MyReportsPage()),
                                                    );
                                                  },
                                                  child: CustomCard(
                                                    img: 'assets/img/ic_my_reports.png',
                                                    title: MyLocalizations.of(context, 'your_reports_txt'),
                                                  ),
                                                )),
                                          ],
                                        ),
                                        SizedBox(
                                          height: 10,
                                        ),
                                        // Card(
                                        //   elevation: 2,
                                        //   shape: RoundedRectangleBorder(
                                        //       borderRadius: BorderRadius.circular(20)),
                                        //   child: Container(
                                        //     padding: EdgeInsets.only(left: 20, right: 10, top: 15, bottom: 15),
                                        //     child: Row(
                                        //       children: <Widget>[
                                        //         Image.asset(
                                        //           'assets/img/ic_validate_photos.png',
                                        //           width: 55,
                                        //           fit: BoxFit.fitWidth,
                                        //         ),
                                        //         SizedBox(width: 15,),
                                        //         Expanded(
                                        //           flex: 2,
                                        //           child: Column(
                                        //             children: <Widget>[
                                        //               Style.titleMedium(
                                        //                   MyLocalizations.of(context,
                                        //                       'help_validating_other_photos_txt'),
                                        //                   fontSize: 16),
                                        //               SizedBox(
                                        //                 height: 5,
                                        //               ),
                                        //               Style.bodySmall(MyLocalizations.of(
                                        //                   context, 'we_need_help_txt')),
                                        //               SizedBox(
                                        //                 height: 5,
                                        //               ),
                                        //             ],
                                        //           ),
                                        //         )
                                        //       ],
                                        //     ),
                                        //   ),
                                        // ),
                                      ],
                                    ),
                                  ),
                                  Flexible(
                                    child: Container(
                                      margin: EdgeInsets.only(top: 25),
                                      child: SvgPicture.asset(
                                        'assets/img/ic_bottom_waves.svg',
                                        width: double.infinity,
                                        fit: BoxFit.fitWidth,
                                        alignment: Alignment.bottomCenter,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ))*/
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

  _createBiteReport() async {
    bool createReport = await Utils.createNewReport('bite');
    loadingStream.add(false);
    if (createReport) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => BitingReportPage()),
      );
    } else {
      Utils.showAlert(MyLocalizations.of(context, 'app_name'),
          MyLocalizations.of(context, 'save_report_ko_txt'), context);
    }
  }

  _createAdultReport() async {
    bool createReport = await Utils.createNewReport('adult');
    loadingStream.add(false);
    if (createReport) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AdultReportPage()),
      );
    } else {
      Utils.showAlert(MyLocalizations.of(context, 'app_name'),
          MyLocalizations.of(context, 'save_report_ko_txt'), context);
    }
  }

  _createSiteReport() async {
    bool createReport = await Utils.createNewReport('site');
    loadingStream.add(false);
    if (createReport) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => BreedingReportPage()),
      );
    } else {
      Utils.showAlert(MyLocalizations.of(context, 'app_name'),
          MyLocalizations.of(context, 'save_report_ko_txt'), context);
    }
  }
}
