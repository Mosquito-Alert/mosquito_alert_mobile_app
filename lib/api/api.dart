import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mosquito_alert/mosquito_alert.dart';
import 'package:mosquito_alert/src/auth/jwt_auth.dart';
import 'package:mosquito_alert_app/app_config.dart';
import 'package:mosquito_alert_app/models/notification.dart';
import 'package:mosquito_alert_app/models/report.dart';
import 'package:mosquito_alert_app/models/session.dart';
import 'package:mosquito_alert_app/models/topic.dart';
import 'package:mosquito_alert_app/utils/UserManager.dart';
import 'package:mosquito_alert_app/utils/Utils.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class ApiSingleton {
  static String baseUrl = '';
  static String serverUrl = '';

  static late MosquitoAlert api;
  static late AuthApi authApi;

  static final ApiSingleton _singleton = ApiSingleton._internal();

  factory ApiSingleton() {
    return _singleton;
  }

  ApiSingleton._internal();

  static Future<void> initialize() async {
    final config = await AppConfig.loadConfig();
    baseUrl = config.baseUrl;
    serverUrl = '$baseUrl/api';
    await initializeApiClient();
  }

  static ApiSingleton getInstance() {
    return ApiSingleton();
  }

  static Future<void> initializeApiClient() async {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        validateStatus: (status) {
          return status != null && status < 500;
        },
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );
    api = MosquitoAlert(
      basePathOverride: baseUrl,
      dio: dio,
    );

    authApi = api.getAuthApi();

    // Try to restore session if we have stored credentials
    final apiUser = await UserManager.getApiUser();
    final apiPassword = await UserManager.getApiPassword();
    if (apiUser != null && apiPassword != null) {
      await loginJwt(apiUser, apiPassword);
    }
  }

  Future<dynamic> createUser(String? uuid) async {
    try {
      // Try to authenticate with existing credentials first
      final apiUser = await UserManager.getApiUser();
      final apiPassword = await UserManager.getApiPassword();

      if (apiUser != null && apiPassword != null) {
        final success = await loginJwt(apiUser, apiPassword);
        if (success) {
          return true;
        }
      }

      // No stored credentials or login failed - register as new guest
      // Generate a random string of 16 characters for password
      final random = Random.secure();
      const chars =
          'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*';
      final guestPassword =
          List.generate(16, (index) => chars[random.nextInt(chars.length)])
              .join();

      final guestRegistrationRequest =
          GuestRegistrationRequest((b) => b..password = guestPassword);

      final registeredGuest = await authApi.signupGuest(
          guestRegistrationRequest: guestRegistrationRequest);

      if (registeredGuest.data?.username != null) {
        final newApiUser = registeredGuest.data!.username;
        await UserManager.setUser(newApiUser, guestPassword);

        final success = await loginJwt(newApiUser, guestPassword);
        if (success) {
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Error creating user: $e');
      return null;
    }
  }

  static Future<bool> loginJwt(String user, String password) async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    final deviceInfo = await deviceInfoPlugin.deviceInfo;
    String? deviceId;
    if (deviceInfo is AndroidDeviceInfo) {
      deviceId = deviceInfo.id;
    } else if (deviceInfo is IosDeviceInfo) {
      deviceId = deviceInfo.identifierForVendor;
    }
    AppUserTokenObtainPairRequest appUserTokenObtainPairRequest =
        AppUserTokenObtainPairRequest((b) => b
          ..username = user
          ..password = password
          ..deviceId = deviceId);

    try {
      final obtainToken = await authApi.obtainToken(
          appUserTokenObtainPairRequest: appUserTokenObtainPairRequest);

      if (obtainToken.data?.access != null &&
          obtainToken.data?.refresh != null) {
        // Clear any existing interceptors and add the JWT auth interceptor
        api.dio.interceptors.clear();
        api.dio.interceptors.add(JwtAuthInterceptor(
          apiClient: api,
          accessToken: obtainToken.data!.access,
          refreshToken: obtainToken.data!.refresh,
        ));

        // Store tokens for future use
        await UserManager.setToken(obtainToken.data!.access);
        await UserManager.setRefreshToken(obtainToken.data!.refresh);

        return true;
      }
    } catch (e) {
      print("Login failed: $e");
    }
    return false;
  }

  Future<dynamic> getUserScores() async {
    // TODO
    return 0; // Temporarily return 0 to avoid exception, until method is implemented
  }

  //Sessions
  Future<dynamic> getLastSession(String? userUUID) async {
    // TODO
    return false;
  }

  Future<int?> createSession(Session session) async {
    // TODO
    return null;
  }

  Future<dynamic> closeSession(Session session) async {
    // TODO
    return false;
  }

  //Reports
  Future<dynamic> createReport(Report report) async {
    // TODO
    return null;
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
    // TODO
    return [];
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
      print(data);
    } catch (c) {
      print(c);
      return false;
    }

    // TODO
    return false;
  }

  Future<bool> sendFixes(String trackingUuid, double lat, double lon,
      DateTime time, int power) async {
    // TODO
    return false;
  }

  Future<dynamic> getCampaigns(countryId) async {
    // TODO
    return false;
  }

  /*
  * Notifications Module
  * */
  Future<List<MyNotification>> getNotifications() async {
    // TODO
    return [];
  }

  Future<dynamic> updateNotification(id, acknowledge) async {
    // TODO
    return false;
  }

  Future<dynamic> markNotificationAsRead(
      String? userIdentifier, int? notificationId) async {
    // TODO
    return false;
  }

  Future<bool> subscribeToTopic(
      String userIdentifier, String? topicIdentifier) async {
    // TODO
    return false;
  }

  Future<bool> unsubscribeFromTopic(
      String userIdentifier, String topicIdentifier) async {
    // TODO
    return false;
  }

  Future<List<Topic>?> getTopicsSubscribed(String userIdentifier) async {
    // TODO
    return [];
  }

  Future<bool> setFirebaseToken(String? userIdentifier, String fcmToken) async {
    // TODO
    return false;
  }
}
