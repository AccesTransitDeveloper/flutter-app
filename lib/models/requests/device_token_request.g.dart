// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_token_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceTokenRequest _$DeviceTokenRequestFromJson(Map<String, dynamic> json) =>
    DeviceTokenRequest(
      deviceId: json['deviceId'] as String,
      manufacturer: json['manufacturer'] as String,
      deviceName: json['deviceName'] as String,
      deviceType: $enumDecode(_$DeviceTypeEnumMap, json['deviceType']),
      os: json['os'] as String,
      appVersion: json['appVersion'] as String,
    );

Map<String, dynamic> _$DeviceTokenRequestToJson(DeviceTokenRequest instance) =>
    <String, dynamic>{
      'deviceId': instance.deviceId,
      'manufacturer': instance.manufacturer,
      'deviceName': instance.deviceName,
      'deviceType': _$DeviceTypeEnumMap[instance.deviceType]!,
      'os': instance.os,
      'appVersion': instance.appVersion,
    };

const _$DeviceTypeEnumMap = {
  DeviceType.android: 'ANDROID',
  DeviceType.ios: 'IOS',
};
