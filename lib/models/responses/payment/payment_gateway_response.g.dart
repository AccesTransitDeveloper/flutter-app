// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_gateway_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentGatewayResponse _$PaymentGatewayResponseFromJson(
  Map<String, dynamic> json,
) => PaymentGatewayResponse(
  paymentGateways: (json['paymentGateways'] as List<dynamic>?)
      ?.map((e) => PaymentGateway.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$PaymentGatewayResponseToJson(
  PaymentGatewayResponse instance,
) => <String, dynamic>{'paymentGateways': instance.paymentGateways};

PaymentGateway _$PaymentGatewayFromJson(Map<String, dynamic> json) =>
    PaymentGateway(
      credential: json['credential'] == null
          ? null
          : Credential.fromJson(json['credential'] as Map<String, dynamic>),
      isAllowCaptureLater: json['isAllowCaptureLater'] as bool?,
      isAllowSaveBank: json['isAllowSaveBank'] as bool?,
      isAllowSaveCard: json['isAllowSaveCard'] as bool?,
      type: (json['type'] as num?)?.toInt(),
      name: json['name'] as String?,
    );

Map<String, dynamic> _$PaymentGatewayToJson(PaymentGateway instance) =>
    <String, dynamic>{
      'credential': instance.credential,
      'isAllowCaptureLater': instance.isAllowCaptureLater,
      'isAllowSaveBank': instance.isAllowSaveBank,
      'isAllowSaveCard': instance.isAllowSaveCard,
      'type': instance.type,
      'name': instance.name,
    };

Credential _$CredentialFromJson(Map<String, dynamic> json) =>
    Credential(publicKey: json['publicKey'] as String?);

Map<String, dynamic> _$CredentialToJson(Credential instance) =>
    <String, dynamic>{'publicKey': instance.publicKey};
