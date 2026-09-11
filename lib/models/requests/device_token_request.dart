import 'package:json_annotation/json_annotation.dart';

part 'device_token_request.g.dart';

enum DeviceType {
  @JsonValue('ANDROID')
  android,
  @JsonValue('IOS')
  ios;
}

@JsonSerializable()
class DeviceTokenRequest {
  final String deviceId;
  final String manufacturer;
  final String deviceName;
  final DeviceType deviceType;
  final String os;
  final String appVersion;

  DeviceTokenRequest({
    required this.deviceId,
    required this.manufacturer,
    required this.deviceName,
    required this.deviceType,
    required this.os,
    required this.appVersion,
  });

  factory DeviceTokenRequest.fromJson(Map<String, dynamic> json) =>
      _$DeviceTokenRequestFromJson(json);

  Map<String, dynamic> toJson() => _$DeviceTokenRequestToJson(this);
}
