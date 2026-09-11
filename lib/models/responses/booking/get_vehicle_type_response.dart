import 'package:json_annotation/json_annotation.dart';

import 'accessibility_preference.dart';
import 'booking_detail_response.dart';
import 'speaking_language.dart';

part 'get_vehicle_type_response.g.dart';

@JsonSerializable()
class CustomPrice {
  @JsonKey(name: '_id')
  final String? id;
  final String? title;

  CustomPrice({
    this.id,
    this.title,
  });

  factory CustomPrice.fromJson(Map<String, dynamic> json) =>
      _$CustomPriceFromJson(json);

  Map<String, dynamic> toJson() => _$CustomPriceToJson(this);
}

@JsonSerializable()
class GetVehicleTypeResponse {
  final List<AccessibilityPreference>? accessibilities;
  final List<CustomPrice>? customPrices;
  final CitySetting? citySetting;
  final CountrySettings? countrySetting;
  final List<int?>? bookingTypeOrder;
  final Map<String, String>? bookingTypeLogo;
  final Map<String, String>? darkBookingTypeLogo;
  final List<NormalVehicles>? normalList;
  final List<NormalVehicles>? rentalList;
  final List<NormalVehicles>? shareList;
  final List<NormalVehicles>? fixGroupBookingList;
  final String? directionPath;
  final int? distance;
  final int? time;
  final List<NormalVehicles>? interCityCourierList;
  final List<NormalVehicles>? intraCityCourierList;
  final List<NormalVehicles>? moverList;

  GetVehicleTypeResponse({
    this.accessibilities,
    this.customPrices,
    this.citySetting,
    this.countrySetting,
    this.bookingTypeOrder,
    this.bookingTypeLogo,
    this.darkBookingTypeLogo,
    this.normalList,
    this.rentalList,
    this.shareList,
    this.fixGroupBookingList,
    this.directionPath,
    this.distance,
    this.time,
    this.interCityCourierList,
    this.intraCityCourierList,
    this.moverList,
  });

  factory GetVehicleTypeResponse.fromJson(Map<String, dynamic> json) =>
      _$GetVehicleTypeResponseFromJson(json);

  Map<String, dynamic> toJson() => _$GetVehicleTypeResponseToJson(this);
}

@JsonSerializable()
class CitySetting {
  final DriverSettings? driverSetting;
  final BidSetting? bidSetting;
  final BusinessSettings? bookingSetting;
  @JsonKey(name: 'businessSetting')
  final BusinessSettings? businessSettings;
  final List<String>? businessSequence;
  final bool? isAllowSetLocationFromMap;
  final bool? isShowCityInHomeScreen;
  final bool? isShowPeakHoursChart;
  final int? maxStopLimit;
  final PaymentSetting? paymentSetting;
  final BookingSetting? customerBookingSetting;
  @JsonKey(name: '_id')
  final String? id;
  final List<double>? tipPrices;
  final String? cityId;
  final bool isAds;
  final String? timezone;

  CitySetting({
    this.driverSetting,
    this.bidSetting,
    this.bookingSetting,
    this.businessSettings,
    this.businessSequence,
    this.isAllowSetLocationFromMap,
    this.isShowCityInHomeScreen,
    this.isShowPeakHoursChart,
    this.maxStopLimit,
    this.paymentSetting,
    this.customerBookingSetting,
    this.id,
    this.tipPrices,
    this.cityId,
    this.isAds = false,
    this.timezone,
  });

  factory CitySetting.fromJson(Map<String, dynamic> json) =>
      _$CitySettingFromJson(json);

  Map<String, dynamic> toJson() => _$CitySettingToJson(this);
}

