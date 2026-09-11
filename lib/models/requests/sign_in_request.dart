import 'package:json_annotation/json_annotation.dart';

part 'sign_in_request.g.dart';

@JsonSerializable(includeIfNull: false)
class SignInRequest {
  final int? sendTo;
  final int? loginBy;
  final String? countryPhoneCode;
  final String? phone;
  final String? email;
  final String? password;
  final String? enteredOTP;
  final String? socialId;
  final String? language;

  SignInRequest({
    this.sendTo,
    this.loginBy,
    this.countryPhoneCode,
    this.phone,
    this.email,
    this.password,
    this.enteredOTP,
    this.socialId,
    this.language,
  });

  factory SignInRequest.fromJson(Map<String, dynamic> json) =>
      _$SignInRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SignInRequestToJson(this);
}
