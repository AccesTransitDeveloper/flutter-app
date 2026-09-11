import 'package:json_annotation/json_annotation.dart';

import '../../requests/get_vehicle_types_request.dart';
import 'promo_code_response.dart';
export 'promo_code_response.dart' show PromoDetail;

part 'booking_detail_response.g.dart';

@JsonSerializable()
class BookingDetailResponse {
  final BookingDetails? booking;
  final int? cancelUptoStatus;
  final bool? isAllowCancelBooking;
  final bool? isAllowCall;
  final BookingCitySetting? citySetting;
  final ServiceSetting? serviceSetting;
  final String? videoCallUrl;
  final LiveActivity? liveActivity;

  BookingDetailResponse({
    this.booking,
    this.cancelUptoStatus,
    this.isAllowCancelBooking,
    this.isAllowCall,
    this.citySetting,
    this.serviceSetting,
    this.videoCallUrl,
    this.liveActivity,
  });

  factory BookingDetailResponse.fromJson(Map<String, dynamic> json) =>
      _$BookingDetailResponseFromJson(json);

  Map<String, dynamic> toJson() => _$BookingDetailResponseToJson(this);
}

@JsonSerializable()
class LiveActivity {
  final int? progress;
  final List<int>? pickupPoint;
  final int? destinationPoint;

  LiveActivity({
    this.progress,
    this.pickupPoint,
    this.destinationPoint,
  });

  factory LiveActivity.fromJson(Map<String, dynamic> json) =>
      _$LiveActivityFromJson(json);

  Map<String, dynamic> toJson() => _$LiveActivityToJson(this);
}

@JsonSerializable()
class BookingCitySetting {
  final List<String>? bookingSetting;
  @JsonKey(name: 'businessSettings')
  final List<String?>? businessSetting;
  final CustomerBookingSetting? customerBookingSetting;
  @JsonKey(name: '_id')
  final String? id;
  final List<double>? tipPrices;
  final BookingPaymentSetting? paymentSetting;

  BookingCitySetting({
    this.bookingSetting,
    this.businessSetting,
    this.customerBookingSetting,
    this.id,
    this.tipPrices,
    this.paymentSetting,
  });

  factory BookingCitySetting.fromJson(Map<String, dynamic> json) =>
      _$BookingCitySettingFromJson(json);

  Map<String, dynamic> toJson() => _$BookingCitySettingToJson(this);
}

@JsonSerializable()
class ServiceSetting {
  final String? id;

  ServiceSetting({this.id});

  factory ServiceSetting.fromJson(Map<String, dynamic> json) =>
      _$ServiceSettingFromJson(json);

  Map<String, dynamic> toJson() => _$ServiceSettingToJson(this);
}

@JsonSerializable()
class BookingDetails {
  final List<dynamic>? actualDestinationAddresses;
  final BiddingDetail? biddingDetail;
  final String? countryId;
  final String? corporateId;
  final BookingInvoice? bookingInvoice;
  final List<String>? bookingTags;
  final int? bookingTime;
  final int? bookingType;
  final int? businessType;
  final String? cancellationReason;
  final String? cityId;
  final ConfirmedDriver? confirmedDriver;
  final CreatedDeviceInfo? createdDeviceInfo;
  final List<DestinationAddress>? destinationAddresses;
  @JsonKey(name: '_id')
  final String? id;
  final DestinationAddress? pickupAddress;
  final String? speakingLanguage;
  final int? status;
  final int? nextStatus;
  final int? completedAt;
  final String? timezone;
  @JsonKey(fromJson: _toStringOrNull)
  final String? uniqueId;
  final String? vehiclePriceId;
  final BookingVehicleType? vehicleType;
  final RentalPackageDetail? packageDetail;
  final String? vehicleTypeId;
  final bool? isShowOtp;
  final String? otp;
  final BookingRating? rating;
  final int? setCurrencySign;
  final int? decimalPointValue;
  final String? priceStr;
  final String? distanceStr;
  final String? dateTimeStr;
  final String? estimatedTimeStr;
  final bool? isDriveDetailVisible;
  final bool? isUserRated;
  final String? bookingTimeStr;
  final QuickCommerce? quickCommerce;
  final BookingCartData? cart;
  final OtherCustomerDetails? customerDetail;
  final bool? isBookForOther;
  final String? deliverIn;
  final CustomerVehicleDetail? customerVehicleDetail;
  @JsonKey(name: 'citySetting')
  final BookingCitySetting? historyCitySetting;
  final bool? isPaymentRequired;
  final List<Parcel>? parcels;
  final Courier? courier;
  final Courier? service;
  final List<StatusTimeLine>? statusTimeline;