@JsonSerializable()
class DriverSettings {
  @JsonKey(name: 'NORMAL')
  final NormalDriverSettings? normal;
  @JsonKey(name: 'RENTAL')
  final NormalDriverSettings? rental;
  @JsonKey(name: 'SHARE')
  final NormalDriverSettings? share;
  @JsonKey(name: 'FIX_GROUP_BOOKING')
  final NormalDriverSettings? fixGroupBooking;
  @JsonKey(name: 'DELIVERY')
  final NormalDriverSettings? delivery;
  @JsonKey(name: 'PICKUP')
  final NormalDriverSettings? pickup;
  @JsonKey(name: 'ON_SITE_SERVICE')
  final NormalDriverSettings? onSiteService;
  @JsonKey(name: 'SERVICE_AT_HOME')
  final NormalDriverSettings? serviceAtHome;
  @JsonKey(name: 'ONLINE_SERVICE')
  final NormalDriverSettings? onlineService;
  @JsonKey(name: 'INTER_CITY_COURIER')
  final NormalDriverSettings? interCityCourier;
  @JsonKey(name: 'INTRA_CITY_COURIER')
  final NormalDriverSettings? intraCityCourier;
  @JsonKey(name: 'MOVER')
  final NormalDriverSettings? mover;

  DriverSettings({
    this.normal,
    this.rental,
    this.share,
    this.fixGroupBooking,
    this.delivery,
    this.pickup,
    this.onSiteService,
    this.serviceAtHome,
    this.onlineService,
    this.interCityCourier,
    this.intraCityCourier,
    this.mover,
  });

  factory DriverSettings.fromJson(Map<String, dynamic> json) =>
      _$DriverSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$DriverSettingsToJson(this);
}

@JsonSerializable()
class NormalDriverSettings {
  @JsonKey(name: 'NOW')
  final Now? now;
  @JsonKey(name: 'SCHEDULE')
  final Schedule? schedule;

  NormalDriverSettings({
    this.now,
    this.schedule,
  });

  factory NormalDriverSettings.fromJson(Map<String, dynamic> json) =>
      _$NormalDriverSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$NormalDriverSettingsToJson(this);
}

@JsonSerializable()
class Now {
  final int? driverSearchRadius;
  final int? driverTimeout;
  final int? findDriverType;
  final int? maxDriverLimit;
  final int? nextCycleStartAfterTime;
  final int? noOfTimeCheckDriver;

  Now({
    this.driverSearchRadius,
    this.driverTimeout,
    this.findDriverType,
    this.maxDriverLimit,
    this.nextCycleStartAfterTime,
    this.noOfTimeCheckDriver,
  });

  factory Now.fromJson(Map<String, dynamic> json) => _$NowFromJson(json);

  Map<String, dynamic> toJson() => _$NowToJson(this);
}

@JsonSerializable()
class Schedule {
  final int? bufferTime;
  final int? cancelBookingBeforeTime;
  final int? driverSearchRadius;
  final int? driverTimeout;
  final int? findDriverBeforeBookingTime;
  final String? findDriverMode;
  final int? findDriverType;
  final bool? isMoveBookingToMarketPlace;
  final int? maxBookingDays;
  final int? maxDriverLimit;
  final int? nextCycleStartAfterTime;
  final int? noOfTimeCheckDriver;
  final List<int?>? sendNotificationBeforTime;
  final int? scheduleTimeSelectionType;
  final int? slotIntervalInMinutes;

  Schedule({
    this.bufferTime,
    this.cancelBookingBeforeTime,
    this.driverSearchRadius,
    this.driverTimeout,
    this.findDriverBeforeBookingTime,
    this.findDriverMode,
    this.findDriverType,
    this.isMoveBookingToMarketPlace,
    this.maxBookingDays,
    this.maxDriverLimit,
    this.nextCycleStartAfterTime,
    this.noOfTimeCheckDriver,
    this.sendNotificationBeforTime,
    this.scheduleTimeSelectionType,
    this.slotIntervalInMinutes,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) =>
      _$ScheduleFromJson(json);

  Map<String, dynamic> toJson() => _$ScheduleToJson(this);
}

@JsonSerializable()
class BidSetting {
  @JsonKey(name: 'NORMAL')
  final BidSettingInfo? normal;
  @JsonKey(name: 'FIX_GROUP_BOOKING')
  final BidSettingInfo? fixGroupBooking;
  @JsonKey(name: 'RENTAL')
  final BidSettingInfo? rental;
  @JsonKey(name: 'SHARE')
  final BidSettingInfo? share;

