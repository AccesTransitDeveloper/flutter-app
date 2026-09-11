// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'change_password_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChangePasswordRequest _$ChangePasswordRequestFromJson(
  Map<String, dynamic> json,
) => ChangePasswordRequest(
  sendTo: (json['sendTo'] as num?)?.toInt(),
  countryPhoneCode: json['countryPhoneCode'] as String?,
  phone: json['phone'] as String?,
  email: json['email'] as String?,
  password: json['password'] as String?,
  verificationToken: json['verificationToken'] as String?,
);

Map<String, dynamic> _$ChangePasswordRequestToJson(
  ChangePasswordRequest instance,
) => <String, dynamic>{
  'sendTo': ?instance.sendTo,
  'countryPhoneCode': ?instance.countryPhoneCode,
  'phone': ?instance.phone,
  'email': ?instance.email,
  'password': ?instance.password,
  'verificationToken': ?instance.verificationToken,
};
