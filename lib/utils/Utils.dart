import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:mosquito_alert_app/api/api.dart';
import 'package:mosquito_alert_app/app_config.dart';
import 'package:mosquito_alert_app/models/question.dart';
import 'package:mosquito_alert_app/models/report.dart';
import 'package:mosquito_alert_app/providers/user_provider.dart';
import 'package:mosquito_alert_app/utils/UserManager.dart';
import 'package:mosquito_alert_app/utils/style.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:random_string/random_string.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import 'MyLocalizations.dart';

class Utils {
  static Locale language = Locale('en', 'US');
  static List<Map>? imagePath;
  static double maskCoordsValue = 0.025;

  //Manage Data
  static LatLng? location;
  static LatLng defaultLocation = LatLng(0, 0);

  //REPORTS
  static Report? report;
  static List<Report?>? reportsList;
  static Report? savedAdultReport;

  static void saveImgPath(File img) {
    imagePath ??= [];
    imagePath!
        .add({'image': img.path, 'id': report!.version_UUID, 'imageFile': img});
  }

  static void deleteImage(String? image) {
    imagePath!.removeWhere((element) => element['image'] == image);
  }

  static Future<bool> createNewReport(
    String type, {
    double? lat,
    double? lon,
    String? locationType,
    required BuildContext context,
  }) async {
    var lang = await UserManager.getLanguage();
    final userUUID =
        Provider.of<UserProvider>(context, listen: false).user?.uuid;
    report = Report(
        type: type,
        report_id: randomAlphaNumeric(4).toString(),
        version_number: 0,
        version_UUID: Uuid().v4(),
        user: userUUID,
        responses: []);

    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    report!.package_name = packageInfo.packageName;
    report!.package_version = 34;

    if (Platform.isAndroid) {
      var buildData = await DeviceInfoPlugin().androidInfo;
      report!.device_manufacturer = buildData.manufacturer;
      report!.device_model = buildData.model;
      report!.os = 'Android';
      report!.os_language = language.languageCode;
      report!.os_version = buildData.version.sdkInt.toString();
      report!.app_language = lang ?? language.languageCode;
    } else if (Platform.isIOS) {
      var buildData = await DeviceInfoPlugin().iosInfo;
      report!.device_manufacturer = 'Apple';
      report!.device_model = buildData.model;
      report!.os = buildData.systemName;
      report!.os_language = language.languageCode;
      report!.os_version = buildData.systemVersion;
      report!.app_language = lang ?? language.languageCode;
    }

    if (lat != null && lon != null) {
      if (locationType == 'selected') {
        report!.location_choice = 'selected';
        report!.selected_location_lat = lat;
        report!.selected_location_lon = lon;
      } else {
        report!.location_choice = 'current';
        report!.current_location_lat = lat;
        report!.current_location_lon = lon;
      }
    }
    return true;
  }

  static void resetReport() {
    report = null;
    reportsList = null;
  }

  static void setEditReport(Report editReport) {
    resetReport();
    report = editReport;
    report!.version_number = report!.version_number! + 1;
    report!.version_UUID = Uuid().v4();

    if (editReport.photos != null || editReport.photos!.isNotEmpty) {
      imagePath = [];
      editReport.photos!.forEach((element) {
        imagePath!.add({
          'image': '${ApiSingleton.baseUrl}/media/${element.photo}',
          'id': editReport.version_UUID
        });
      });
    }
  }

  static void addOtherReport(String type, BuildContext context) {
    report!.version_time = DateTime.now().toUtc().toIso8601String();
    report!.creation_time = DateTime.now().toUtc().toIso8601String();

    reportsList!.add(report);
    report = null;
    if (reportsList!.last!.location_choice == 'selected') {
      createNewReport(type,
          lat: reportsList!.last!.selected_location_lat,
          lon: reportsList!.last!.selected_location_lon,
          locationType: 'selected',
          context: context);
    } else {
      createNewReport(type,
          lat: reportsList!.last!.current_location_lat,
          lon: reportsList!.last!.current_location_lon,
          locationType: 'current',
          context: context);
    }
  }

