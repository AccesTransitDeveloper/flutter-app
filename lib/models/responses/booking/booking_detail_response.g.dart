// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_detail_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookingDetailResponse _$BookingDetailResponseFromJson(
  Map<String, dynamic> json,
) => BookingDetailResponse(
  booking: json['booking'] == null
      ? null
      : BookingDetails.fromJson(json['booking'] as Map<String, dynamic>),
  cancelUptoStatus: (json['cancelUptoStatus'] as num?)?.toInt(),
  isAllowCancelBooking: json['isAllowCancelBooking'] as bool?,
  isAllowCall: json['isAllowCall'] as bool?,
  citySetting: json['citySetting'] == null
      ? null
      : BookingCitySetting.fromJson(
          json['citySetting'] as Map<String, dynamic>,
        ),
  serviceSetting: json['serviceSetting'] == null
      ? null
      : ServiceSetting.fromJson(json['serviceSetting'] as Map<String, dynamic>),
  videoCallUrl: json['videoCallUrl'] as String?,
  liveActivity: json['liveActivity'] == null
      ? null
      : LiveActivity.fromJson(json['liveActivity'] as Map<String, dynamic>),
);

Map<String, dynamic> _$BookingDetailResponseToJson(
  BookingDetailResponse instance,
) => <String, dynamic>{
  'booking': instance.booking,
  'cancelUptoStatus': instance.cancelUptoStatus,
  'isAllowCancelBooking': instance.isAllowCancelBooking,
  'isAllowCall': instance.isAllowCall,
  'citySetting': instance.citySetting,
  'serviceSetting': instance.serviceSetting,
  'videoCallUrl': instance.videoCallUrl,
  'liveActivity': instance.liveActivity,
};

LiveActivity _$LiveActivityFromJson(Map<String, dynamic> json) => LiveActivity(
  progress: (json['progress'] as num?)?.toInt(),
  pickupPoint: (json['pickupPoint'] as List<dynamic>?)
      ?.map((e) => (e as num).toInt())
      .toList(),
  destinationPoint: (json['destinationPoint'] as num?)?.toInt(),
);

Map<String, dynamic> _$LiveActivityToJson(LiveActivity instance) =>
    <String, dynamic>{
      'progress': instance.progress,
      'pickupPoint': instance.pickupPoint,
      'destinationPoint': instance.destinationPoint,
    };

