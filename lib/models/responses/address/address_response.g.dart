// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'address_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AddressResponse _$AddressResponseFromJson(Map<String, dynamic> json) =>
    AddressResponse(
      addresses: (json['addresses'] as List<dynamic>?)
          ?.map((e) => SavedAddress.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$AddressResponseToJson(AddressResponse instance) =>
    <String, dynamic>{'addresses': instance.addresses};

SavedAddress _$SavedAddressFromJson(Map<String, dynamic> json) => SavedAddress(
  id: json['_id'] as String?,
  address: json['address'] as String?,
  title: json['title'] as String?,
  addressType: (json['addressType'] as num?)?.toInt(),
  city: json['city'] as String?,
  country: json['country'] as String?,
  countryCode: json['countryCode'] as String?,
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
  note: json['note'] as String?,
  placeId: json['placeId'] as String?,
  postalCode: json['postalCode'] as String?,
  type: (json['type'] as num?)?.toInt(),
  typeId: json['typeId'] as String?,
  createdAt: json['createdAt'] as String?,
  updatedAt: json['updatedAt'] as String?,
  metadata: (json['metadata'] as List<dynamic>?)
      ?.map((e) => AddressMetadata.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$SavedAddressToJson(SavedAddress instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'address': instance.address,
      'title': instance.title,
      'addressType': instance.addressType,
      'city': instance.city,
      'country': instance.country,
      'countryCode': instance.countryCode,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'note': instance.note,
      'placeId': instance.placeId,
      'postalCode': instance.postalCode,
      'type': instance.type,
      'typeId': instance.typeId,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
      'metadata': instance.metadata,
    };
