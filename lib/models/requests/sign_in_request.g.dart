// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sign_in_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SignInRequest _$SignInRequestFromJson(Map<String, dynamic> json) =>
    SignInRequest(
      sendTo: (json['sendTo'] as num?)?.toInt(),
      loginBy: (json['loginBy'] as num?)?.toInt(),
      countryPhoneCode: json['countryPhoneCode'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      password: json['password'] as String?,
      enteredOTP: json['enteredOTP'] as String?,
      socialId: json['socialId'] as String?,
      language: json['language'] as String?,
    );

Map<String, dynamic> _$SignInRequestToJson(SignInRequest instance) =>
    <String, dynamic>{
      'sendTo': ?instance.sendTo,
      'loginBy': ?instance.loginBy,
      'countryPhoneCode': ?instance.countryPhoneCode,
      'phone': ?instance.phone,
      'email': ?instance.email,
      'password': ?instance.password,
      'enteredOTP': ?instance.enteredOTP,
      'socialId': ?instance.socialId,
      'language': ?instance.language,
    };
