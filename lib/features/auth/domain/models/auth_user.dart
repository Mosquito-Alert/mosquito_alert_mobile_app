import 'package:mosquito_alert_app/core/outbox/outbox_offline_model.dart';
import 'package:mosquito_alert_app/features/auth/data/models/user_registration_request.dart';

class AuthUser extends OfflineModel {
  final String password;
  final String? username;

  AuthUser({required this.password, this.username, super.localId});
  factory AuthUser.fromCreateRequest(UserRegistrationRequest userRegistration) {
    return AuthUser(
      localId: userRegistration.localId,
      username: userRegistration.username,
      password: userRegistration.password,
    );
  }
}
