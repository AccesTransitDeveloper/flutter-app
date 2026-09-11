// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fix_group_detail_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FixGroupDetailResponse _$FixGroupDetailResponseFromJson(
  Map<String, dynamic> json,
) => FixGroupDetailResponse(
  fixedGroupRide: json['fixedGroupRide'] == null
      ? null
      : FixedGroupRide.fromJson(json['fixedGroupRide'] as Map<String, dynamic>),
  citySetting: json['citySetting'] == null
      ? null
      : FixGroupCitySetting.fromJson(
          json['citySetting'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$FixGroupDetailResponseToJson(
  FixGroupDetailResponse instance,
) => <String, dynamic>{
  'fixedGroupRide': instance.fixedGroupRide,
  'citySetting': instance.citySetting,
};

FixGroupCitySetting _$FixGroupCitySettingFromJson(Map<String, dynamic> json) =>
    FixGroupCitySetting(
      paymentSetting: json['paymentSetting'] == null
          ? null
          : BookingPaymentSetting.fromJson(
              json['paymentSetting'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$FixGroupCitySettingToJson(
  FixGroupCitySetting instance,
) => <String, dynamic>{'paymentSetting': instance.paymentSetting};

FixedGroupRide _$FixedGroupRideFromJson(Map<String, dynamic> json) =>
    FixedGroupRide(
      id: json['_id'] as String?,
      status: (json['status'] as num?)?.toInt(),
      customerId: json['customerId'] as String?,
      countryId: json['countryId'] as String?,
      cityId: json['cityId'] as String?,
      vehicleTypeId: json['vehicleTypeId'] as String?,
      vehiclePriceId: json['vehiclePriceId'] as String?,
      pickupAddress: json['pickupAddress'] == null
          ? null
          : DestinationAddress.fromJson(
              json['pickupAddress'] as Map<String, dynamic>,
            ),
      destinationAddresses: (json['destinationAddresses'] as List<dynamic>?)
          ?.map((e) => DestinationAddress.fromJson(e as Map<String, dynamic>))
          .toList(),
      businessType: (json['businessType'] as num?)?.toInt(),
      paymentMode: (json['paymentMode'] as num?)?.toInt(),
      bookingType: (json['bookingType'] as num?)?.toInt(),
      startDate: (json['startDate'] as num?)?.toInt(),
      departureTime: (json['departureTime'] as num?)?.toInt(),
      returnTime: (json['returnTime'] as num?)?.toInt(),
      paymentStatus: (json['paymentStatus'] as num?)?.toInt(),
      priceTypePreference: json['priceTypePreference'] as String?,
      createdDeviceInfo: json['createdDeviceInfo'] == null
          ? null
          : CreatedDeviceInfo.fromJson(
              json['createdDeviceInfo'] as Map<String, dynamic>,
            ),
      bookingTags: (json['bookingTags'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      customerNote: json['customerNote'] as String?,
      verificationCodeLength: (json['verificationCodeLength'] as num?)?.toInt(),
      timezone: json['timezone'] as String?,
      distanceUnit: (json['distanceUnit'] as num?)?.toInt(),
      currencyCode: json['currencyCode'] as String?,
      currencySign: json['currencySign'] as String?,
      setCurrencySign: (json['setCurrencySign'] as num?)?.toInt(),
      decimalPointValue: (json['decimalPointValue'] as num?)?.toInt(),
      price: (json['price'] as List<dynamic>?)
          ?.map((e) => Price.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      uniqueId: json['uniqueId'] as String?,
      v: (json['__v'] as num?)?.toInt(),
      vehicleType: json['vehicleType'] == null
          ? null
          : BookingVehicleType.fromJson(
              json['vehicleType'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$FixedGroupRideToJson(FixedGroupRide instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'status': instance.status,
      'customerId': instance.customerId,
      'countryId': instance.countryId,
      'cityId': instance.cityId,
      'vehicleTypeId': instance.vehicleTypeId,
      'vehiclePriceId': instance.vehiclePriceId,
      'pickupAddress': instance.pickupAddress,
      'destinationAddresses': instance.destinationAddresses,
      'businessType': instance.businessType,
      'paymentMode': instance.paymentMode,
      'bookingType': instance.bookingType,
      'startDate': instance.startDate,
      'departureTime': instance.departureTime,
      'returnTime': instance.returnTime,
      'paymentStatus': instance.paymentStatus,
      'priceTypePreference': instance.priceTypePreference,
      'createdDeviceInfo': instance.createdDeviceInfo,
      'bookingTags': instance.bookingTags,
      'customerNote': instance.customerNote,
      'verificationCodeLength': instance.verificationCodeLength,
      'timezone': instance.timezone,
      'distanceUnit': instance.distanceUnit,
      'currencyCode': instance.currencyCode,
      'currencySign': instance.currencySign,
      'setCurrencySign': instance.setCurrencySign,
      'decimalPointValue': instance.decimalPointValue,
      'price': instance.price,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
      'uniqueId': instance.uniqueId,
      '__v': instance.v,
      'vehicleType': instance.vehicleType,
    };

Price _$PriceFromJson(Map<String, dynamic> json) => Price(
  type: json['type'] as String?,
  price: (json['price'] as num?)?.toDouble(),
);

Map<String, dynamic> _$PriceToJson(Price instance) => <String, dynamic>{
  'type': instance.type,
  'price': instance.price,
};
