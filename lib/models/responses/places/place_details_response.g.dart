// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'place_details_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlaceDetailsResponse _$PlaceDetailsResponseFromJson(
  Map<String, dynamic> json,
) => PlaceDetailsResponse(
  result: json['result'] == null
      ? null
      : PlaceResult.fromJson(json['result'] as Map<String, dynamic>),
  status: json['status'] as String?,
  errorMessage: json['error_message'] as String?,
);

Map<String, dynamic> _$PlaceDetailsResponseToJson(
  PlaceDetailsResponse instance,
) => <String, dynamic>{
  'result': instance.result,
  'status': instance.status,
  'error_message': instance.errorMessage,
};

PlaceResult _$PlaceResultFromJson(Map<String, dynamic> json) => PlaceResult(
  formattedAddress: json['formatted_address'] as String?,
  geometry: json['geometry'] == null
      ? null
      : Geometry.fromJson(json['geometry'] as Map<String, dynamic>),
  name: json['name'] as String?,
  placeId: json['place_id'] as String?,
  addressComponents: (json['address_components'] as List<dynamic>?)
      ?.map((e) => AddressComponent.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$PlaceResultToJson(PlaceResult instance) =>
    <String, dynamic>{
      'formatted_address': instance.formattedAddress,
      'geometry': instance.geometry,
      'name': instance.name,
      'place_id': instance.placeId,
      'address_components': instance.addressComponents,
    };

Geometry _$GeometryFromJson(Map<String, dynamic> json) => Geometry(
  location: json['location'] == null
      ? null
      : Location.fromJson(json['location'] as Map<String, dynamic>),
);

Map<String, dynamic> _$GeometryToJson(Geometry instance) => <String, dynamic>{
  'location': instance.location,
};

Location _$LocationFromJson(Map<String, dynamic> json) => Location(
  lat: (json['lat'] as num?)?.toDouble(),
  lng: (json['lng'] as num?)?.toDouble(),
);

Map<String, dynamic> _$LocationToJson(Location instance) => <String, dynamic>{
  'lat': instance.lat,
  'lng': instance.lng,
};

AddressComponent _$AddressComponentFromJson(Map<String, dynamic> json) =>
    AddressComponent(
      longName: json['long_name'] as String?,
      shortName: json['short_name'] as String?,
      types: (json['types'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$AddressComponentToJson(AddressComponent instance) =>
    <String, dynamic>{
      'long_name': instance.longName,
      'short_name': instance.shortName,
      'types': instance.types,
    };
