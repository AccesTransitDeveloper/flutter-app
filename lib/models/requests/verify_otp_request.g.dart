// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verify_otp_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VerifyOtpRequest _$VerifyOtpRequestFromJson(Map<String, dynamic> json) =>
    VerifyOtpRequest(
      sendTo: (json['sendTo'] as num?)?.toInt(),
      countryPhoneCode: json['countryPhoneCode'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      enteredOTP: json['enteredOTP'] as String?,
      enteredOTPMail: json['enteredOTPMail'] as String?,
    );

Map<String, dynamic> _$VerifyOtpRequestToJson(VerifyOtpRequest instance) =>
    <String, dynamic>{
      'sendTo': ?instance.sendTo,
      'countryPhoneCode': ?instance.countryPhoneCode,
      'phone': ?instance.phone,
      'email': ?instance.email,
      'enteredOTP': ?instance.enteredOTP,
      'enteredOTPMail': ?instance.enteredOTPMail,
    };
