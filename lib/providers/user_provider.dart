import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:mosquito_alert/mosquito_alert.dart';
import 'package:mosquito_alert/src/auth/jwt_auth.dart';
import 'package:mosquito_alert_app/api/api.dart';
import 'package:mosquito_alert_app/utils/UserManager.dart';

class UserProvider extends ChangeNotifier {
  User? _user;
  User? get user => _user;

  int get userScore => _user?.score.value ?? 0;

  Future<void> fetchUser() async {
    try {
      final response = await ApiSingleton.usersApi.retrieveMine();
      if (response.statusCode == 200 && response.data != null) {
        _user = response.data;
      }
    } catch (e) {
      print('Error getting user: $e');
      _user = null;
    } finally {
      notifyListeners();
    }
  }

  Future<bool?> createUser() async {
    try {
      // Try to authenticate with existing credentials first
      final apiUser = await UserManager.getApiUser();
      final apiPassword = await UserManager.getApiPassword();

      if (apiUser != null && apiPassword != null) {
        final success = await loginJwt(apiUser, apiPassword);
        if (success) {
          await fetchUser();
          return true;
        }
      }

      // No stored credentials or login failed - register as new guest
      final random = Random.secure();
      const chars =
          'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*';
      final guestPassword =
          List.generate(16, (index) => chars[random.nextInt(chars.length)])
              .join();

      final guestRegistrationRequest =
          GuestRegistrationRequest((b) => b..password = guestPassword);
      final registeredGuest = await ApiSingleton.authApi
          .signupGuest(guestRegistrationRequest: guestRegistrationRequest);

      final username = registeredGuest.data?.username;
      if (username == null) {
        return false;
      }

      await UserManager.setUser(username, guestPassword);

      if (!await loginJwt(username, guestPassword)) return false;

      await fetchUser();
      return true;
    } catch (e) {
      print('Error creating user: $e');
      return null;
    }
  }

  Future<bool> loginJwt(String user, String password) async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    final deviceInfo = await deviceInfoPlugin.deviceInfo;
    String? deviceId;
    if (deviceInfo is AndroidDeviceInfo) {
      deviceId = deviceInfo.id;
    } else if (deviceInfo is IosDeviceInfo) {
      deviceId = deviceInfo.identifierForVendor;
    }
    AppUserTokenObtainPairRequest appUserTokenObtainPairRequest =
        AppUserTokenObtainPairRequest((b) => b
          ..username = user
          ..password = password
          ..deviceId = deviceId);
    try {
      final obtainToken = await ApiSingleton.authApi.obtainToken(
          appUserTokenObtainPairRequest: appUserTokenObtainPairRequest);
      if (obtainToken.data?.access != null &&
          obtainToken.data?.refresh != null) {
        ApiSingleton.api.dio.interceptors.clear();
        ApiSingleton.api.dio.interceptors.add(JwtAuthInterceptor(
          apiClient: ApiSingleton.api,
          accessToken: obtainToken.data!.access,
          refreshToken: obtainToken.data!.refresh,
        ));
        await UserManager.setToken(obtainToken.data!.access);
        await UserManager.setRefreshToken(obtainToken.data!.refresh);
        return true;
      }
    } catch (e) {
      print("Login failed: $e");
    }
    return false;
  }
}
