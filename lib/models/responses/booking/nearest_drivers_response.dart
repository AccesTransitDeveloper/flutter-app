import 'package:json_annotation/json_annotation.dart';

part 'nearest_drivers_response.g.dart';

@JsonSerializable()
class NearestDriversResponse {
  final List<NearestDriverItem>? drivers;

  NearestDriversResponse({this.drivers});

  factory NearestDriversResponse.fromJson(Map<String, dynamic> json) =>
      _$NearestDriversResponseFromJson(json);

  Map<String, dynamic> toJson() => _$NearestDriversResponseToJson(this);
}

@JsonSerializable()
class NearestDriverItem {
  final List<dynamic>? bookingIds;
  final String? email;
  final String? firstName;
  @JsonKey(name: '_id')
  final String? id;
  final String? imageUrl;
  final String? lastName;
  final DriverLocation? location;
  final String? phone;
  final double? rate;
  final String? socketId;
  final int? uniqueId;
  final String? vehicleTypeId;
  final String? mapPinUrl;

  NearestDriverItem({
    this.bookingIds,
    this.email,
    this.firstName,
    this.id,
    this.imageUrl,
    this.lastName,
    this.location,
    this.phone,
    this.rate,
    this.socketId,
    this.uniqueId,
    this.vehicleTypeId,
    this.mapPinUrl,
  });

  factory NearestDriverItem.fromJson(Map<String, dynamic> json) =>
      _$NearestDriverItemFromJson(json);

  Map<String, dynamic> toJson() => _$NearestDriverItemToJson(this);
}

@JsonSerializable()
class DriverLocation {
  final List<double>? coordinates;
  final String? type;

  DriverLocation({
    this.coordinates,
    this.type,
  });

  factory DriverLocation.fromJson(Map<String, dynamic> json) =>
      _$DriverLocationFromJson(json);

  Map<String, dynamic> toJson() => _$DriverLocationToJson(this);
}
