// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'validate_promo_code_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ValidatePromoCodeRequest _$ValidatePromoCodeRequestFromJson(
  Map<String, dynamic> json,
) => ValidatePromoCodeRequest(
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
  promoCode: json['promoCode'] as String?,
  paymentMethod: (json['paymentMethod'] as num?)?.toInt(),
  cityId: json['cityId'] as String?,
  bookingTime: (json['bookingTime'] as num?)?.toInt(),
  vehicleTypeId: json['vehicleTypeId'] as String?,
  priceMode: (json['priceMode'] as num?)?.toInt(),
);

Map<String, dynamic> _$ValidatePromoCodeRequestToJson(
  ValidatePromoCodeRequest instance,
) => <String, dynamic>{
  'latitude': ?instance.latitude,
  'longitude': ?instance.longitude,
  'promoCode': ?instance.promoCode,
  'paymentMethod': ?instance.paymentMethod,
  'cityId': ?instance.cityId,
  'bookingTime': ?instance.bookingTime,
  'vehicleTypeId': ?instance.vehicleTypeId,
  'priceMode': ?instance.priceMode,
};
