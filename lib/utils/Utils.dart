import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:mosquito_alert_app/utils/UserManager.dart';
import 'package:mosquito_alert_app/utils/style.dart';

import 'MyLocalizations.dart';

class Utils {
  static Locale language = Locale('en', 'US');

  //Alerts
  static Future showAlert(String? title, String? text, BuildContext? context,
      {onPressed, barrierDismissible}) {
    if (Platform.isAndroid) {
      return showDialog(
        context: context!,
        barrierDismissible: barrierDismissible ?? true, // user must tap button!
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title!),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text(text!),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                //Changed from FlatButton
                child: Text(MyLocalizations.of(context, 'ok')),
                onPressed: () {
                  if (onPressed != null) {
                    onPressed();
                  } else {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          );
        },
      );
    } else {
      return showDialog(
        context: context!, //
        builder: (BuildContext context) {
          return CupertinoAlertDialog(
            title: Text(
              title!,
              style: TextStyle(letterSpacing: -0.3),
            ),
            content: Column(
              children: <Widget>[
                SizedBox(
                  height: 4,
                ),
                Text(
                  text!,
                  style: TextStyle(height: 1.2),
                )
              ],
            ),
            actions: <Widget>[
              CupertinoDialogAction(
                isDefaultAction: true,
                child: Text(MyLocalizations.of(context, 'ok')),
                onPressed: () {
                  if (onPressed != null) {
                    onPressed();
                  } else {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          );
        },
      );
    }
  }

  static Future showCustomAlert(
      String? title, Widget body, BuildContext context,
      {onPressed, barrierDismissible}) {
    if (Platform.isAndroid) {
      return showDialog(
        context: context,
        barrierDismissible: barrierDismissible ?? true, // user must tap button!
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title!),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  body,
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                //Changed from FlatButton
                child: Text(MyLocalizations.of(context, 'ok')),
                onPressed: () {
                  if (onPressed != null) {
                    onPressed();
                  } else {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          );
        },
      );
    } else {
      return showDialog(
        context: context, //
        builder: (BuildContext context) {
          return CupertinoAlertDialog(
            title: Text(
              title!,
              style: TextStyle(letterSpacing: -0.3),
            ),
            content: Column(
              children: <Widget>[
                SizedBox(
                  height: 4,
                ),
                body,
              ],
            ),
            actions: <Widget>[
              CupertinoDialogAction(
                isDefaultAction: true,
                child: Text(MyLocalizations.of(context, 'ok')),
                onPressed: () {
                  if (onPressed != null) {
                    onPressed();
                  } else {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          );
        },
      );
    }
  }

  static Future showAlertYesNo(
    String? title,
    String? text,
    onYesPressed,
    BuildContext context,
  ) {
    if (Platform.isAndroid) {
      return showDialog(
        context: context, // user must tap button!
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title!),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text(text!),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text(MyLocalizations.of(context, 'yes')),
                onPressed: () {
                  Navigator.of(context).pop();
                  onYesPressed();
                },
              ),
              TextButton(
                child: Text(MyLocalizations.of(context, 'no')),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } else {
      return showDialog(
        context: context, //
        builder: (BuildContext context) {
          return CupertinoAlertDialog(
            title: Text(title!),
            content: Column(
              children: <Widget>[
                SizedBox(
                  height: 4,
                ),
                Text(
                  text!,
                )
              ],
            ),
            actions: <Widget>[
              CupertinoDialogAction(
                isDefaultAction: true,
                child: Text(MyLocalizations.of(context, 'yes')),
                onPressed: () {
                  onYesPressed();
                  Navigator.of(context).pop();
                },
              ),
              CupertinoDialogAction(
                child: Text(MyLocalizations.of(context, 'no')),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  static Widget loading(_isLoading, [Color? indicatorColor]) {
    return _isLoading == true
        ? IgnorePointer(
            child: Container(
            color: Colors.transparent,
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                    indicatorColor ?? Style.colorPrimary),
              ),
            ),
          ))
        : Container();
  }

  static ui.Locale getLanguage() {
    var stringLanguange =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    var stringCountry =
        WidgetsBinding.instance.platformDispatcher.locale.countryCode;

    language = Locale('en', 'US');

    if (stringLanguange == 'es' && stringCountry == 'ES' ||
        stringLanguange == 'ca' && stringCountry == 'ES' ||
        stringLanguange == 'en' && stringCountry == 'US' ||
        stringLanguange == 'sq' ||
        stringLanguange == 'bg' ||
        stringLanguange == 'nl' ||
        stringLanguange == 'de' ||
        stringLanguange == 'it' ||
        stringLanguange == 'pt' ||
        stringLanguange == 'ro') {
      language = WidgetsBinding.instance.platformDispatcher.locale;
    }

    return language;
  }

  static Future<String?> getCityNameFromCoords(double lat, double lon) async {
    var locale = await UserManager.getUserLocale();
    await setLocaleIdentifier(locale!);
    var placemarks = await placemarkFromCoordinates(lat, lon);
    if (placemarks.isEmpty) {
      return null;
    }
    return placemarks.first.locality;
  }

  static String getRandomPassword(int length) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*';
    final rand = Random.secure();
    return List.generate(length, (index) => chars[rand.nextInt(chars.length)])
        .join();
  }
}