  BidSetting({
    this.normal,
    this.fixGroupBooking,
    this.rental,
    this.share,
  });

  factory BidSetting.fromJson(Map<String, dynamic> json) =>
      _$BidSettingFromJson(json);

  Map<String, dynamic> toJson() => _$BidSettingToJson(this);
}

@JsonSerializable()
class BidSettingInfo {
  final int? customerBiddingTimeout;
  final int? customerMinBid;
  final int? driverBiddingTimeout;
  final int? driverMaxBid;
  final bool? isCustomerCanBid;
  final int? maxDriverBidLimit;
  final bool? isAllowIncrementDecrementStepper;
  final double? incrementDecrementStepper;

  BidSettingInfo({
    this.customerBiddingTimeout,
    this.customerMinBid,
    this.driverBiddingTimeout,
    this.driverMaxBid,
    this.isCustomerCanBid,
    this.maxDriverBidLimit,
    this.isAllowIncrementDecrementStepper,
    this.incrementDecrementStepper,
  });

  factory BidSettingInfo.fromJson(Map<String, dynamic> json) =>
      _$BidSettingInfoFromJson(json);

  Map<String, dynamic> toJson() => _$BidSettingInfoToJson(this);
}

@JsonSerializable()
class BusinessSettings {
  @JsonKey(name: 'NORMAL')
  final List<String>? normal;
  @JsonKey(name: 'RENTAL')
  final List<String>? rental;
  @JsonKey(name: 'SHARE')
  final List<String>? share;
  @JsonKey(name: 'FIX_GROUP_BOOKING')
  final List<String>? fixGroupBooking;
  @JsonKey(name: 'QUICK_COMMERCE')
  final List<String>? quickCommerce;
  @JsonKey(name: 'DELIVERY')
  final List<String>? delivery;
  @JsonKey(name: 'PICKUP')
  final List<String>? pickup;
  @JsonKey(name: 'ON_SITE_SERVICE')
  final List<String>? onSiteService;
  @JsonKey(name: 'SERVICE_AT_HOME')
  final List<String>? serviceAtHome;
  @JsonKey(name: 'ONLINE_SERVICE')
  final List<String>? onlineService;
  @JsonKey(name: 'INTRA_CITY_COURIER')
  final List<String>? intraCityCourier;
  @JsonKey(name: 'INTER_CITY_COURIER')
  final List<String>? interCityCourier;
  @JsonKey(name: 'MOVER')
  final List<String>? mover;

  BusinessSettings({
    this.normal,
    this.rental,
    this.share,
    this.fixGroupBooking,
    this.quickCommerce,
    this.delivery,
    this.pickup,
    this.onSiteService,
    this.serviceAtHome,
    this.onlineService,
    this.intraCityCourier,
    this.interCityCourier,
    this.mover,
  });

  factory BusinessSettings.fromJson(Map<String, dynamic> json) =>
      _$BusinessSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$BusinessSettingsToJson(this);
}

@JsonSerializable()
class BookingSetting {
  @JsonKey(name: 'NORMAL')
  final BookingTypeSettings? normal;
  @JsonKey(name: 'RENTAL')
  final BookingTypeSettings? rental;
  @JsonKey(name: 'SHARE')
  final BookingTypeSettings? share;
  @JsonKey(name: 'FIX_GROUP_BOOKING')
  final BookingTypeSettings? fixGroupBooking;

  BookingSetting({
    this.normal,
    this.rental,
    this.share,
    this.fixGroupBooking,
  });

  factory BookingSetting.fromJson(Map<String, dynamic> json) =>
      _$BookingSettingFromJson(json);

  Map<String, dynamic> toJson() => _$BookingSettingToJson(this);
}

@JsonSerializable()
class BookingTypeSettings {
  final bool? isAllowDestinationLater;
  final bool? isAllowScheduleBooking;
  final bool? isDestinationRequired;
  final bool? isShowEstimateFare;

  BookingTypeSettings({
    this.isAllowDestinationLater,
    this.isAllowScheduleBooking,
    this.isDestinationRequired,
    this.isShowEstimateFare,
  });

