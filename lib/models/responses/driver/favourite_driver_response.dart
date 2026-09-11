import 'package:json_annotation/json_annotation.dart';

part 'favourite_driver_response.g.dart';

@JsonSerializable(includeIfNull: false)
class FavouriteDriverResponse {
  @JsonKey(name: 'favouriteDriverIds')
  final List<FavouriteDriver>? favouriteDrivers;

  FavouriteDriverResponse({
    this.favouriteDrivers,
  });

  factory FavouriteDriverResponse.fromJson(Map<String, dynamic> json) =>
      _$FavouriteDriverResponseFromJson(json);

  Map<String, dynamic> toJson() => _$FavouriteDriverResponseToJson(this);
}

@JsonSerializable(includeIfNull: false)
class FavouriteDriver {
  @JsonKey(name: '_id')
  final String? id;
  final String? firstName;
  final String? lastName;
  final String? countryPhoneCode;
  final String? phone;
  final String? imageUrl;
  final String? fullName;
  final String? fullPhone;

  FavouriteDriver({
    this.id,
    this.firstName,
    this.lastName,
    this.countryPhoneCode,
    this.phone,
    this.imageUrl,
    this.fullName,
    this.fullPhone,
  });

  factory FavouriteDriver.fromJson(Map<String, dynamic> json) =>
      _$FavouriteDriverFromJson(json);

  Map<String, dynamic> toJson() => _$FavouriteDriverToJson(this);
}