  static Future<void> deleteLastReport() async {
    report = null;
    report = await Report.fromJsonAsync(reportsList!.last!.toJson());
    reportsList!.removeLast();
    print('${jsonEncode(reportsList)}');
    // print(reportsList);
  }

  static void setCurrentLocation(double latitude, double longitude) {
    report!.location_choice = 'current';
    report!.selected_location_lat = null;
    report!.selected_location_lon = null;
    report!.current_location_lat = latitude;
    report!.current_location_lon = longitude;
  }

  static void setSelectedLocation(double? lat, lon) {
    report!.location_choice = 'selected';
    report!.current_location_lat = null;
    report!.current_location_lon = null;
    report!.selected_location_lat = lat;
    report!.selected_location_lon = lon;
  }

  static void addBiteResponse(String? question, String? answer,
      {question_id, answer_id, answer_value}) {
    if (report == null) {
      return;
    }

    var _questions = report!.responses;

    // add total bites

    if (question_id == 1) {
      var currentIndex = _questions!
          .indexWhere((question) => question!.question_id == question_id);
      if (currentIndex == -1) {
        _questions.add(Question(
          question: question.toString(),
          answer: 'N/A',
          answer_id: answer_id,
          question_id: question_id,
          answer_value: '1',
        ));
      } else {
        _questions[currentIndex]!.answer_value = answer_value.toString();
      }
    }

    //increase answer_value question 2
    if (question_id == 2) {
      var currentIndex = _questions!
          .indexWhere((question) => question!.answer_id == answer_id);
      if (currentIndex == -1) {
        _questions.add(Question(
          question: question.toString(),
          answer: answer.toString(),
          answer_id: answer_id,
          question_id: question_id,
          answer_value: '1',
        ));
      } else {
        var value = int.parse(_questions[currentIndex]!.answer_value!);
        value = value + 1;
        _questions[currentIndex]!.answer_value = value.toString();
      }
    }

    //add other questions without answer_value
    if (question_id != 2 && question_id != 1) {
      if (_questions!.any((q) => q!.answer_id == answer_id)) {
        // delete question from list
        _questions.removeWhere((q) => q!.answer_id == answer_id);
      } else {
        if (_questions.any(
            (q) => q!.question_id == question_id && q.answer_id != answer_id)) {
          //modify question
          var index =
              _questions.indexWhere((q) => q!.question_id == question_id);
          _questions[index]!.answer_id = answer_id;
          _questions[index]!.answer = answer;
        } else {
          _questions.add(Question(
            question: question.toString(),
            answer: answer.toString(),
            answer_id: answer_id,
            question_id: question_id,
          ));
        }
      }
    }

    if (answer_id == 131) {
      _questions!.removeWhere((q) => q!.question_id == 3);
    }
    report!.responses = _questions;
  }

  static void resetBitingQuestion() {
    var _questions = report!.responses!;

    _questions.removeWhere((q) => q!.question_id == 2);

    report!.responses = _questions;
  }

  static void addAdultPartsResponse(answer, answerId, i) {
    var _questions = report!.responses!;
    var index = _questions
        .indexWhere((q) => q!.answer_id! > i && q.answer_id! < i + 10);
    if (index != -1) {
      if (_questions[index]!.answer_id == answerId) {
        _questions.removeAt(index);
      } else {
        _questions[index]!.answer_id = answerId;
        _questions[index]!.answer = answer;
      }
    } else {
      var newQuestion = Question(
        question: 'question_7',
        answer: answer,
        question_id: 7,
        answer_id: answerId,
      );
      _questions.add(newQuestion);
    }
    report!.responses = _questions;
  }

  static void addResponse(Question? question) {
    var index = report!.responses!
        .indexWhere((q) => q!.question_id == question!.question_id);
    var _responses = report!.responses;
    _responses ??= [];
    if (index != -1) {
      _responses[index] = question;
    } else {
      _responses.add(question);
      report!.responses = _responses;
    }
  }

  static void deleteResonse(id) {
    report!.responses!.removeWhere((element) => element!.question_id == id);
  }