  BookingDetails({
    this.actualDestinationAddresses,
    this.biddingDetail,
    this.countryId,
    this.corporateId,
    this.bookingInvoice,
    this.bookingTags,
    this.bookingTime,
    this.bookingType,
    this.businessType,
    this.cancellationReason,
    this.cityId,
    this.confirmedDriver,
    this.createdDeviceInfo,
    this.destinationAddresses,
    this.id,
    this.pickupAddress,
    this.speakingLanguage,
    this.status,
    this.nextStatus,
    this.completedAt,
    this.timezone,
    this.uniqueId,
    this.vehiclePriceId,
    this.vehicleType,
    this.packageDetail,
    this.vehicleTypeId,
    this.isShowOtp,
    this.otp,
    this.rating,
    this.setCurrencySign,
    this.decimalPointValue,
    this.priceStr,
    this.distanceStr,
    this.dateTimeStr,
    this.estimatedTimeStr,
    this.isDriveDetailVisible,
    this.isUserRated,
    this.bookingTimeStr,
    this.quickCommerce,
    this.cart,
    this.customerDetail,
    this.isBookForOther,
    this.deliverIn,
    this.customerVehicleDetail,
    this.historyCitySetting,
    this.isPaymentRequired,
    this.parcels,
    this.courier,
    this.service,
    this.statusTimeline,
  });

  static String? _toStringOrNull(dynamic value) => value?.toString();

  factory BookingDetails.fromJson(Map<String, dynamic> json) =>
      _$BookingDetailsFromJson(json);

  Map<String, dynamic> toJson() => _$BookingDetailsToJson(this);
}

@JsonSerializable()
class OtherCustomerDetails {
  final String? email;
  final String? id;
  final String? imageUrl;
  final String? name;
  final String? phone;
  final double? rate;
  final int? uniqueId;

  OtherCustomerDetails({
    this.email,
    this.id,
    this.imageUrl,
    this.name,
    this.phone,
    this.rate,
    this.uniqueId,
  });

  factory OtherCustomerDetails.fromJson(Map<String, dynamic> json) =>
      _$OtherCustomerDetailsFromJson(json);

  Map<String, dynamic> toJson() => _$OtherCustomerDetailsToJson(this);
}

@JsonSerializable()
class BookingRating {
  final double? customerRate;
  final String? customerReview;
  final int? driverRate;
  final String? driverReview;
  final double? customerMerchantRate;

  BookingRating({
    this.customerRate,
    this.customerReview,
    this.driverRate,
    this.driverReview,
    this.customerMerchantRate,
  });

  factory BookingRating.fromJson(Map<String, dynamic> json) =>
      _$BookingRatingFromJson(json);

  Map<String, dynamic> toJson() => _$BookingRatingToJson(this);
}

@JsonSerializable()
class BiddingDetail {
  final List<Bid>? bids;
  final double? customerBidPrice;
  final int? customerBidRejectTime;
  final double? finalBidPrice;
  final int? remainingTime;
  final String? createdAt;
  final bool? isBidding;
  final int? price;
  final String? updatedAt;

  BiddingDetail({
    this.bids,
    this.customerBidPrice,
    this.customerBidRejectTime,
    this.finalBidPrice,
    this.remainingTime,
    this.createdAt,
    this.isBidding,
    this.price,
    this.updatedAt,
  });

