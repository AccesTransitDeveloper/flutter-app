// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'string_object.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StringObject _$StringObjectFromJson(Map<String, dynamic> json) => StringObject(
  common: json['COMMON'] as String?,
  taxi: json['TAXI'] as String?,
  quickCommerce: json['QUICK_COMMERCE'] as String?,
  delivery: json['DELIVERY'] as String?,
  service: json['SERVICE'] as String?,
  courier: json['COURIER'] as String?,
);

Map<String, dynamic> _$StringObjectToJson(StringObject instance) =>
    <String, dynamic>{
      'COMMON': instance.common,
      'TAXI': instance.taxi,
      'QUICK_COMMERCE': instance.quickCommerce,
      'DELIVERY': instance.delivery,
      'SERVICE': instance.service,
      'COURIER': instance.courier,
    };
