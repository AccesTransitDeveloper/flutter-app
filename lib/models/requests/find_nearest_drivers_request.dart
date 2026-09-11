import 'package:json_annotation/json_annotation.dart';

part 'find_nearest_drivers_request.g.dart';

@JsonSerializable()
class FindNearestDriversRequest {
  final int? bookingType;
  final String? cityId;
  final PickupAddress? pickupAddress;
  final String? vehicleTypeId;

  FindNearestDriversRequest({
    this.bookingType,
    this.cityId,
    this.pickupAddress,
    this.vehicleTypeId,
  });

  factory FindNearestDriversRequest.fromJson(Map<String, dynamic> json) =>
      _$FindNearestDriversRequestFromJson(json);

  Map<String, dynamic> toJson() => _$FindNearestDriversRequestToJson(this);
}

@JsonSerializable()
class PickupAddress {
  final double? latitude;
  final double? longitude;

  PickupAddress({
    this.latitude,
    this.longitude,
  });

  factory PickupAddress.fromJson(Map<String, dynamic> json) =>
      _$PickupAddressFromJson(json);

  Map<String, dynamic> toJson() => _$PickupAddressToJson(this);
}
