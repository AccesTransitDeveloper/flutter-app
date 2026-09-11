// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_vehicle_type_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CustomPrice _$CustomPriceFromJson(Map<String, dynamic> json) =>
    CustomPrice(id: json['_id'] as String?, title: json['title'] as String?);

Map<String, dynamic> _$CustomPriceToJson(CustomPrice instance) =>
    <String, dynamic>{'_id': instance.id, 'title': instance.title};

GetVehicleTypeResponse _$GetVehicleTypeResponseFromJson(
  Map<String, dynamic> json,
) => GetVehicleTypeResponse(
  accessibilities: (json['accessibilities'] as List<dynamic>?)
      ?.map((e) => AccessibilityPreference.fromJson(e as Map<String, dynamic>))
      .toList(),
  customPrices: (json['customPrices'] as List<dynamic>?)
      ?.map((e) => CustomPrice.fromJson(e as Map<String, dynamic>))
      .toList(),
  citySetting: json['citySetting'] == null
      ? null
      : CitySetting.fromJson(json['citySetting'] as Map<String, dynamic>),
  countrySetting: json['countrySetting'] == null
      ? null
      : CountrySettings.fromJson(
          json['countrySetting'] as Map<String, dynamic>,
        ),
  bookingTypeOrder: (json['bookingTypeOrder'] as List<dynamic>?)
      ?.map((e) => (e as num?)?.toInt())
      .toList(),
  bookingTypeLogo: (json['bookingTypeLogo'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, e as String),
  ),
  darkBookingTypeLogo: (json['darkBookingTypeLogo'] as Map<String, dynamic>?)
      ?.map((k, e) => MapEntry(k, e as String)),
  normalList: (json['normalList'] as List<dynamic>?)
      ?.map((e) => NormalVehicles.fromJson(e as Map<String, dynamic>))
      .toList(),
  rentalList: (json['rentalList'] as List<dynamic>?)
      ?.map((e) => NormalVehicles.fromJson(e as Map<String, dynamic>))
      .toList(),
  shareList: (json['shareList'] as List<dynamic>?)
      ?.map((e) => NormalVehicles.fromJson(e as Map<String, dynamic>))
      .toList(),
  fixGroupBookingList: (json['fixGroupBookingList'] as List<dynamic>?)
      ?.map((e) => NormalVehicles.fromJson(e as Map<String, dynamic>))
      .toList(),
  directionPath: json['directionPath'] as String?,
  distance: (json['distance'] as num?)?.toInt(),
  time: (json['time'] as num?)?.toInt(),
  interCityCourierList: (json['interCityCourierList'] as List<dynamic>?)
      ?.map((e) => NormalVehicles.fromJson(e as Map<String, dynamic>))
      .toList(),
  intraCityCourierList: (json['intraCityCourierList'] as List<dynamic>?)
      ?.map((e) => NormalVehicles.fromJson(e as Map<String, dynamic>))
      .toList(),
  moverList: (json['moverList'] as List<dynamic>?)
      ?.map((e) => NormalVehicles.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$GetVehicleTypeResponseToJson(
  GetVehicleTypeResponse instance,
) => <String, dynamic>{
  'accessibilities': instance.accessibilities,
  'customPrices': instance.customPrices,
  'citySetting': instance.citySetting,
  'countrySetting': instance.countrySetting,
  'bookingTypeOrder': instance.bookingTypeOrder,
  'bookingTypeLogo': instance.bookingTypeLogo,
  'darkBookingTypeLogo': instance.darkBookingTypeLogo,
  'normalList': instance.normalList,
  'rentalList': instance.rentalList,
  'shareList': instance.shareList,
  'fixGroupBookingList': instance.fixGroupBookingList,
  'directionPath': instance.directionPath,
  'distance': instance.distance,
  'time': instance.time,
  'interCityCourierList': instance.interCityCourierList,
  'intraCityCourierList': instance.intraCityCourierList,
  'moverList': instance.moverList,
};

CitySetting _$CitySettingFromJson(Map<String, dynamic> json) => CitySetting(
  driverSetting: json['driverSetting'] == null
      ? null
      : DriverSettings.fromJson(json['driverSetting'] as Map<String, dynamic>),
  bidSetting: json['bidSetting'] == null
      ? null
      : BidSetting.fromJson(json['bidSetting'] as Map<String, dynamic>),
  bookingSetting: json['bookingSetting'] == null
      ? null
      : BusinessSettings.fromJson(
          json['bookingSetting'] as Map<String, dynamic>,
        ),
  businessSettings: json['businessSetting'] == null
      ? null
      : BusinessSettings.fromJson(
          json['businessSetting'] as Map<String, dynamic>,
        ),
  businessSequence: (json['businessSequence'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  isAllowSetLocationFromMap: json['isAllowSetLocationFromMap'] as bool?,
  isShowCityInHomeScreen: json['isShowCityInHomeScreen'] as bool?,
  isShowPeakHoursChart: json['isShowPeakHoursChart'] as bool?,
  maxStopLimit: (json['maxStopLimit'] as num?)?.toInt(),
  paymentSetting: json['paymentSetting'] == null
      ? null
      : PaymentSetting.fromJson(json['paymentSetting'] as Map<String, dynamic>),
  customerBookingSetting: json['customerBookingSetting'] == null
      ? null
      : BookingSetting.fromJson(
          json['customerBookingSetting'] as Map<String, dynamic>,
        ),
  id: json['_id'] as String?,
  tipPrices: (json['tipPrices'] as List<dynamic>?)
      ?.map((e) => (e as num).toDouble())
      .toList(),
  cityId: json['cityId'] as String?,
  isAds: json['isAds'] as bool? ?? false,
  timezone: json['timezone'] as String?,
);

Map<String, dynamic> _$CitySettingToJson(CitySetting instance) =>
    <String, dynamic>{
      'driverSetting': instance.driverSetting,
      'bidSetting': instance.bidSetting,
      'bookingSetting': instance.bookingSetting,
      'businessSetting': instance.businessSettings,
      'businessSequence': instance.businessSequence,
      'isAllowSetLocationFromMap': instance.isAllowSetLocationFromMap,
      'isShowCityInHomeScreen': instance.isShowCityInHomeScreen,
      'isShowPeakHoursChart': instance.isShowPeakHoursChart,
      'maxStopLimit': instance.maxStopLimit,
      'paymentSetting': instance.paymentSetting,
      'customerBookingSetting': instance.customerBookingSetting,
      '_id': instance.id,
      'tipPrices': instance.tipPrices,
      'cityId': instance.cityId,
      'isAds': instance.isAds,
      'timezone': instance.timezone,
    };

DriverSettings _$DriverSettingsFromJson(
  Map<String, dynamic> json,
) => DriverSettings(
  normal: json['NORMAL'] == null
      ? null
      : NormalDriverSettings.fromJson(json['NORMAL'] as Map<String, dynamic>),
  rental: json['RENTAL'] == null
      ? null
      : NormalDriverSettings.fromJson(json['RENTAL'] as Map<String, dynamic>),
  share: json['SHARE'] == null
      ? null
      : NormalDriverSettings.fromJson(json['SHARE'] as Map<String, dynamic>),
  fixGroupBooking: json['FIX_GROUP_BOOKING'] == null
      ? null
      : NormalDriverSettings.fromJson(
          json['FIX_GROUP_BOOKING'] as Map<String, dynamic>,
        ),
  delivery: json['DELIVERY'] == null
      ? null
      : NormalDriverSettings.fromJson(json['DELIVERY'] as Map<String, dynamic>),
  pickup: json['PICKUP'] == null
      ? null
      : NormalDriverSettings.fromJson(json['PICKUP'] as Map<String, dynamic>),
  onSiteService: json['ON_SITE_SERVICE'] == null
      ? null
      : NormalDriverSettings.fromJson(
          json['ON_SITE_SERVICE'] as Map<String, dynamic>,
        ),
  serviceAtHome: json['SERVICE_AT_HOME'] == null
      ? null
      : NormalDriverSettings.fromJson(
          json['SERVICE_AT_HOME'] as Map<String, dynamic>,
        ),
  onlineService: json['ONLINE_SERVICE'] == null
      ? null
      : NormalDriverSettings.fromJson(
          json['ONLINE_SERVICE'] as Map<String, dynamic>,
        ),
  interCityCourier: json['INTER_CITY_COURIER'] == null
      ? null
      : NormalDriverSettings.fromJson(
          json['INTER_CITY_COURIER'] as Map<String, dynamic>,
        ),
  intraCityCourier: json['INTRA_CITY_COURIER'] == null
      ? null
      : NormalDriverSettings.fromJson(
          json['INTRA_CITY_COURIER'] as Map<String, dynamic>,
        ),
  mover: json['MOVER'] == null
      ? null
      : NormalDriverSettings.fromJson(json['MOVER'] as Map<String, dynamic>),
);

Map<String, dynamic> _$DriverSettingsToJson(DriverSettings instance) =>
    <String, dynamic>{
      'NORMAL': instance.normal,
      'RENTAL': instance.rental,
      'SHARE': instance.share,
      'FIX_GROUP_BOOKING': instance.fixGroupBooking,
      'DELIVERY': instance.delivery,
      'PICKUP': instance.pickup,
      'ON_SITE_SERVICE': instance.onSiteService,
      'SERVICE_AT_HOME': instance.serviceAtHome,
      'ONLINE_SERVICE': instance.onlineService,
      'INTER_CITY_COURIER': instance.interCityCourier,
      'INTRA_CITY_COURIER': instance.intraCityCourier,
      'MOVER': instance.mover,
    };

NormalDriverSettings _$NormalDriverSettingsFromJson(
  Map<String, dynamic> json,
) => NormalDriverSettings(
  now: json['NOW'] == null
      ? null
      : Now.fromJson(json['NOW'] as Map<String, dynamic>),
  schedule: json['SCHEDULE'] == null
      ? null
      : Schedule.fromJson(json['SCHEDULE'] as Map<String, dynamic>),
);

Map<String, dynamic> _$NormalDriverSettingsToJson(
  NormalDriverSettings instance,
) => <String, dynamic>{'NOW': instance.now, 'SCHEDULE': instance.schedule};

Now _$NowFromJson(Map<String, dynamic> json) => Now(
  driverSearchRadius: (json['driverSearchRadius'] as num?)?.toInt(),
  driverTimeout: (json['driverTimeout'] as num?)?.toInt(),
  findDriverType: (json['findDriverType'] as num?)?.toInt(),
  maxDriverLimit: (json['maxDriverLimit'] as num?)?.toInt(),
  nextCycleStartAfterTime: (json['nextCycleStartAfterTime'] as num?)?.toInt(),
  noOfTimeCheckDriver: (json['noOfTimeCheckDriver'] as num?)?.toInt(),
);

Map<String, dynamic> _$NowToJson(Now instance) => <String, dynamic>{
  'driverSearchRadius': instance.driverSearchRadius,
  'driverTimeout': instance.driverTimeout,
  'findDriverType': instance.findDriverType,
  'maxDriverLimit': instance.maxDriverLimit,
  'nextCycleStartAfterTime': instance.nextCycleStartAfterTime,
  'noOfTimeCheckDriver': instance.noOfTimeCheckDriver,
};

Schedule _$ScheduleFromJson(Map<String, dynamic> json) => Schedule(
  bufferTime: (json['bufferTime'] as num?)?.toInt(),
  cancelBookingBeforeTime: (json['cancelBookingBeforeTime'] as num?)?.toInt(),
  driverSearchRadius: (json['driverSearchRadius'] as num?)?.toInt(),
  driverTimeout: (json['driverTimeout'] as num?)?.toInt(),
  findDriverBeforeBookingTime: (json['findDriverBeforeBookingTime'] as num?)
      ?.toInt(),
  findDriverMode: json['findDriverMode'] as String?,
  findDriverType: (json['findDriverType'] as num?)?.toInt(),
  isMoveBookingToMarketPlace: json['isMoveBookingToMarketPlace'] as bool?,
  maxBookingDays: (json['maxBookingDays'] as num?)?.toInt(),
  maxDriverLimit: (json['maxDriverLimit'] as num?)?.toInt(),
  nextCycleStartAfterTime: (json['nextCycleStartAfterTime'] as num?)?.toInt(),
  noOfTimeCheckDriver: (json['noOfTimeCheckDriver'] as num?)?.toInt(),
  sendNotificationBeforTime:
      (json['sendNotificationBeforTime'] as List<dynamic>?)
          ?.map((e) => (e as num?)?.toInt())
          .toList(),
  scheduleTimeSelectionType: (json['scheduleTimeSelectionType'] as num?)
      ?.toInt(),
  slotIntervalInMinutes: (json['slotIntervalInMinutes'] as num?)?.toInt(),
);

Map<String, dynamic> _$ScheduleToJson(Schedule instance) => <String, dynamic>{
  'bufferTime': instance.bufferTime,
  'cancelBookingBeforeTime': instance.cancelBookingBeforeTime,
  'driverSearchRadius': instance.driverSearchRadius,
  'driverTimeout': instance.driverTimeout,
  'findDriverBeforeBookingTime': instance.findDriverBeforeBookingTime,
  'findDriverMode': instance.findDriverMode,
  'findDriverType': instance.findDriverType,
  'isMoveBookingToMarketPlace': instance.isMoveBookingToMarketPlace,
  'maxBookingDays': instance.maxBookingDays,
  'maxDriverLimit': instance.maxDriverLimit,
  'nextCycleStartAfterTime': instance.nextCycleStartAfterTime,
  'noOfTimeCheckDriver': instance.noOfTimeCheckDriver,
  'sendNotificationBeforTime': instance.sendNotificationBeforTime,
  'scheduleTimeSelectionType': instance.scheduleTimeSelectionType,
  'slotIntervalInMinutes': instance.slotIntervalInMinutes,
};

BidSetting _$BidSettingFromJson(Map<String, dynamic> json) => BidSetting(
  normal: json['NORMAL'] == null
      ? null
      : BidSettingInfo.fromJson(json['NORMAL'] as Map<String, dynamic>),
  fixGroupBooking: json['FIX_GROUP_BOOKING'] == null
      ? null
      : BidSettingInfo.fromJson(
          json['FIX_GROUP_BOOKING'] as Map<String, dynamic>,
        ),
  rental: json['RENTAL'] == null
      ? null
      : BidSettingInfo.fromJson(json['RENTAL'] as Map<String, dynamic>),
  share: json['SHARE'] == null
      ? null
      : BidSettingInfo.fromJson(json['SHARE'] as Map<String, dynamic>),
);

Map<String, dynamic> _$BidSettingToJson(BidSetting instance) =>
    <String, dynamic>{
      'NORMAL': instance.normal,
      'FIX_GROUP_BOOKING': instance.fixGroupBooking,
      'RENTAL': instance.rental,
      'SHARE': instance.share,
    };

BidSettingInfo _$BidSettingInfoFromJson(Map<String, dynamic> json) =>
    BidSettingInfo(
      customerBiddingTimeout: (json['customerBiddingTimeout'] as num?)?.toInt(),
      customerMinBid: (json['customerMinBid'] as num?)?.toInt(),
      driverBiddingTimeout: (json['driverBiddingTimeout'] as num?)?.toInt(),
      driverMaxBid: (json['driverMaxBid'] as num?)?.toInt(),
      isCustomerCanBid: json['isCustomerCanBid'] as bool?,
      maxDriverBidLimit: (json['maxDriverBidLimit'] as num?)?.toInt(),
      isAllowIncrementDecrementStepper:
          json['isAllowIncrementDecrementStepper'] as bool?,
      incrementDecrementStepper: (json['incrementDecrementStepper'] as num?)
          ?.toDouble(),
    );

Map<String, dynamic> _$BidSettingInfoToJson(
  BidSettingInfo instance,
) => <String, dynamic>{
  'customerBiddingTimeout': instance.customerBiddingTimeout,
  'customerMinBid': instance.customerMinBid,
  'driverBiddingTimeout': instance.driverBiddingTimeout,
  'driverMaxBid': instance.driverMaxBid,
  'isCustomerCanBid': instance.isCustomerCanBid,
  'maxDriverBidLimit': instance.maxDriverBidLimit,
  'isAllowIncrementDecrementStepper': instance.isAllowIncrementDecrementStepper,
  'incrementDecrementStepper': instance.incrementDecrementStepper,
};

BusinessSettings _$BusinessSettingsFromJson(
  Map<String, dynamic> json,
) => BusinessSettings(
  normal: (json['NORMAL'] as List<dynamic>?)?.map((e) => e as String).toList(),
  rental: (json['RENTAL'] as List<dynamic>?)?.map((e) => e as String).toList(),
  share: (json['SHARE'] as List<dynamic>?)?.map((e) => e as String).toList(),
  fixGroupBooking: (json['FIX_GROUP_BOOKING'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  quickCommerce: (json['QUICK_COMMERCE'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  delivery: (json['DELIVERY'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  pickup: (json['PICKUP'] as List<dynamic>?)?.map((e) => e as String).toList(),
  onSiteService: (json['ON_SITE_SERVICE'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  serviceAtHome: (json['SERVICE_AT_HOME'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  onlineService: (json['ONLINE_SERVICE'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  intraCityCourier: (json['INTRA_CITY_COURIER'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  interCityCourier: (json['INTER_CITY_COURIER'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  mover: (json['MOVER'] as List<dynamic>?)?.map((e) => e as String).toList(),
);

Map<String, dynamic> _$BusinessSettingsToJson(BusinessSettings instance) =>
    <String, dynamic>{
      'NORMAL': instance.normal,
      'RENTAL': instance.rental,
      'SHARE': instance.share,
      'FIX_GROUP_BOOKING': instance.fixGroupBooking,
      'QUICK_COMMERCE': instance.quickCommerce,
      'DELIVERY': instance.delivery,
      'PICKUP': instance.pickup,
      'ON_SITE_SERVICE': instance.onSiteService,
      'SERVICE_AT_HOME': instance.serviceAtHome,
      'ONLINE_SERVICE': instance.onlineService,
      'INTRA_CITY_COURIER': instance.intraCityCourier,
      'INTER_CITY_COURIER': instance.interCityCourier,
      'MOVER': instance.mover,
    };

BookingSetting _$BookingSettingFromJson(
  Map<String, dynamic> json,
) => BookingSetting(
  normal: json['NORMAL'] == null
      ? null
      : BookingTypeSettings.fromJson(json['NORMAL'] as Map<String, dynamic>),
  rental: json['RENTAL'] == null
      ? null
      : BookingTypeSettings.fromJson(json['RENTAL'] as Map<String, dynamic>),
  share: json['SHARE'] == null
      ? null
      : BookingTypeSettings.fromJson(json['SHARE'] as Map<String, dynamic>),
  fixGroupBooking: json['FIX_GROUP_BOOKING'] == null
      ? null
      : BookingTypeSettings.fromJson(
          json['FIX_GROUP_BOOKING'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$BookingSettingToJson(BookingSetting instance) =>
    <String, dynamic>{
      'NORMAL': instance.normal,
      'RENTAL': instance.rental,
      'SHARE': instance.share,
      'FIX_GROUP_BOOKING': instance.fixGroupBooking,
    };

BookingTypeSettings _$BookingTypeSettingsFromJson(Map<String, dynamic> json) =>
    BookingTypeSettings(
      isAllowDestinationLater: json['isAllowDestinationLater'] as bool?,
      isAllowScheduleBooking: json['isAllowScheduleBooking'] as bool?,
      isDestinationRequired: json['isDestinationRequired'] as bool?,
      isShowEstimateFare: json['isShowEstimateFare'] as bool?,
    );

Map<String, dynamic> _$BookingTypeSettingsToJson(
  BookingTypeSettings instance,
) => <String, dynamic>{
  'isAllowDestinationLater': instance.isAllowDestinationLater,
  'isAllowScheduleBooking': instance.isAllowScheduleBooking,
  'isDestinationRequired': instance.isDestinationRequired,
  'isShowEstimateFare': instance.isShowEstimateFare,
};

PaymentSetting _$PaymentSettingFromJson(Map<String, dynamic> json) =>
    PaymentSetting(
      normal: json['NORMAL'] == null
          ? null
          : VehicleTypePaymentSetting.fromJson(
              json['NORMAL'] as Map<String, dynamic>,
            ),
      fixGroupBooking: json['FIX_GROUP_BOOKING'] == null
          ? null
          : VehicleTypePaymentSetting.fromJson(
              json['FIX_GROUP_BOOKING'] as Map<String, dynamic>,
            ),
      rental: json['RENTAL'] == null
          ? null
          : VehicleTypePaymentSetting.fromJson(
              json['RENTAL'] as Map<String, dynamic>,
            ),
      share: json['SHARE'] == null
          ? null
          : VehicleTypePaymentSetting.fromJson(
              json['SHARE'] as Map<String, dynamic>,
            ),
      quickCommerce: json['QUICK_COMMERCE'] == null
          ? null
          : VehicleTypePaymentSetting.fromJson(
              json['QUICK_COMMERCE'] as Map<String, dynamic>,
            ),
      delivery: json['DELIVERY'] == null
          ? null
          : VehicleTypePaymentSetting.fromJson(
              json['DELIVERY'] as Map<String, dynamic>,
            ),
      pickup: json['PICKUP'] == null
          ? null
          : VehicleTypePaymentSetting.fromJson(
              json['PICKUP'] as Map<String, dynamic>,
            ),
      onSiteService: json['ON_SITE_SERVICE'] == null
          ? null
          : VehicleTypePaymentSetting.fromJson(
              json['ON_SITE_SERVICE'] as Map<String, dynamic>,
            ),
      serviceAtHome: json['SERVICE_AT_HOME'] == null
          ? null
          : VehicleTypePaymentSetting.fromJson(
              json['SERVICE_AT_HOME'] as Map<String, dynamic>,
            ),
      onlineService: json['ONLINE_SERVICE'] == null
          ? null
          : VehicleTypePaymentSetting.fromJson(
              json['ONLINE_SERVICE'] as Map<String, dynamic>,
            ),
      interCityCourier: json['INTER_CITY_COURIER'] == null
          ? null
          : VehicleTypePaymentSetting.fromJson(
              json['INTER_CITY_COURIER'] as Map<String, dynamic>,
            ),
      intraCityCourier: json['INTRA_CITY_COURIER'] == null
          ? null
          : VehicleTypePaymentSetting.fromJson(
              json['INTRA_CITY_COURIER'] as Map<String, dynamic>,
            ),
      mover: json['MOVER'] == null
          ? null
          : VehicleTypePaymentSetting.fromJson(
              json['MOVER'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$PaymentSettingToJson(PaymentSetting instance) =>
    <String, dynamic>{
      'NORMAL': instance.normal,
      'FIX_GROUP_BOOKING': instance.fixGroupBooking,
      'RENTAL': instance.rental,
      'SHARE': instance.share,
      'QUICK_COMMERCE': instance.quickCommerce,
      'DELIVERY': instance.delivery,
      'PICKUP': instance.pickup,
      'ON_SITE_SERVICE': instance.onSiteService,
      'SERVICE_AT_HOME': instance.serviceAtHome,
      'ONLINE_SERVICE': instance.onlineService,
      'INTER_CITY_COURIER': instance.interCityCourier,
      'INTRA_CITY_COURIER': instance.intraCityCourier,
      'MOVER': instance.mover,
    };

VehicleTypePaymentSetting _$VehicleTypePaymentSettingFromJson(
  Map<String, dynamic> json,
) => VehicleTypePaymentSetting(
  isCash: json['isCash'] as bool?,
  isWallet: json['isWallet'] as bool?,
  paymentGateways: _gatewaysFromJson(json['paymentGateways']),
  isAdvancePaymentLimit: json['isAdvancePaymentLimit'] as bool?,
  advancePaymentLimit: (json['advancePaymentLimit'] as num?)?.toDouble(),
);

Map<String, dynamic> _$VehicleTypePaymentSettingToJson(
  VehicleTypePaymentSetting instance,
) => <String, dynamic>{
  'isCash': instance.isCash,
  'isWallet': instance.isWallet,
  'paymentGateways': instance.paymentGateways,
  'isAdvancePaymentLimit': instance.isAdvancePaymentLimit,
  'advancePaymentLimit': instance.advancePaymentLimit,
};

CountrySettings _$CountrySettingsFromJson(Map<String, dynamic> json) =>
    CountrySettings(
      currencySign: json['currencySign'] as String?,
      decimalPointValue: (json['decimalPointValue'] as num?)?.toInt(),
      distanceUnit: (json['distanceUnit'] as num?)?.toInt(),
      id: json['_id'] as String?,
      isAllowGenderSelection: json['isAllowGenderSelection'] as bool?,
      isBusiness: json['isBusiness'] as bool?,
      roundingMethod: (json['roundingMethod'] as num?)?.toDouble(),
      setCurrencySign: (json['setCurrencySign'] as num?)?.toInt(),
      speakingLanguages: (json['speakingLanguages'] as List<dynamic>?)
          ?.map((e) => SpeakingLanguage.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CountrySettingsToJson(CountrySettings instance) =>
    <String, dynamic>{
      'currencySign': instance.currencySign,
      'decimalPointValue': instance.decimalPointValue,
      'distanceUnit': instance.distanceUnit,
      '_id': instance.id,
      'isAllowGenderSelection': instance.isAllowGenderSelection,
      'isBusiness': instance.isBusiness,
      'roundingMethod': instance.roundingMethod,
      'setCurrencySign': instance.setCurrencySign,
      'speakingLanguages': instance.speakingLanguages,
    };

NormalVehicles _$NormalVehiclesFromJson(Map<String, dynamic> json) =>
    NormalVehicles(
      cityId: json['cityId'] as String?,
      countryId: json['countryId'] as String?,
      id: json['_id'] as String?,
      priceDetail: json['priceDetail'] == null
          ? null
          : InvoiceDetail.fromJson(json['priceDetail'] as Map<String, dynamic>),
      vehicleTypeDetail: json['vehicleTypeDetail'] == null
          ? null
          : VehicleTypeDetail.fromJson(
              json['vehicleTypeDetail'] as Map<String, dynamic>,
            ),
      vehicleTypeId: json['vehicleTypeId'] as String?,
      isMinFareApplied: json['isMinFareApplied'] as bool?,
      packageList: (json['packageList'] as List<dynamic>?)
          ?.map((e) => RentalPack.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$NormalVehiclesToJson(NormalVehicles instance) =>
    <String, dynamic>{
      'cityId': instance.cityId,
      'countryId': instance.countryId,
      '_id': instance.id,
      'priceDetail': instance.priceDetail,
      'vehicleTypeDetail': instance.vehicleTypeDetail,
      'vehicleTypeId': instance.vehicleTypeId,
      'isMinFareApplied': instance.isMinFareApplied,
      'packageList': instance.packageList,
    };

VehicleTypeDetail _$VehicleTypeDetailFromJson(Map<String, dynamic> json) =>
    VehicleTypeDetail(
      imageUrl: json['imageUrl'] as String?,
      isBusiness: json['isBusiness'] as bool?,
      isDefaultSelected: json['isDefaultSelected'] as bool?,
      luggageCapacity: (json['luggageCapacity'] as num?)?.toInt(),
      mapPinUrl: json['mapPinUrl'] as String?,
      name: json['name'] as String?,
      passengerCapacity: (json['passengerCapacity'] as num?)?.toInt(),
      type: (json['type'] as num?)?.toInt(),
      allowedEntities: (json['allowedEntities'] as List<dynamic>?)
          ?.map((e) => (e as num?)?.toInt())
          .toList(),
      fallbackTypes: (json['fallbackTypes'] as List<dynamic>?)
          ?.map(
            (e) => e == null
                ? null
                : FallbackType.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      uniqueId: (json['uniqueId'] as num?)?.toInt(),
      description: json['description'] as String?,
      isDescriptionEnabled: json['isDescriptionEnabled'] as bool?,
      isShowInMainScreen: json['isShowInMainScreen'] as bool? ?? false,
      weightCapacity: (json['weightCapacity'] as num?)?.toInt(),
      dimensions: json['dimensions'] == null
          ? null
          : Dimensions.fromJson(json['dimensions'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$VehicleTypeDetailToJson(VehicleTypeDetail instance) =>
    <String, dynamic>{
      'imageUrl': instance.imageUrl,
      'isBusiness': instance.isBusiness,
      'isDefaultSelected': instance.isDefaultSelected,
      'luggageCapacity': instance.luggageCapacity,
      'mapPinUrl': instance.mapPinUrl,
      'name': instance.name,
      'passengerCapacity': instance.passengerCapacity,
      'type': instance.type,
      'allowedEntities': instance.allowedEntities,
      'fallbackTypes': instance.fallbackTypes,
      'uniqueId': instance.uniqueId,
      'description': instance.description,
      'isDescriptionEnabled': instance.isDescriptionEnabled,
      'isShowInMainScreen': instance.isShowInMainScreen,
      'weightCapacity': instance.weightCapacity,
      'dimensions': instance.dimensions,
    };

FallbackType _$FallbackTypeFromJson(Map<String, dynamic> json) => FallbackType(
  id: json['_id'] as String?,
  isApplySelectedVehicleTypePrice:
      json['isApplySelectedVehicleTypePrice'] as bool?,
  vehicleTypeId: json['vehicleTypeId'] as String?,
);

Map<String, dynamic> _$FallbackTypeToJson(
  FallbackType instance,
) => <String, dynamic>{
  '_id': instance.id,
  'isApplySelectedVehicleTypePrice': instance.isApplySelectedVehicleTypePrice,
  'vehicleTypeId': instance.vehicleTypeId,
};

Dimensions _$DimensionsFromJson(Map<String, dynamic> json) => Dimensions(
  length: (json['length'] as num?)?.toDouble(),
  width: (json['width'] as num?)?.toDouble(),
  height: (json['height'] as num?)?.toDouble(),
);

Map<String, dynamic> _$DimensionsToJson(Dimensions instance) =>
    <String, dynamic>{
      'length': instance.length,
      'width': instance.width,
      'height': instance.height,
    };

RentalPack _$RentalPackFromJson(Map<String, dynamic> json) => RentalPack(
  id: json['_id'] as String?,
  packageName: json['packageName'] as String?,
  priceDetail: json['priceDetail'] == null
      ? null
      : InvoiceDetail.fromJson(json['priceDetail'] as Map<String, dynamic>),
  packageDetail: json['packageDetail'] == null
      ? null
      : PackageDetail.fromJson(json['packageDetail'] as Map<String, dynamic>),
);

Map<String, dynamic> _$RentalPackToJson(RentalPack instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'packageName': instance.packageName,
      'priceDetail': instance.priceDetail,
      'packageDetail': instance.packageDetail,
    };

PackageDetail _$PackageDetailFromJson(Map<String, dynamic> json) =>
    PackageDetail(
      distancePrice: json['distancePrice'] == null
          ? null
          : PriceData.fromJson(json['distancePrice'] as Map<String, dynamic>),
      timePrice: json['timePrice'] == null
          ? null
          : PriceData.fromJson(json['timePrice'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PackageDetailToJson(PackageDetail instance) =>
    <String, dynamic>{
      'distancePrice': instance.distancePrice,
      'timePrice': instance.timePrice,
    };
