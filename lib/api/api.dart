import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as path;
import 'package:dio/dio.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mosquito_alert_app/models/notification.dart';
import 'package:mosquito_alert_app/models/owcampaing.dart';
import 'package:mosquito_alert_app/models/partner.dart';
import 'package:mosquito_alert_app/models/report.dart';
import 'package:mosquito_alert_app/models/response.dart';
import 'package:mosquito_alert_app/models/session.dart';
import 'package:mosquito_alert_app/models/topic.dart';
import 'package:mosquito_alert_app/utils/PushNotificationsManager.dart';
import 'package:mosquito_alert_app/utils/UserManager.dart';
import 'package:mosquito_alert_app/utils/Utils.dart';
import 'package:mosquito_alert_app/app_config.dart';
import 'package:path_provider/path_provider.dart';

class ApiSingleton {
  static final _timeoutTimerInSeconds = 10;

  static String baseUrl = '';
  static String serverUrl = '';

  static String token = 'D4w29W49rMKC7L6vYQ3ua3rd6fQ12YZ6n70P';

  //User
  static const users = '/users/';
  static const userScore = '/stats/user_xp_data/';

  //Reports
  static const reports = '/reports/';

  //Session
  static const sessions = '/sessions/';
  static const sessionUpdate = '/session_update/';

  //Images
  static const photos = '/photos/';

  //Notifications
  static const notifications = '/user_notifications/';
  static const mark_notification_as_read = '/mark_notif_as_ack/';
  static const subscribe_to_topic = '/subscribe_to_topic/';
  static const unsub_from_topic = '/unsub_from_topic/';
  static const get_my_topics = '/topics_subscribed/';
  static const firebaseToken = '/token/';

  //Fixes
  static const fixes = '/fixes/';

  //Owcampaigns
  static const campaigns = '/owcampaigns/';

  //Partners
  static const partners = '/organizationpins';

  //Headers
  var headers = {
    'Content-Type': ' application/json',
    'Authorization': 'Token ' + token
  };

  static final ApiSingleton _singleton = ApiSingleton._internal();

  factory ApiSingleton() {
    return _singleton;
  }

  ApiSingleton._internal();

  static Future<void> initialize() async {
    final config = await AppConfig.loadConfig();
    baseUrl = config.baseUrl;
    serverUrl = '$baseUrl/api';
  }

  static ApiSingleton getInstance() {
    return ApiSingleton();
  }

  Future<bool> checkUserExist(String? uuid) async {
    var url = '$serverUrl$users$uuid/';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      print('Error: $e');
    }

