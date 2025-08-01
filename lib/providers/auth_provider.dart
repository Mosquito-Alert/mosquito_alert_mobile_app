import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mosquito_alert/mosquito_alert.dart';

class AuthProvider with ChangeNotifier {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  late final AuthApi authApi;

  String? _accessToken;
  String? _refreshToken;
  String? _username;
  String? _password;

  Future<void> init() async {
    _accessToken = await _storage.read(key: 'access_token');
    _refreshToken = await _storage.read(key: 'refresh_token');
    _username = await _storage.read(key: 'username');
    _password = await _storage.read(key: 'password');
    notifyListeners();
  }

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  String? get username => _username;
  String? get password => _password;

  void setApiClient(MosquitoAlert apiClient) {
    authApi = apiClient.getAuthApi();
  }

  Future<void> _setUsername({required String username}) async {
    _username = username;
    await _storage.write(key: 'username', value: username);
    notifyListeners();
  }

  Future<void> _setPassword({required String password}) async {
    _password = password;
    await _storage.write(key: 'password', value: password);
    notifyListeners();
  }

  Future<void> setAccessToken({required String accessToken}) async {
    _accessToken = accessToken;
    await _storage.write(key: 'access_token', value: accessToken);
    notifyListeners();
  }

  Future<void> setRefreshToken({required String refreshToken}) async {
    _refreshToken = refreshToken;
    await _storage.write(key: 'refresh_token', value: refreshToken);
    notifyListeners();
  }

  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    notifyListeners();
  }

  Future<GuestRegistration> createGuestUser({required String password}) async {
    final GuestRegistrationRequest guestRegistrationRequest =
        GuestRegistrationRequest((b) => b..password = password);
    try {
      final Response<GuestRegistration> response = await authApi.signupGuest(
          guestRegistrationRequest: guestRegistrationRequest);

      if (response.statusCode == 201 && response.data != null) {
        return response.data!;
      } else {
        throw Exception(
          'Failed to create guest user: StatusCode=${response.statusCode}, '
          'Username=${response.data?.username}',
        );
      }
    } catch (e) {
      print('Error creating user: $e');
      rethrow;
    }
  }

  Future<void> login(
      {required String username, required String password}) async {
    try {
      final deviceInfoPlugin = DeviceInfoPlugin();
      final deviceInfo = await deviceInfoPlugin.deviceInfo;

      String? deviceId;
      if (deviceInfo is AndroidDeviceInfo) {
        deviceId = deviceInfo.id;
      } else if (deviceInfo is IosDeviceInfo) {
        deviceId = deviceInfo.identifierForVendor;
      }

      final AppUserTokenObtainPairRequest request =
          AppUserTokenObtainPairRequest((b) => b
            ..username = username
            ..password = password
            ..deviceId = deviceId);

      final Response<AppUserTokenObtainPair> response =
          await authApi.obtainToken(appUserTokenObtainPairRequest: request);

      if (response.statusCode == 200 && response.data != null) {
        _setUsername(username: username);
        _setPassword(password: password);
        setAccessToken(accessToken: response.data!.access);
        setRefreshToken(refreshToken: response.data!.refresh);
        return;
      } else {
        throw Exception(
            'Login failed: Server responded with status ${response.statusCode}');
      }
    } catch (e) {
      print("Login failed: $e");
      rethrow;
    }
  }
}
