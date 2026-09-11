// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'card_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetCardsResponse _$GetCardsResponseFromJson(Map<String, dynamic> json) =>
    GetCardsResponse(
      cards: (json['cards'] as List<dynamic>?)
          ?.map((e) => CardResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$GetCardsResponseToJson(GetCardsResponse instance) =>
    <String, dynamic>{'cards': instance.cards};

CardResponse _$CardResponseFromJson(Map<String, dynamic> json) => CardResponse(
  cardType: json['cardType'] as String?,
  fingerprint: json['fingerprint'] as String?,
  id: json['_id'] as String?,
  isDefault: json['isDefault'] as bool?,
  lastFour: json['lastFour'] as String?,
  paymentCustomerId: json['paymentCustomerId'] as String?,
  paymentGatewayType: (json['paymentGatewayType'] as num?)?.toInt(),
  paymentGatewayTypeId: json['paymentGatewayTypeId'] as String?,
  token: json['token'] as String?,
  type: (json['type'] as num?)?.toInt(),
  typeId: json['typeId'] as String?,
  cardName: json['cardName'] as String?,
  isEnable: json['isEnable'] as bool?,
);

Map<String, dynamic> _$CardResponseToJson(CardResponse instance) =>
    <String, dynamic>{
      'cardType': instance.cardType,
      'fingerprint': instance.fingerprint,
      '_id': instance.id,
      'isDefault': instance.isDefault,
      'lastFour': instance.lastFour,
      'paymentCustomerId': instance.paymentCustomerId,
      'paymentGatewayType': instance.paymentGatewayType,
      'paymentGatewayTypeId': instance.paymentGatewayTypeId,
      'token': instance.token,
      'type': instance.type,
      'typeId': instance.typeId,
      'cardName': instance.cardName,
      'isEnable': instance.isEnable,
    };
