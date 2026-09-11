// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'check_registered_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CheckRegisteredRequest _$CheckRegisteredRequestFromJson(
  Map<String, dynamic> json,
) => CheckRegisteredRequest(
  loginBy: (json['loginBy'] as num).toInt(),
  countryPhoneCode: json['countryPhoneCode'] as String?,
  phone: json['phone'] as String?,
  email: json['email'] as String?,
  socialId: json['socialId'] as String?,
);

Map<String, dynamic> _$CheckRegisteredRequestToJson(
  CheckRegisteredRequest instance,
) => <String, dynamic>{
  'loginBy': instance.loginBy,
  'countryPhoneCode': ?instance.countryPhoneCode,
  'phone': ?instance.phone,
  'email': ?instance.email,
  'socialId': ?instance.socialId,
};