  factory BiddingDetail.fromJson(Map<String, dynamic> json) =>
      _$BiddingDetailFromJson(json);

  Map<String, dynamic> toJson() => _$BiddingDetailToJson(this);
}

@JsonSerializable()
class Bid {
  final String? email;
  final String? id;
  @JsonKey(name: '_id')
  final String? mongoId;
  final String? imageUrl;
  final bool? isFavourite;
  final String? name;
  final String? phone;
  final double? price;
  final double? rate;
  final int? status;
  final int? uniqueId;

  Bid({
    this.email,
    this.id,
    this.mongoId,
    this.imageUrl,
    this.isFavourite,
    this.name,
    this.phone,
    this.price,
    this.rate,
    this.status,
    this.uniqueId,
  });

  factory Bid.fromJson(Map<String, dynamic> json) => _$BidFromJson(json);

  Map<String, dynamic> toJson() => _$BidToJson(this);
}

@JsonSerializable()
class BookingInvoice {
  @JsonKey(name: '_id')
  final String? id;
  final int? distanceUnit;
  final String? currencySign;
  final int? decimalPointValue;
  final InvoiceDetail? estimated;
  final InvoiceDetail? actual;
  final int? paymentMode;
  final int? paymentStatus;
  final bool? isCapturePaymentPending;
  final int? setCurrencySign;
  final PromoDetail? promoDetail;
  final PaymentDetail? paymentDetail;
  final bool? isAdvancePaymentLimit;
  final double? advancePaymentLimit;

  BookingInvoice({
    this.id,
    this.distanceUnit,
    this.currencySign,
    this.decimalPointValue,
    this.estimated,
    this.actual,
    this.paymentMode,
    this.paymentStatus,
    this.isCapturePaymentPending,
    this.setCurrencySign,
    this.promoDetail,
    this.paymentDetail,
    this.isAdvancePaymentLimit,
    this.advancePaymentLimit,
  });

  factory BookingInvoice.fromJson(Map<String, dynamic> json) =>
      _$BookingInvoiceFromJson(json);

  Map<String, dynamic> toJson() => _$BookingInvoiceToJson(this);
}

@JsonSerializable()
class PaymentDetail {
  final double? remaining;

  PaymentDetail({this.remaining});

  factory PaymentDetail.fromJson(Map<String, dynamic> json) =>
      _$PaymentDetailFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentDetailToJson(this);
}

@JsonSerializable()
class InvoiceDetail {
  final double? distance;
  final int? time;
  final double? waitingTime;
  final double? stopWaitingTime;
  final double? trafficTime;
  final String? directionPath;
  final bool? isMinFareApplied;
  final List<PriceData>? charges;
  final List<PriceData>? additionalPrices;
  final List<PriceData>? accessibilityPrices;
  final List<PriceData>? taxPrices;
  final bool? isOutsideBoundary;
  final int? priceType;
  final double? total;
  final double? driverProfit;
  final int? bookingFee;
  @JsonKey(name: 'boookingType')
  final int? bookingType;
  final int? distancePrice;
  final int? distanceUnit;
  final List<AppliedOffer>? appliedOffer;
  @JsonKey(name: 'modifierPrices')
  final List<ModifierPrice>? modifierPrice;
  final String? orderReceiveDate;

  InvoiceDetail({
    this.distance,
    this.time,
    this.waitingTime,
    this.stopWaitingTime,
    this.trafficTime,
    this.directionPath,
    this.isMinFareApplied,
    this.charges,
    this.additionalPrices,
    this.accessibilityPrices,
    this.taxPrices,
    this.isOutsideBoundary,
    this.priceType,
    this.total,
    this.driverProfit,
    this.bookingFee,
    this.bookingType,
    this.distancePrice,
    this.distanceUnit,
    this.appliedOffer,
    this.modifierPrice,
    this.orderReceiveDate,
  });

  factory InvoiceDetail.fromJson(Map<String, dynamic> json) =>
      _$InvoiceDetailFromJson(json);

  Map<String, dynamic> toJson() => _$InvoiceDetailToJson(this);
}

