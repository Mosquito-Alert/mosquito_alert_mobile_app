import 'dart:convert';
import 'dart:io';

import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'package:flutter_twitter/flutter_twitter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:mosquito_alert_app/models/notification.dart';
import 'package:mosquito_alert_app/models/owcampaing.dart';
import 'package:mosquito_alert_app/models/report.dart';
import 'package:mosquito_alert_app/models/response.dart';
import 'package:mosquito_alert_app/models/session.dart';
import 'package:mosquito_alert_app/utils/UserManager.dart';
import 'package:mosquito_alert_app/utils/Utils.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:http_parser/http_parser.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class ApiSingleton {
  static final _timeoutTimerInSeconds = 5;
  //static String baseUrl = 'http://madev.creaf.cat';
  static String baseUrl = 'http://webserver.mosquitoalert.com';
  static String serverUrl = '$baseUrl/api';

  static String token = 'D4w29W49rMKC7L6vYQ3ua3rd6fQ12YZ6n70P';

  //User
  static const users = '/users/';
  static const profile = '/profile/';
  static const newProfile = '/profile/new/';
  static const userScore = '/stats/user_xp_data/';

  //Reports
  static const reports = '/reports/';
  static const nearbyReports = '/nearby_reports_nod/';

  //Session
  static const sessions = '/sessions';
  static const sessionUpdate = '/session_update/';

  //Images
  static const photos = '/photos/';

  //Notifications
  static const notifications = '/user_notifications/';

  //Fixes
  static const fixes = '/fixes/';

  //Owcampaigns
  static const campaigns = '/owcampaigns/';

  //Headders
  var headers = {
    'Content-Type': ' application/json',
    'Authorization': 'Token ' + token
  };

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/contacts.readonly',
    ],
  );
  final facebookLogin = FacebookLogin();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  static final ApiSingleton _singleton = ApiSingleton._internal();

  factory ApiSingleton() {
    return _singleton;
  }

  ApiSingleton._internal();

  static ApiSingleton getInstance() {
    return ApiSingleton();
  }

  //User
  Future<dynamic> createUser(String uuid) async {
    try {
      final response = await http.post('$serverUrl$users',
          headers: headers,
          body: json.encode({
            'user_UUID': uuid,
          })).timeout(
        Duration(seconds: _timeoutTimerInSeconds),
        onTimeout: () {
          print('Request timed out');
          return;
        },
      );;

      if (response.statusCode != 201) {
        print(
          // ignore: prefer_single_quotes
            "Request: ${response.request.toString()} -> Response: ${response.body}");
        return ApiResponse.fromJson(json.decode(response.body));
      }
      return true;
    } catch (c) {
      return null;
    }
  }

  Future<dynamic> checkEmail(String email) async {
    var response = (await _auth.fetchSignInMethodsForEmail(email: email));
    return response;
  }

  Future<dynamic> singUp(String email, String password) async {
    final user = (await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    ))
        .user;
    if (user != null) {
      return user;
    } else {
      return false;
    }
  }

  Future<FirebaseUser> loginEmail(String email, String password) async {
    final FirebaseUser user = (await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    ))
        .user;
    if (user != null) {
      return user;
    } else {
      return user;
    }
  }

  Future<FirebaseUser> sigInWithGoogle() async {
    final GoogleSignInAccount googleUser =
    await _googleSignIn.signIn().catchError((e) {
      print(e);
      return null;
    });
    final GoogleSignInAuthentication googleAuth =
    await googleUser.authentication;

    final AuthCredential credential = GoogleAuthProvider.getCredential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final FirebaseUser user =
        (await _auth.signInWithCredential(credential)).user;

    _googleSignIn.signOut();
    return user;
  }

  Future<FirebaseUser> singInWithFacebook() async {
    AuthCredential credential;
    facebookLogin.loginBehavior = Platform.isIOS
        ? FacebookLoginBehavior.webViewOnly
        : FacebookLoginBehavior.nativeWithFallback;
    final result = await facebookLogin.logIn(['email', 'public_profile']);
    switch (result.status) {
      case FacebookLoginStatus.loggedIn:
        credential = FacebookAuthProvider.getCredential(
          accessToken: result.accessToken.token,
        );

        final FirebaseUser user =
            (await _auth.signInWithCredential(credential)).user;
        assert(user.email != null);
        assert(user.displayName != null);
        assert(!user.isAnonymous);
        assert(await user.getIdToken() != null);
        final FirebaseUser currentUser = await _auth.currentUser();
        assert(user.uid == currentUser.uid);
        return currentUser;
        break;
      case FacebookLoginStatus.cancelledByUser:
      // Todo: Show alert
        break;
      case FacebookLoginStatus.error:
        print(result.errorMessage);
        break;
    }
  }

  Future<FirebaseUser> singInWithTwitter() async {
    TwitterLogin twitterInstance = new TwitterLogin(
        consumerKey: '4mhrNfBnXQXaVntPFYdIfXtCz',
        consumerSecret: 'Vi3SE7MgpTUyOBL6ouZHKfei6okzMElpwteN2gr3QyEyapZc3F');

    final TwitterLoginResult result = await twitterInstance.authorize();

    final AuthCredential credential = TwitterAuthProvider.getCredential(
      authTokenSecret: result.session.secret,
      authToken: result.session.token,
    );
    final FirebaseUser user =
        (await _auth.signInWithCredential(credential)).user;
    // assert(user.displayName != null);
    // assert(!user.isAnonymous);
    // assert(await user.getIdToken() != null);

    final FirebaseUser currentUser = await _auth.currentUser();
    assert(user.uid == currentUser.uid);

    if (user != null) {
      return user;
    } else {
      return null;
    }
  }

  Future<bool> logout() async {
    _auth.signOut().then((res) {
      return true;
    }).catchError((e) {
      print(e);
      return false;
    });
  }

  Future<void> recoverPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<dynamic> createProfile(String firebaseId) async {
    String userUUID = await UserManager.getUUID();

    try {
      final response = await http.post(
          '$serverUrl$newProfile?fbt=$firebaseId&usr=$userUUID',
          headers: headers).timeout(
        Duration(seconds: _timeoutTimerInSeconds),
        onTimeout: () {
          print('Request timed out');
          return;
        },
      );;

      // print(response);

      if (response.statusCode != 200) {
        print(
            "Request: ${response.request.toString()} -> Response: ${response.body}");
        return ApiResponse.fromJson(json.decode(response.body));
      }
      return true;
    } catch (e) {
      print(e.errorMessage);
    }
  }

  Future<dynamic> getUserScores() async {
    try {
      String userUUID = await UserManager.getUUID();

      final response = await http.get(
        '$serverUrl$userScore?user_id=$userUUID&update=True',
        headers: headers,
      ).timeout(
        Duration(seconds: _timeoutTimerInSeconds),
        onTimeout: () {
          print('Request timed out');
          return;
        },
      );

      if (response.statusCode != 200) {
        print(
            "Request: ${response.request.toString()} -> Response: ${response.body}");
        return ApiResponse.fromJson(json.decode(response.body));
      }
      Map<String, dynamic> jsonAnswer = json.decode(response.body);

      UserManager.userScore = jsonAnswer['total_score'];
      Utils.userScoresController.add(jsonAnswer['total_score']);
      return UserManager.userScore;
    } catch (e) {
      return 1;
    }
  }

  //Notifications
  Future<dynamic> getNotifications() async {
    try {
      String userUUID = await UserManager.getUUID();
      String locale = await UserManager.getLanguage();

      final response = await http.get(
        '$serverUrl$notifications?user_id=$userUUID&locale=$locale',
        headers: headers,
      ).timeout(
        Duration(seconds: 10),
        onTimeout: () {
          print('Request timed out');
          return;
        },
      );

      print(response);
      if (response.statusCode != 200) {
        print(
            "Request: ${response.request.toString()} -> Response: ${response.body}");
        return ApiResponse.fromJson(json.decode(response.body));
      }

      var list = json.decode(utf8.decode(response.bodyBytes)) as List;
      List<MyNotification> data =
      list.map((i) => MyNotification.fromJson(i)).toList();
      return data;
    } catch (e) {
      return false;
    }
  }

  Future<dynamic> updateNotification(id, aknowlaged) async {
    try {
      final response = await http.post(
        '$serverUrl$notifications?id=$id&acknowledged=$aknowlaged',
        headers: headers,
      ).timeout(
        Duration(seconds: _timeoutTimerInSeconds),
        onTimeout: () {
          print('Request timed out');
          return;
        },
      );;

      print(response);
      if (response.statusCode != 200) {
        print(
            "Request: ${response.request.toString()} -> Response: ${response.body}");
        return ApiResponse.fromJson(json.decode(response.body));
      }
      Map<String, dynamic> jsonAnswer = json.decode(response.body);

      print(jsonAnswer);
      return true;
    } catch (e) {
      return false;
    }
  }

  //Sessions
  Future<dynamic> getLastSession(String userUUID) async {
    try {
      final response = await http.get(
        '$serverUrl$sessions?user=$userUUID',
        headers: headers,
      ).timeout(
        Duration(seconds: _timeoutTimerInSeconds),
        onTimeout: () {
          print('Request timed out');
          return;
        },
      );;

      if (response.statusCode != 200) {
        print(
            "Request: ${response.request.toString()} -> Response: ${response.body}");
        return ApiResponse.fromJson(json.decode(response.body));
      } else {
        List<dynamic> jsonAnswer = json.decode(response.body);
        List<Session> allSessions = List();

        for (var item in jsonAnswer) {
          allSessions.add(Session.fromJson(item));
        }

        if (allSessions.length == 0) {
          return 0;
        }

        return allSessions[0].session_ID;
      }
    } catch (e) {
      print(e.message);
      return false;
    }
  }

  Future<dynamic> createSession(Session session) async {
    try {
      final response = await http.post('$serverUrl$sessions/',
          headers: headers,
          body: json.encode(
            session.toJson(),
          )).timeout(
        Duration(seconds: _timeoutTimerInSeconds),
        onTimeout: () {
          print('Request timed out');
          return;
        },
      );;

      if (response.statusCode != 201) {
        print(
            "Request: ${response.request.toString()} -> Response: ${response.body}");
        return ApiResponse.fromJson(json.decode(response.body));
      }

      var body = json.decode(response.body);
      return body['id'];
    } catch (e) {
      // print(e);
      return false;
    }
  }

  Future<dynamic> closeSession(Session session) async {
    try {
      final response = await http.put(
          '$serverUrl$sessionUpdate${session.session_ID}/',
          headers: headers,
          body: json.encode({'session_end_time': session.session_end_time})).timeout(
        Duration(seconds: _timeoutTimerInSeconds),
        onTimeout: () {
          print('Request timed out');
          return;
        },
      );;

      if (response.statusCode != 200) {
        print(
            "Request: ${response.request.toString()} -> Response: ${response.body}");
        return ApiResponse.fromJson(json.decode(response.body));
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  //Reports
  Future<Report> createReport(Report report) async {
    try {
      var body = {};

      if (report.version_UUID != null && report.version_UUID.isNotEmpty) {
        body.addAll({'version_UUID': report.version_UUID});
      }
      if (report.version_number != null) {
        body.addAll({'version_number': report.version_number});
      }
      if (report.user != null && report.user.isNotEmpty) {
        body.addAll({'user': report.user});
      }
      if (report.report_id != null && report.report_id.isNotEmpty) {
        body.addAll({'report_id': report.report_id});
      }
      if (report.phone_upload_time != null &&
          report.phone_upload_time.isNotEmpty) {
        body.addAll({'phone_upload_time': report.phone_upload_time});
      }
      if (report.creation_time != null && report.creation_time.isNotEmpty) {
        body.addAll({'creation_time': report.creation_time});
      }
      if (report.version_time != null && report.version_time.isNotEmpty) {
        body.addAll({'version_time': report.version_time});
      }
      if (report.type != null && report.type.isNotEmpty) {
        body.addAll({'type': report.type});
      }
      if (report.location_choice != null && report.location_choice.isNotEmpty) {
        body.addAll({'location_choice': report.location_choice});
      }
      if (report.current_location_lat != null) {
        body.addAll({'current_location_lat': report.current_location_lat});
      }
      if (report.current_location_lon != null) {
        body.addAll({'current_location_lon': report.current_location_lon});
      }
      if (report.selected_location_lat != null) {
        body.addAll({'selected_location_lat': report.selected_location_lat});
      }
      if (report.selected_location_lon != null) {
        body.addAll({'selected_location_lon': report.selected_location_lon});
      }
      if (report.package_name != null) {
        body.addAll({'package_name': report.package_name});
      }
      if (report.package_version != null) {
        body.addAll({'package_version': report.package_version});
      }
      if (report.responses != null && report.responses.isNotEmpty) {
        body.addAll(
            {'responses': report.responses.map((r) => r.toJson()).toList()});
      }
      if (report.device_manufacturer != null) {
        body.addAll({'device_manufacturer': report.device_manufacturer});
      }
      if (report.device_model != null) {
        body.addAll({'device_model': report.device_model});
      }
      if (report.os != null) {
        body.addAll({'os': report.os});
      }
      if (report.os_version != null) {
        body.addAll({'os_version': report.os_version});
      }
      if (report.os_language != null) {
        body.addAll({'os_language': report.os_language});
      }
      if (report.app_language != null) {
        body.addAll({'app_language': report.app_language});
      }
      if (report.note != null && report.note != "") {
        body.addAll({'note': report.note});
      }

      final response = await http.post(
        '$serverUrl$reports',
        headers: headers,
        body: json.encode(body),
      ).timeout(
        Duration(seconds: _timeoutTimerInSeconds),
        onTimeout: () {
          print('Request timed out');
          return;
        },
      );;

      await saveImages(report);

      // print(response);
      if (response.statusCode != 201) {
        print(
            'Request: ${response.request.toString()} -> Response: ${response.body}');
        return null;
      }

      if (report.version_number > 0) {
        // var b = json.decode(response.body);
        // print(b);
        // var a = Report.fromJson(json.decode(response.body));
        // print(a);
        //Utils.report = Report.fromJson(json.decode(response.body));

      }
      var jsonAnswer = json.decode(response.body);
      var newReport = Report.fromJson(jsonAnswer);

      await getUserScores();
      return newReport;
    } catch (e) {
      return null;
    }
  }

  Future saveImages(Report report) async {
    if (Utils.imagePath != null) {
      Utils.imagePath.forEach((img) async {
        if (img['id'] == report.version_UUID) {
          if (!img['image'].contains('http')) {
            bool isSaved = await saveImage(img['image'], report.version_UUID);
            if (!isSaved) {
              final Directory directory =
              await getApplicationDocumentsDirectory();
              File newImage = await img['imageFile']
                  .copy('${directory.path}/${report.version_UUID}.png');

              Utils.saveLocalImage(newImage.path, report.version_UUID);
            } else {
              Utils.deleteImage(img['image']);
            }
          }
        }
      });
    }
  }

  Future<List<Report>> getReportsList(
      lat,
      lon, {
        int page,
        List<Report> allReports,
        bool show_hidden,
        int radius,
        bool show_verions,
      }) async {
    try {
      var userUUID = await UserManager.getUUID();

      final response = await http.get(
        '$serverUrl$nearbyReports?lat=$lat&lon=$lon&page=${page != null ? page : '1'}&user=$userUUID&page_size=75&radius=${100}' +
            (show_hidden == true ? '&show_hidden=1' : '') +
            (show_verions == true ? '&show_versions=1' : ''),
        headers: headers,
      ).timeout(
        Duration(seconds: _timeoutTimerInSeconds),
        onTimeout: () {
          print('Request timed out');
          return;
        },
      );


      if (response.statusCode != 200) {
        print(
            'Request: ${response.request.toString()} -> Response: ${response.body}');
        return null;
      } else {
        Map<String, dynamic> jsonAnswer = json.decode(response.body);
        List<Report> list = [];
        page = jsonAnswer['next'];

        if (allReports == null) {
          allReports = List();
          UserManager.profileUUIDs = jsonAnswer['user_uuids'];
        }
        for (var item in jsonAnswer['results']) {
          if (UserManager.profileUUIDs.any((id) => id == item['user'])) {
            list.add(Report.fromJson(item));
          }
        }
        allReports.addAll(list);
        //callback(list);
        if (page == null) {
          return allReports;
        }
      }

      return getReportsList(lat, lon,
          page: page, allReports: allReports, radius: radius);
    } catch (e) {
      // print(e);
      return null;
    }
  }

  //Images
  Future<bool> saveImage(String image, String versionUUID) async {
    try {
      String fileName = image != null ? image.split('/').last : null;
      var dio = new Dio();

      var img = await MultipartFile.fromFile(image,
          filename: fileName, contentType: MediaType('image', 'jpeg'));

      FormData data = FormData.fromMap({"photo": img, "report": versionUUID});

      var response = await dio.post('$serverUrl$photos',
          data: data,
          options: Options(
            headers: {'Authorization': 'Token ' + token},
            contentType: 'multipart/form-data',
          ));

      return response.statusCode == 200;
    } catch (c) {
      print(c.message);
      return false;
    }
  }

  Future<dynamic> sendFixes(lat, lon, time, power) async {
    try {
      var userIdFix = await UserManager.getTrackingId();

      var body = {
        'user_coverage_uuid': userIdFix,
        'fix_time': time,
        'masked_lat': lat,
        'masked_lon': lon,
        'power': power,
        'phone_upload_time': DateTime.now().toIso8601String(),
      };

      final response = await http.post(
        '$serverUrl$fixes',
        headers: headers,
        body: json.encode(body),
      ).timeout(
        Duration(seconds: _timeoutTimerInSeconds),
        onTimeout: () {
          print('Request timed out');
          return;
        },
      );;

      if (response.statusCode != 201) {
        print(
            'Request: ${response.request.toString()} -> Response: ${response.body}');
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<dynamic> getCampaigns(countryId) async {
    try {
      final response = await http.get(
        '$serverUrl$campaigns?country_id=$countryId',
        headers: headers,
      );

      if (response.statusCode != 200) {
        print(
            'Request: ${response.request.toString()} -> Response: ${response.body}');
        return ApiResponse.fromJson(json.decode(response.body));
      } else {
        List<dynamic> jsonAnswer = json.decode(response.body);

        print(json.decode(response.body));
        var allCampaigns = <Campaign>[];

        for (var item in jsonAnswer) {
          allCampaigns.add(Campaign.fromJson(item));
        }
        return allCampaigns;
      }
    } catch (e) {
      print(e.message);
      return false;
    }
  }
}
