// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'corporate_payment_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CorporatePaymentResponse _$CorporatePaymentResponseFromJson(
  Map<String, dynamic> json,
) => CorporatePaymentResponse(
  paymentGateways: (json['paymentGateways'] as List<dynamic>?)
      ?.map((e) => (e as num).toInt())
      .toList(),
);

Map<String, dynamic> _$CorporatePaymentResponseToJson(
  CorporatePaymentResponse instance,
) => <String, dynamic>{'paymentGateways': instance.paymentGateways};
