import 'dart:async';

import 'package:connectivity/connectivity.dart';
import 'package:firebase_core/firebase_core.dart';
//import 'package:connectivity_widget/connectivity_widget.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:mosquito_alert_app/pages/main/main_vc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mosquito_alert_app/utils/Application.dart';
import 'package:mosquito_alert_app/utils/MessageNotification.dart';
import 'package:mosquito_alert_app/utils/MyLocalizationsDelegate.dart';
import 'package:mosquito_alert_app/utils/UserManager.dart';
import 'package:mosquito_alert_app/utils/Utils.dart';
import 'package:mosquito_alert_app/utils/version_control.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'utils/MyLocalizations.dart';

final GlobalKey<NavigatorState> navigatorKey = new GlobalKey<NavigatorState>();


main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (err) {
    print("$err");
  }
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();

  static void setLocale(BuildContext context) {}
}

class _MyAppState extends State<MyApp> {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

  StreamSubscription<ConnectivityResult> subscription;

  MyLocalizationsDelegate _newLocaleDelegate = MyLocalizationsDelegate();

  @override
  void initState() {
    super.initState();

    //backgroud sync reports
    subscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {
      switch (result) {
        case ConnectivityResult.mobile:
        case ConnectivityResult.wifi:
          Utils.syncReports();
          break;
        case ConnectivityResult.none:
          break;
      }
    });
    application.onLocaleChanged = onLocaleChange;
  }



  void onLocaleChange(Locale locale) {
    setState(() {
      _newLocaleDelegate = MyLocalizationsDelegate(newLocale: locale);
    });
  }

  @override
  dispose() {
    super.dispose();
    subscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return OverlaySupport(child: MaterialApp(
      title: 'Mosquito alert',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      navigatorKey: navigatorKey,
      home: MainVC(),
      localizationsDelegates: [
        _newLocaleDelegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: application.supportedLocales(),
    ));
  }
}
