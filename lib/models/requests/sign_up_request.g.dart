// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sign_up_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SignUpRequest _$SignUpRequestFromJson(Map<String, dynamic> json) =>
    SignUpRequest(
      authMethod: (json['authMethod'] as num?)?.toInt(),
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      countryPhoneCode: json['countryPhoneCode'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      countryCode: json['countryCode'] as String?,
      creditCurrencyCode: json['creditCurrencyCode'] as String?,
      password: json['password'] as String?,
      referralCode: json['referralCode'] as String?,
      socialId: json['socialId'] as String?,
    );

Map<String, dynamic> _$SignUpRequestToJson(SignUpRequest instance) =>
    <String, dynamic>{
      'authMethod': ?instance.authMethod,
      'firstName': ?instance.firstName,
      'lastName': ?instance.lastName,
      'countryPhoneCode': ?instance.countryPhoneCode,
      'phone': ?instance.phone,
      'email': ?instance.email,
      'countryCode': ?instance.countryCode,
      'creditCurrencyCode': ?instance.creditCurrencyCode,
      'password': ?instance.password,
      'referralCode': ?instance.referralCode,
      'socialId': ?instance.socialId,
    };
