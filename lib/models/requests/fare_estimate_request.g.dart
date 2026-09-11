// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fare_estimate_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FareEstimateRequest _$FareEstimateRequestFromJson(Map<String, dynamic> json) =>
    FareEstimateRequest(
      countryCode: json['countryCode'] as String?,
      vehiclePriceId: json['vehiclePriceId'] as String?,
      businessType: (json['businessType'] as num?)?.toInt(),
      priceMode: (json['priceMode'] as num?)?.toInt(),
      pickupAddress: json['pickupAddress'] == null
          ? null
          : DestinationAddress.fromJson(
              json['pickupAddress'] as Map<String, dynamic>,
            ),
      destinationAddresses: (json['destinationAddresses'] as List<dynamic>?)
          ?.map((e) => DestinationAddress.fromJson(e as Map<String, dynamic>))
          .toList(),
      promoCodeId: json['promoCodeId'] as String?,
      bookingTime: (json['bookingTime'] as num?)?.toInt(),
      paymentMode: (json['paymentMode'] as num?)?.toInt(),
      bookingType: (json['bookingType'] as num?)?.toInt(),
      customerNote: json['customerNote'] as String?,
      accessibilityIds: (json['accessibilityIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$FareEstimateRequestToJson(
  FareEstimateRequest instance,
) => <String, dynamic>{
  'countryCode': ?instance.countryCode,
  'vehiclePriceId': ?instance.vehiclePriceId,
  'businessType': ?instance.businessType,
  'priceMode': ?instance.priceMode,
  'pickupAddress': ?instance.pickupAddress,
  'destinationAddresses': ?instance.destinationAddresses,
  'promoCodeId': ?instance.promoCodeId,
  'bookingTime': ?instance.bookingTime,
  'paymentMode': ?instance.paymentMode,
  'bookingType': ?instance.bookingType,
  'customerNote': ?instance.customerNote,
  'accessibilityIds': ?instance.accessibilityIds,
};
