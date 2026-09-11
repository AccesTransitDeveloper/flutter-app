// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_profile_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateProfileRequest _$UpdateProfileRequestFromJson(
  Map<String, dynamic> json,
) => UpdateProfileRequest(
  enteredOTP: json['enteredOTP'] as String?,
  enteredOTPMail: json['enteredOTPMail'] as String?,
  firstName: json['firstName'] as String?,
  lastName: json['lastName'] as String?,
  countryPhoneCode: json['countryPhoneCode'] as String?,
  phone: json['phone'] as String?,
  sendTo: (json['sendTo'] as num?)?.toInt(),
  email: json['email'] as String?,
  password: json['password'] as String?,
  newPassword: json['newPassword'] as String?,
  gender: json['gender'] as String?,
  countryCode: json['countryCode'] as String?,
);

Map<String, dynamic> _$UpdateProfileRequestToJson(
  UpdateProfileRequest instance,
) => <String, dynamic>{
  'enteredOTP': ?instance.enteredOTP,
  'enteredOTPMail': ?instance.enteredOTPMail,
  'firstName': ?instance.firstName,
  'lastName': ?instance.lastName,
  'countryPhoneCode': ?instance.countryPhoneCode,
  'phone': ?instance.phone,
  'sendTo': ?instance.sendTo,
  'email': ?instance.email,
  'password': ?instance.password,
  'newPassword': ?instance.newPassword,
  'gender': ?instance.gender,
  'countryCode': ?instance.countryCode,
};
