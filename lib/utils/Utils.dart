import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mosquito_alert_app/utils/UserManager.dart';
import 'package:mosquito_alert_app/utils/style.dart';
import 'package:url_launcher/url_launcher.dart';

import 'MyLocalizations.dart';

class Utils {
  static Locale language = Locale('en', 'US');
  static List<Map>? imagePath;
  static double maskCoordsValue = 0.025;

  //Manage Data
  static LatLng? location;
  static LatLng defaultLocation = LatLng(0, 0);

  static void deleteImage(String? image) {
    imagePath!.removeWhere((element) => element['image'] == image);
  }

  static Future<void> saveLocalImage(
      String? image, String? version_UUID) async {
    var savedImages = await UserManager.getImageList();
    if (savedImages == null || savedImages.isEmpty) {
      savedImages = [];
    }

    var imageString =
        json.encode({'image': image, 'verison_UUID': version_UUID});
    savedImages.add(imageString);
    await UserManager.setImageList(savedImages);
  }

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

  static Future? modalDetailTrackingforPlatform(List<Widget> list,
      TargetPlatform platform, BuildContext context, Function close,
      {title, cancelButton}) {
    if (platform == TargetPlatform.iOS) {
      return showCupertinoModalPopup(
          context: context,
          builder: (context) {
            return CupertinoActionSheet(
                title: title != null ? Text(title) : null,
                cancelButton: cancelButton ??
                    CupertinoActionSheetAction(
                      onPressed: close as void Function(),
                      child: Text(
                        MyLocalizations.of(context, 'cancel'),
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                actions: list);
          });
    } else if (platform == TargetPlatform.android) {
      showModalBottomSheet(
          context: context,
          builder: (context) {
            return BottomSheet(
              builder: (BuildContext context) {
                return SafeArea(
                    child: Container(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      title != null
                          ? Container(
                              width: double.infinity,
                              padding: EdgeInsets.only(
                                  top: 20, left: 20, right: 20, bottom: 0),
                              child: Text(title,
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w400)),
                            )
                          : Container(),
                      Wrap(children: list),
                    ],
                  ),
                ));
              },
              onClosing: close as void Function(),
            );
          });
    }
    return null;
  }

  static Widget authBottomInfo(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: 15, left: 15, right: 15),
        child: Wrap(
          alignment: WrapAlignment.center,
          children: <Widget>[
            Text('${MyLocalizations.of(context, 'terms_and_conditions_txt1')} ',
                style: TextStyle(color: Style.textColor, fontSize: 12)),
            InkWell(
              onTap: () async {
                Uri url =
                    Uri.parse(MyLocalizations.of(context, 'url_politics'));
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                } else {
                  throw 'Could not launch $url';
                }
              },
              child: Text(
                  MyLocalizations.of(context, 'terms_and_conditions_txt2'),
                  style: TextStyle(
                      color: Style.textColor,
                      fontSize: 12,
                      decoration: TextDecoration.underline)),
            ),
            Text(
                ' ${MyLocalizations.of(context, 'terms_and_conditions_txt3')} ',
                style: TextStyle(color: Style.textColor, fontSize: 12)),
            InkWell(
              onTap: () async {
                Uri url = Uri.parse(MyLocalizations.of(context, 'url_legal'));
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                } else {
                  throw 'Could not launch $url';
                }
              },
              child: Text(
                  MyLocalizations.of(context, 'terms_and_conditions_txt4'),
                  style: TextStyle(
                      color: Style.textColor,
                      fontSize: 12,
                      decoration: TextDecoration.underline)),
            ),
            Text('.', style: TextStyle(color: Style.textColor, fontSize: 12)),
          ],
        ),
      ),
    );
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

  static Future showAlertCampaign(ctx, onPressed) {
    if (Platform.isAndroid) {
      return showDialog(
        context: ctx,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              MyLocalizations.of(context, 'app_name'),
            ),
            content: SingleChildScrollView(
              child: ListBody(children: <Widget>[
                Style.body(MyLocalizations.of(context, 'save_report_ok_txt')),
                SizedBox(
                  height: 12,
                ),
                Style.title(
                    MyLocalizations.of(
                        context, 'alert_campaign_found_create_body'),
                    textAlign: TextAlign.left,
                    fontSize: 15.0,
                    height: 1.2)
              ]),
            ),
            actions: <Widget>[
              TextButton(
                  //Changed from FlatButton
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        'assets/img/sendmodule/ic_adn.svg',
                        colorFilter: ColorFilter.mode(
                            Style.colorPrimary, BlendMode.srcIn),
                        height: 20,
                      ),
                      SizedBox(
                        width: 7,
                      ),
                      Text(MyLocalizations.of(context, 'show_info'))
                    ],
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    onPressed(context);
                  }),
              TextButton(
                //Changed from FlatButton
                child: Text(MyLocalizations.of(context, 'no_show_info')),
                onPressed: () {
                  Navigator.of(context).popUntil((r) => r.isFirst);
                },
              ),
            ],
          );
        },
      );
    } else {
      return showDialog(
        context: ctx,
        builder: (BuildContext context) {
          return CupertinoAlertDialog(
            title: Text(
              MyLocalizations.of(context, 'app_name'),
              style: TextStyle(letterSpacing: -0.3),
            ),
            content: Column(
              children: <Widget>[
                SizedBox(
                  height: 4,
                ),
                Style.body(MyLocalizations.of(context, 'save_report_ok_txt'),
                    textAlign: TextAlign.center),
                SizedBox(
                  height: 12,
                ),
                Style.title(
                    MyLocalizations.of(
                        context, 'alert_campaign_found_create_body'),
                    textAlign: TextAlign.center,
                    fontSize: 15.0,
                    height: 1.2)
              ],
            ),
            actions: <Widget>[
              CupertinoDialogAction(
                  isDefaultAction: true,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        'assets/img/sendmodule/ic_adn.svg',
                        colorFilter: ColorFilter.mode(
                            Colors.blueAccent, BlendMode.srcIn),
                        height: 20,
                      ),
                      SizedBox(
                        width: 7,
                      ),
                      Text(MyLocalizations.of(context, 'show_info'))
                    ],
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    onPressed(context);
                  }),
              CupertinoDialogAction(
                isDefaultAction: true,
                child: Text(MyLocalizations.of(context, 'no_show_info')),
                onPressed: () {
                  Navigator.of(context).popUntil((r) => r.isFirst);
                },
              ),
            ],
          );
        },
      );
    }
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

  static String getTranslatedReportType(
      BuildContext context, String? reportType) {
    var translationString;
    switch (reportType) {
      case 'adult':
        translationString = 'single_mosquito';
        break;
      case 'bite':
        translationString = 'single_bite';
        break;
      case 'site':
        translationString = 'single_breeding_site';
        break;
      default:
        print('Unhandled report type: $reportType');
        return reportType ?? '';
    }

    return MyLocalizations.of(context, translationString);
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
