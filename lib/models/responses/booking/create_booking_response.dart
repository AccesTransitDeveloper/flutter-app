import 'package:json_annotation/json_annotation.dart';

part 'create_booking_response.g.dart';

@JsonSerializable()
class CreateBookingResponse {
  final int? paymentGatewayType;
  final String? paymentTransactionId;
  final int? paymentTransactionStatus;
  @JsonKey(name: 'intent')
  final IntentPayment? intentPayment;
  final bool? isCapturePaymentPending;

  CreateBookingResponse({
    this.paymentGatewayType,
    this.paymentTransactionId,
    this.paymentTransactionStatus,
    this.intentPayment,
    this.isCapturePaymentPending,
  });

  factory CreateBookingResponse.fromJson(Map<String, dynamic> json) =>
      _$CreateBookingResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CreateBookingResponseToJson(this);
}

@JsonSerializable()
class IntentPayment {
  final String? clientSecret;
  final String? paymentIntentId;

  IntentPayment({
    this.clientSecret,
    this.paymentIntentId,
  });

  factory IntentPayment.fromJson(Map<String, dynamic> json) =>
      _$IntentPaymentFromJson(json);

  Map<String, dynamic> toJson() => _$IntentPaymentToJson(this);
}
