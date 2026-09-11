// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_booking_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateBookingRequest _$CreateBookingRequestFromJson(
  Map<String, dynamic> json,
) => CreateBookingRequest(
  bookingTime: (json['bookingTime'] as num?)?.toInt(),
  bookingType: (json['bookingType'] as num?)?.toInt(),
  businessType: (json['businessType'] as num?)?.toInt(),
  isBookForOther: json['isBookForOther'] as bool?,
  customerDetail: json['customerDetail'] == null
      ? null
      : CustomerDetail.fromJson(json['customerDetail'] as Map<String, dynamic>),
  destinationAddresses: (json['destinationAddresses'] as List<dynamic>?)
      ?.map((e) => DestinationAddress.fromJson(e as Map<String, dynamic>))
      .toList(),
  isBidding: json['isBidding'] as bool?,
  isFixFare: json['isFixFare'] as bool?,
  paymentMode: (json['paymentMode'] as num?)?.toInt(),
  cardId: json['cardId'] as String?,
  pickupAddress: json['pickupAddress'] == null
      ? null
      : DestinationAddress.fromJson(
          json['pickupAddress'] as Map<String, dynamic>,
        ),
  vehiclePriceId: json['vehiclePriceId'] as String?,
  bidPrice: (json['bidPrice'] as num?)?.toDouble(),
  accessibilityIds: (json['accessibilityIds'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  promoCodeId: json['promoCodeId'] as String?,
  speakingLanguages: (json['speakingLanguages'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  customerNote: json['customerNote'] as String?,
  corporateId: json['corporateId'] as String?,
  returnTime: json['returnTime'] as String?,
  fixedGroupRidePriceType: json['fixedGroupRidePriceType'] as String?,
  preferredGender: json['preferredGender'] as String?,
  estimatedTime: (json['estimatedTime'] as num?)?.toInt() ?? 0,
  estimatedDistance: (json['estimatedDistance'] as num?)?.toInt() ?? 0,
  directionPath: json['directionPath'] as String? ?? '',
  isApplePay: json['isApplePay'] as bool? ?? false,
);

Map<String, dynamic> _$CreateBookingRequestToJson(
  CreateBookingRequest instance,
) => <String, dynamic>{
  'bookingTime': ?instance.bookingTime,
  'bookingType': ?instance.bookingType,
  'businessType': ?instance.businessType,
  'isBookForOther': ?instance.isBookForOther,
  'customerDetail': ?instance.customerDetail,
  'destinationAddresses': ?instance.destinationAddresses,
  'isBidding': ?instance.isBidding,
  'isFixFare': ?instance.isFixFare,
  'paymentMode': ?instance.paymentMode,
  'cardId': ?instance.cardId,
  'pickupAddress': ?instance.pickupAddress,
  'vehiclePriceId': ?instance.vehiclePriceId,
  'bidPrice': ?instance.bidPrice,
  'accessibilityIds': ?instance.accessibilityIds,
  'promoCodeId': ?instance.promoCodeId,
  'speakingLanguages': ?instance.speakingLanguages,
  'customerNote': ?instance.customerNote,
  'corporateId': ?instance.corporateId,
  'returnTime': ?instance.returnTime,
  'fixedGroupRidePriceType': ?instance.fixedGroupRidePriceType,
  'preferredGender': ?instance.preferredGender,
  'estimatedTime': instance.estimatedTime,
  'estimatedDistance': instance.estimatedDistance,
  'directionPath': instance.directionPath,
  'isApplePay': instance.isApplePay,
};

CustomerDetail _$CustomerDetailFromJson(Map<String, dynamic> json) =>
    CustomerDetail(
      email: json['email'] as String?,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      phone: json['phone'] as String?,
      countryPhoneCode: json['countryPhoneCode'] as String?,
    );

Map<String, dynamic> _$CustomerDetailToJson(CustomerDetail instance) =>
    <String, dynamic>{
      'email': ?instance.email,
      'firstName': ?instance.firstName,
      'lastName': ?instance.lastName,
      'phone': ?instance.phone,
      'countryPhoneCode': ?instance.countryPhoneCode,
    };
