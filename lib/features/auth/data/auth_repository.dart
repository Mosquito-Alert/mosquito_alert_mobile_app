import 'dart:async';

import 'package:dio/dio.dart';
import 'package:hive_ce/hive.dart';
import 'package:mosquito_alert/mosquito_alert.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mosquito_alert_app/core/outbox/outbox_item.dart';
import 'package:mosquito_alert_app/core/outbox/outbox_mixin.dart';
import 'package:mosquito_alert_app/env/env.dart';
import 'package:mosquito_alert_app/features/auth/data/models/user_registration_request.dart';
import 'package:mosquito_alert_app/features/auth/domain/models/auth_user.dart';
import 'package:mosquito_alert_app/features/device/data/device_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mosquito_alert_app/features/auth/utils/random.dart';
import 'package:uuid/uuid.dart';

class AuthRepository with OutboxMixin<AuthUser, UserRegistrationRequest> {
  final _authController = StreamController<bool>.broadcast();

  static final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _usernameKey = 'username';
  static const _passwordKey = 'password';
  static const _deviceIdKey = 'device_id';
  static const _autoChangePasswordKey = 'auto_change_password';

  late final AuthApi _authApi;

  final Future<Device> Function()? getCurrentDevice;

  AuthRepository._({required MosquitoAlert apiClient, this.getCurrentDevice})
    : _authApi = apiClient.getAuthApi();

  static Future<AuthRepository> create({
    required MosquitoAlert apiClient,
    Future<Device> Function()? getCurrentDevice,
  }) async {
    final repository = AuthRepository._(
      apiClient: apiClient,
      getCurrentDevice: getCurrentDevice,
    );

    await repository._init();
    return repository;
  }

  Future<void> _init() async {
    String? username = await _storage.read(key: _usernameKey);
    String? password = await _storage.read(key: _passwordKey);

    // Migrate old auth system if needed
    if (username == null && password == null) {
      final prefs = await SharedPreferences.getInstance();
      final String? legacyUsername = prefs.getString('uuid');
      if (legacyUsername != null) {
        username = legacyUsername;
        password = Env.oldPassword;

        await _setCredentials(username: username, password: password);
        await _storage.write(
          key: _autoChangePasswordKey,
          value: getRandomPassword(10),
        );
        await prefs.remove('uuid');
      }
    }

    _authController.add(await hasCredentials());
  }

  static const itemBoxName = 'offline_auth';

  @override
  bool get requiresAuth => false;

  @override
  String get repoName => 'auth';

  @override
  Box<AuthUser> get itemBox => Hive.box<AuthUser>(itemBoxName);

  @override
  AuthUser buildItemFromCreateRequest(UserRegistrationRequest request) {
    return AuthUser.fromCreateRequest(request);
  }

  @override
  UserRegistrationRequest createRequestFactory(Map<String, dynamic> payload) {
    return UserRegistrationRequest.fromJson(payload);
  }

  @override
  UserRegistrationRequest buildCreateRequestFromItem(AuthUser item) {
    return UserRegistrationRequest.fromModel(item);
  }

  @override
  OutboxTask buildOutboxTaskFromItem({required OutboxItem item}) {
    return OutboxTask(
      item: item,
      action: () async {
        switch (item.operation) {
          case OutBoxOperation.create:
            final request = createRequestFactory(item.payload);
            try {
              final newUser = await _sendCreateGuestToApi(request: request);
              await login(
                username: newUser.username!,
                password: newUser.password,
              );
            } catch (e) {
              print('Error processing create guest account outbox item: $e');
              rethrow;
            }
            break;
          default:
            throw Exception("Unknown op: ${item.operation}");
        }
      },
    );
  }

  static Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  static Future<void> setAccessToken(String accessToken) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
  }

  Future<void> _setCredentials({
    required String username,
    required String password,
  }) async {
    await _storage.write(key: _usernameKey, value: username);
    await _storage.write(key: _passwordKey, value: password);
    _authController.add(true);
  }

  Stream<bool> get authChanges => _authController.stream;

  Future<bool> hasCredentials() async {
    final username = await _storage.read(key: _usernameKey);
    final password = await _storage.read(key: _passwordKey);
    final hasOfflineCredentials = itemBox.isNotEmpty;
    return hasOfflineCredentials || (username != null && password != null);
  }

  Future<AuthUser> _sendCreateGuestToApi({
    required UserRegistrationRequest request,
  }) async {
    final response = await _authApi.signupGuest(
      guestRegistrationRequest: GuestRegistrationRequest(
        (b) => b..password = request.password,
      ),
    );
    // Not setting localId since the user is already created in the backend
    // and we won't be syncing it from the outbox
    return AuthUser(
      username: response.data!.username,
      password: request.password,
    );
  }

  Future<AuthUser> _createGuestApiOrLocal({
    required UserRegistrationRequest request,
  }) async {
    AuthUser newAuthUser;
    try {
      newAuthUser = await _sendCreateGuestToApi(request: request);
      await itemBox.delete(request.localId);
    } on DioException catch (_) {
      newAuthUser = buildItemFromCreateRequest(request);
    }
    return newAuthUser;
  }

  Future<AuthUser> createGuestAccount() async {
    final request = UserRegistrationRequest(
      password: getRandomPassword(10),
      localId: Uuid().v4(),
    );
    final newGuestAuthUser = await _createGuestApiOrLocal(request: request);
    if (newGuestAuthUser.localId != null) {
      final createItem = OutboxItem(
        id: request.localId,
        repository: repoName,
        operation: OutBoxOperation.create,
        payload: request.toJson(),
      );
      final createTask = buildOutboxTaskFromItem(item: createItem);
      await schedule(createTask, runNow: false);
      _authController.add(true);
    }
    return newGuestAuthUser;
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

    await _setCredentials(username: username, password: password);
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
    final username = await _storage.read(key: _usernameKey);
    await _setCredentials(username: username!, password: password);
  }

  // -------- RESTORE SESSION (OFFLINE SAFE) --------
  Future<bool> restoreSession({bool forceLogin = false}) async {
    final access = await getAccessToken();
    final refresh = await getRefreshToken();
    if (!forceLogin && access != null && refresh != null) {
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
          if (e.response?.statusCode != null && e.response!.statusCode == 400) {
            // Invalid tokens
            await _storage.delete(key: _accessTokenKey);
            await _storage.delete(key: _refreshTokenKey);
          }
        }
      }
    }

    String? username = await _storage.read(key: _usernameKey);
    String? password = await _storage.read(key: _passwordKey);
    if (username != null && password != null) {
      try {
        await login(username: username, password: password);
        return true;
      } on DioException catch (e) {
        final status = e.response?.statusCode;
        if (status == 400 || status == 401) {
          await logout();
        }
      }
    }

    return false;
  }

  // -------- LOGOUT --------
  Future<void> logout() async {
    // TODO: Ensure all itemBox data is cleared across repositories.
    // Otherwise, stale data may persist and be re-associated with the next logged-in user.
    await itemBox.clear();
    await _storage.deleteAll();
    _authController.add(false);
  }
}
