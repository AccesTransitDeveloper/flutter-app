import 'package:json_annotation/json_annotation.dart';

part 'verify_otp_request.g.dart';

@JsonSerializable(includeIfNull: false)
class VerifyOtpRequest {
  final int? sendTo;
  final String? countryPhoneCode;
  final String? phone;
  final String? email;
  final String? enteredOTP;

  /// Email OTP. Native sends this alongside [enteredOTP] in a single call when
  /// both verifications are on (RegisterViewModel.verifyOtp) — without it the
  /// server only ever saw the phone code.
  final String? enteredOTPMail;

  VerifyOtpRequest({
    this.sendTo,
    this.countryPhoneCode,
    this.phone,
    this.email,
    this.enteredOTP,
    this.enteredOTPMail,
  });

  factory VerifyOtpRequest.fromJson(Map<String, dynamic> json) =>
      _$VerifyOtpRequestFromJson(json);

  Map<String, dynamic> toJson() => _$VerifyOtpRequestToJson(this);
}
