import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:mosquito_alert/mosquito_alert.dart';

class UserProvider extends ChangeNotifier {
  final MosquitoAlert apiClient;

  UserProvider({required this.apiClient});

  User? _user;
  User? get user => _user;

  int get userScore => _user?.score.value ?? 0;

  set user(User? newUser) {
    _user = newUser;
    _setFirebaseUserId(newUser);
    notifyListeners();
  }

  Future<void> fetchUser() async {
    try {
      final response = await apiClient.getUsersApi().retrieveMine();
      user = response.data;
    } catch (e) {
      print('Error getting user: $e');
      user = null;
      rethrow;
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
