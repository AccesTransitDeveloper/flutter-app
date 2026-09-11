import 'package:json_annotation/json_annotation.dart';

import '../../requests/get_vehicle_types_request.dart';
import 'booking_detail_response.dart';

part 'my_bookings_response.g.dart';

@JsonSerializable()
class MyBookingsResponse {
  final List<MyBooking>? bookings;

  MyBookingsResponse({this.bookings});

  factory MyBookingsResponse.fromJson(Map<String, dynamic> json) =>
      _$MyBookingsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MyBookingsResponseToJson(this);
}

@JsonSerializable()
class MyBooking {
  @JsonKey(name: '_id')
  final String? id;
  @JsonKey(fromJson: _toStringOrNull)
  final String? uniqueId;

  static String? _toStringOrNull(dynamic value) => value?.toString();
  final int? status;
  final int? bookingTime;
  final int? bookingType;
  final int? businessType;
  final String? timezone;
  final String? speakingLanguage;
  final List<String>? bookingTags;
  final DestinationAddress? pickupAddress;
  final List<DestinationAddress>? destinationAddresses;
  final ConfirmedDriver? confirmedDriver;
  final BookingVehicleType? vehicleType;
  final BookingInvoice? bookingInvoice;
  final BiddingDetail? biddingDetail;
  final bool? isAllowCall;
  final BookingCitySetting? citySetting;

  // Formatted display fields (set during transform, not from API)
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? priceStr;
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? dateTimeStr;
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? timeStr;

  MyBooking({
    this.id,
    this.uniqueId,
    this.status,
    this.bookingTime,
    this.bookingType,
    this.businessType,
    this.timezone,
    this.speakingLanguage,
    this.bookingTags,
    this.pickupAddress,
    this.destinationAddresses,
    this.confirmedDriver,
    this.vehicleType,
    this.bookingInvoice,
    this.biddingDetail,
    this.isAllowCall,
    this.citySetting,
    this.priceStr,
    this.dateTimeStr,
    this.timeStr,
  });

  MyBooking copyWith({
    String? id,
    String? uniqueId,
    int? status,
    int? bookingTime,
    int? bookingType,
    int? businessType,
    String? timezone,
    String? speakingLanguage,
    List<String>? bookingTags,
    DestinationAddress? pickupAddress,
    List<DestinationAddress>? destinationAddresses,
    ConfirmedDriver? confirmedDriver,
    BookingVehicleType? vehicleType,
    BookingInvoice? bookingInvoice,
    BiddingDetail? biddingDetail,
    bool? isAllowCall,
    BookingCitySetting? citySetting,
    String? priceStr,
    String? dateTimeStr,
    String? timeStr,
  }) {
    return MyBooking(
      id: id ?? this.id,
      uniqueId: uniqueId ?? this.uniqueId,
      status: status ?? this.status,
      bookingTime: bookingTime ?? this.bookingTime,
      bookingType: bookingType ?? this.bookingType,
      businessType: businessType ?? this.businessType,
      timezone: timezone ?? this.timezone,
      speakingLanguage: speakingLanguage ?? this.speakingLanguage,
      bookingTags: bookingTags ?? this.bookingTags,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      destinationAddresses: destinationAddresses ?? this.destinationAddresses,
      confirmedDriver: confirmedDriver ?? this.confirmedDriver,
      vehicleType: vehicleType ?? this.vehicleType,
      bookingInvoice: bookingInvoice ?? this.bookingInvoice,
      biddingDetail: biddingDetail ?? this.biddingDetail,
      isAllowCall: isAllowCall ?? this.isAllowCall,
      citySetting: citySetting ?? this.citySetting,
      priceStr: priceStr ?? this.priceStr,
      dateTimeStr: dateTimeStr ?? this.dateTimeStr,
      timeStr: timeStr ?? this.timeStr,
    );
  }

  factory MyBooking.fromJson(Map<String, dynamic> json) =>
      _$MyBookingFromJson(json);

  Map<String, dynamic> toJson() => _$MyBookingToJson(this);
}
