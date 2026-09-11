// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'accessibility_preference.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AccessibilityPreference _$AccessibilityPreferenceFromJson(
  Map<String, dynamic> json,
) => AccessibilityPreference(
  id: json['_id'] as String?,
  accessibility: json['accessibility'] as String?,
  priceStr: json['priceStr'] as String?,
  price: (json['price'] as num?)?.toDouble(),
);

Map<String, dynamic> _$AccessibilityPreferenceToJson(
  AccessibilityPreference instance,
) => <String, dynamic>{
  '_id': instance.id,
  'accessibility': instance.accessibility,
  'priceStr': instance.priceStr,
  'price': instance.price,
};
