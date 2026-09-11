import 'package:json_annotation/json_annotation.dart';

import '../../requests/get_vehicle_types_request.dart';
import 'booking_detail_response.dart';

part 'fix_group_detail_response.g.dart';

@JsonSerializable()
class FixGroupDetailResponse {
  final FixedGroupRide? fixedGroupRide;
  final FixGroupCitySetting? citySetting;

  FixGroupDetailResponse({
    this.fixedGroupRide,
    this.citySetting,
  });

  factory FixGroupDetailResponse.fromJson(Map<String, dynamic> json) =>
      _$FixGroupDetailResponseFromJson(json);

  Map<String, dynamic> toJson() => _$FixGroupDetailResponseToJson(this);
}

@JsonSerializable()
class FixGroupCitySetting {
  final BookingPaymentSetting? paymentSetting;

  FixGroupCitySetting({
    this.paymentSetting,
  });

  factory FixGroupCitySetting.fromJson(Map<String, dynamic> json) =>
      _$FixGroupCitySettingFromJson(json);

  Map<String, dynamic> toJson() => _$FixGroupCitySettingToJson(this);
}

@JsonSerializable()
class FixedGroupRide {
  @JsonKey(name: '_id')
  final String? id;
  final int? status;
  final String? customerId;
  final String? countryId;
  final String? cityId;
  final String? vehicleTypeId;
  final String? vehiclePriceId;
  final DestinationAddress? pickupAddress;
  final List<DestinationAddress>? destinationAddresses;
  final int? businessType;
  final int? paymentMode;
  final int? bookingType;
  final int? startDate;
  final int? departureTime;
  final int? returnTime;
  final int? paymentStatus;
  final String? priceTypePreference;
  final CreatedDeviceInfo? createdDeviceInfo;
  final List<String>? bookingTags;
  final String? customerNote;
  final int? verificationCodeLength;
  final String? timezone;
  final int? distanceUnit;
  final String? currencyCode;
  final String? currencySign;
  final int? setCurrencySign;
  final int? decimalPointValue;
  final List<Price>? price;
  final String? createdAt;
  final String? updatedAt;
  final String? uniqueId;
  @JsonKey(name: '__v')
  final int? v;
  final BookingVehicleType? vehicleType;

  FixedGroupRide({
    this.id,
    this.status,
    this.customerId,
    this.countryId,
    this.cityId,
    this.vehicleTypeId,
    this.vehiclePriceId,
    this.pickupAddress,
    this.destinationAddresses,
    this.businessType,
    this.paymentMode,
    this.bookingType,
    this.startDate,
    this.departureTime,
    this.returnTime,
    this.paymentStatus,
    this.priceTypePreference,
    this.createdDeviceInfo,
    this.bookingTags,
    this.customerNote,
    this.verificationCodeLength,
    this.timezone,
    this.distanceUnit,
    this.currencyCode,
    this.currencySign,
    this.setCurrencySign,
    this.decimalPointValue,
    this.price,
    this.createdAt,
    this.updatedAt,
    this.uniqueId,
    this.v,
    this.vehicleType,
  });

  factory FixedGroupRide.fromJson(Map<String, dynamic> json) =>
      _$FixedGroupRideFromJson(json);

  Map<String, dynamic> toJson() => _$FixedGroupRideToJson(this);
}

@JsonSerializable()
class Price {
  final String? type;
  final double? price;

  Price({
    this.type,
    this.price,
  });

  factory Price.fromJson(Map<String, dynamic> json) => _$PriceFromJson(json);

  Map<String, dynamic> toJson() => _$PriceToJson(this);
}
