import 'package:mosquito_alert/mosquito_alert.dart';

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
