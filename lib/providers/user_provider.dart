import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:mosquito_alert/mosquito_alert.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';

import 'package:shared_preferences/shared_preferences.dart';

class UserProvider extends ChangeNotifier {
  final UsersApi usersApi;

  UserProvider._(this.usersApi);

  static Future<UserProvider> create({required MosquitoAlert apiClient}) async {
    final provider = UserProvider._(apiClient.getUsersApi());
    await provider._initLanguage();
    return provider;
  }

  Future<void> _initLanguage() async {
    final prefs = await SharedPreferences.getInstance();

    // Migrate old locale format if necessary
    final oldLang = prefs.getString('language');
    final oldCountry = prefs.getString('languageCountry');
    if (oldLang != null) {
      await prefs.setString(
          'locale', Locale(oldLang, oldCountry).toLanguageTag());
      await prefs.remove('language');
      await prefs.remove('languageCountry');
    }

    final storedLocale = prefs.getString('locale');

    if (storedLocale == null || storedLocale.trim().isEmpty) {
      // Use system locale as default
      this.locale = WidgetsBinding.instance.platformDispatcher.locale;
      return;
    }

    final parts = storedLocale.split(RegExp('[-_]'));

    this.locale = Locale.fromSubtags(
      languageCode: parts.isNotEmpty ? parts[0] : 'en',
      scriptCode: parts.length == 3 ? parts[1] : null,
      countryCode: parts.length >= 2 ? parts[parts.length - 1] : null,
    );
  }

  User? _user;
  User? get user => _user;

  set user(User? newUser) {
    _user = newUser;
    _setFirebaseUserId(newUser);
    notifyListeners();
  }

  Locale? _locale;
  Locale get locale => _locale ?? MyLocalizations.defaultFallbackLocale;

  set locale(Locale locale) {
    Locale resolvedLocale = MyLocalizations.resolveLocale(locale);

    if (_locale == resolvedLocale) return; // Prevent unnecessary work
    _locale = resolvedLocale;
    notifyListeners();
    _persistAndSyncLocale(resolvedLocale);
  }

  Future<void> _persistAndSyncLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', locale.toLanguageTag());

    if (this.user == null) return; // no sync possible yet

    await _syncUserLocale(locale);
  }

  Future<void> _syncUserLocale(Locale locale) async {
    final newCode = locale.languageCode.toLowerCase();

    // If already the same, skip API call
    if (user?.languageIso == newCode) return;

    final localeEnum = PatchedUserRequestLocaleEnum.values.firstWhere(
      (e) => e.name == newCode,
      orElse: () => PatchedUserRequestLocaleEnum.en,
    );

    final req = PatchedUserRequest((b) => b..locale = localeEnum);

    try {
      final response = await usersApi.partialUpdate(
        uuid: user!.uuid,
        patchedUserRequest: req,
      );
      this.user = response.data!;
    } catch (e) {
      debugPrint('Error updating user locale: $e');
    }
  }

  Future<void> fetchUser() async {
    try {
      final response = await usersApi.retrieveMine();
      this.user = response.data!;
    } catch (e) {
      print('Error getting user: $e');
      this.user = null;
      rethrow;
    }

    // Ensure backend locale matches selected locale
    try {
      await _syncUserLocale(locale);
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