@JsonSerializable()
class PriceData {
  final bool? isActive;
  final String? title;
  final String? chargeId;
  final int? type;
  final double? price;
  final double? discountedPrice;
  final int? priceType;
  final double? driverProfit;
  final int? driverProfitType;
  final List<String>? applyOn;
  final List<AppliedSlot>? appliedSlots;
  final List<AppliedSlot>? slots;
  final double? basePrice;
  final double? basePriceUnit;
  final double? unitPrice;
  final double? driverProfitPercentage;
  final double? unit;
  final bool? isApplySlotPrice;
  final bool? isSlotInPriceWithUnitCalculation;
  final bool? isSlotInPriceWithSum;
  final bool? isMinFareApplied;
  final bool? isApplyTax;
  final List<PriceData>? childs;

  PriceData({
    this.isActive,
    this.title,
    this.chargeId,
    this.type,
    this.price,
    this.discountedPrice,
    this.priceType,
    this.driverProfit,
    this.driverProfitType,
    this.applyOn,
    this.appliedSlots,
    this.slots,
    this.basePrice,
    this.basePriceUnit,
    this.unitPrice,
    this.driverProfitPercentage,
    this.unit,
    this.isApplySlotPrice,
    this.isSlotInPriceWithUnitCalculation,
    this.isSlotInPriceWithSum,
    this.isMinFareApplied,
    this.isApplyTax,
    this.childs,
  });

  factory PriceData.fromJson(Map<String, dynamic> json) =>
      _$PriceDataFromJson(json);

  Map<String, dynamic> toJson() => _$PriceDataToJson(this);
}

@JsonSerializable()
class AppliedSlot {
  final double? min;
  final double? max;
  final double? price;
  final double? unitPrice;
  final double? unit;
  final double? driverProfit;

  AppliedSlot({
    this.min,
    this.max,
    this.price,
    this.unitPrice,
    this.unit,
    this.driverProfit,
  });

  factory AppliedSlot.fromJson(Map<String, dynamic> json) =>
      _$AppliedSlotFromJson(json);

  Map<String, dynamic> toJson() => _$AppliedSlotToJson(this);
}

@JsonSerializable()
class AppliedOffer {
  final String? id;
  final String? name;
  final double? discount;

  AppliedOffer({
    this.id,
    this.name,
    this.discount,
  });

  factory AppliedOffer.fromJson(Map<String, dynamic> json) =>
      _$AppliedOfferFromJson(json);

  Map<String, dynamic> toJson() => _$AppliedOfferToJson(this);
}

@JsonSerializable()
class ConfirmedDriver {
  final String? id;
  final String? imageUrl;
  final bool? isFavourite;
  final DriverGeoLocation? location;
  final String? name;
  final String? phone;
  final double? rate;
  final DriverVehicleDetail? vehicleDetail;
  final bool? isDriverHasOtherBookings;

  ConfirmedDriver({
    this.id,
    this.imageUrl,
    this.isFavourite,
    this.location,
    this.name,
    this.phone,
    this.rate,
    this.vehicleDetail,
    this.isDriverHasOtherBookings,
  });

  factory ConfirmedDriver.fromJson(Map<String, dynamic> json) =>
      _$ConfirmedDriverFromJson(json);

  Map<String, dynamic> toJson() => _$ConfirmedDriverToJson(this);
}

@JsonSerializable()
class DriverGeoLocation {
  final List<double>? coordinates;
  final String? type;

  DriverGeoLocation({
    this.coordinates,
    this.type,
  });

  factory DriverGeoLocation.fromJson(Map<String, dynamic> json) =>
      _$DriverGeoLocationFromJson(json);

  Map<String, dynamic> toJson() => _$DriverGeoLocationToJson(this);
}

@JsonSerializable()
class CreatedDeviceInfo {
  final int? type;

  CreatedDeviceInfo({this.type});

  factory CreatedDeviceInfo.fromJson(Map<String, dynamic> json) =>
      _$CreatedDeviceInfoFromJson(json);

