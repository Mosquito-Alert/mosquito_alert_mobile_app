import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mosquito_alert_app/app_config.dart';
import 'package:mosquito_alert_app/models/report.dart';
import 'package:mosquito_alert_app/utils/Utils.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class ApiSingleton {
  static String baseUrl = '';
  static String serverUrl = '';

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

  Future<dynamic> getCampaigns(countryId) async {
    // TODO
    return false;
  }

  Future<bool> setFirebaseToken(String? userIdentifier, String fcmToken) async {
    // TODO
    return false;
  }
}
