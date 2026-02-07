import 'package:hive_ce/hive.dart';
import 'package:flutter/material.dart';
import 'package:mosquito_alert/mosquito_alert.dart';
import 'package:dio/dio.dart';

class UserRepository {
  static const String itemBoxName = 'user';

  final UsersApi _usersApi;

  UserRepository({required MosquitoAlert apiClient})
    : _usersApi = apiClient.getUsersApi();

  final _box = Hive.box<User>(itemBoxName);

  Stream<User> getUser() async* {
    try {
      final cachedUser = _box.getAt(0);
      if (cachedUser != null) yield cachedUser;
    } catch (e) {
      // Ignore cache errors
    }
    try {
      yield await fetchUser();
    } catch (e) {
      // Ignore fetch errors
    }
  }

  Future<User> fetchUser() async {
    int attempts = 0;
    Duration delay = const Duration(seconds: 1);
    while (true) {
      try {
        final response = await _usersApi.retrieveMine();
        final networkUser = response.data!;
        try {
          await _box.putAt(0, networkUser);
        } on IndexError {
          await _box.add(networkUser);
        }
        return networkUser;
      } on DioException catch (e) {
        final isTransient =
            e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout;
        if (!isTransient || attempts >= 2) {
          rethrow;
        }
        await Future.delayed(delay);
        delay *= 2;
        attempts++;
      }
    }
  }

  Future<User> updateLocale(Locale locale) async {
    final user = _box.getAt(0);
    if (user == null) {
      throw Exception('No user to update');
    }

    final newCode = locale.languageCode.toLowerCase();
    // If already the same, skip API call
    if (user.languageIso == newCode) return user;

    final localeEnum = PatchedUserRequestLocaleEnum.values.firstWhere(
      (e) => e.name == newCode,
      orElse: () => PatchedUserRequestLocaleEnum.en,
    );

    final req = PatchedUserRequest((b) => b..locale = localeEnum);
    final response = await _usersApi.partialUpdate(
      uuid: user.uuid,
      patchedUserRequest: req,
    );
    final updatedUser = response.data!;
    await _box.putAt(0, updatedUser); // Update local cache
    return updatedUser;
  }
}
