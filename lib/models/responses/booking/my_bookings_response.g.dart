// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'my_bookings_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MyBookingsResponse _$MyBookingsResponseFromJson(Map<String, dynamic> json) =>
    MyBookingsResponse(
      bookings: (json['bookings'] as List<dynamic>?)
          ?.map((e) => MyBooking.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$MyBookingsResponseToJson(MyBookingsResponse instance) =>
    <String, dynamic>{'bookings': instance.bookings};

MyBooking _$MyBookingFromJson(Map<String, dynamic> json) => MyBooking(
  id: json['_id'] as String?,
  uniqueId: MyBooking._toStringOrNull(json['uniqueId']),
  status: (json['status'] as num?)?.toInt(),
  bookingTime: (json['bookingTime'] as num?)?.toInt(),
  bookingType: (json['bookingType'] as num?)?.toInt(),
  businessType: (json['businessType'] as num?)?.toInt(),
  timezone: json['timezone'] as String?,
  speakingLanguage: json['speakingLanguage'] as String?,
  bookingTags: (json['bookingTags'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  pickupAddress: json['pickupAddress'] == null
      ? null
      : DestinationAddress.fromJson(
          json['pickupAddress'] as Map<String, dynamic>,
        ),
  destinationAddresses: (json['destinationAddresses'] as List<dynamic>?)
      ?.map((e) => DestinationAddress.fromJson(e as Map<String, dynamic>))
      .toList(),
  confirmedDriver: json['confirmedDriver'] == null
      ? null
      : ConfirmedDriver.fromJson(
          json['confirmedDriver'] as Map<String, dynamic>,
        ),
  vehicleType: json['vehicleType'] == null
      ? null
      : BookingVehicleType.fromJson(
          json['vehicleType'] as Map<String, dynamic>,
        ),
  bookingInvoice: json['bookingInvoice'] == null
      ? null
      : BookingInvoice.fromJson(json['bookingInvoice'] as Map<String, dynamic>),
  biddingDetail: json['biddingDetail'] == null
      ? null
      : BiddingDetail.fromJson(json['biddingDetail'] as Map<String, dynamic>),
  isAllowCall: json['isAllowCall'] as bool?,
  citySetting: json['citySetting'] == null
      ? null
      : BookingCitySetting.fromJson(
          json['citySetting'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$MyBookingToJson(MyBooking instance) => <String, dynamic>{
  '_id': instance.id,
  'uniqueId': instance.uniqueId,
  'status': instance.status,
  'bookingTime': instance.bookingTime,
  'bookingType': instance.bookingType,
  'businessType': instance.businessType,
  'timezone': instance.timezone,
  'speakingLanguage': instance.speakingLanguage,
  'bookingTags': instance.bookingTags,
  'pickupAddress': instance.pickupAddress,
  'destinationAddresses': instance.destinationAddresses,
  'confirmedDriver': instance.confirmedDriver,
  'vehicleType': instance.vehicleType,
  'bookingInvoice': instance.bookingInvoice,
  'biddingDetail': instance.biddingDetail,
  'isAllowCall': instance.isAllowCall,
  'citySetting': instance.citySetting,
};
