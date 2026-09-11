import 'package:json_annotation/json_annotation.dart';

part 'change_password_request.g.dart';

@JsonSerializable(includeIfNull: false)
class ChangePasswordRequest {
  final int? sendTo;
  final String? countryPhoneCode;
  final String? phone;
  final String? email;
  final String? password;
  final String? verificationToken;

  ChangePasswordRequest({
    this.sendTo,
    this.countryPhoneCode,
    this.phone,
    this.email,
    this.password,
    this.verificationToken,
  });

  factory ChangePasswordRequest.fromJson(Map<String, dynamic> json) =>
      _$ChangePasswordRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ChangePasswordRequestToJson(this);
}
