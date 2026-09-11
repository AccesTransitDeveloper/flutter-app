import 'package:json_annotation/json_annotation.dart';

import '../../requests/get_vehicle_types_request.dart';

part 'address_response.g.dart';

@JsonSerializable()
class AddressResponse {
  final List<SavedAddress>? addresses;

  AddressResponse({this.addresses});

  factory AddressResponse.fromJson(Map<String, dynamic> json) =>
      _$AddressResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AddressResponseToJson(this);
}

@JsonSerializable()
class SavedAddress {
  @JsonKey(name: '_id')
  final String? id;
  final String? address;
  final String? title;
  final int? addressType;
  final String? city;
  final String? country;
  final String? countryCode;
  final double? latitude;
  final double? longitude;
  final String? note;
  final String? placeId;
  final String? postalCode;
  final int? type;
  final String? typeId;
  final String? createdAt;
  final String? updatedAt;
  final List<AddressMetadata>? metadata;

  SavedAddress({
    this.id,
    this.address,
    this.title,
    this.addressType,
    this.city,
    this.country,
    this.countryCode,
    this.latitude,
    this.longitude,
    this.note,
    this.placeId,
    this.postalCode,
    this.type,
    this.typeId,
    this.createdAt,
    this.updatedAt,
    this.metadata,
  });

  factory SavedAddress.fromJson(Map<String, dynamic> json) =>
      _$SavedAddressFromJson(json);

  Map<String, dynamic> toJson() => _$SavedAddressToJson(this);

  /// Convert to DestinationAddress for use in location selection
  DestinationAddress toDestinationAddress() {
    return DestinationAddress(
      address: address,
      title: title,
      addressType: addressType,
      city: city,
      country: country,
      countryCode: countryCode,
      latitude: latitude,
      longitude: longitude,
      note: note,
      placeId: placeId,
      postalCode: postalCode,
      type: type,
      selectedId: id,
      metadata: metadata,
    );
  }
}