  Map<String, dynamic> toJson() => _$CreatedDeviceInfoToJson(this);
}

@JsonSerializable()
class BookingVehicleType {
  @JsonKey(name: '_id')
  final String? id;
  final String? name;
  final String? imageUrl;
  final String? mapPinUrl;

  BookingVehicleType({
    this.id,
    this.name,
    this.imageUrl,
    this.mapPinUrl,
  });

  factory BookingVehicleType.fromJson(Map<String, dynamic> json) =>
      _$BookingVehicleTypeFromJson(json);

  Map<String, dynamic> toJson() => _$BookingVehicleTypeToJson(this);
}

@JsonSerializable()
class RentalPackageDetail {
  @JsonKey(name: '_id')
  final String? id;
  final String? packageName;
  final PriceData? distancePrice;
  final PriceData? timePrice;

  RentalPackageDetail({
    this.id,
    this.packageName,
    this.distancePrice,
    this.timePrice,
  });

  factory RentalPackageDetail.fromJson(Map<String, dynamic> json) =>
      _$RentalPackageDetailFromJson(json);

  Map<String, dynamic> toJson() => _$RentalPackageDetailToJson(this);
}

@JsonSerializable()
class DriverVehicleDetail {
  final String? id;
  final int? type;
  final int? vehicleType;
  final String? name;
  final String? brandId;
  final String? brand;
  final String? modelId;
  final String? model;
  final String? color;
  final String? year;
  final String? plateNo;
  final String? vehicleLicense;

  DriverVehicleDetail({
    this.id,
    this.type,
    this.vehicleType,
    this.name,
    this.brandId,
    this.brand,
    this.modelId,
    this.model,
    this.color,
    this.year,
    this.plateNo,
    this.vehicleLicense,
  });

  factory DriverVehicleDetail.fromJson(Map<String, dynamic> json) =>
      _$DriverVehicleDetailFromJson(json);

  Map<String, dynamic> toJson() => _$DriverVehicleDetailToJson(this);
}

@JsonSerializable()
class CustomerVehicleDetail {
  final String? id;
  final int? type;
  final int? vehicleType;
  final String? name;
  final String? brandId;
  final String? brand;
  final String? modelId;
  final String? model;
  final String? color;
  final String? year;
  final String? plateNo;
  final String? vehicleLicense;

  CustomerVehicleDetail({
    this.id,
    this.type,
    this.vehicleType,
    this.name,
    this.brandId,
    this.brand,
    this.modelId,
    this.model,
    this.color,
    this.year,
    this.plateNo,
    this.vehicleLicense,
  });

  factory CustomerVehicleDetail.fromJson(Map<String, dynamic> json) =>
      _$CustomerVehicleDetailFromJson(json);

  Map<String, dynamic> toJson() => _$CustomerVehicleDetailToJson(this);
}

@JsonSerializable()
class BookingPaymentSetting {
  final bool? isCash;
  final bool? isWallet;
  final List<int>? paymentGateways;
  final List<int>? captureRequiredPaymentGateways;
  final List<int>? advancePaymentPaymentGateways;
  final bool? isWalletAdvancePayment;
  final bool? isPartialPayment;

  BookingPaymentSetting({
    this.isCash,
    this.isWallet,
    this.paymentGateways,
    this.captureRequiredPaymentGateways,
    this.advancePaymentPaymentGateways,
    this.isWalletAdvancePayment,
    this.isPartialPayment,
  });

  factory BookingPaymentSetting.fromJson(Map<String, dynamic> json) =>
      _$BookingPaymentSettingFromJson(json);

  Map<String, dynamic> toJson() => _$BookingPaymentSettingToJson(this);

