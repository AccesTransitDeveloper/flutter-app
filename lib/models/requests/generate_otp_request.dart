import 'package:json_annotation/json_annotation.dart';

part 'generate_otp_request.g.dart';

@JsonSerializable(includeIfNull: false)
class GenerateOtpRequest {
  final int? sendTo;
  final String? countryPhoneCode;
  final String? phone;
  final String? email;

  GenerateOtpRequest({
    this.sendTo,
    this.countryPhoneCode,
    this.phone,
    this.email,
  });

  factory GenerateOtpRequest.fromJson(Map<String, dynamic> json) =>
      _$GenerateOtpRequestFromJson(json);

  Map<String, dynamic> toJson() => _$GenerateOtpRequestToJson(this);
}
