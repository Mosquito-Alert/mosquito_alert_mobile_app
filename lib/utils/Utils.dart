import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:mosquito_alert_app/api/api.dart';
import 'package:mosquito_alert_app/models/question.dart';
import 'package:mosquito_alert_app/models/report.dart';
import 'package:mosquito_alert_app/models/response.dart';
import 'package:mosquito_alert_app/models/session.dart';
import 'package:mosquito_alert_app/utils/PushNotificationsManager.dart';
import 'package:mosquito_alert_app/utils/UserManager.dart';
import 'package:mosquito_alert_app/utils/style.dart';
import 'package:package_info/package_info.dart';
import 'package:random_string/random_string.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  static StreamController<int?> userScoresController =
      StreamController<int?>.broadcast();

  //REPORTS
  static Report? report;
  static Session? session;
  static List<Report?>? reportsList;
  static Report? savedAdultReport;

  // Initialized data flags
  static Map<String, dynamic> initializedCheckData = {
    'user': false, // Whether the user got fetched
    'userScores': false, // Whether the user scores got fetched
    'userCreated': {
      'created': false,
      'required': false,
    },
    'firebase': false, // Whether firebase got initialized
  };

  static void saveImgPath(File img) {
    imagePath ??= [];
    imagePath!
        .add({'image': img.path, 'id': report!.version_UUID, 'imageFile': img});
  }

  static void deleteImage(String? image) {
    imagePath!.removeWhere((element) => element['image'] == image);
  }

  static void closeSession() {
    session!.session_end_time = DateTime.now().toUtc().toIso8601String();
    ApiSingleton().closeSession(session!);
  }

  static Future<bool> createNewReport(
    String type, {
    lat,
    lon,
    locationType,
  }) async {
    if (session == null) {
      reportsList = [];

      var userUUID = await UserManager.getUUID();

      dynamic response = await ApiSingleton().getLastSession(userUUID);
      if (response is bool && !response) {
        print('Unable to get last session.');
        return false;
      }

      if (response is ApiResponse) {
        print('response is of type ApiResponse, not a number.');
        return false;
      }

      int? sessionId = response + 1;

      session = Session(
          session_ID: sessionId,
          user: userUUID,
          session_start_time: DateTime.now().toUtc().toIso8601String());

      print(language);
      session!.id = await ApiSingleton().createSession(session!);
      // print("Session: ${jsonEncode(session.toJson())}");
    }

    if (session!.id != null) {
      var lang = await UserManager.getLanguage();
      var userUUID = await UserManager.getUUID();
      report = Report(
          type: type,
          report_id: randomAlphaNumeric(4).toString(),
          version_number: 0,
          version_UUID: Uuid().v4(),
          user: userUUID,
          session: session!.id,
          responses: []);

      var packageInfo = await PackageInfo.fromPlatform();
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

    return false;
  }

  static void resetReport() {
    report = null;
    session = null;
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

  static void addOtherReport(String type) {
    report!.version_time = DateTime.now().toUtc().toIso8601String();
    report!.creation_time = DateTime.now().toUtc().toIso8601String();

    reportsList!.add(report);
    report = null;
    if (reportsList!.last!.location_choice == 'selected') {
      createNewReport(type,
          lat: reportsList!.last!.selected_location_lat,
          lon: reportsList!.last!.selected_location_lon,
          locationType: 'selected');
    } else {
      createNewReport(type,
          lat: reportsList!.last!.current_location_lat,
          lon: reportsList!.last!.current_location_lon,
          locationType: 'current');
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

      closeSession();
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
    List? savedReports = await UserManager.getReportList();
    List? savedImages = await UserManager.getImageList();

    await UserManager.setReportList(<String>[]);
    await UserManager.setImageList(<String>[]);

    if (savedReports != null && savedReports.isNotEmpty) {
      bool isCreated;
      for (var i = 0; i < savedReports.length; i++) {
        var savedReport = await Report.fromJsonAsync(json.decode(savedReports[i]));
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

  static Future<void> checkForUnfetchedData() async {
    SharedPreferences prefs;
    // if (userCreated["required"] && !userCreated["created"]) {
    final Map<String, bool> userCreated = initializedCheckData['userCreated'];
    if (userCreated['required']! && !userCreated['created']!) {
      print('Utils (checkForUnfetchedData): Creating user...');
      prefs = await SharedPreferences.getInstance();
      final uuid = prefs.getString('uuid');
      await ApiSingleton().createUser(uuid);
    } else {
      print(
          'Utils (checkForUnfetchedData): Either the user was created or it was not required (${jsonEncode(userCreated)})');
    }

    if (!initializedCheckData['userScores']) {
      print('Utils (checkForUnfetchedData): Fetching user scores...');
      UserManager.userScore = await ApiSingleton().getUserScores();
    } else {
      print('Utils (checkForUnfetchedData): UserScores were already fetched');
    }

    if (!initializedCheckData['user']) {
      print('Utils (checkForUnfetchedData): Fetching user...');
      await UserManager.fetchUser();
    } else {
      print('Utils (checkForUnfetchedData): User was already fetched');
    }

    if (!initializedCheckData['firebase']) {
      print('Utils (checkForUnfetchedData): Loading Firebase...');
      await loadFirebase();
    } else {
      print('Utils (checkForUnfetchedData): Firebase was already initialized.');
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

  static Future<void> loadFirebase() async {
    await PushNotificationsManager.init();
    await PushNotificationsManager.subscribeToLanguage();
  }

  static getLocation(BuildContext context) async {
    await Geolocator.requestPermission();
    var currentPermission = await Geolocator.checkPermission();
    if (currentPermission == LocationPermission.denied ||
        currentPermission == LocationPermission.deniedForever ||
        currentPermission == LocationPermission.unableToDetermine) {
      await showAlertYesNo(MyLocalizations.of(context, 'app_name'),
          MyLocalizations.of(context, 'NSLocationWhenInUseUsageDescription'),
          () async {
        await Geolocator.openLocationSettings();
      }, context);
    } else {
      var pos = await Geolocator.getLastKnownPosition();
      location = LatLng(pos!.latitude, pos.longitude);
    }
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
                final url = MyLocalizations.of(context, 'url_politics');
                if (await canLaunch(url)) {
                  await launch(url);
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
                final url = MyLocalizations.of(context, 'url_legal');
                if (await canLaunch(url)) {
                  await launch(url);
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

  static Future<Future> infoAdultCamera(context, getImage,
      {bool gallery = false}) async {
    var showInfo = await UserManager.getShowInfoAdult();
    if (showInfo == null || !showInfo) {
      return showDialog(
          barrierDismissible: true,
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              contentPadding: EdgeInsets.all(0),
              backgroundColor: Colors.transparent,
              content: Container(
                padding: EdgeInsets.all(20),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.50,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  image: DecorationImage(
                      alignment: Alignment.topCenter,
                      image: AssetImage(
                        'assets/img/bg_alert_camera_adult.png',
                      ),
                      fit: BoxFit.cover),
                ),
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: double.infinity),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        SizedBox(
                          height: 45,
                        ),
                        Style.body(
                          MyLocalizations.of(
                              context, 'camera_info_adult_txt_01'),
                        ),
                        SizedBox(
                          height: 5,
                        ),
                        Style.body(
                          MyLocalizations.of(
                              context, 'camera_info_adult_txt_02'),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Expanded(
                              child: Style.noBgButton(
                                MyLocalizations.of(context, 'ok_next_txt'),
                                () {
                                  Navigator.of(context).pop();
                                  !gallery
                                      ? getImage(ImageSource.camera)
                                      : getImage();
                                },
                                textColor: Style.colorPrimary,
                              ),
                            ),
                            Expanded(
                              child: Style.noBgButton(
                                MyLocalizations.of(context, 'no_show_again'),
                                () {
                                  !gallery
                                      ? getImage(ImageSource.camera)
                                      : getImage();
                                  UserManager.setSowInfoAdult(true);
                                  Navigator.of(context).pop();
                                },
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
            );
          });
    } else {
      !gallery ? getImage(ImageSource.camera) : getImage();
    }

    // Add a return statement at the end
    return throw StateError(
        'infoAdultCamera function completed without returning a Future value.');
  }

  static Future<Future> infoBreedingCamera(context, getImage,
      {bool gallery = false}) async {
    var showInfo = await UserManager.getShowInfoBreeding();

    if (showInfo == null || !showInfo) {
      return showDialog(
          barrierDismissible: true,
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              contentPadding: EdgeInsets.all(0),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              content: Container(
                padding: EdgeInsets.fromLTRB(25, 25, 25, 10),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.35,
                ),
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: double.infinity),
                    child: Column(
                      children: <Widget>[
                        Style.body(
                          MyLocalizations.of(
                              context, 'camera_info_breeding_txt_01'),
                        ),
                        SizedBox(
                          height: 5,
                        ),
                        Style.body(
                          MyLocalizations.of(
                              context, 'camera_info_breeding_txt_02'),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Expanded(
                              child: Style.noBgButton(
                                MyLocalizations.of(context, 'ok_next_txt'),
                                () {
                                  Navigator.of(context).pop();
                                  !gallery
                                      ? getImage(ImageSource.camera)
                                      : getImage();
                                },
                                textColor: Style.colorPrimary,
                              ),
                            ),
                            Expanded(
                              child: Style.noBgButton(
                                MyLocalizations.of(context, 'no_show_again'),
                                () {
                                  UserManager.setSowInfoBreeding(true);
                                  Navigator.of(context).pop();
                                  !gallery
                                      ? getImage(ImageSource.camera)
                                      : getImage();
                                },
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
            );
          });
    } else {
      !gallery ? getImage(ImageSource.camera) : getImage();
    }

    //Throws a StateError if the function completes without returning a Future value.
    throw StateError(
        'infoBreedingCamera function completed without returning a Future value.');
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
                        color: Style.colorPrimary,
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
                        color: Colors.blueAccent,
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
    if (ui.window.locale != null) {
      var stringLanguange = ui.window.locale.languageCode;
      var stringCountry = ui.window.locale.countryCode;

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
        language = ui.window.locale;
      }
    } else {
      language = Locale('en', 'US');
    }

    return language;
  }

  static launchUrl(url) async {
    if (await canLaunch(url)) {
      await launch(url, forceSafariVC: false);
    } else {
      throw 'Could not launch';
    }
  }

  static String getTranslatedReportType(BuildContext context, String? reportType){
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
    var placemarks = await placemarkFromCoordinates(lat, lon, localeIdentifier: locale);
    if (placemarks.isEmpty) { return null; }
    return placemarks.first.locality;
  }

  static void requestInAppReview() async {
    var myReports = await ApiSingleton().getReportsList();
    var numReports = myReports.length;

    if (numReports < 3) { return; }

    final now = DateTime.now().millisecondsSinceEpoch;
    final lastReportCount = await UserManager.getLastReportCount() ?? 0;
    final lastReviewRequest = await UserManager.getLastReviewRequest() ?? 0;

    var shouldRequestReview = (numReports == 3 || numReports == 4 || numReports >= lastReportCount + 3 || now - lastReviewRequest >= 14 * 24 * 60 * 60 * 1000);

    if (!shouldRequestReview) { return; }

    final inAppReview = InAppReview.instance;

    if (await inAppReview.isAvailable()) {
      await inAppReview.requestReview();

      await UserManager.setLastReviewRequest(now);
      await UserManager.setLastReportCount(numReports);
    }
  }
}