  BookingPaymentSetting copyWith({
    bool? isCash,
    bool? isWallet,
    List<int>? paymentGateways,
    List<int>? captureRequiredPaymentGateways,
    List<int>? advancePaymentPaymentGateways,
    bool? isWalletAdvancePayment,
    bool? isPartialPayment,
  }) {
    return BookingPaymentSetting(
      isCash: isCash ?? this.isCash,
      isWallet: isWallet ?? this.isWallet,
      paymentGateways: paymentGateways ?? this.paymentGateways,
      captureRequiredPaymentGateways:
          captureRequiredPaymentGateways ?? this.captureRequiredPaymentGateways,
      advancePaymentPaymentGateways:
          advancePaymentPaymentGateways ?? this.advancePaymentPaymentGateways,
      isWalletAdvancePayment:
          isWalletAdvancePayment ?? this.isWalletAdvancePayment,
      isPartialPayment: isPartialPayment ?? this.isPartialPayment,
    );
  }
}

@JsonSerializable()
class CustomerBookingSetting {
  @JsonKey(name: 'ACCEPTED')
  final List<String>? accepted;
  @JsonKey(name: 'ARRIVED_AT_DESTINATION')
  final List<String>? arrivedAtDestination;
  @JsonKey(name: 'ARRIVED_AT_PICKUP')
  final List<String>? arrivedAtPickup;
  @JsonKey(name: 'ARRIVED_AT_STOP')
  final List<String>? arrivedAtStop;
  @JsonKey(name: 'ASSIGNED')
  final List<String>? assigned;
  @JsonKey(name: 'IN_ROUTE')
  final List<String>? inRoute;
  @JsonKey(name: 'REQUESTED')
  final List<String>? requested;
  @JsonKey(name: 'STARTED')
  final List<String>? started;
  @JsonKey(name: 'PICKED')
  final List<String>? picked;
  @JsonKey(name: 'DROPPED')
  final List<String>? dropped;
  @JsonKey(name: 'ARRIVED_NEAR_DESTINATION')
  final List<String>? arrivedNearDestination;
  @JsonKey(name: 'MERCHANT_ACCEPTED')
  final List<String>? merchantAccepted;
  @JsonKey(name: 'MERCHANT_PREPARING')
  final List<String>? merchantPreparing;
  @JsonKey(name: 'MERCHANT_COMPLETED')
  final List<String>? merchantCompleted;
  @JsonKey(name: 'SERVICE_COMPLETED')
  final List<String>? serviceCompleted;
  final int? verificationCodeLength;

  CustomerBookingSetting({
    this.accepted,
    this.arrivedAtDestination,
    this.arrivedAtPickup,
    this.arrivedAtStop,
    this.assigned,
    this.inRoute,
    this.requested,
    this.started,
    this.picked,
    this.dropped,
    this.arrivedNearDestination,
    this.merchantAccepted,
    this.merchantPreparing,
    this.merchantCompleted,
    this.serviceCompleted,
    this.verificationCodeLength,
  });

  factory CustomerBookingSetting.fromJson(Map<String, dynamic> json) =>
      _$CustomerBookingSettingFromJson(json);

  Map<String, dynamic> toJson() => _$CustomerBookingSettingToJson(this);
}

@JsonSerializable()
class QuickCommerce {
  final String? id;

  QuickCommerce({this.id});

  factory QuickCommerce.fromJson(Map<String, dynamic> json) =>
      _$QuickCommerceFromJson(json);

  Map<String, dynamic> toJson() => _$QuickCommerceToJson(this);
}

@JsonSerializable()
class BookingCartData {
  @JsonKey(name: '_id')
  final String? id;
  final List<AvailableProduct>? products;

  BookingCartData({
    this.id,
    this.products,
  });

  factory BookingCartData.fromJson(Map<String, dynamic> json) =>
      _$BookingCartDataFromJson(json);

  Map<String, dynamic> toJson() => _$BookingCartDataToJson(this);
}

@JsonSerializable()
class AvailableProduct {
  @JsonKey(name: '_id')
  final String? id;
  final String? name;
  final double? price;
  final int? quantity;
  final String? imageUrl;

  AvailableProduct({
    this.id,
    this.name,
    this.price,
    this.quantity,
    this.imageUrl,
  });

  factory AvailableProduct.fromJson(Map<String, dynamic> json) =>
      _$AvailableProductFromJson(json);

  Map<String, dynamic> toJson() => _$AvailableProductToJson(this);
}

