import 'package:dio/dio.dart';
import 'package:mosquito_alert/mosquito_alert.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mosquito_alert_app/env/env.dart';
import 'package:mosquito_alert_app/features/device/presentation/state/data/device_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mosquito_alert_app/features/auth/utils/random.dart';

class AuthRepository {
  static final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _usernameKey = 'username';
  static const _passwordKey = 'password';
  static const _deviceIdKey = 'device_id';
  static const _autoChangePasswordKey = 'auto_change_password';
  static const _needsGuestAccountKey = 'needs_guest_account';

  final AuthApi _authApi;

  final Future<Device> Function()? getCurrentDevice;

  AuthRepository({required MosquitoAlert apiClient, this.getCurrentDevice})
    : _authApi = apiClient.getAuthApi();

  static Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  static Future<void> setAccessToken(String accessToken) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
  }

  static Future<void> setNeedsGuestAccount(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_needsGuestAccountKey, value);
  }

  static Future<bool> getNeedsGuestAccount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_needsGuestAccountKey) ?? false;
  }

  Future<void> createGuestAccount() async {
    final password = getRandomPassword(10);
    final request = GuestRegistrationRequest((b) => b..password = password);
    final response = await _authApi.signupGuest(
      guestRegistrationRequest: request,
    );
    final username = response.data!.username;
    return login(username: username, password: password);
  }

  // -------- LOGIN --------
  Future<void> login({
    required String username,
    required String password,
    Device? device,
  }) async {
    String? deviceId = device?.deviceId;
    if (device == null) {
      final lastLoggedInDeviceId = await _storage.read(key: _deviceIdKey);
      final currentDeviceId = await DeviceRepository.getDeviceId();
      if (lastLoggedInDeviceId != null &&
          lastLoggedInDeviceId == currentDeviceId) {
        // Device has not changed, use current device
        deviceId = currentDeviceId;
      }
    }

    final request = AppUserTokenObtainPairRequest(
      (b) => b
        ..username = username
        ..password = password
        ..deviceId = deviceId,
    );

    final response = await _authApi.obtainToken(
      appUserTokenObtainPairRequest: request,
    );

    await _storage.write(key: _usernameKey, value: username);
    await _storage.write(key: _passwordKey, value: password);
    await _storage.write(key: _deviceIdKey, value: deviceId);
    await _storage.write(key: _accessTokenKey, value: response.data!.access);
    await _storage.write(key: _refreshTokenKey, value: response.data!.refresh);

    final autoChangePassword = await _storage.read(key: _autoChangePasswordKey);
    if (autoChangePassword != null) {
      try {
        await changePassword(password: autoChangePassword);
        await _storage.delete(key: _autoChangePasswordKey);
      } on DioException catch (_) {
        // Ignore password change errors
      } catch (e) {
        rethrow;
      }
    }

    if (deviceId == null && getCurrentDevice != null) {
      try {
        return login(
          username: username,
          password: password,
          device: await getCurrentDevice!(),
        );
      } catch (e) {
        // Ignore errors retrieving device
      }
    }
  }

  Future<void> changePassword({required String password}) async {
    final request = PasswordChangeRequest((b) => b..password = password);

    await _authApi.changePassword(passwordChangeRequest: request);
    await _storage.write(key: _passwordKey, value: password);
  }

  // -------- RESTORE SESSION (OFFLINE SAFE) --------
  Future<bool> restoreSession() async {
    final access = await _storage.read(key: _accessTokenKey);
    final refresh = await _storage.read(key: _refreshTokenKey);
    if (access != null && refresh != null) {
      final lastLoggedInDeviceId = await _storage.read(key: _deviceIdKey);
      final currentDeviceId = await DeviceRepository.getDeviceId();
      if (lastLoggedInDeviceId != null &&
          lastLoggedInDeviceId == currentDeviceId) {
        // TODO: what if the mobile app has been updated? or any of the nested options for a device. checking ID is not enough.
        // Device has not changed, so the session can be restored using JWT tokens.
        try {
          await _authApi.refreshToken(
            tokenRefreshRequest: TokenRefreshRequest(
              (b) => b..refresh = refresh,
            ),
          );
          return true;
        } on DioException catch (e) {
          if (e.response?.statusCode != null && e.response!.statusCode! < 500) {
            // Invalid tokens
            await _storage.delete(key: _accessTokenKey);
            await _storage.delete(key: _refreshTokenKey);
          }
        }
      }
    }

    String? username = await _storage.read(key: _usernameKey);
    String? password = await _storage.read(key: _passwordKey);
    // Migrate old auth system if needed
    if (username == null && password == null) {
      final prefs = await SharedPreferences.getInstance();
      String? legacyUsername = prefs.getString('uuid');
      if (legacyUsername != null) {
        username = legacyUsername;
        password = Env.oldPassword;
        await _storage.write(
          key: _autoChangePasswordKey,
          value: getRandomPassword(10),
        );
        await prefs.remove('uuid');
      }
    }

    if (username != null && password != null) {
      try {
        await login(username: username, password: password);
        return true;
      } on DioException catch (e) {
        if (e.response?.statusCode != null && e.response!.statusCode! < 500) {
          // Invalid credentials
          await _storage.delete(key: _usernameKey);
          await _storage.delete(key: _passwordKey);
        }
      }
    }

    return false;
  }

  // -------- LOGOUT --------
  Future<void> logout() async {
    await _storage.deleteAll();
  }
}
