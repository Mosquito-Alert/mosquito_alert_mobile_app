import 'package:flutter/material.dart';
import 'package:mosquito_alert_app/features/settings/data/settings_repository.dart';

class SettingsProvider with ChangeNotifier {
  final SettingsRepository _repository;
  List<String> _hashtags = [];

  List<String> get hashtags => _hashtags;
  set hashtags(List<String> value) {
    _hashtags = value;
    notifyListeners();
    _repository.setHashtags(value);
  }

  SettingsProvider(this._repository) {
    _init();
  }

  Future<void> _init() async {
    hashtags = await _repository.getHashtags();
  }
}
