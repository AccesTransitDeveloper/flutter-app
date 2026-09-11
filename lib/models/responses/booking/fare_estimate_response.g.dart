// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fare_estimate_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FareEstimateResponse _$FareEstimateResponseFromJson(
  Map<String, dynamic> json,
) => FareEstimateResponse(
  priceDetail: json['priceDetail'] == null
      ? null
      : InvoiceDetail.fromJson(json['priceDetail'] as Map<String, dynamic>),
  deliveryOptions: (json['deliveryOptions'] as List<dynamic>?)
      ?.map((e) => DeliveryOption.fromJson(e as Map<String, dynamic>))
      .toList(),
  modifiers: (json['modifiers'] as List<dynamic>?)
      ?.map((e) => ItemModifier.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$FareEstimateResponseToJson(
  FareEstimateResponse instance,
) => <String, dynamic>{
  'priceDetail': instance.priceDetail,
  'deliveryOptions': instance.deliveryOptions,
  'modifiers': instance.modifiers,
};

DeliveryOption _$DeliveryOptionFromJson(Map<String, dynamic> json) =>
    DeliveryOption(
      id: json['_id'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      deliveryOption: json['deliveryOption'] as String?,
      cutOffTime: (json['cutOffTime'] as num?)?.toInt(),
      noOfDay: (json['noOfDay'] as num?)?.toInt(),
      estimatedDeliveryTime: (json['estimatedDeliveryTime'] as num?)?.toInt(),
    );

Map<String, dynamic> _$DeliveryOptionToJson(DeliveryOption instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'price': instance.price,
      'deliveryOption': instance.deliveryOption,
      'cutOffTime': instance.cutOffTime,
      'noOfDay': instance.noOfDay,
      'estimatedDeliveryTime': instance.estimatedDeliveryTime,
    };

ItemModifier _$ItemModifierFromJson(Map<String, dynamic> json) => ItemModifier(
  id: json['_id'] as String?,
  name: json['name'] as String?,
  price: (json['price'] as num?)?.toDouble(),
);

Map<String, dynamic> _$ItemModifierToJson(ItemModifier instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'name': instance.name,
      'price': instance.price,
    };