  static Future<bool?> createReport() async {
    if (report!.version_number! > 0) {
      report!.version_time = DateTime.now().toUtc().toIso8601String();
      var res = await ApiSingleton().createReport(report!);
      if (res != null) {
        if (res.type == 'adult') {
          savedAdultReport = res;
        }
        return true;
      } else {
        return false;
      }
    } else {
      report!.version_time = DateTime.now().toUtc().toIso8601String();
      report!.creation_time = DateTime.now().toUtc().toIso8601String();
      reportsList!.add(report);
      bool? isCreated;
      for (var i = 0; i < reportsList!.length; i++) {
        var res = await ApiSingleton().createReport(reportsList![i]!);
        if (res?.type == 'adult') {
          savedAdultReport = res;
        }
        isCreated = res != null ? true : false;
        if (!isCreated) {
          await saveLocalReport(reportsList![i]!);
        }
      }

      return isCreated;
    }
  }

  static Future<void> saveLocalReport(Report report) async {
    var savedReports = await UserManager.getReportList();
    if (savedReports == null || savedReports.isEmpty) {
      savedReports = [];
    }
    var reportString = json.encode(report.toJson());
    savedReports.add(reportString);
    await UserManager.setReportList(savedReports);
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

  static void syncReports() async {
    final appConfig = await AppConfig.loadConfig();
    if (!appConfig.useAuth) {
      return;
    }

    List? savedReports = await UserManager.getReportList();
    List? savedImages = await UserManager.getImageList();

    await UserManager.setReportList(<String>[]);
    await UserManager.setImageList(<String>[]);

    if (savedReports != null && savedReports.isNotEmpty) {
      bool isCreated;
      for (var i = 0; i < savedReports.length; i++) {
        var savedReport =
            await Report.fromJsonAsync(json.decode(savedReports[i]));
        isCreated = await ApiSingleton().createReport(savedReport) != null
            ? true
            : false;

        if (!isCreated) {
          await saveLocalReport(savedReport);
        }
      }
    }

    if (savedImages != null && savedImages.isNotEmpty) {
      bool isCreated;
      for (var i = 0; i < savedImages.length; i++) {
        Map image = json.decode(savedImages[i]);
        isCreated = await ApiSingleton()
            .saveImage(image['image'], image['verison_UUID']);
        if (!isCreated) {
          await saveLocalImage(image['image'], image['verison_UUID']);
        } else {
          await File(image['image']).delete();
        }
      }
    }
  }

  static Future<bool> deleteReport(r) async {
    Report deleteReport = r;
    deleteReport.version_time = DateTime.now().toUtc().toIso8601String();
    deleteReport.version_number = -1;
    deleteReport.version_UUID = Uuid().v4();

    var res =
        await ApiSingleton().createReport(deleteReport) != null ? true : false;
    return res;
  }

  static final RegExp mailRegExp = RegExp(
      r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$');

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

  static Future showAlertCampaign(ctx, activeCampaign, onPressed) {
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
                  Utils.resetReport();
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
                  Utils.resetReport();
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

  static void requestInAppReview() async {
    var myReports = await ApiSingleton().getReportsList();
    var numReports = myReports.length;

    if (numReports < 3) {
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final lastReportCount = await UserManager.getLastReportCount() ?? 0;
    final lastReviewRequest = await UserManager.getLastReviewRequest() ?? 0;

    var shouldRequestReview = (numReports == 3 ||
        numReports == 4 ||
        numReports >= lastReportCount + 3 ||
        now - lastReviewRequest >= 14 * 24 * 60 * 60 * 1000);

    if (!shouldRequestReview) {
      return;
    }

    final inAppReview = InAppReview.instance;

    if (await inAppReview.isAvailable()) {
      await inAppReview.requestReview();

      await UserManager.setLastReviewRequest(now);
      await UserManager.setLastReportCount(numReports);
    }
  }

  static String getRandomPassword(int length) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*';
    final rand = Random.secure();
    return List.generate(length, (index) => chars[rand.nextInt(chars.length)])
        .join();
  }
}