  factory BookingTypeSettings.fromJson(Map<String, dynamic> json) =>
      _$BookingTypeSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$BookingTypeSettingsToJson(this);
}

@JsonSerializable()
class PaymentSetting {
  @JsonKey(name: 'NORMAL')
  final VehicleTypePaymentSetting? normal;
  @JsonKey(name: 'FIX_GROUP_BOOKING')
  final VehicleTypePaymentSetting? fixGroupBooking;
  @JsonKey(name: 'RENTAL')
  final VehicleTypePaymentSetting? rental;
  @JsonKey(name: 'SHARE')
  final VehicleTypePaymentSetting? share;
  @JsonKey(name: 'QUICK_COMMERCE')
  final VehicleTypePaymentSetting? quickCommerce;
  @JsonKey(name: 'DELIVERY')
  final VehicleTypePaymentSetting? delivery;
  @JsonKey(name: 'PICKUP')
  final VehicleTypePaymentSetting? pickup;
  @JsonKey(name: 'ON_SITE_SERVICE')
  final VehicleTypePaymentSetting? onSiteService;
  @JsonKey(name: 'SERVICE_AT_HOME')
  final VehicleTypePaymentSetting? serviceAtHome;
  @JsonKey(name: 'ONLINE_SERVICE')
  final VehicleTypePaymentSetting? onlineService;
  @JsonKey(name: 'INTER_CITY_COURIER')
  final VehicleTypePaymentSetting? interCityCourier;
  @JsonKey(name: 'INTRA_CITY_COURIER')
  final VehicleTypePaymentSetting? intraCityCourier;
  @JsonKey(name: 'MOVER')
  final VehicleTypePaymentSetting? mover;

  PaymentSetting({
    this.normal,
    this.fixGroupBooking,
    this.rental,
    this.share,
    this.quickCommerce,
    this.delivery,
    this.pickup,
    this.onSiteService,
    this.serviceAtHome,
    this.onlineService,
    this.interCityCourier,
    this.intraCityCourier,
    this.mover,
  });

  factory PaymentSetting.fromJson(Map<String, dynamic> json) =>
      _$PaymentSettingFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentSettingToJson(this);
}

@JsonSerializable()
class VehicleTypePaymentSetting {
  final bool? isCash;
  final bool? isWallet;

  /// Gateway ids as strings — native declares `List<String?>` and compares with
  /// `PaymentGatewayType.X.value.toString()`. Parsing these as ints made the
  /// cast fail on the wire format, leaving the list null: the cards request
  /// then went out with an empty `paymentGatewayTypes` and returned nothing.
  @JsonKey(fromJson: _gatewaysFromJson)
  final List<String?>? paymentGateways;
  final bool? isAdvancePaymentLimit;
  final double? advancePaymentLimit;

  VehicleTypePaymentSetting({
    this.isCash,
    this.isWallet,
    this.paymentGateways,
    this.isAdvancePaymentLimit,
    this.advancePaymentLimit,
  });

  factory VehicleTypePaymentSetting.fromJson(Map<String, dynamic> json) =>
      _$VehicleTypePaymentSettingFromJson(json);

  Map<String, dynamic> toJson() => _$VehicleTypePaymentSettingToJson(this);
}

@JsonSerializable()
class CountrySettings {
  final String? currencySign;
  final int? decimalPointValue;
  final int? distanceUnit;
  @JsonKey(name: '_id')
  final String? id;
  final bool? isAllowGenderSelection;
  final bool? isBusiness;
  final double? roundingMethod;
  final int? setCurrencySign;
  final List<SpeakingLanguage>? speakingLanguages;

  CountrySettings({
    this.currencySign,
    this.decimalPointValue,
    this.distanceUnit,
    this.id,
    this.isAllowGenderSelection,
    this.isBusiness,
    this.roundingMethod,
    this.setCurrencySign,
    this.speakingLanguages,
  });

  factory CountrySettings.fromJson(Map<String, dynamic> json) =>
      _$CountrySettingsFromJson(json);

