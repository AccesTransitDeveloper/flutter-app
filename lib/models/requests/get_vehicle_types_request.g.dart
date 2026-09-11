// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_vehicle_types_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetVehicleTypesRequest _$GetVehicleTypesRequestFromJson(
  Map<String, dynamic> json,
) => GetVehicleTypesRequest(
  countryCode: json['countryCode'] as String?,
  destinationAddresses: (json['destinationAddresses'] as List<dynamic>?)
      ?.map((e) => DestinationAddress.fromJson(e as Map<String, dynamic>))
      .toList(),
  pickupAddress: json['pickupAddress'] == null
      ? null
      : DestinationAddress.fromJson(
          json['pickupAddress'] as Map<String, dynamic>,
        ),
  businessType: (json['businessType'] as num?)?.toInt(),
);

Map<String, dynamic> _$GetVehicleTypesRequestToJson(
  GetVehicleTypesRequest instance,
) => <String, dynamic>{
  'countryCode': ?instance.countryCode,
  'destinationAddresses': ?instance.destinationAddresses,
  'pickupAddress': ?instance.pickupAddress,
  'businessType': ?instance.businessType,
};

DestinationAddress _$DestinationAddressFromJson(Map<String, dynamic> json) =>
    DestinationAddress(
      address: json['address'] as String?,
      addressType: (json['addressType'] as num?)?.toInt(),
      city: json['city'] as String?,
      country: json['country'] as String?,
      countryCode: json['countryCode'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      note: json['note'] as String?,
      placeId: json['placeId'] as String?,
      postalCode: json['postalCode'] as String?,
      title: json['title'] as String?,
      selectedId: json['selectedId'] as String?,
      isRecentAddress: json['isRecentAddress'] as bool?,
      metadata: (json['metadata'] as List<dynamic>?)
          ?.map((e) => AddressMetadata.fromJson(e as Map<String, dynamic>))
          .toList(),
      pickupParcelIds: (json['pickupParcelIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      dropoffParcelIds: (json['dropoffParcelIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      name: json['name'] as String?,
      phone: json['phone'] as String?,
      type: (json['type'] as num?)?.toInt(),
    );

Map<String, dynamic> _$DestinationAddressToJson(DestinationAddress instance) =>
    <String, dynamic>{
      'address': ?instance.address,
      'addressType': ?instance.addressType,
      'city': ?instance.city,
      'country': ?instance.country,
      'countryCode': ?instance.countryCode,
      'latitude': ?instance.latitude,
      'longitude': ?instance.longitude,
      'note': ?instance.note,
      'placeId': ?instance.placeId,
      'postalCode': ?instance.postalCode,
      'title': ?instance.title,
      'selectedId': ?instance.selectedId,
      'isRecentAddress': ?instance.isRecentAddress,
      'metadata': ?instance.metadata,
      'pickupParcelIds': ?instance.pickupParcelIds,
      'dropoffParcelIds': ?instance.dropoffParcelIds,
      'name': ?instance.name,
      'phone': ?instance.phone,
      'type': ?instance.type,
    };

AddressMetadata _$AddressMetadataFromJson(Map<String, dynamic> json) =>
    AddressMetadata(id: json['id'], value: json['value']);

Map<String, dynamic> _$AddressMetadataToJson(AddressMetadata instance) =>
    <String, dynamic>{'id': ?instance.id, 'value': ?instance.value};