    return false;
  }

  //User
  Future<dynamic> createUser(String? uuid) async {
    var userExists = await checkUserExist(uuid);
    try {
      if (userExists) {
        print('Skipping user creation. User already exists');
      } else {
        final response = await http
            .post(Uri.parse('$serverUrl$users'),
                headers: headers,
                body: json.encode({
                  'user_UUID': uuid,
                }))
            .timeout(
          Duration(seconds: _timeoutTimerInSeconds),
          onTimeout: () {
            print('Request timed out');
            return Future.error('Request timed out');
          },
        );
        ;

        if (response.statusCode != 201) {
          print(
              // ignore: prefer_single_quotes
              "Request: ${response.request.toString()} -> Response: ${response.body}");
          return ApiResponse.fromJson(json.decode(response.body));
        }
      }
      // Utils.userCreated["created"] = true;
      Utils.initializedCheckData['userCreated']['created'] = true;
      return true;
    } catch (c) {
      return null;
    }
  }

  Future<dynamic> getUserScores() async {
    try {
      var userUUID = await UserManager.getUUID();

      final response = await http
          .get(
        Uri.parse('$serverUrl$userScore?user_id=$userUUID&update=True'),
        headers: headers,
      )
          .timeout(
        Duration(seconds: _timeoutTimerInSeconds),
        onTimeout: () {
          print('Request timed out');
          // Utils.userScoresFetched = false;
          Utils.initializedCheckData['userScores'] = false;
          return Future.error('Request timed out');
        },
      );

      if (response.statusCode != 200) {
        print(
            'Request: ${response.request.toString()} -> Response: ${response.body}');
        return 0;
      }
      Map<String, dynamic> jsonAnswer = json.decode(response.body);

      UserManager.userScore = jsonAnswer['total_score'];
      Utils.userScoresController.add(jsonAnswer['total_score']);
      // Utils.userScoresFetched = true;
      Utils.initializedCheckData['userScores'] = true;
      return UserManager.userScore;
    } catch (e) {
      return 1;
    }
  }

  //Sessions
  Future<dynamic> getLastSession(String? userUUID) async {
    try {
      final response = await http
          .get(
        Uri.parse('$serverUrl$sessions?user=$userUUID'),
        headers: headers,
      )
          .timeout(
        Duration(seconds: _timeoutTimerInSeconds),
        onTimeout: () {
          print('Request timed out');
          return Future.error('Request timed out');
        },
      );

      if (response.statusCode != 200) {
        print(
            'Request: ${response.request.toString()} -> Response: ${response.body}');
        return ApiResponse.fromJson(json.decode(response.body));
      } else {
        List<dynamic> jsonAnswer = json.decode(response.body);
        var allSessions = <Session>[];

        for (var item in jsonAnswer) {
          allSessions.add(Session.fromJson(item));
        }

        if (allSessions.isEmpty) {
          return 0;
        }

        return allSessions[0].session_ID;
      }
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<dynamic> createSession(Session session) async {
    try {
      final response = await http
          .post(Uri.parse('$serverUrl$sessions'),
              headers: headers,
              body: json.encode(
                session.toJson(),
              ))
          .timeout(
        Duration(seconds: _timeoutTimerInSeconds),
        onTimeout: () {
          print('Request timed out');
          return Future.error('Request timed out');
        },
      );
      ;

      if (response.statusCode != 201) {
        print(
            'Request: ${response.request.toString()} -> Response: ${response.body}');
        return ApiResponse.fromJson(json.decode(response.body));
      }

      var body = json.decode(response.body);
      return body['id'];
    } catch (e) {
      return null;
    }
  }

  Future<dynamic> closeSession(Session session) async {
    try {
      final response = await http
          .put(Uri.parse('$serverUrl$sessionUpdate${session.session_ID}/'),
              headers: headers,
              body: json.encode({'session_end_time': session.session_end_time}))
          .timeout(
        Duration(seconds: _timeoutTimerInSeconds),
        onTimeout: () {
          print('Request timed out');
          return Future.error('Request timed out');
        },
      );
      ;

      if (response.statusCode != 200) {
        print(
            'Request: ${response.request.toString()} -> Response: ${response.body}');
        return ApiResponse.fromJson(json.decode(response.body));
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  //Reports
  Future<Report?> createReport(Report report) async {
    try {
      var body = {};

      if (report.version_UUID != null && report.version_UUID!.isNotEmpty) {
        body.addAll({'version_UUID': report.version_UUID});
      }
      if (report.version_number != null) {
        body.addAll({'version_number': report.version_number});
      }
      if (report.user != null && report.user!.isNotEmpty) {
        body.addAll({'user': report.user});
      }
      if (report.report_id != null && report.report_id!.isNotEmpty) {
        body.addAll({'report_id': report.report_id});
      }
      if (report.version_number != null && report.version_number == 0) {
        body.addAll(
            {'phone_upload_time': DateTime.now().toUtc().toIso8601String()});
      } else if (report.phone_upload_time != null &&
          report.phone_upload_time!.isNotEmpty) {
        body.addAll({'phone_upload_time': report.phone_upload_time});
      }
      if (report.creation_time != null && report.creation_time!.isNotEmpty) {
        body.addAll({'creation_time': report.creation_time});
      }
      if (report.version_time != null && report.version_time!.isNotEmpty) {
        body.addAll({'version_time': report.version_time});
      }
      if (report.type != null && report.type!.isNotEmpty) {
        body.addAll({'type': report.type});
      }
      if (report.location_choice != null &&
          report.location_choice!.isNotEmpty) {
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
      if (report.responses != null && report.responses!.isNotEmpty) {
        body.addAll(
            {'responses': report.responses!.map((r) => r!.toJson()).toList()});
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

      var hashtag = await UserManager.getHashtags();
      if ((report.note != null && report.note != '') || hashtag != null) {
        var combinedHashtags = hashtag?.map((tag) => '#$tag').join(' ');
        body.addAll({
          'note':
              '${report.note != null && report.note != "" ? report.note : ''}${report.note != null && report.note != "" && combinedHashtags != null ? ' ' : ''}${combinedHashtags != null ? '$combinedHashtags' : ''}'
        });
      }

      final response = await http
          .post(
        Uri.parse('$serverUrl$reports'),
        headers: headers,
        body: json.encode(body),
      )
          .timeout(
        Duration(seconds: _timeoutTimerInSeconds),
        onTimeout: () {
          print('Request timed out');
          return Future.error('Request timed out');
        },
      );
      ;

      await saveImages(report);
      if (response.statusCode != 201) {
        print(
            'Request: ${response.request.toString()} -> Response: ${response.body}');
        return null;
      }

      var jsonAnswer = json.decode(response.body);
      var newReport = await Report.fromJsonAsync(jsonAnswer);

      await PushNotificationsManager.subscribeToReportResult(newReport);

      await getUserScores();
      return newReport;
    } catch (e) {
      return null;
    }
  }

  Future saveImages(Report report) async {
    if (Utils.imagePath != null) {
      Utils.imagePath!.forEach((img) async {
        if (img['id'] == report.version_UUID) {
          if (!img['image'].contains('http')) {
            var isSaved = await saveImage(img['image'], report.version_UUID);
            if (!isSaved) {
              final directory = await getApplicationDocumentsDirectory();
              File newImage = await img['imageFile']
                  .copy('${directory.path}/${report.version_UUID}.png');

              await Utils.saveLocalImage(newImage.path, report.version_UUID);
            } else {
              Utils.deleteImage(img['image']);
            }
          }
        }
      });
    }
  }

  Future<List<Report>> getReportsList() async {
    try {
      var userUUID = await UserManager.getUUID();

      final response = await http
          .get(
        Uri.parse(
            '$serverUrl$reports?user=$userUUID&is_deleted=false&is_last_version=true'),
        headers: headers,
      )
          .timeout(
        Duration(seconds: _timeoutTimerInSeconds),
        onTimeout: () {
          print('Request timed out');
          return Future.error('Request timed out');
        },
      );

      if (response.statusCode != 200) {
        print(
            'Request: ${response.request.toString()} -> Response: ${response.body}');
        return [];
      } else {
        List<dynamic> jsonAnswer = json.decode(response.body);
        var list = <Report>[];
        for (var item in jsonAnswer) {
          list.add(await Report.fromJsonAsync(item));
        }
        return list;
      }
    } catch (e) {
      // print(e);
      return [];
    }
  }

  //Images
  Future<bool> saveImage(String imagePath, String? versionUUID) async {
    try {
      // Compressing image to jpeg 4k max = 3840x2180
      Uint8List? compressedImage = await FlutterImageCompress.compressWithFile(
          imagePath,
          minWidth: 3840,
          minHeight: 2180,
          quality: 98,
          autoCorrectionAngle: true,
          format: CompressFormat.jpeg,
          keepExif: true);

      if (compressedImage == null) {
        print('Failed to compress image');
        return false;
      }

      var img = await MultipartFile.fromBytes(compressedImage,
          filename: '${path.basenameWithoutExtension(imagePath)}.jpeg',
          contentType: MediaType('image', 'jpeg'));

      var data = FormData.fromMap({'photo': img, 'report': versionUUID});

      var dio = Dio();
      var response = await dio.post('$serverUrl$photos',
          data: data,
          options: Options(
            headers: {'Authorization': 'Token ' + token},
            contentType: 'multipart/form-data',
          ));

      return response.statusCode == 200;
    } catch (c) {
      print(c);
      return false;
    }
  }

  Future<bool> sendFixes(String trackingUuid, double lat, double lon,
      DateTime time, int power) async {
    try {
      final double maskedLat =
          (lat / Utils.maskCoordsValue).floor() * Utils.maskCoordsValue;
      final double maskedLon =
          (lon / Utils.maskCoordsValue).floor() * Utils.maskCoordsValue;

      final body = json.encode({
        'user_coverage_uuid': trackingUuid,
        'fix_time': time.toUtc().toIso8601String(),
        'masked_lat': maskedLat,
        'masked_lon': maskedLon,
        'power': power,
        'phone_upload_time': DateTime.now().toUtc().toIso8601String(),
      });

      final url = Uri.parse('$serverUrl$fixes');

      final response = await http
          .post(
            url,
            headers: headers,
            body: body,
          )
          .timeout(Duration(seconds: _timeoutTimerInSeconds));

      return response.statusCode == 201;
    } on TimeoutException {
      print("Error: Request timed out.");
    } on http.ClientException catch (e) {
      print("HTTP Client Exception: $e");
    } catch (e) {
      print("Error : ${e}");
    }
    return false;
  }

  Future<dynamic> getCampaigns(countryId) async {
    try {
      final response = await http.get(
        Uri.parse('$serverUrl$campaigns?country_id=$countryId'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        print(
            'Request: ${response.request.toString()} -> Response: ${response.body}');
        return ApiResponse.fromJson(json.decode(response.body));
      } else {
        List<dynamic> jsonAnswer = json.decode(utf8.decode(response.bodyBytes));

        var allCampaigns = <Campaign>[];

        for (var item in jsonAnswer) {
          allCampaigns.add(Campaign.fromJson(item));
        }
        return allCampaigns;
      }
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<dynamic> getPartners() async {
    try {
      final response = await http.get(
        Uri.parse('$serverUrl$partners'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        print(
            'Request: ${response.request.toString()} -> Response: ${response.body}');
        return ApiResponse.fromJson(json.decode(response.body));
      } else {
        List<dynamic> jsonAnswer = json.decode(response.body);

        print(json.decode(response.body));
        var allPartners = <Partner>[];

        for (var item in jsonAnswer) {
          allPartners.add(Partner.fromJson(item));
        }
        return allPartners;
      }
    } catch (e) {
      print(e);
      return false;
    }
  }

  /*
  * Notifications Module
  * */
  Future<List<MyNotification>> getNotifications() async {
    try {
      var userUUID = await UserManager.getUUID();
      var locale = await UserManager.getLanguage();

      final response = await http
          .get(
        Uri.parse('$serverUrl$notifications?user_id=$userUUID&locale=$locale'),
        headers: headers,
      )
          .timeout(
        Duration(seconds: 10),
        onTimeout: () {
          print('Request timed out');
          return Future.error('Request timed out');
        },
      );

      if (response.statusCode != 200) {
        print(
            'Request: ${response.request.toString()} -> Response: ${response.body}');
        return [];
      }

      var list = json.decode(utf8.decode(response.bodyBytes)) as List;
      var data = list.map((i) => MyNotification.fromJson(i)).toList();
      return data;
    } catch (e) {
      return [];
    }
  }

  Future<dynamic> updateNotification(id, acknowledge) async {
    try {
      final response = await http
          .post(
        Uri.parse('$serverUrl$notifications?id=$id&acknowledged=$acknowledge'),
        headers: headers,
      )
          .timeout(
        Duration(seconds: _timeoutTimerInSeconds),
        onTimeout: () {
          print('Request timed out');
          return Future.error('Request timed out');
        },
      );
      ;
      if (response.statusCode != 200) {
        print(
            'Request: ${response.request.toString()} -> Response: ${response.body}');
        return ApiResponse.fromJson(json.decode(response.body));
      }
      json.decode(response.body);
      return true;
    } catch (e) {
      print('updateNotification, failed for $e');
      return false;
    }
  }

  Future<dynamic> markNotificationAsRead(
      String? userIdentifier, int? notificationId) async {
    try {
      final response = await http
          .delete(
              Uri.parse(
                  '$serverUrl$mark_notification_as_read?user=$userIdentifier&notif=$notificationId'),
              headers: headers)
          .timeout(
        Duration(seconds: _timeoutTimerInSeconds),
        onTimeout: () {
          print('Request timed out');
          return Future.error('Request timed out');
        },
      );
      if (response.statusCode == 204) {
        return true;
      }
      print('markNotificationAsRead failed');
      return false;
    } catch (e) {
      print('markNotificationAsRead, failed for $e');
      return false;
    }
  }

  Future<bool> subscribeToTopic(
      String userIdentifier, String? topicIdentifier) async {
    try {
      final response = await http
          .post(
              Uri.parse(
                  '$serverUrl$subscribe_to_topic?user=$userIdentifier&code=$topicIdentifier'),
              headers: headers)
          .timeout(
        Duration(seconds: _timeoutTimerInSeconds),
        onTimeout: () {
          print('Request timed out');
          return Future.error('Request timed out');
        },
      );
      if (response.statusCode == 201) {
        print('Succes subscribing to $topicIdentifier.');

        return true;
      }
      print(
          'subscribeToTopic $topicIdentifier, failed (code ${response.statusCode})');
      return false;
    } catch (e) {
      print('subscribeToTopic $topicIdentifier, failed for $e');
      return false;
    }
  }

  Future<bool> unsubscribeFromTopic(
      String userIdentifier, String topicIdentifier) async {
    try {
      final response = await http
          .post(
              Uri.parse(
                  '$serverUrl$unsub_from_topic?user=$userIdentifier&code=$topicIdentifier'),
              headers: headers)
          .timeout(
        Duration(seconds: _timeoutTimerInSeconds),
        onTimeout: () {
          print('Request timed out');
          return Future.error('Request timed out');
        },
      );
      if (response.statusCode == 204) {
        return true;
      }
      print('unsubscribeFromTopic, failed.');
      return false;
    } catch (e) {
      print('unsubscribeFromTopic, failed for $e.');
      return false;
    }
  }

  Future<List<Topic>?> getTopicsSubscribed(String userIdentifier) async {
    try {
      final response = await http
          .get(Uri.parse('$serverUrl$get_my_topics?user=$userIdentifier'),
              headers: headers)
          .timeout(
        Duration(seconds: _timeoutTimerInSeconds),
        onTimeout: () {
          print('Request timed out');
          return Future.error('Request timed out');
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        var topicList = <Topic>[];
        for (dynamic top in data) {
          var topic = Topic.fromJson(top);
          topicList.add(topic);
        }
        return topicList;
      }
      print('getTopicsSubscribed, failed.');
      return null;
    } catch (e) {
      print('getTopicsSubscribed, failed for $e');
      return null;
    }
  }

  Future<bool> setFirebaseToken(String? userIdentifier, String fcmToken) async {
    print(userIdentifier);
    print(fcmToken);
    try {
      final response = await http
          .post(
              Uri.parse(
                  '$serverUrl$firebaseToken?user_id=$userIdentifier&token=$fcmToken'),
              headers: headers)
          .timeout(
        Duration(seconds: _timeoutTimerInSeconds),
        onTimeout: () {
          print('Request timed out');
          return Future.error('Request timed out');
        },
      );
      if (response.statusCode == 200) {
        return true;
      }
      print('setFirebaseToken, failed');
      return false;
    } catch (e) {
      print('setFirebaseToken, failed for $e');
      return false;
    }
  }
}
