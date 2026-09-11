import 'package:json_annotation/json_annotation.dart';

part 'place_details_response.g.dart';

@JsonSerializable()
class PlaceDetailsResponse {
  final PlaceResult? result;
  final String? status;
  @JsonKey(name: 'error_message')
  final String? errorMessage;

  PlaceDetailsResponse({
    this.result,
    this.status,
    this.errorMessage,
  });

  factory PlaceDetailsResponse.fromJson(Map<String, dynamic> json) =>
      _$PlaceDetailsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PlaceDetailsResponseToJson(this);
}

@JsonSerializable()
class PlaceResult {
  @JsonKey(name: 'formatted_address')
  final String? formattedAddress;
  final Geometry? geometry;
  final String? name;
  @JsonKey(name: 'place_id')
  final String? placeId;
  @JsonKey(name: 'address_components')
  final List<AddressComponent>? addressComponents;

  PlaceResult({
    this.formattedAddress,
    this.geometry,
    this.name,
    this.placeId,
    this.addressComponents,
  });

  factory PlaceResult.fromJson(Map<String, dynamic> json) =>
      _$PlaceResultFromJson(json);

  Map<String, dynamic> toJson() => _$PlaceResultToJson(this);
}

@JsonSerializable()
class Geometry {
  final Location? location;

  Geometry({this.location});

  factory Geometry.fromJson(Map<String, dynamic> json) =>
      _$GeometryFromJson(json);

  Map<String, dynamic> toJson() => _$GeometryToJson(this);
}

@JsonSerializable()
class Location {
  final double? lat;
  final double? lng;

  Location({this.lat, this.lng});

  factory Location.fromJson(Map<String, dynamic> json) =>
      _$LocationFromJson(json);

  Map<String, dynamic> toJson() => _$LocationToJson(this);
}

@JsonSerializable()
class AddressComponent {
  @JsonKey(name: 'long_name')
  final String? longName;
  @JsonKey(name: 'short_name')
  final String? shortName;
  final List<String>? types;

  AddressComponent({
    this.longName,
    this.shortName,
    this.types,
  });

  factory AddressComponent.fromJson(Map<String, dynamic> json) =>
      _$AddressComponentFromJson(json);

  Map<String, dynamic> toJson() => _$AddressComponentToJson(this);
}
