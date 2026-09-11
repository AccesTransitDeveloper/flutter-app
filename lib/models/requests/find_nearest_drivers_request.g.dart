// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'find_nearest_drivers_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FindNearestDriversRequest _$FindNearestDriversRequestFromJson(
  Map<String, dynamic> json,
) => FindNearestDriversRequest(
  bookingType: (json['bookingType'] as num?)?.toInt(),
  cityId: json['cityId'] as String?,
  pickupAddress: json['pickupAddress'] == null
      ? null
      : PickupAddress.fromJson(json['pickupAddress'] as Map<String, dynamic>),
  vehicleTypeId: json['vehicleTypeId'] as String?,
);

Map<String, dynamic> _$FindNearestDriversRequestToJson(
  FindNearestDriversRequest instance,
) => <String, dynamic>{
  'bookingType': instance.bookingType,
  'cityId': instance.cityId,
  'pickupAddress': instance.pickupAddress,
  'vehicleTypeId': instance.vehicleTypeId,
};

PickupAddress _$PickupAddressFromJson(Map<String, dynamic> json) =>
    PickupAddress(
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$PickupAddressToJson(PickupAddress instance) =>
    <String, dynamic>{
      'latitude': instance.latitude,
      'longitude': instance.longitude,
    };