BookingCitySetting _$BookingCitySettingFromJson(Map<String, dynamic> json) =>
    BookingCitySetting(
      bookingSetting: (json['bookingSetting'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      businessSetting: (json['businessSettings'] as List<dynamic>?)
          ?.map((e) => e as String?)
          .toList(),
      customerBookingSetting: json['customerBookingSetting'] == null
          ? null
          : CustomerBookingSetting.fromJson(
              json['customerBookingSetting'] as Map<String, dynamic>,
            ),
      id: json['_id'] as String?,
      tipPrices: (json['tipPrices'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
      paymentSetting: json['paymentSetting'] == null
          ? null
          : BookingPaymentSetting.fromJson(
              json['paymentSetting'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$BookingCitySettingToJson(BookingCitySetting instance) =>
    <String, dynamic>{
      'bookingSetting': instance.bookingSetting,
      'businessSettings': instance.businessSetting,
      'customerBookingSetting': instance.customerBookingSetting,
      '_id': instance.id,
      'tipPrices': instance.tipPrices,
      'paymentSetting': instance.paymentSetting,
    };

ServiceSetting _$ServiceSettingFromJson(Map<String, dynamic> json) =>
    ServiceSetting(id: json['id'] as String?);

Map<String, dynamic> _$ServiceSettingToJson(ServiceSetting instance) =>
    <String, dynamic>{'id': instance.id};

BookingDetails _$BookingDetailsFromJson(
  Map<String, dynamic> json,
) => BookingDetails(
  actualDestinationAddresses:
      json['actualDestinationAddresses'] as List<dynamic>?,
  biddingDetail: json['biddingDetail'] == null
      ? null
      : BiddingDetail.fromJson(json['biddingDetail'] as Map<String, dynamic>),
  countryId: json['countryId'] as String?,
  corporateId: json['corporateId'] as String?,
  bookingInvoice: json['bookingInvoice'] == null
      ? null
      : BookingInvoice.fromJson(json['bookingInvoice'] as Map<String, dynamic>),
  bookingTags: (json['bookingTags'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  bookingTime: (json['bookingTime'] as num?)?.toInt(),
  bookingType: (json['bookingType'] as num?)?.toInt(),
  businessType: (json['businessType'] as num?)?.toInt(),
  cancellationReason: json['cancellationReason'] as String?,
  cityId: json['cityId'] as String?,
  confirmedDriver: json['confirmedDriver'] == null
      ? null
      : ConfirmedDriver.fromJson(
          json['confirmedDriver'] as Map<String, dynamic>,
        ),
  createdDeviceInfo: json['createdDeviceInfo'] == null
      ? null
      : CreatedDeviceInfo.fromJson(
          json['createdDeviceInfo'] as Map<String, dynamic>,
        ),
  destinationAddresses: (json['destinationAddresses'] as List<dynamic>?)
      ?.map((e) => DestinationAddress.fromJson(e as Map<String, dynamic>))
      .toList(),
  id: json['_id'] as String?,
  pickupAddress: json['pickupAddress'] == null
      ? null
      : DestinationAddress.fromJson(
          json['pickupAddress'] as Map<String, dynamic>,
        ),
  speakingLanguage: json['speakingLanguage'] as String?,
  status: (json['status'] as num?)?.toInt(),
  nextStatus: (json['nextStatus'] as num?)?.toInt(),
  completedAt: (json['completedAt'] as num?)?.toInt(),
  timezone: json['timezone'] as String?,
  uniqueId: BookingDetails._toStringOrNull(json['uniqueId']),
  vehiclePriceId: json['vehiclePriceId'] as String?,
  vehicleType: json['vehicleType'] == null
      ? null
      : BookingVehicleType.fromJson(
          json['vehicleType'] as Map<String, dynamic>,
        ),
  packageDetail: json['packageDetail'] == null
      ? null
      : RentalPackageDetail.fromJson(
          json['packageDetail'] as Map<String, dynamic>,
        ),
  vehicleTypeId: json['vehicleTypeId'] as String?,
  isShowOtp: json['isShowOtp'] as bool?,
  otp: json['otp'] as String?,
  rating: json['rating'] == null
      ? null
      : BookingRating.fromJson(json['rating'] as Map<String, dynamic>),
  setCurrencySign: (json['setCurrencySign'] as num?)?.toInt(),
  decimalPointValue: (json['decimalPointValue'] as num?)?.toInt(),
  priceStr: json['priceStr'] as String?,
  distanceStr: json['distanceStr'] as String?,
  dateTimeStr: json['dateTimeStr'] as String?,
  estimatedTimeStr: json['estimatedTimeStr'] as String?,
  isDriveDetailVisible: json['isDriveDetailVisible'] as bool?,
  isUserRated: json['isUserRated'] as bool?,
  bookingTimeStr: json['bookingTimeStr'] as String?,
  quickCommerce: json['quickCommerce'] == null
      ? null
      : QuickCommerce.fromJson(json['quickCommerce'] as Map<String, dynamic>),
  cart: json['cart'] == null
      ? null
      : BookingCartData.fromJson(json['cart'] as Map<String, dynamic>),
  customerDetail: json['customerDetail'] == null
      ? null
      : OtherCustomerDetails.fromJson(
          json['customerDetail'] as Map<String, dynamic>,
        ),
  isBookForOther: json['isBookForOther'] as bool?,
  deliverIn: json['deliverIn'] as String?,
  customerVehicleDetail: json['customerVehicleDetail'] == null
      ? null
      : CustomerVehicleDetail.fromJson(
          json['customerVehicleDetail'] as Map<String, dynamic>,
        ),
  historyCitySetting: json['citySetting'] == null
      ? null
      : BookingCitySetting.fromJson(
          json['citySetting'] as Map<String, dynamic>,
        ),
  isPaymentRequired: json['isPaymentRequired'] as bool?,
  parcels: (json['parcels'] as List<dynamic>?)
      ?.map((e) => Parcel.fromJson(e as Map<String, dynamic>))
      .toList(),
  courier: json['courier'] == null
      ? null
      : Courier.fromJson(json['courier'] as Map<String, dynamic>),
  service: json['service'] == null
      ? null
      : Courier.fromJson(json['service'] as Map<String, dynamic>),
  statusTimeline: (json['statusTimeline'] as List<dynamic>?)
      ?.map((e) => StatusTimeLine.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$BookingDetailsToJson(BookingDetails instance) =>
    <String, dynamic>{
      'actualDestinationAddresses': instance.actualDestinationAddresses,
      'biddingDetail': instance.biddingDetail,
      'countryId': instance.countryId,
      'corporateId': instance.corporateId,
      'bookingInvoice': instance.bookingInvoice,
      'bookingTags': instance.bookingTags,
      'bookingTime': instance.bookingTime,
      'bookingType': instance.bookingType,
      'businessType': instance.businessType,
      'cancellationReason': instance.cancellationReason,
      'cityId': instance.cityId,
      'confirmedDriver': instance.confirmedDriver,
      'createdDeviceInfo': instance.createdDeviceInfo,
      'destinationAddresses': instance.destinationAddresses,
      '_id': instance.id,
      'pickupAddress': instance.pickupAddress,
      'speakingLanguage': instance.speakingLanguage,
      'status': instance.status,
      'nextStatus': instance.nextStatus,
      'completedAt': instance.completedAt,
      'timezone': instance.timezone,
      'uniqueId': instance.uniqueId,
      'vehiclePriceId': instance.vehiclePriceId,
      'vehicleType': instance.vehicleType,
      'packageDetail': instance.packageDetail,
      'vehicleTypeId': instance.vehicleTypeId,
      'isShowOtp': instance.isShowOtp,
      'otp': instance.otp,
      'rating': instance.rating,
      'setCurrencySign': instance.setCurrencySign,
      'decimalPointValue': instance.decimalPointValue,
      'priceStr': instance.priceStr,
      'distanceStr': instance.distanceStr,
      'dateTimeStr': instance.dateTimeStr,
      'estimatedTimeStr': instance.estimatedTimeStr,
      'isDriveDetailVisible': instance.isDriveDetailVisible,
      'isUserRated': instance.isUserRated,
      'bookingTimeStr': instance.bookingTimeStr,
      'quickCommerce': instance.quickCommerce,
      'cart': instance.cart,
      'customerDetail': instance.customerDetail,
      'isBookForOther': instance.isBookForOther,
      'deliverIn': instance.deliverIn,
      'customerVehicleDetail': instance.customerVehicleDetail,
      'citySetting': instance.historyCitySetting,
      'isPaymentRequired': instance.isPaymentRequired,
      'parcels': instance.parcels,
      'courier': instance.courier,
      'service': instance.service,
      'statusTimeline': instance.statusTimeline,
    };

OtherCustomerDetails _$OtherCustomerDetailsFromJson(
  Map<String, dynamic> json,
) => OtherCustomerDetails(
  email: json['email'] as String?,
  id: json['id'] as String?,
  imageUrl: json['imageUrl'] as String?,
  name: json['name'] as String?,
  phone: json['phone'] as String?,
  rate: (json['rate'] as num?)?.toDouble(),
  uniqueId: (json['uniqueId'] as num?)?.toInt(),
);

Map<String, dynamic> _$OtherCustomerDetailsToJson(
  OtherCustomerDetails instance,
) => <String, dynamic>{
  'email': instance.email,
  'id': instance.id,
  'imageUrl': instance.imageUrl,
  'name': instance.name,
  'phone': instance.phone,
  'rate': instance.rate,
  'uniqueId': instance.uniqueId,
};

BookingRating _$BookingRatingFromJson(Map<String, dynamic> json) =>
    BookingRating(
      customerRate: (json['customerRate'] as num?)?.toDouble(),
      customerReview: json['customerReview'] as String?,
      driverRate: (json['driverRate'] as num?)?.toInt(),
      driverReview: json['driverReview'] as String?,
      customerMerchantRate: (json['customerMerchantRate'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$BookingRatingToJson(BookingRating instance) =>
    <String, dynamic>{
      'customerRate': instance.customerRate,
      'customerReview': instance.customerReview,
      'driverRate': instance.driverRate,
      'driverReview': instance.driverReview,
      'customerMerchantRate': instance.customerMerchantRate,
    };

BiddingDetail _$BiddingDetailFromJson(Map<String, dynamic> json) =>
    BiddingDetail(
      bids: (json['bids'] as List<dynamic>?)
          ?.map((e) => Bid.fromJson(e as Map<String, dynamic>))
          .toList(),
      customerBidPrice: (json['customerBidPrice'] as num?)?.toDouble(),
      customerBidRejectTime: (json['customerBidRejectTime'] as num?)?.toInt(),
      finalBidPrice: (json['finalBidPrice'] as num?)?.toDouble(),
      remainingTime: (json['remainingTime'] as num?)?.toInt(),
      createdAt: json['createdAt'] as String?,
      isBidding: json['isBidding'] as bool?,
      price: (json['price'] as num?)?.toInt(),
      updatedAt: json['updatedAt'] as String?,
    );

Map<String, dynamic> _$BiddingDetailToJson(BiddingDetail instance) =>
    <String, dynamic>{
      'bids': instance.bids,
      'customerBidPrice': instance.customerBidPrice,
      'customerBidRejectTime': instance.customerBidRejectTime,
      'finalBidPrice': instance.finalBidPrice,
      'remainingTime': instance.remainingTime,
      'createdAt': instance.createdAt,
      'isBidding': instance.isBidding,
      'price': instance.price,
      'updatedAt': instance.updatedAt,
    };

Bid _$BidFromJson(Map<String, dynamic> json) => Bid(
  email: json['email'] as String?,
  id: json['id'] as String?,
  mongoId: json['_id'] as String?,
  imageUrl: json['imageUrl'] as String?,
  isFavourite: json['isFavourite'] as bool?,
  name: json['name'] as String?,
  phone: json['phone'] as String?,
  price: (json['price'] as num?)?.toDouble(),
  rate: (json['rate'] as num?)?.toDouble(),
  status: (json['status'] as num?)?.toInt(),
  uniqueId: (json['uniqueId'] as num?)?.toInt(),
);

Map<String, dynamic> _$BidToJson(Bid instance) => <String, dynamic>{
  'email': instance.email,
  'id': instance.id,
  '_id': instance.mongoId,
  'imageUrl': instance.imageUrl,
  'isFavourite': instance.isFavourite,
  'name': instance.name,
  'phone': instance.phone,
  'price': instance.price,
  'rate': instance.rate,
  'status': instance.status,
  'uniqueId': instance.uniqueId,
};

BookingInvoice _$BookingInvoiceFromJson(Map<String, dynamic> json) =>
    BookingInvoice(
      id: json['_id'] as String?,
      distanceUnit: (json['distanceUnit'] as num?)?.toInt(),
      currencySign: json['currencySign'] as String?,
      decimalPointValue: (json['decimalPointValue'] as num?)?.toInt(),
      estimated: json['estimated'] == null
          ? null
          : InvoiceDetail.fromJson(json['estimated'] as Map<String, dynamic>),
      actual: json['actual'] == null
          ? null
          : InvoiceDetail.fromJson(json['actual'] as Map<String, dynamic>),
      paymentMode: (json['paymentMode'] as num?)?.toInt(),
      paymentStatus: (json['paymentStatus'] as num?)?.toInt(),
      isCapturePaymentPending: json['isCapturePaymentPending'] as bool?,
      setCurrencySign: (json['setCurrencySign'] as num?)?.toInt(),
      promoDetail: json['promoDetail'] == null
          ? null
          : PromoDetail.fromJson(json['promoDetail'] as Map<String, dynamic>),
      paymentDetail: json['paymentDetail'] == null
          ? null
          : PaymentDetail.fromJson(
              json['paymentDetail'] as Map<String, dynamic>,
            ),
      isAdvancePaymentLimit: json['isAdvancePaymentLimit'] as bool?,
      advancePaymentLimit: (json['advancePaymentLimit'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$BookingInvoiceToJson(BookingInvoice instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'distanceUnit': instance.distanceUnit,
      'currencySign': instance.currencySign,
      'decimalPointValue': instance.decimalPointValue,
      'estimated': instance.estimated,
      'actual': instance.actual,
      'paymentMode': instance.paymentMode,
      'paymentStatus': instance.paymentStatus,
      'isCapturePaymentPending': instance.isCapturePaymentPending,
      'setCurrencySign': instance.setCurrencySign,
      'promoDetail': instance.promoDetail,
      'paymentDetail': instance.paymentDetail,
      'isAdvancePaymentLimit': instance.isAdvancePaymentLimit,
      'advancePaymentLimit': instance.advancePaymentLimit,
    };

PaymentDetail _$PaymentDetailFromJson(Map<String, dynamic> json) =>
    PaymentDetail(remaining: (json['remaining'] as num?)?.toDouble());

Map<String, dynamic> _$PaymentDetailToJson(PaymentDetail instance) =>
    <String, dynamic>{'remaining': instance.remaining};

InvoiceDetail _$InvoiceDetailFromJson(Map<String, dynamic> json) =>
    InvoiceDetail(
      distance: (json['distance'] as num?)?.toDouble(),
      time: (json['time'] as num?)?.toInt(),
      waitingTime: (json['waitingTime'] as num?)?.toDouble(),
      stopWaitingTime: (json['stopWaitingTime'] as num?)?.toDouble(),
      trafficTime: (json['trafficTime'] as num?)?.toDouble(),
      directionPath: json['directionPath'] as String?,
      isMinFareApplied: json['isMinFareApplied'] as bool?,
      charges: (json['charges'] as List<dynamic>?)
          ?.map((e) => PriceData.fromJson(e as Map<String, dynamic>))
          .toList(),
      additionalPrices: (json['additionalPrices'] as List<dynamic>?)
          ?.map((e) => PriceData.fromJson(e as Map<String, dynamic>))
          .toList(),
      accessibilityPrices: (json['accessibilityPrices'] as List<dynamic>?)
          ?.map((e) => PriceData.fromJson(e as Map<String, dynamic>))
          .toList(),
      taxPrices: (json['taxPrices'] as List<dynamic>?)
          ?.map((e) => PriceData.fromJson(e as Map<String, dynamic>))
          .toList(),
      isOutsideBoundary: json['isOutsideBoundary'] as bool?,
      priceType: (json['priceType'] as num?)?.toInt(),
      total: (json['total'] as num?)?.toDouble(),
      driverProfit: (json['driverProfit'] as num?)?.toDouble(),
      bookingFee: (json['bookingFee'] as num?)?.toInt(),
      bookingType: (json['boookingType'] as num?)?.toInt(),
      distancePrice: (json['distancePrice'] as num?)?.toInt(),
      distanceUnit: (json['distanceUnit'] as num?)?.toInt(),
      appliedOffer: (json['appliedOffer'] as List<dynamic>?)
          ?.map((e) => AppliedOffer.fromJson(e as Map<String, dynamic>))
          .toList(),
      modifierPrice: (json['modifierPrices'] as List<dynamic>?)
          ?.map((e) => ModifierPrice.fromJson(e as Map<String, dynamic>))
          .toList(),
      orderReceiveDate: json['orderReceiveDate'] as String?,
    );

Map<String, dynamic> _$InvoiceDetailToJson(InvoiceDetail instance) =>
    <String, dynamic>{
      'distance': instance.distance,
      'time': instance.time,
      'waitingTime': instance.waitingTime,
      'stopWaitingTime': instance.stopWaitingTime,
      'trafficTime': instance.trafficTime,
      'directionPath': instance.directionPath,
      'isMinFareApplied': instance.isMinFareApplied,
      'charges': instance.charges,
      'additionalPrices': instance.additionalPrices,
      'accessibilityPrices': instance.accessibilityPrices,
      'taxPrices': instance.taxPrices,
      'isOutsideBoundary': instance.isOutsideBoundary,
      'priceType': instance.priceType,
      'total': instance.total,
      'driverProfit': instance.driverProfit,
      'bookingFee': instance.bookingFee,
      'boookingType': instance.bookingType,
      'distancePrice': instance.distancePrice,
      'distanceUnit': instance.distanceUnit,
      'appliedOffer': instance.appliedOffer,
      'modifierPrices': instance.modifierPrice,
      'orderReceiveDate': instance.orderReceiveDate,
    };

PriceData _$PriceDataFromJson(Map<String, dynamic> json) => PriceData(
  isActive: json['isActive'] as bool?,
  title: json['title'] as String?,
  chargeId: json['chargeId'] as String?,
  type: (json['type'] as num?)?.toInt(),
  price: (json['price'] as num?)?.toDouble(),
  discountedPrice: (json['discountedPrice'] as num?)?.toDouble(),
  priceType: (json['priceType'] as num?)?.toInt(),
  driverProfit: (json['driverProfit'] as num?)?.toDouble(),
  driverProfitType: (json['driverProfitType'] as num?)?.toInt(),
  applyOn: (json['applyOn'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  appliedSlots: (json['appliedSlots'] as List<dynamic>?)
      ?.map((e) => AppliedSlot.fromJson(e as Map<String, dynamic>))
      .toList(),
  slots: (json['slots'] as List<dynamic>?)
      ?.map((e) => AppliedSlot.fromJson(e as Map<String, dynamic>))
      .toList(),
  basePrice: (json['basePrice'] as num?)?.toDouble(),
  basePriceUnit: (json['basePriceUnit'] as num?)?.toDouble(),
  unitPrice: (json['unitPrice'] as num?)?.toDouble(),
  driverProfitPercentage: (json['driverProfitPercentage'] as num?)?.toDouble(),
  unit: (json['unit'] as num?)?.toDouble(),
  isApplySlotPrice: json['isApplySlotPrice'] as bool?,
  isSlotInPriceWithUnitCalculation:
      json['isSlotInPriceWithUnitCalculation'] as bool?,
  isSlotInPriceWithSum: json['isSlotInPriceWithSum'] as bool?,
  isMinFareApplied: json['isMinFareApplied'] as bool?,
  isApplyTax: json['isApplyTax'] as bool?,
  childs: (json['childs'] as List<dynamic>?)
      ?.map((e) => PriceData.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$PriceDataToJson(PriceData instance) => <String, dynamic>{
  'isActive': instance.isActive,
  'title': instance.title,
  'chargeId': instance.chargeId,
  'type': instance.type,
  'price': instance.price,
  'discountedPrice': instance.discountedPrice,
  'priceType': instance.priceType,
  'driverProfit': instance.driverProfit,
  'driverProfitType': instance.driverProfitType,
  'applyOn': instance.applyOn,
  'appliedSlots': instance.appliedSlots,
  'slots': instance.slots,
  'basePrice': instance.basePrice,
  'basePriceUnit': instance.basePriceUnit,
  'unitPrice': instance.unitPrice,
  'driverProfitPercentage': instance.driverProfitPercentage,
  'unit': instance.unit,
  'isApplySlotPrice': instance.isApplySlotPrice,
  'isSlotInPriceWithUnitCalculation': instance.isSlotInPriceWithUnitCalculation,
  'isSlotInPriceWithSum': instance.isSlotInPriceWithSum,
  'isMinFareApplied': instance.isMinFareApplied,
  'isApplyTax': instance.isApplyTax,
  'childs': instance.childs,
};

AppliedSlot _$AppliedSlotFromJson(Map<String, dynamic> json) => AppliedSlot(
  min: (json['min'] as num?)?.toDouble(),
  max: (json['max'] as num?)?.toDouble(),
  price: (json['price'] as num?)?.toDouble(),
  unitPrice: (json['unitPrice'] as num?)?.toDouble(),
  unit: (json['unit'] as num?)?.toDouble(),
  driverProfit: (json['driverProfit'] as num?)?.toDouble(),
);

Map<String, dynamic> _$AppliedSlotToJson(AppliedSlot instance) =>
    <String, dynamic>{
      'min': instance.min,
      'max': instance.max,
      'price': instance.price,
      'unitPrice': instance.unitPrice,
      'unit': instance.unit,
      'driverProfit': instance.driverProfit,
    };

AppliedOffer _$AppliedOfferFromJson(Map<String, dynamic> json) => AppliedOffer(
  id: json['id'] as String?,
  name: json['name'] as String?,
  discount: (json['discount'] as num?)?.toDouble(),
);

Map<String, dynamic> _$AppliedOfferToJson(AppliedOffer instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'discount': instance.discount,
    };

ConfirmedDriver _$ConfirmedDriverFromJson(Map<String, dynamic> json) =>
    ConfirmedDriver(
      id: json['id'] as String?,
      imageUrl: json['imageUrl'] as String?,
      isFavourite: json['isFavourite'] as bool?,
      location: json['location'] == null
          ? null
          : DriverGeoLocation.fromJson(
              json['location'] as Map<String, dynamic>,
            ),
      name: json['name'] as String?,
      phone: json['phone'] as String?,
      rate: (json['rate'] as num?)?.toDouble(),
      vehicleDetail: json['vehicleDetail'] == null
          ? null
          : DriverVehicleDetail.fromJson(
              json['vehicleDetail'] as Map<String, dynamic>,
            ),
      isDriverHasOtherBookings: json['isDriverHasOtherBookings'] as bool?,
    );

Map<String, dynamic> _$ConfirmedDriverToJson(ConfirmedDriver instance) =>
    <String, dynamic>{
      'id': instance.id,
      'imageUrl': instance.imageUrl,
      'isFavourite': instance.isFavourite,
      'location': instance.location,
      'name': instance.name,
      'phone': instance.phone,
      'rate': instance.rate,
      'vehicleDetail': instance.vehicleDetail,
      'isDriverHasOtherBookings': instance.isDriverHasOtherBookings,
    };

DriverGeoLocation _$DriverGeoLocationFromJson(Map<String, dynamic> json) =>
    DriverGeoLocation(
      coordinates: (json['coordinates'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
      type: json['type'] as String?,
    );

Map<String, dynamic> _$DriverGeoLocationToJson(DriverGeoLocation instance) =>
    <String, dynamic>{
      'coordinates': instance.coordinates,
      'type': instance.type,
    };

CreatedDeviceInfo _$CreatedDeviceInfoFromJson(Map<String, dynamic> json) =>
    CreatedDeviceInfo(type: (json['type'] as num?)?.toInt());

Map<String, dynamic> _$CreatedDeviceInfoToJson(CreatedDeviceInfo instance) =>
    <String, dynamic>{'type': instance.type};

BookingVehicleType _$BookingVehicleTypeFromJson(Map<String, dynamic> json) =>
    BookingVehicleType(
      id: json['_id'] as String?,
      name: json['name'] as String?,
      imageUrl: json['imageUrl'] as String?,
      mapPinUrl: json['mapPinUrl'] as String?,
    );

Map<String, dynamic> _$BookingVehicleTypeToJson(BookingVehicleType instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'name': instance.name,
      'imageUrl': instance.imageUrl,
      'mapPinUrl': instance.mapPinUrl,
    };

RentalPackageDetail _$RentalPackageDetailFromJson(Map<String, dynamic> json) =>
    RentalPackageDetail(
      id: json['_id'] as String?,
      packageName: json['packageName'] as String?,
      distancePrice: json['distancePrice'] == null
          ? null
          : PriceData.fromJson(json['distancePrice'] as Map<String, dynamic>),
      timePrice: json['timePrice'] == null
          ? null
          : PriceData.fromJson(json['timePrice'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$RentalPackageDetailToJson(
  RentalPackageDetail instance,
) => <String, dynamic>{
  '_id': instance.id,
  'packageName': instance.packageName,
  'distancePrice': instance.distancePrice,
  'timePrice': instance.timePrice,
};

DriverVehicleDetail _$DriverVehicleDetailFromJson(Map<String, dynamic> json) =>
    DriverVehicleDetail(
      id: json['id'] as String?,
      type: (json['type'] as num?)?.toInt(),
      vehicleType: (json['vehicleType'] as num?)?.toInt(),
      name: json['name'] as String?,
      brandId: json['brandId'] as String?,
      brand: json['brand'] as String?,
      modelId: json['modelId'] as String?,
      model: json['model'] as String?,
      color: json['color'] as String?,
      year: json['year'] as String?,
      plateNo: json['plateNo'] as String?,
      vehicleLicense: json['vehicleLicense'] as String?,
    );

Map<String, dynamic> _$DriverVehicleDetailToJson(
  DriverVehicleDetail instance,
) => <String, dynamic>{
  'id': instance.id,
  'type': instance.type,
  'vehicleType': instance.vehicleType,
  'name': instance.name,
  'brandId': instance.brandId,
  'brand': instance.brand,
  'modelId': instance.modelId,
  'model': instance.model,
  'color': instance.color,
  'year': instance.year,
  'plateNo': instance.plateNo,
  'vehicleLicense': instance.vehicleLicense,
};

CustomerVehicleDetail _$CustomerVehicleDetailFromJson(
  Map<String, dynamic> json,
) => CustomerVehicleDetail(
  id: json['id'] as String?,
  type: (json['type'] as num?)?.toInt(),
  vehicleType: (json['vehicleType'] as num?)?.toInt(),
  name: json['name'] as String?,
  brandId: json['brandId'] as String?,
  brand: json['brand'] as String?,
  modelId: json['modelId'] as String?,
  model: json['model'] as String?,
  color: json['color'] as String?,
  year: json['year'] as String?,
  plateNo: json['plateNo'] as String?,
  vehicleLicense: json['vehicleLicense'] as String?,
);

Map<String, dynamic> _$CustomerVehicleDetailToJson(
  CustomerVehicleDetail instance,
) => <String, dynamic>{
  'id': instance.id,
  'type': instance.type,
  'vehicleType': instance.vehicleType,
  'name': instance.name,
  'brandId': instance.brandId,
  'brand': instance.brand,
  'modelId': instance.modelId,
  'model': instance.model,
  'color': instance.color,
  'year': instance.year,
  'plateNo': instance.plateNo,
  'vehicleLicense': instance.vehicleLicense,
};

BookingPaymentSetting _$BookingPaymentSettingFromJson(
  Map<String, dynamic> json,
) => BookingPaymentSetting(
  isCash: json['isCash'] as bool?,
  isWallet: json['isWallet'] as bool?,
  paymentGateways: (json['paymentGateways'] as List<dynamic>?)
      ?.map((e) => (e as num).toInt())
      .toList(),
  captureRequiredPaymentGateways:
      (json['captureRequiredPaymentGateways'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
  advancePaymentPaymentGateways:
      (json['advancePaymentPaymentGateways'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
  isWalletAdvancePayment: json['isWalletAdvancePayment'] as bool?,
  isPartialPayment: json['isPartialPayment'] as bool?,
);

Map<String, dynamic> _$BookingPaymentSettingToJson(
  BookingPaymentSetting instance,
) => <String, dynamic>{
  'isCash': instance.isCash,
  'isWallet': instance.isWallet,
  'paymentGateways': instance.paymentGateways,
  'captureRequiredPaymentGateways': instance.captureRequiredPaymentGateways,
  'advancePaymentPaymentGateways': instance.advancePaymentPaymentGateways,
  'isWalletAdvancePayment': instance.isWalletAdvancePayment,
  'isPartialPayment': instance.isPartialPayment,
};

CustomerBookingSetting _$CustomerBookingSettingFromJson(
  Map<String, dynamic> json,
) => CustomerBookingSetting(
  accepted: (json['ACCEPTED'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  arrivedAtDestination: (json['ARRIVED_AT_DESTINATION'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  arrivedAtPickup: (json['ARRIVED_AT_PICKUP'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  arrivedAtStop: (json['ARRIVED_AT_STOP'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  assigned: (json['ASSIGNED'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  inRoute: (json['IN_ROUTE'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  requested: (json['REQUESTED'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  started: (json['STARTED'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  picked: (json['PICKED'] as List<dynamic>?)?.map((e) => e as String).toList(),
  dropped: (json['DROPPED'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  arrivedNearDestination: (json['ARRIVED_NEAR_DESTINATION'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  merchantAccepted: (json['MERCHANT_ACCEPTED'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  merchantPreparing: (json['MERCHANT_PREPARING'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  merchantCompleted: (json['MERCHANT_COMPLETED'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  serviceCompleted: (json['SERVICE_COMPLETED'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  verificationCodeLength: (json['verificationCodeLength'] as num?)?.toInt(),
);

Map<String, dynamic> _$CustomerBookingSettingToJson(
  CustomerBookingSetting instance,
) => <String, dynamic>{
  'ACCEPTED': instance.accepted,
  'ARRIVED_AT_DESTINATION': instance.arrivedAtDestination,
  'ARRIVED_AT_PICKUP': instance.arrivedAtPickup,
  'ARRIVED_AT_STOP': instance.arrivedAtStop,
  'ASSIGNED': instance.assigned,
  'IN_ROUTE': instance.inRoute,
  'REQUESTED': instance.requested,
  'STARTED': instance.started,
  'PICKED': instance.picked,
  'DROPPED': instance.dropped,
  'ARRIVED_NEAR_DESTINATION': instance.arrivedNearDestination,
  'MERCHANT_ACCEPTED': instance.merchantAccepted,
  'MERCHANT_PREPARING': instance.merchantPreparing,
  'MERCHANT_COMPLETED': instance.merchantCompleted,
  'SERVICE_COMPLETED': instance.serviceCompleted,
  'verificationCodeLength': instance.verificationCodeLength,
};

QuickCommerce _$QuickCommerceFromJson(Map<String, dynamic> json) =>
    QuickCommerce(id: json['id'] as String?);

Map<String, dynamic> _$QuickCommerceToJson(QuickCommerce instance) =>
    <String, dynamic>{'id': instance.id};

BookingCartData _$BookingCartDataFromJson(Map<String, dynamic> json) =>
    BookingCartData(
      id: json['_id'] as String?,
      products: (json['products'] as List<dynamic>?)
          ?.map((e) => AvailableProduct.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$BookingCartDataToJson(BookingCartData instance) =>
    <String, dynamic>{'_id': instance.id, 'products': instance.products};

AvailableProduct _$AvailableProductFromJson(Map<String, dynamic> json) =>
    AvailableProduct(
      id: json['_id'] as String?,
      name: json['name'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      quantity: (json['quantity'] as num?)?.toInt(),
      imageUrl: json['imageUrl'] as String?,
    );

Map<String, dynamic> _$AvailableProductToJson(AvailableProduct instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'name': instance.name,
      'price': instance.price,
      'quantity': instance.quantity,
      'imageUrl': instance.imageUrl,
    };

Parcel _$ParcelFromJson(Map<String, dynamic> json) => Parcel(
  id: json['id'] as String?,
  weight: (json['weight'] as num?)?.toDouble(),
  dimensions: json['dimensions'] == null
      ? null
      : ParcelDimensions.fromJson(json['dimensions'] as Map<String, dynamic>),
  assets: (json['assets'] as List<dynamic>?)
      ?.map((e) => ParcelAsset.fromJson(e as Map<String, dynamic>))
      .toList(),
  quantity: (json['quantity'] as num?)?.toInt(),
  valueOfParcel: (json['valueOfParcel'] as num?)?.toDouble(),
  mongoId: json['_id'] as String?,
  createdAt: json['createdAt'] as String?,
  updatedAt: json['updatedAt'] as String?,
  category: json['category'] == null
      ? null
      : ParcelCategory.fromJson(json['category'] as Map<String, dynamic>),
  subCategory: json['subCategory'] == null
      ? null
      : ParcelCategory.fromJson(json['subCategory'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ParcelToJson(Parcel instance) => <String, dynamic>{
  'id': instance.id,
  'weight': instance.weight,
  'dimensions': instance.dimensions,
  'assets': instance.assets,
  'quantity': instance.quantity,
  'valueOfParcel': instance.valueOfParcel,
  '_id': instance.mongoId,
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
  'category': instance.category,
  'subCategory': instance.subCategory,
};

ParcelAsset _$ParcelAssetFromJson(Map<String, dynamic> json) => ParcelAsset(
  id: json['_id'] as String?,
  url: json['url'] as String?,
  type: json['type'] as String?,
);

Map<String, dynamic> _$ParcelAssetToJson(ParcelAsset instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'url': instance.url,
      'type': instance.type,
    };

ParcelDimensions _$ParcelDimensionsFromJson(Map<String, dynamic> json) =>
    ParcelDimensions(
      width: (json['width'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      length: (json['length'] as num?)?.toDouble(),
      unit: json['unit'] as String?,
    );

Map<String, dynamic> _$ParcelDimensionsToJson(ParcelDimensions instance) =>
    <String, dynamic>{
      'width': instance.width,
      'height': instance.height,
      'length': instance.length,
      'unit': instance.unit,
    };

ParcelCategory _$ParcelCategoryFromJson(Map<String, dynamic> json) =>
    ParcelCategory(id: json['id'] as String?, name: json['name'] as String?);

Map<String, dynamic> _$ParcelCategoryToJson(ParcelCategory instance) =>
    <String, dynamic>{'id': instance.id, 'name': instance.name};

Courier _$CourierFromJson(Map<String, dynamic> json) => Courier(
  maxWeight: (json['maxWeight'] as num?)?.toDouble(),
  merchantIds: (json['merchantIds'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  merchantDetails: (json['merchantDetails'] as List<dynamic>?)
      ?.map((e) => MerchantDetail.fromJson(e as Map<String, dynamic>))
      .toList(),
  estimatedDeliveryTime: (json['estimatedDeliveryTime'] as num?)?.toInt(),
  deliveryOption: json['deliveryOption'] as String?,
  currentMerchantId: json['currentMerchantId'] as String?,
);

Map<String, dynamic> _$CourierToJson(Courier instance) => <String, dynamic>{
  'maxWeight': instance.maxWeight,
  'merchantIds': instance.merchantIds,
  'merchantDetails': instance.merchantDetails,
  'estimatedDeliveryTime': instance.estimatedDeliveryTime,
  'deliveryOption': instance.deliveryOption,
  'currentMerchantId': instance.currentMerchantId,
};

MerchantDetail _$MerchantDetailFromJson(Map<String, dynamic> json) =>
    MerchantDetail(id: json['id'] as String?, name: json['name'] as String?);

Map<String, dynamic> _$MerchantDetailToJson(MerchantDetail instance) =>
    <String, dynamic>{'id': instance.id, 'name': instance.name};

DriverDetail _$DriverDetailFromJson(Map<String, dynamic> json) => DriverDetail(
  id: json['id'] as String?,
  driverType: (json['driverType'] as num?)?.toInt(),
  uniqueId: json['uniqueId'] as String?,
  name: json['name'] as String?,
  phone: json['phone'] as String?,
  email: json['email'] as String?,
  imageUrl: json['imageUrl'] as String?,
  rate: (json['rate'] as num?)?.toInt(),
  isFavourite: json['isFavourite'] as bool?,
  vehicleDetail: json['vehicleDetail'] == null
      ? null
      : DriverVehicleDetail.fromJson(
          json['vehicleDetail'] as Map<String, dynamic>,
        ),
  location: json['location'] == null
      ? null
      : DriverGeoLocation.fromJson(json['location'] as Map<String, dynamic>),
  deviceInfo: json['deviceInfo'] == null
      ? null
      : DriverDeviceInfo.fromJson(json['deviceInfo'] as Map<String, dynamic>),
  pickupAddressIndex: (json['pickupAddressIndex'] as num?)?.toInt(),
  destinationAddressIndex: (json['destinationAddressIndex'] as num?)?.toInt(),
  createdAt: json['createdAt'] as String?,
  updatedAt: json['updatedAt'] as String?,
);

Map<String, dynamic> _$DriverDetailToJson(DriverDetail instance) =>
    <String, dynamic>{
      'id': instance.id,
      'driverType': instance.driverType,
      'uniqueId': instance.uniqueId,
      'name': instance.name,
      'phone': instance.phone,
      'email': instance.email,
      'imageUrl': instance.imageUrl,
      'rate': instance.rate,
      'isFavourite': instance.isFavourite,
      'vehicleDetail': instance.vehicleDetail,
      'location': instance.location,
      'deviceInfo': instance.deviceInfo,
      'pickupAddressIndex': instance.pickupAddressIndex,
      'destinationAddressIndex': instance.destinationAddressIndex,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };

DriverDeviceInfo _$DriverDeviceInfoFromJson(Map<String, dynamic> json) =>
    DriverDeviceInfo(
      deviceId: json['deviceId'] as String?,
      type: (json['type'] as num?)?.toInt(),
      typeIds: (json['typeIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      manufacturer: json['manufacturer'] as String?,
      deviceName: json['deviceName'] as String?,
      deviceType: json['deviceType'] as String?,
      os: json['os'] as String?,
      appVersion: json['appVersion'] as String?,
      preferedLanguage: json['preferedLanguage'] as String?,
      mongoId: json['_id'] as String?,
    );

Map<String, dynamic> _$DriverDeviceInfoToJson(DriverDeviceInfo instance) =>
    <String, dynamic>{
      'deviceId': instance.deviceId,
      'type': instance.type,
      'typeIds': instance.typeIds,
      'manufacturer': instance.manufacturer,
      'deviceName': instance.deviceName,
      'deviceType': instance.deviceType,
      'os': instance.os,
      'appVersion': instance.appVersion,
      'preferedLanguage': instance.preferedLanguage,
      '_id': instance.mongoId,
    };

ModifierPrice _$ModifierPriceFromJson(Map<String, dynamic> json) =>
    ModifierPrice(
      id: json['id'] as String?,
      name: json['name'] as String?,
      isAllowAddQuantity: json['isAllowAddQuantity'] as bool?,
      maxQtyAddInCart: (json['maxQtyAddInCart'] as num?)?.toDouble(),
      driverProfit: (json['driverProfit'] as num?)?.toDouble(),
      driverProfitType: (json['driverProfitType'] as num?)?.toInt(),
      options: (json['options'] as List<dynamic>?)
          ?.map((e) => ModifierOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      price: (json['price'] as num?)?.toDouble(),
      discountedPrice: (json['discountedPrice'] as num?)?.toDouble(),
      driverProfitPercentage: (json['driverProfitPercentage'] as num?)
          ?.toDouble(),
    );

Map<String, dynamic> _$ModifierPriceToJson(ModifierPrice instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'isAllowAddQuantity': instance.isAllowAddQuantity,
      'maxQtyAddInCart': instance.maxQtyAddInCart,
      'driverProfit': instance.driverProfit,
      'driverProfitType': instance.driverProfitType,
      'options': instance.options,
      'price': instance.price,
      'discountedPrice': instance.discountedPrice,
      'driverProfitPercentage': instance.driverProfitPercentage,
    };

ModifierOption _$ModifierOptionFromJson(Map<String, dynamic> json) =>
    ModifierOption(
      id: json['id'] as String?,
      name: json['name'] as String?,
      image: json['image'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      qty: (json['qty'] as num?)?.toInt(),
      driverProfit: (json['driverProfit'] as num?)?.toDouble(),
      driverProfitType: (json['driverProfitType'] as num?)?.toInt(),
      discountedPrice: (json['discountedPrice'] as num?)?.toDouble(),
      driverProfitPercentage: (json['driverProfitPercentage'] as num?)
          ?.toDouble(),
    );

Map<String, dynamic> _$ModifierOptionToJson(ModifierOption instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'image': instance.image,
      'price': instance.price,
      'qty': instance.qty,
      'driverProfit': instance.driverProfit,
      'driverProfitType': instance.driverProfitType,
      'discountedPrice': instance.discountedPrice,
      'driverProfitPercentage': instance.driverProfitPercentage,
    };

StatusTimeLine _$StatusTimeLineFromJson(Map<String, dynamic> json) =>
    StatusTimeLine(
      status: (json['status'] as num?)?.toInt(),
      time: (json['time'] as num?)?.toInt(),
      note: json['note'] as String?,
      isMainStatus: json['isMainStatus'] as bool?,
      createdAt: json['createdAt'] as String?,
      findDriverVehicleTypeIds:
          json['findDriverVehicleTypeIds'] as List<dynamic>?,
      id: json['_id'] as String?,
      name: json['name'] as String?,
      rejectedDriverIds: json['rejectedDriverIds'] as List<dynamic>?,
      type: (json['type'] as num?)?.toInt(),
      typeId: json['typeId'] as String?,
      updatedAt: json['updatedAt'] as String?,
      waitingTime: (json['waitingTime'] as num?)?.toInt(),
    );

Map<String, dynamic> _$StatusTimeLineToJson(StatusTimeLine instance) =>
    <String, dynamic>{
      'status': instance.status,
      'time': instance.time,
      'note': instance.note,
      'isMainStatus': instance.isMainStatus,
      'createdAt': instance.createdAt,
      'findDriverVehicleTypeIds': instance.findDriverVehicleTypeIds,
      '_id': instance.id,
      'name': instance.name,
      'rejectedDriverIds': instance.rejectedDriverIds,
      'type': instance.type,
      'typeId': instance.typeId,
      'updatedAt': instance.updatedAt,
      'waitingTime': instance.waitingTime,
    };

UpdateAddressResponse _$UpdateAddressResponseFromJson(
  Map<String, dynamic> json,
) => UpdateAddressResponse(
  directionPath: json['directionPath'] as String?,
  estimatedDistance: (json['estimatedDistance'] as num?)?.toInt(),
  estimatedTime: (json['estimatedTime'] as num?)?.toInt(),
);

Map<String, dynamic> _$UpdateAddressResponseToJson(
  UpdateAddressResponse instance,
) => <String, dynamic>{
  'directionPath': instance.directionPath,
  'estimatedDistance': instance.estimatedDistance,
  'estimatedTime': instance.estimatedTime,
};
