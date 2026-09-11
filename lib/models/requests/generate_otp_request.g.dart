// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'generate_otp_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GenerateOtpRequest _$GenerateOtpRequestFromJson(Map<String, dynamic> json) =>
    GenerateOtpRequest(
      sendTo: (json['sendTo'] as num?)?.toInt(),
      countryPhoneCode: json['countryPhoneCode'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
    );

Map<String, dynamic> _$GenerateOtpRequestToJson(GenerateOtpRequest instance) =>
    <String, dynamic>{
      'sendTo': ?instance.sendTo,
      'countryPhoneCode': ?instance.countryPhoneCode,
      'phone': ?instance.phone,
      'email': ?instance.email,
    };
