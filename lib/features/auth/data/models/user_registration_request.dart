import 'package:json_annotation/json_annotation.dart';
import 'package:mosquito_alert_app/core/data/models/requests.dart';
import 'package:mosquito_alert_app/features/auth/domain/models/auth_user.dart';

part 'user_registration_request.g.dart';

@JsonSerializable()
class UserRegistrationRequest extends CreateRequest {
  final String password;
  final String? username;

  UserRegistrationRequest({
    required this.password,
    this.username,
    required super.localId,
  });

  factory UserRegistrationRequest.fromModel(AuthUser model) {
    return UserRegistrationRequest(
      username: model.username,
      password: model.password,
      localId: model.localId!,
    );
  }

  factory UserRegistrationRequest.fromJson(Map<String, dynamic> json) =>
      _$UserRegistrationRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UserRegistrationRequestToJson(this);
}
