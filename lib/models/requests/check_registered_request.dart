import 'package:json_annotation/json_annotation.dart';

part 'check_registered_request.g.dart';

@JsonSerializable(includeIfNull: false)
class CheckRegisteredRequest {
  final int loginBy;
  final String? countryPhoneCode;
  final String? phone;
  final String? email;
  final String? socialId;

  CheckRegisteredRequest({
    required this.loginBy,
    this.countryPhoneCode,
    this.phone,
    this.email,
    this.socialId,
  });

  factory CheckRegisteredRequest.fromJson(Map<String, dynamic> json) =>
      _$CheckRegisteredRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CheckRegisteredRequestToJson(this);
}
