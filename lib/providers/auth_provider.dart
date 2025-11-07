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
  String? _deviceId;

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

  Future<void> setDevice(Device device) async {
    if (device.deviceId != _deviceId) {
      await login(username: _username!, password: _password!, device: device);
    }
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

  Future<void> _setDeviceId({required String? deviceId}) async {
    _deviceId = deviceId;
    await _storage.write(key: 'deviceId', value: deviceId);
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
    final guestRegistrationRequest =
        GuestRegistrationRequest((b) => b..password = password);
    final response = await authApi.signupGuest(
        guestRegistrationRequest: guestRegistrationRequest);

    return response.data!;
  }

  Future<void> changePassword({required String password}) async {
    final changePasswordRequest =
        PasswordChangeRequest((b) => b..password = password);

    await authApi.changePassword(passwordChangeRequest: changePasswordRequest);

    await _setPassword(password: password);
  }

  Future<void> login(
      {required String username,
      required String password,
      Device? device}) async {
    final request = AppUserTokenObtainPairRequest((b) => b
      ..username = username
      ..password = password
      ..deviceId = device?.deviceId ?? _deviceId);

    final response =
        await authApi.obtainToken(appUserTokenObtainPairRequest: request);

    _setUsername(username: username);
    _setPassword(password: password);
    _setDeviceId(deviceId: device?.deviceId);
    setAccessToken(accessToken: response.data!.access);
    setRefreshToken(refreshToken: response.data!.refresh);
  }
}