@JsonSerializable()
class Parcel {
  final String? id;
  final double? weight;
  final ParcelDimensions? dimensions;
  final List<ParcelAsset>? assets;
  final int? quantity;
  final double? valueOfParcel;
  @JsonKey(name: '_id')
  final String? mongoId;
  final String? createdAt;
  final String? updatedAt;
  final ParcelCategory? category;
  final ParcelCategory? subCategory;

  Parcel({
    this.id,
    this.weight,
    this.dimensions,
    this.assets,
    this.quantity,
    this.valueOfParcel,
    this.mongoId,
    this.createdAt,
    this.updatedAt,
    this.category,
    this.subCategory,
  });

  factory Parcel.fromJson(Map<String, dynamic> json) => _$ParcelFromJson(json);

  Map<String, dynamic> toJson() => _$ParcelToJson(this);
}

@JsonSerializable()
class ParcelAsset {
  @JsonKey(name: '_id')
  final String? id;
  final String? url;
  final String? type;

  ParcelAsset({
    this.id,
    this.url,
    this.type,
  });

  factory ParcelAsset.fromJson(Map<String, dynamic> json) =>
      _$ParcelAssetFromJson(json);

  Map<String, dynamic> toJson() => _$ParcelAssetToJson(this);
}

@JsonSerializable()
class ParcelDimensions {
  final double? width;
  final double? height;
  final double? length;
  final String? unit;

  ParcelDimensions({
    this.width,
    this.height,
    this.length,
    this.unit,
  });

  factory ParcelDimensions.fromJson(Map<String, dynamic> json) =>
      _$ParcelDimensionsFromJson(json);

  Map<String, dynamic> toJson() => _$ParcelDimensionsToJson(this);
}

@JsonSerializable()
class ParcelCategory {
  final String? id;
  final String? name;

  ParcelCategory({
    this.id,
    this.name,
  });

  factory ParcelCategory.fromJson(Map<String, dynamic> json) =>
      _$ParcelCategoryFromJson(json);

  Map<String, dynamic> toJson() => _$ParcelCategoryToJson(this);
}

@JsonSerializable()
class Courier {
  final double? maxWeight;
  final List<String>? merchantIds;
  final List<MerchantDetail>? merchantDetails;
  final int? estimatedDeliveryTime;
  final String? deliveryOption;
  final String? currentMerchantId;

  Courier({
    this.maxWeight,
    this.merchantIds,
    this.merchantDetails,
    this.estimatedDeliveryTime,
    this.deliveryOption,
    this.currentMerchantId,
  });

  factory Courier.fromJson(Map<String, dynamic> json) =>
      _$CourierFromJson(json);

  Map<String, dynamic> toJson() => _$CourierToJson(this);
}

@JsonSerializable()
class MerchantDetail {
  final String? id;
  final String? name;

  MerchantDetail({
    this.id,
    this.name,
  });

  factory MerchantDetail.fromJson(Map<String, dynamic> json) =>
      _$MerchantDetailFromJson(json);

  Map<String, dynamic> toJson() => _$MerchantDetailToJson(this);
}

@JsonSerializable()
class DriverDetail {
  final String? id;
  final int? driverType;
  final String? uniqueId;
  final String? name;
  final String? phone;
  final String? email;
  final String? imageUrl;
  final int? rate;
  final bool? isFavourite;
  final DriverVehicleDetail? vehicleDetail;
  final DriverGeoLocation? location;
  final DriverDeviceInfo? deviceInfo;
  final int? pickupAddressIndex;
  final int? destinationAddressIndex;
  final String? createdAt;
  final String? updatedAt;

  DriverDetail({
    this.id,
    this.driverType,
    this.uniqueId,
    this.name,
    this.phone,
    this.email,
    this.imageUrl,
    this.rate,
    this.isFavourite,
    this.vehicleDetail,
    this.location,
    this.deviceInfo,
    this.pickupAddressIndex,
    this.destinationAddressIndex,
    this.createdAt,
    this.updatedAt,
  });

