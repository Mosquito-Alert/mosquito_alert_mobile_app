import 'dart:io';

import 'package:app_set_id/app_set_id.dart';
import 'package:dio/dio.dart';
import 'package:intl/locale.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mosquito_alert/mosquito_alert.dart';
import 'package:package_info_plus/package_info_plus.dart';

class DeviceInfoData {
  final String? manufacturer;
  final String model;
  final String? osName;
  final String osVersion;
  final DeviceRequestTypeEnum type;

  DeviceInfoData({
    required this.manufacturer,
    required this.model,
    required this.osName,
    required this.osVersion,
    required this.type,
  });
}

class DeviceProvider with ChangeNotifier {
  late final DevicesApi devicesApi;
  late final String? _currentDeviceId;
  Device? device;

  DeviceProvider._({required this.devicesApi, required String? deviceId}) {
    _currentDeviceId = deviceId;
  }

  static Future<DeviceProvider> create(
      {required MosquitoAlert apiClient}) async {
    final devicesApi = apiClient.getDevicesApi();
    final _appSetIdPlugin = AppSetId();

    String? deviceId;
    try {
      deviceId = await _appSetIdPlugin.getIdentifier();
    } on PlatformException catch (e) {
      debugPrint('Failed to get device ID: ${e.message}');
    }

    return DeviceProvider._(devicesApi: devicesApi, deviceId: deviceId);
  }

  void setDevice(Device? newDevice) {
    device = newDevice;
    notifyListeners();
  }

  Future<void> updateFcmToken(String fcmToken) async {
    if (device == null) return null;
    final request = PatchedDeviceUpdateRequest((b) => b..fcmToken = fcmToken);
    await devicesApi.partialUpdate(
        deviceId: device!.deviceId, patchedDeviceUpdateRequest: request);
  }

  Future<void> registerDevice() async {
    final DeviceInfoData deviceInfoData = await _getDeviceInfo();
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final String? fcmToken = await _getFcmToken();

    final os = DeviceOsRequest((b) => b
      ..nameValue = deviceInfoData.osName
      ..version = deviceInfoData.osVersion
      ..locale = _getBcp47Locale());

    final mobileApp = MobileAppRequest((b) => b
      ..packageName = packageInfo.packageName
      ..packageVersion = '${packageInfo.version}+${packageInfo.buildNumber}');

    await _fetchDevice();
    if (device == null) {
      // Create a new device
      final request = DeviceRequest((b) => b
        ..deviceId = _currentDeviceId
        ..fcmToken = fcmToken
        ..type = deviceInfoData.type
        ..manufacturer = deviceInfoData.manufacturer
        ..model = deviceInfoData.model
        ..os = os.toBuilder()
        ..mobileApp = mobileApp.toBuilder());

      final response = await devicesApi.create(deviceRequest: request);
      if (response.statusCode == 201) {
        setDevice(response.data!);
      }
    } else {
      // Update existing device
      final request = DeviceUpdateRequest((b) => b
        ..fcmToken = fcmToken
        ..os = os.toBuilder()
        ..mobileApp = mobileApp.toBuilder());

      await devicesApi.update(
          deviceId: device!.deviceId, deviceUpdateRequest: request);
      await _fetchDevice();
    }
  }

  Future<void> _fetchDevice() async {
    // NOTE: This function should never raise.
    if (_currentDeviceId == null) return null;

    try {
      final response = await devicesApi.retrieve(deviceId: _currentDeviceId);
      if (response.data != null) {
        setDevice(response.data);
      }
    } on DioException catch (e) {
      debugPrint(e.toString());
      setDevice(null);
    }
  }

  String _getBcp47Locale() {
    // Remove charset if present
    final cleaned = Platform.localeName.split('.')[0];

    // Parse to Flutter Locale
    final locale = Locale.parse(cleaned);

    // Format to BCP 47: language[-REGION]
    if (locale.countryCode?.isNotEmpty ?? false) {
      return '${locale.languageCode}-${locale.countryCode}';
    } else {
      return locale.languageCode;
    }
  }

  Future<DeviceInfoData> _getDeviceInfo() async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    final deviceInfo = await deviceInfoPlugin.deviceInfo;

    if (deviceInfo is AndroidDeviceInfo) {
      return DeviceInfoData(
          manufacturer: deviceInfo.manufacturer,
          model: deviceInfo.model,
          osName: 'Android',
          osVersion: deviceInfo.version.release,
          type: DeviceRequestTypeEnum.android);
    } else if (deviceInfo is IosDeviceInfo) {
      return DeviceInfoData(
          manufacturer: 'Apple',
          model: deviceInfo.model,
          osName: deviceInfo.systemName,
          osVersion: deviceInfo.systemVersion,
          type: DeviceRequestTypeEnum.ios);
    } else {
      return DeviceInfoData(
          manufacturer: null,
          model: 'unknown',
          osName: null,
          osVersion: 'unknown',
          type: DeviceRequestTypeEnum.unknownDefaultOpenApi);
    }
  }

  Future<String?> _getFcmToken() async {
    if (Platform.isIOS) {
      await FirebaseMessaging.instance.getAPNSToken();
    }

    return await FirebaseMessaging.instance
        .getToken()
        .timeout(Duration(seconds: 10), onTimeout: () => null);
  }
}
