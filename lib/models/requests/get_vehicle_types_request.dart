import 'package:json_annotation/json_annotation.dart';

part 'get_vehicle_types_request.g.dart';

@JsonSerializable(includeIfNull: false)
class GetVehicleTypesRequest {
  final String? countryCode;
  final List<DestinationAddress>? destinationAddresses;
  final DestinationAddress? pickupAddress;
  final int? businessType;

  GetVehicleTypesRequest({
    this.countryCode,
    this.destinationAddresses,
    this.pickupAddress,
    this.businessType,
  });

  factory GetVehicleTypesRequest.fromJson(Map<String, dynamic> json) =>
      _$GetVehicleTypesRequestFromJson(json);

  Map<String, dynamic> toJson() => _$GetVehicleTypesRequestToJson(this);
}

@JsonSerializable(includeIfNull: false)
class DestinationAddress {
  final String? address;
  final int? addressType;
  final String? city;
  final String? country;
  final String? countryCode;
  final double? latitude;
  final double? longitude;
  final String? note;
  final String? placeId;
  final String? postalCode;
  final String? title;
  final String? selectedId;
  final bool? isRecentAddress;
  final List<AddressMetadata>? metadata;
  final List<String>? pickupParcelIds;
  final List<String>? dropoffParcelIds;
  final String? name;
  final String? phone;
  final int? type;

  DestinationAddress({
    this.address,
    this.addressType,
    this.city,
    this.country,
    this.countryCode,
    this.latitude,
    this.longitude,
    this.note,
    this.placeId,
    this.postalCode,
    this.title,
    this.selectedId,
    this.isRecentAddress,
    this.metadata,
    this.pickupParcelIds,
    this.dropoffParcelIds,
    this.name,
    this.phone,
    this.type,
  });

  factory DestinationAddress.fromJson(Map<String, dynamic> json) =>
      _$DestinationAddressFromJson(json);

  Map<String, dynamic> toJson() => _$DestinationAddressToJson(this);
}

@JsonSerializable(includeIfNull: false)
class AddressMetadata {
  final dynamic id;
  final dynamic value;

  AddressMetadata({this.id, this.value});

  factory AddressMetadata.fromJson(Map<String, dynamic> json) =>
      _$AddressMetadataFromJson(json);

  Map<String, dynamic> toJson() => _$AddressMetadataToJson(this);
}
