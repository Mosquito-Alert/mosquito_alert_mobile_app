import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:mosquito_alert/mosquito_alert.dart';
import 'package:mosquito_alert_app/core/localizations/MyLocalizations.dart';
import 'package:mosquito_alert_app/features/user/data/user_repository.dart';

import 'package:shared_preferences/shared_preferences.dart';

class UserProvider extends ChangeNotifier {
  final UserRepository _repository;

  User? _user;
  User? get user => _user;

  Locale? _locale;
  Locale get locale => _locale ?? MyLocalizations.defaultFallbackLocale;

  bool isLoading = false;

  UserProvider._({required UserRepository repository})
    : _repository = repository {
    _listenToUser();
  }

  void _listenToUser() {
    _repository.getUser().listen((newUser) async {
      await setUser(newUser);
    });
  }

  static Future<UserProvider> create({
    required UserRepository repository,
  }) async {
    final provider = UserProvider._(repository: repository);
    await provider._initLanguage();
    return provider;
  }

  Future<void> fetchUser() async {
    isLoading = true;
    notifyListeners();
    try {
      final fetchedUser = await _repository.fetchUser();
      await setUser(fetchedUser);
    } catch (e) {
      debugPrint('Error fetching user: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _initLanguage() async {
    final prefs = await SharedPreferences.getInstance();

    // Migrate old locale format if necessary
    final oldLang = prefs.getString('language');
    final oldCountry = prefs.getString('languageCountry');
    if (oldLang != null) {
      await prefs.setString(
        'locale',
        Locale(oldLang, oldCountry).toLanguageTag(),
      );
      await prefs.remove('language');
      await prefs.remove('languageCountry');
    }

    final storedLocale = prefs.getString('locale');

    if (storedLocale == null || storedLocale.trim().isEmpty) {
      // Use system locale as default
      await setLocale(WidgetsBinding.instance.platformDispatcher.locale);
      return;
    }

    final parts = storedLocale.split(RegExp('[-_]'));

    await setLocale(
      Locale.fromSubtags(
        languageCode: parts.isNotEmpty ? parts[0] : 'en',
        scriptCode: parts.length == 3 ? parts[1] : null,
        countryCode: parts.length >= 2 ? parts[parts.length - 1] : null,
      ),
    );
  }

  Future<void> setUser(User? newUser) async {
    _user = newUser;
    await _setFirebaseUserId(newUser);
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    Locale resolvedLocale = MyLocalizations.resolveLocale(locale);

    if (_locale == resolvedLocale) return; // Prevent unnecessary work
    _locale = resolvedLocale;
    notifyListeners();
    await _persistAndSyncLocale(resolvedLocale);
  }

  Future<void> _persistAndSyncLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', locale.toLanguageTag());

    if (this.user == null) return; // no sync possible yet

    await _syncUserLocale(locale);
  }

  Future<void> _syncUserLocale(Locale locale) async {
    if (_user == null) return;
    try {
      final updatedUser = await _repository.updateLocale(locale);
      await setUser(updatedUser);
    } catch (e) {
      debugPrint('Error updating user locale: $e');
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
