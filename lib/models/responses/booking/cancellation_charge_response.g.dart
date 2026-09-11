// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cancellation_charge_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CancellationChargeResponse _$CancellationChargeResponseFromJson(
  Map<String, dynamic> json,
) => CancellationChargeResponse(
  charges: (json['charges'] as List<dynamic>?)
      ?.map((e) => Charge.fromJson(e as Map<String, dynamic>))
      .toList(),
  taxPrices: json['taxPrices'] as List<dynamic>?,
  total: (json['total'] as num?)?.toDouble(),
  driverProfit: (json['driverProfit'] as num?)?.toDouble(),
  notes: (json['notes'] as List<dynamic>?)?.map((e) => e as String).toList(),
);

Map<String, dynamic> _$CancellationChargeResponseToJson(
  CancellationChargeResponse instance,
) => <String, dynamic>{
  'charges': instance.charges,
  'taxPrices': instance.taxPrices,
  'total': instance.total,
  'driverProfit': instance.driverProfit,
  'notes': instance.notes,
};

Charge _$ChargeFromJson(Map<String, dynamic> json) => Charge(
  title: json['title'] as String?,
  price: (json['price'] as num?)?.toDouble(),
  type: (json['type'] as num?)?.toInt(),
);

Map<String, dynamic> _$ChargeToJson(Charge instance) => <String, dynamic>{
  'title': instance.title,
  'price': instance.price,
  'type': instance.type,
};
