// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_booking_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateBookingResponse _$CreateBookingResponseFromJson(
  Map<String, dynamic> json,
) => CreateBookingResponse(
  paymentGatewayType: (json['paymentGatewayType'] as num?)?.toInt(),
  paymentTransactionId: json['paymentTransactionId'] as String?,
  paymentTransactionStatus: (json['paymentTransactionStatus'] as num?)?.toInt(),
  intentPayment: json['intent'] == null
      ? null
      : IntentPayment.fromJson(json['intent'] as Map<String, dynamic>),
  isCapturePaymentPending: json['isCapturePaymentPending'] as bool?,
);

Map<String, dynamic> _$CreateBookingResponseToJson(
  CreateBookingResponse instance,
) => <String, dynamic>{
  'paymentGatewayType': instance.paymentGatewayType,
  'paymentTransactionId': instance.paymentTransactionId,
  'paymentTransactionStatus': instance.paymentTransactionStatus,
  'intent': instance.intentPayment,
  'isCapturePaymentPending': instance.isCapturePaymentPending,
};

IntentPayment _$IntentPaymentFromJson(Map<String, dynamic> json) =>
    IntentPayment(
      clientSecret: json['clientSecret'] as String?,
      paymentIntentId: json['paymentIntentId'] as String?,
    );

Map<String, dynamic> _$IntentPaymentToJson(IntentPayment instance) =>
    <String, dynamic>{
      'clientSecret': instance.clientSecret,
      'paymentIntentId': instance.paymentIntentId,
    };
