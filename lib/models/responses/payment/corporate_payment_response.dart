import 'package:json_annotation/json_annotation.dart';

part 'corporate_payment_response.g.dart';

@JsonSerializable()
class CorporatePaymentResponse {
  final List<int>? paymentGateways;

  CorporatePaymentResponse({this.paymentGateways});

  factory CorporatePaymentResponse.fromJson(Map<String, dynamic> json) =>
      _$CorporatePaymentResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CorporatePaymentResponseToJson(this);
}
