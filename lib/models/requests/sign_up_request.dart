import 'package:json_annotation/json_annotation.dart';

part 'sign_up_request.g.dart';

@JsonSerializable(includeIfNull: false)
class SignUpRequest {
  final int? authMethod;
  final String? firstName;
  final String? lastName;
  final String? countryPhoneCode;
  final String? phone;
  final String? email;
  final String? countryCode;
  final String? creditCurrencyCode;
  final String? password;
  final String? referralCode;
  final String? socialId;

  SignUpRequest({
    this.authMethod,
    this.firstName,
    this.lastName,
    this.countryPhoneCode,
    this.phone,
    this.email,
    this.countryCode,
    this.creditCurrencyCode,
    this.password,
    this.referralCode,
    this.socialId,
  });

  factory SignUpRequest.fromJson(Map<String, dynamic> json) =>
      _$SignUpRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SignUpRequestToJson(this);
}
