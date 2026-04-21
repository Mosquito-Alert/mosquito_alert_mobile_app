import 'package:flutter/material.dart';
import 'package:mosquito_alert_app/features/auth/data/auth_repository.dart';

class AuthProvider with ChangeNotifier {
  final AuthRepository _repository;

  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  AuthProvider({required AuthRepository repository}) : _repository = repository;

  Future<void> restoreSession() async {
    _isLoading = true;
    notifyListeners();
    try {
      _isAuthenticated = await _repository.restoreSession();
    } catch (e) {
      _isAuthenticated = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
      final newUser = await _repository.createGuestAccount();
      if (newUser.isOffline) {
        _isAuthenticated = false;
      } else {
        await login(username: newUser.username!, password: newUser.password);
      }
    } catch (e) {
      _isAuthenticated = false;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
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
