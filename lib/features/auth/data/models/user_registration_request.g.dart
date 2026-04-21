// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_registration_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserRegistrationRequest _$UserRegistrationRequestFromJson(
  Map<String, dynamic> json,
) => UserRegistrationRequest(
  password: json['password'] as String,
  username: json['username'] as String?,
  localId: json['localId'] as String,
);

Map<String, dynamic> _$UserRegistrationRequestToJson(
  UserRegistrationRequest instance,
) => <String, dynamic>{
  'localId': instance.localId,
  'password': instance.password,
  'username': instance.username,
};
