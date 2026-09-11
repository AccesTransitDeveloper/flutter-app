import 'package:json_annotation/json_annotation.dart';

import 'get_vehicle_types_request.dart';

part 'create_booking_request.g.dart';

@JsonSerializable(includeIfNull: false)
class CreateBookingRequest {
  final int? bookingTime;
  final int? bookingType;
  final int? businessType;
  final bool? isBookForOther;
  final CustomerDetail? customerDetail;
  final List<DestinationAddress>? destinationAddresses;
  final bool? isBidding;
  final bool? isFixFare;
  final int? paymentMode;
  final String? cardId;
  final DestinationAddress? pickupAddress;
  final String? vehiclePriceId;
  final double? bidPrice;
  final List<String>? accessibilityIds;
  final String? promoCodeId;
  final List<String>? speakingLanguages;
  final String? customerNote;
  final String? corporateId;
  final String? returnTime;
  final String? fixedGroupRidePriceType;
  final String? preferredGender;
  // Route/estimate data + Apple Pay flag — sent to match the native iOS app.
  final int estimatedTime;
  final int estimatedDistance;
  final String directionPath;
  final bool isApplePay;

  CreateBookingRequest({
    this.bookingTime,
    this.bookingType,
    this.businessType,
    this.isBookForOther,
    this.customerDetail,
    this.destinationAddresses,
    this.isBidding,
    this.isFixFare,
    this.paymentMode,
    this.cardId,
    this.pickupAddress,
    this.vehiclePriceId,
    this.bidPrice,
    this.accessibilityIds,
    this.promoCodeId,
    this.speakingLanguages,
    this.customerNote,
    this.corporateId,
    this.returnTime,
    this.fixedGroupRidePriceType,
    this.preferredGender,
    this.estimatedTime = 0,
    this.estimatedDistance = 0,
    this.directionPath = '',
    this.isApplePay = false,
  });

  CreateBookingRequest copyWith({
    int? bookingTime,
    int? bookingType,
    int? businessType,
    bool? isBookForOther,
    CustomerDetail? customerDetail,
    List<DestinationAddress>? destinationAddresses,
    bool? isBidding,
    bool? isFixFare,
    int? paymentMode,
    String? cardId,
    DestinationAddress? pickupAddress,
    String? vehiclePriceId,
    double? bidPrice,
    List<String>? accessibilityIds,
    String? promoCodeId,
    List<String>? speakingLanguages,
    String? customerNote,
    String? corporateId,
    String? returnTime,
    String? fixedGroupRidePriceType,
    String? preferredGender,
    int? estimatedTime,
    int? estimatedDistance,
    String? directionPath,
    bool? isApplePay,
  }) {
    return CreateBookingRequest(
      bookingTime: bookingTime ?? this.bookingTime,
      bookingType: bookingType ?? this.bookingType,
      businessType: businessType ?? this.businessType,
      isBookForOther: isBookForOther ?? this.isBookForOther,
      customerDetail: customerDetail ?? this.customerDetail,
      destinationAddresses: destinationAddresses ?? this.destinationAddresses,
      isBidding: isBidding ?? this.isBidding,
      isFixFare: isFixFare ?? this.isFixFare,
      paymentMode: paymentMode ?? this.paymentMode,
      cardId: cardId ?? this.cardId,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      vehiclePriceId: vehiclePriceId ?? this.vehiclePriceId,
      bidPrice: bidPrice ?? this.bidPrice,
      accessibilityIds: accessibilityIds ?? this.accessibilityIds,
      promoCodeId: promoCodeId ?? this.promoCodeId,
      speakingLanguages: speakingLanguages ?? this.speakingLanguages,
      customerNote: customerNote ?? this.customerNote,
      corporateId: corporateId ?? this.corporateId,
      returnTime: returnTime ?? this.returnTime,
      fixedGroupRidePriceType: fixedGroupRidePriceType ?? this.fixedGroupRidePriceType,
      preferredGender: preferredGender ?? this.preferredGender,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      estimatedDistance: estimatedDistance ?? this.estimatedDistance,
      directionPath: directionPath ?? this.directionPath,
      isApplePay: isApplePay ?? this.isApplePay,
    );
  }

  factory CreateBookingRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateBookingRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateBookingRequestToJson(this);
}

@JsonSerializable(includeIfNull: false)
class CustomerDetail {
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? countryPhoneCode;

  CustomerDetail({
    this.email,
    this.firstName,
    this.lastName,
    this.phone,
    this.countryPhoneCode,
  });

  factory CustomerDetail.fromJson(Map<String, dynamic> json) =>
      _$CustomerDetailFromJson(json);

  Map<String, dynamic> toJson() => _$CustomerDetailToJson(this);
}
