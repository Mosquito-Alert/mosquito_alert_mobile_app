import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mosquito_alert_app/features/auth/data/auth_repository.dart';

class AuthProvider with ChangeNotifier {
  final AuthRepository _repository;

  late final StreamSubscription _sub;

  bool _hasCredentials = false;
  bool get hasCredentials => _hasCredentials;

  void _setHasCredentials(bool value) {
    _hasCredentials = value;
    if (!value) {
      _isAuthenticated = false;
    }
  }

  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  AuthProvider({required AuthRepository repository})
    : _repository = repository {
    _init();
  }

  Future<void> _init() async {
    _setHasCredentials(await _repository.hasCredentials());
    notifyListeners();
    _sub = _repository.authChanges.listen((hasCredentials) {
      _setHasCredentials(hasCredentials);
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  Future<void> restoreSession({bool forceLogin = false}) async {
    _isLoading = true;
    notifyListeners();
    try {
      _isAuthenticated = await _repository.restoreSession(
        forceLogin: forceLogin,
      );
    } catch (e) {
      _isAuthenticated = false;
    }

    // Self-heal: if the stored credentials were rejected and wiped during
    // restoreSession (so we now have no credentials at all) but the user has
    // previously completed onboarding on this install, silently create a
    // fresh guest account. This prevents users who hit a stale/rotated/
    // staging-server credential in their iOS Keychain from being bounced
    // back through the onboarding flow on every launch.
    if (!_isAuthenticated &&
        !_hasCredentials &&
        await _repository.wasOnboarded()) {
      try {
        await _createGuestAccountInternal();
      } catch (_) {
        // Best-effort: if recovery itself fails (e.g. no network), the
        // outbox will retry the registration on its next sync cycle.
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.login(username: username, password: password);
      _isAuthenticated = true;
    } catch (e) {
      _isAuthenticated = false;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createGuestAccount() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _createGuestAccountInternal();
    } catch (e) {
      _isAuthenticated = false;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Creates a guest account without touching `_isLoading`. Used both by the
  /// public [createGuestAccount] (which manages loading state) and by the
  /// self-heal path in [restoreSession].
  Future<void> _createGuestAccountInternal() async {
    final newUser = await _repository.createGuestAccount();
    if (newUser.isOffline) {
      _isAuthenticated = false;
      _setHasCredentials(true);
    } else {
      await _repository.login(
        username: newUser.username!,
        password: newUser.password,
      );
      _isAuthenticated = true;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.logout();
      _isAuthenticated = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
