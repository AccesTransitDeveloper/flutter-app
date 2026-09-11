// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nearest_drivers_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NearestDriversResponse _$NearestDriversResponseFromJson(
  Map<String, dynamic> json,
) => NearestDriversResponse(
  drivers: (json['drivers'] as List<dynamic>?)
      ?.map((e) => NearestDriverItem.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$NearestDriversResponseToJson(
  NearestDriversResponse instance,
) => <String, dynamic>{'drivers': instance.drivers};

NearestDriverItem _$NearestDriverItemFromJson(Map<String, dynamic> json) =>
    NearestDriverItem(
      bookingIds: json['bookingIds'] as List<dynamic>?,
      email: json['email'] as String?,
      firstName: json['firstName'] as String?,
      id: json['_id'] as String?,
      imageUrl: json['imageUrl'] as String?,
      lastName: json['lastName'] as String?,
      location: json['location'] == null
          ? null
          : DriverLocation.fromJson(json['location'] as Map<String, dynamic>),
      phone: json['phone'] as String?,
      rate: (json['rate'] as num?)?.toDouble(),
      socketId: json['socketId'] as String?,
      uniqueId: (json['uniqueId'] as num?)?.toInt(),
      vehicleTypeId: json['vehicleTypeId'] as String?,
      mapPinUrl: json['mapPinUrl'] as String?,
    );

Map<String, dynamic> _$NearestDriverItemToJson(NearestDriverItem instance) =>
    <String, dynamic>{
      'bookingIds': instance.bookingIds,
      'email': instance.email,
      'firstName': instance.firstName,
      '_id': instance.id,
      'imageUrl': instance.imageUrl,
      'lastName': instance.lastName,
      'location': instance.location,
      'phone': instance.phone,
      'rate': instance.rate,
      'socketId': instance.socketId,
      'uniqueId': instance.uniqueId,
      'vehicleTypeId': instance.vehicleTypeId,
      'mapPinUrl': instance.mapPinUrl,
    };

DriverLocation _$DriverLocationFromJson(Map<String, dynamic> json) =>
    DriverLocation(
      coordinates: (json['coordinates'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
      type: json['type'] as String?,
    );

Map<String, dynamic> _$DriverLocationToJson(DriverLocation instance) =>
    <String, dynamic>{
      'coordinates': instance.coordinates,
      'type': instance.type,
    };
