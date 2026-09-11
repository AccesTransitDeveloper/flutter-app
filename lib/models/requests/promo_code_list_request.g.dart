// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'promo_code_list_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PromoCodeListRequest _$PromoCodeListRequestFromJson(
  Map<String, dynamic> json,
) => PromoCodeListRequest(
  cityId: json['cityId'] as String?,
  countryId: json['countryId'] as String?,
  vehicleTypeId: json['vehicleTypeId'] as String?,
  priceMode: (json['priceMode'] as num?)?.toInt(),
  businessType: (json['businessType'] as num?)?.toInt(),
);

Map<String, dynamic> _$PromoCodeListRequestToJson(
  PromoCodeListRequest instance,
) => <String, dynamic>{
  'cityId': ?instance.cityId,
  'countryId': ?instance.countryId,
  'vehicleTypeId': ?instance.vehicleTypeId,
  'priceMode': ?instance.priceMode,
  'businessType': ?instance.businessType,
};
