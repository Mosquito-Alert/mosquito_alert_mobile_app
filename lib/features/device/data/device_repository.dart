import 'dart:io';

import 'package:app_set_id/app_set_id.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/locale.dart';
import 'package:mosquito_alert/mosquito_alert.dart';
import 'package:mosquito_alert_app/features/device/data/models/device_info_data.dart';
import 'package:package_info_plus/package_info_plus.dart';

class DeviceRepository {
  final DevicesApi devicesApi;
  late final String? _deviceId;

  DeviceRepository._({required this.devicesApi, required String? deviceId}) {
    _deviceId = deviceId;
  }

  Device? _cachedDevice;
  Device? get currentDevice => _cachedDevice;
  String? get deviceId => _cachedDevice?.deviceId ?? _deviceId;

  static Future<DeviceRepository> create({
    required MosquitoAlert apiClient,
  }) async {
    final devicesApi = apiClient.getDevicesApi();

    return DeviceRepository._(
      devicesApi: devicesApi,
      deviceId: await getDeviceId(),
    );
  }

  static Future<String?> getDeviceId() async {
    final appSetId = AppSetId();
    try {
      return await appSetId.getIdentifier();
    } on PlatformException catch (e) {
      debugPrint('Failed to get device ID: ${e.message}');
      return null;
    }
  }

  Future<Device> registerCurrentDevice() async {
    if (_deviceId != null) {
      try {
        // Try to retrieve existing device
        _cachedDevice = await _getDevice(id: _deviceId);
      } catch (e) {
        debugPrint('Error retrieving device with ID $_deviceId: $e');
      }
    }

    final DeviceInfoData deviceInfoData = await _getDeviceInfo();
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final String? fcmToken = await _getFcmToken();

    final os = DeviceOsRequest(
      (b) => b
        ..nameValue = deviceInfoData.osName
        ..version = deviceInfoData.osVersion
        ..locale = _getBcp47Locale(),
    );

    final mobileApp = MobileAppRequest(
      (b) => b
        ..packageName = packageInfo.packageName
        ..packageVersion = '${packageInfo.version}+${packageInfo.buildNumber}',
    );

    if (_cachedDevice == null) {
      // Create a new device
      final request = DeviceRequest(
        (b) => b
          ..deviceId = _deviceId
          ..fcmToken = fcmToken
          ..type = deviceInfoData.type
          ..manufacturer = deviceInfoData.manufacturer
          ..model = deviceInfoData.model
          ..os = os.toBuilder()
          ..mobileApp = mobileApp.toBuilder(),
      );

      try {
        final response = await devicesApi.create(deviceRequest: request);
        _cachedDevice = response.data!;
      } catch (e) {
        _cachedDevice = null;
        rethrow;
      }
    } else {
      // Update existing device
      final request = DeviceUpdateRequest(
        (b) => b
          ..fcmToken = fcmToken
          ..os = os.toBuilder()
          ..mobileApp = mobileApp.toBuilder(),
      );

      try {
        final response = await devicesApi.update(
          deviceId: _cachedDevice!.deviceId,
          deviceUpdateRequest: request,
        );
        _cachedDevice = await _getDevice(id: response.data!.deviceId);
      } catch (e) {
        _cachedDevice = null;
        rethrow;
      }
    }

    return _cachedDevice!;
  }

  Future<void> updateFcmToken(String fcmToken) async {
    if (_cachedDevice == null) return null;
    final request = PatchedDeviceUpdateRequest((b) => b..fcmToken = fcmToken);
    await devicesApi.partialUpdate(
      deviceId: _cachedDevice!.deviceId,
      patchedDeviceUpdateRequest: request,
    );
  }

  Future<Device> _getDevice({required String id}) async {
    final response = await devicesApi.retrieve(deviceId: id);
    return response.data!;
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
        type: DeviceRequestTypeEnum.android,
      );
    } else if (deviceInfo is IosDeviceInfo) {
      return DeviceInfoData(
        manufacturer: 'Apple',
        model: deviceInfo.model,
        osName: deviceInfo.systemName,
        osVersion: deviceInfo.systemVersion,
        type: DeviceRequestTypeEnum.ios,
      );
    }
    return DeviceInfoData(
      manufacturer: null,
      model: 'unknown',
      osName: null,
      osVersion: 'unknown',
      type: DeviceRequestTypeEnum.unknownDefaultOpenApi,
    );
  }

  Future<String?> _getFcmToken() async {
    if (Platform.isIOS) {
      await FirebaseMessaging.instance.getAPNSToken();
    }

    return await FirebaseMessaging.instance.getToken().timeout(
      Duration(seconds: 10),
      onTimeout: () => null,
    );
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
}
