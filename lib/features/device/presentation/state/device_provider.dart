import 'package:flutter/material.dart';
import 'package:mosquito_alert/mosquito_alert.dart';
import 'package:mosquito_alert_app/features/device/data/device_repository.dart';

class DeviceProvider with ChangeNotifier {
  late final DevicesApi devicesApi;

  final DeviceRepository _repository;
  Device? device;

  DeviceProvider({required DeviceRepository repository})
    : _repository = repository;

  Future<void> registerDevice() async {
    if (device != null) {
      return;
    }
    device = await _repository.registerCurrentDevice();
    notifyListeners();
  }
}
