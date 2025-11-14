import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:mosquito_alert/mosquito_alert.dart';

import 'package:shared_preferences/shared_preferences.dart';

class UserProvider extends ChangeNotifier {
  final UsersApi usersApi;

  UserProvider({required MosquitoAlert apiClient})
      : usersApi = apiClient.getUsersApi();

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final localeString = prefs.getString('locale');

    if (localeString != null) {
      final parts = localeString.split('_');
      this.locale = Locale.fromSubtags(
        languageCode: parts.isNotEmpty ? parts[0] : 'en',
        countryCode: parts.length == 2 ? parts[1] : null,
      );
    }
  }

  User? _user;
  User? get user => _user;

  set user(User? newUser) {
    _user = newUser;
    _setFirebaseUserId(newUser);
    notifyListeners();
  }

  Locale? _locale;
  Locale get locale =>
      _locale ?? WidgetsBinding.instance.platformDispatcher.locale;

  set locale(Locale locale) {
    if (_locale == locale) return; // Prevent unnecessary work
    _locale = locale;
    notifyListeners();
    _applyLocale(locale);
  }

  Future<void> _applyLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', locale.toLanguageTag());

    if (this.user == null) return;

    final localeEnum = PatchedUserRequestLocaleEnum.values.firstWhere(
        (e) => e.name == locale.languageCode,
        orElse: () => PatchedUserRequestLocaleEnum.en);

    final patchedUserRequest =
        PatchedUserRequest((b) => b..locale = localeEnum);

    try {
      final response = await usersApi.partialUpdate(
        uuid: user!.uuid,
        patchedUserRequest: patchedUserRequest,
      );
      this.user = response.data;
    } catch (e) {
      print('Error updating user locale: $e');
    }
  }

  Future<void> fetchUser() async {
    try {
      final response = await usersApi.retrieveMine();
      this.user = response.data;
    } catch (e) {
      print('Error getting user: $e');
      this.user = null;
      rethrow;
    }

    try {
      if (this.user?.languageIso != this.locale.languageCode) {
        await _applyLocale(this.locale);
      }
    } catch (_) {
      print('Error changing user locale');
    }
  }

  Future<void> _setFirebaseUserId(User? user) async {
    try {
      await FirebaseAnalytics.instance.setUserId(id: user?.uuid);
    } catch (e) {
      print('Error setting Firebase user ID: $e');
    }
  }
}
