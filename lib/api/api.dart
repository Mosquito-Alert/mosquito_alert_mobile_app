import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mosquito_alert_app/app_config.dart';
import 'package:mosquito_alert_app/models/report.dart';
import 'package:path/path.dart' as path;

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
    // TODO: Delete?
    return null;
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
}
