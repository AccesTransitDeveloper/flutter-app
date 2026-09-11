// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favourite_driver_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FavouriteDriverResponse _$FavouriteDriverResponseFromJson(
  Map<String, dynamic> json,
) => FavouriteDriverResponse(
  favouriteDrivers: (json['favouriteDriverIds'] as List<dynamic>?)
      ?.map((e) => FavouriteDriver.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$FavouriteDriverResponseToJson(
  FavouriteDriverResponse instance,
) => <String, dynamic>{'favouriteDriverIds': ?instance.favouriteDrivers};

FavouriteDriver _$FavouriteDriverFromJson(Map<String, dynamic> json) =>
    FavouriteDriver(
      id: json['_id'] as String?,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      countryPhoneCode: json['countryPhoneCode'] as String?,
      phone: json['phone'] as String?,
      imageUrl: json['imageUrl'] as String?,
      fullName: json['fullName'] as String?,
      fullPhone: json['fullPhone'] as String?,
    );

Map<String, dynamic> _$FavouriteDriverToJson(FavouriteDriver instance) =>
    <String, dynamic>{
      '_id': ?instance.id,
      'firstName': ?instance.firstName,
      'lastName': ?instance.lastName,
      'countryPhoneCode': ?instance.countryPhoneCode,
      'phone': ?instance.phone,
      'imageUrl': ?instance.imageUrl,
      'fullName': ?instance.fullName,
      'fullPhone': ?instance.fullPhone,
    };