  Map<String, dynamic> toJson() => _$CountrySettingsToJson(this);
}

@JsonSerializable()
class NormalVehicles {
  final String? cityId;
  final String? countryId;
  @JsonKey(name: '_id')
  final String? id;
  final InvoiceDetail? priceDetail;
  final VehicleTypeDetail? vehicleTypeDetail;
  final String? vehicleTypeId;
  final bool? isMinFareApplied;
  final List<RentalPack>? packageList;

  NormalVehicles({
    this.cityId,
    this.countryId,
    this.id,
    this.priceDetail,
    this.vehicleTypeDetail,
    this.vehicleTypeId,
    this.isMinFareApplied,
    this.packageList,
  });

  factory NormalVehicles.fromJson(Map<String, dynamic> json) =>
      _$NormalVehiclesFromJson(json);

  Map<String, dynamic> toJson() => _$NormalVehiclesToJson(this);
}


@JsonSerializable()
class VehicleTypeDetail {
  final String? imageUrl;
  final bool? isBusiness;
  final bool? isDefaultSelected;
  final int? luggageCapacity;
  final String? mapPinUrl;
  final String? name;
  final int? passengerCapacity;
  final int? type;
  final List<int?>? allowedEntities;
  final List<FallbackType?>? fallbackTypes;
  final int? uniqueId;
  final String? description;
  final bool? isDescriptionEnabled;
  final bool isShowInMainScreen;
  final int? weightCapacity;
  final Dimensions? dimensions;

  VehicleTypeDetail({
    this.imageUrl,
    this.isBusiness,
    this.isDefaultSelected,
    this.luggageCapacity,
    this.mapPinUrl,
    this.name,
    this.passengerCapacity,
    this.type,
    this.allowedEntities,
    this.fallbackTypes,
    this.uniqueId,
    this.description,
    this.isDescriptionEnabled,
    this.isShowInMainScreen = false,
    this.weightCapacity,
    this.dimensions,
  });

  factory VehicleTypeDetail.fromJson(Map<String, dynamic> json) =>
      _$VehicleTypeDetailFromJson(json);

  Map<String, dynamic> toJson() => _$VehicleTypeDetailToJson(this);
}

@JsonSerializable()
class FallbackType {
  @JsonKey(name: '_id')
  final String? id;
  final bool? isApplySelectedVehicleTypePrice;
  final String? vehicleTypeId;

  FallbackType({
    this.id,
    this.isApplySelectedVehicleTypePrice,
    this.vehicleTypeId,
  });

  factory FallbackType.fromJson(Map<String, dynamic> json) =>
      _$FallbackTypeFromJson(json);

  Map<String, dynamic> toJson() => _$FallbackTypeToJson(this);
}

@JsonSerializable()
class Dimensions {
  final double? length;
  final double? width;
  final double? height;

  Dimensions({this.length, this.width, this.height});

  factory Dimensions.fromJson(Map<String, dynamic> json) =>
      _$DimensionsFromJson(json);

  Map<String, dynamic> toJson() => _$DimensionsToJson(this);
}

@JsonSerializable()
class RentalPack {
  @JsonKey(name: '_id')
  final String? id;
  final String? packageName;
  final InvoiceDetail? priceDetail;
  final PackageDetail? packageDetail;

  RentalPack({
    this.id,
    this.packageName,
    this.priceDetail,
    this.packageDetail,
  });

  factory RentalPack.fromJson(Map<String, dynamic> json) =>
      _$RentalPackFromJson(json);

  Map<String, dynamic> toJson() => _$RentalPackToJson(this);
}

@JsonSerializable()
class PackageDetail {
  final PriceData? distancePrice;
  final PriceData? timePrice;

  PackageDetail({this.distancePrice, this.timePrice});

  factory PackageDetail.fromJson(Map<String, dynamic> json) =>
      _$PackageDetailFromJson(json);

  Map<String, dynamic> toJson() => _$PackageDetailToJson(this);
}

/// Accepts numbers or strings; native's model is `List<String?>`.
List<String?>? _gatewaysFromJson(dynamic json) {
  if (json is! List) return null;
  return json.map((e) => e?.toString()).toList();
}