  factory DriverDetail.fromJson(Map<String, dynamic> json) =>
      _$DriverDetailFromJson(json);

  Map<String, dynamic> toJson() => _$DriverDetailToJson(this);
}

@JsonSerializable()
class DriverDeviceInfo {
  final String? deviceId;
  final int? type;
  final List<String>? typeIds;
  final String? manufacturer;
  final String? deviceName;
  final String? deviceType;
  final String? os;
  final String? appVersion;
  final String? preferedLanguage;
  @JsonKey(name: '_id')
  final String? mongoId;

  DriverDeviceInfo({
    this.deviceId,
    this.type,
    this.typeIds,
    this.manufacturer,
    this.deviceName,
    this.deviceType,
    this.os,
    this.appVersion,
    this.preferedLanguage,
    this.mongoId,
  });

  factory DriverDeviceInfo.fromJson(Map<String, dynamic> json) =>
      _$DriverDeviceInfoFromJson(json);

  Map<String, dynamic> toJson() => _$DriverDeviceInfoToJson(this);
}

@JsonSerializable()
class ModifierPrice {
  final String? id;
  final String? name;
  final bool? isAllowAddQuantity;
  final double? maxQtyAddInCart;
  final double? driverProfit;
  final int? driverProfitType;
  final List<ModifierOption>? options;
  final double? price;
  final double? discountedPrice;
  final double? driverProfitPercentage;

  ModifierPrice({
    this.id,
    this.name,
    this.isAllowAddQuantity,
    this.maxQtyAddInCart,
    this.driverProfit,
    this.driverProfitType,
    this.options,
    this.price,
    this.discountedPrice,
    this.driverProfitPercentage,
  });

  factory ModifierPrice.fromJson(Map<String, dynamic> json) =>
      _$ModifierPriceFromJson(json);

  Map<String, dynamic> toJson() => _$ModifierPriceToJson(this);
}

@JsonSerializable()
class ModifierOption {
  final String? id;
  final String? name;
  final String? image;
  final double? price;
  final int? qty;
  final double? driverProfit;
  final int? driverProfitType;
  final double? discountedPrice;
  final double? driverProfitPercentage;

  ModifierOption({
    this.id,
    this.name,
    this.image,
    this.price,
    this.qty,
    this.driverProfit,
    this.driverProfitType,
    this.discountedPrice,
    this.driverProfitPercentage,
  });

  factory ModifierOption.fromJson(Map<String, dynamic> json) =>
      _$ModifierOptionFromJson(json);

  Map<String, dynamic> toJson() => _$ModifierOptionToJson(this);
}

@JsonSerializable()
class StatusTimeLine {
  final int? status;
  final int? time;
  final String? note;
  final bool? isMainStatus;
  final String? createdAt;
  final List<dynamic>? findDriverVehicleTypeIds;
  @JsonKey(name: '_id')
  final String? id;
  final String? name;
  final List<dynamic>? rejectedDriverIds;
  final int? type;
  final String? typeId;
  final String? updatedAt;
  final int? waitingTime;

  StatusTimeLine({
    this.status,
    this.time,
    this.note,
    this.isMainStatus,
    this.createdAt,
    this.findDriverVehicleTypeIds,
    this.id,
    this.name,
    this.rejectedDriverIds,
    this.type,
    this.typeId,
    this.updatedAt,
    this.waitingTime,
  });

  factory StatusTimeLine.fromJson(Map<String, dynamic> json) =>
      _$StatusTimeLineFromJson(json);

  Map<String, dynamic> toJson() => _$StatusTimeLineToJson(this);
}

@JsonSerializable()
class UpdateAddressResponse {
  final String? directionPath;
  final int? estimatedDistance;
  final int? estimatedTime;

  const UpdateAddressResponse({
    this.directionPath,
    this.estimatedDistance,
    this.estimatedTime,
  });

  factory UpdateAddressResponse.fromJson(Map<String, dynamic> json) =>
      _$UpdateAddressResponseFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateAddressResponseToJson(this);
}
