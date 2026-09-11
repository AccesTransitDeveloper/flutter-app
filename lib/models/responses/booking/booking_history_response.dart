import 'package:json_annotation/json_annotation.dart';

import 'booking_detail_response.dart';

part 'booking_history_response.g.dart';

@JsonSerializable()
class BookingHistoryResponse {
  final List<Bookings>? bookings;
  final int? dataCount;

  BookingHistoryResponse({
    this.bookings,
    this.dataCount,
  });

  factory BookingHistoryResponse.fromJson(Map<String, dynamic> json) =>
      _$BookingHistoryResponseFromJson(json);

  Map<String, dynamic> toJson() => _$BookingHistoryResponseToJson(this);
}

@JsonSerializable()
class Bookings {
  @JsonKey(name: '_id')
  final String? id;
  final String? uniqueId;
  final int? status;
  final String? countryId;
  final String? vehicleTypeId;
  final int? bookingTime;
  final int? completedAt;
  final String? timezone;
  final String? currencySign;
  final double? total;
  final int? setCurrencySign;
  final int? decimalPointValue;
  final HistoryVehicleType? vehicleType;
  final String? bookingPrice;
  final String? completedTimeValue;
  final String? deliverIn;
  final int? businessType;
  final int? bookingType;
  final ConfirmedDriver? confirmedDriver;
  final bool? isBookForOther;

  Bookings({
    this.id,
    this.uniqueId,
    this.status,
    this.countryId,
    this.vehicleTypeId,
    this.bookingTime,
    this.completedAt,
    this.timezone,
    this.currencySign,
    this.total,
    this.setCurrencySign,
    this.decimalPointValue,
    this.vehicleType,
    this.bookingPrice,
    this.completedTimeValue,
    this.deliverIn,
    this.businessType,
    this.bookingType,
    this.confirmedDriver,
    this.isBookForOther,
  });

  Bookings copyWith({
    String? id,
    String? uniqueId,
    int? status,
    String? countryId,
    String? vehicleTypeId,
    int? bookingTime,
    int? completedAt,
    String? timezone,
    String? currencySign,
    double? total,
    int? setCurrencySign,
    int? decimalPointValue,
    HistoryVehicleType? vehicleType,
    String? bookingPrice,
    String? completedTimeValue,
    String? deliverIn,
    int? businessType,
    int? bookingType,
    ConfirmedDriver? confirmedDriver,
    bool? isBookForOther,
  }) {
    return Bookings(
      id: id ?? this.id,
      uniqueId: uniqueId ?? this.uniqueId,
      status: status ?? this.status,
      countryId: countryId ?? this.countryId,
      vehicleTypeId: vehicleTypeId ?? this.vehicleTypeId,
      bookingTime: bookingTime ?? this.bookingTime,
      completedAt: completedAt ?? this.completedAt,
      timezone: timezone ?? this.timezone,
      currencySign: currencySign ?? this.currencySign,
      total: total ?? this.total,
      setCurrencySign: setCurrencySign ?? this.setCurrencySign,
      decimalPointValue: decimalPointValue ?? this.decimalPointValue,
      vehicleType: vehicleType ?? this.vehicleType,
      bookingPrice: bookingPrice ?? this.bookingPrice,
      completedTimeValue: completedTimeValue ?? this.completedTimeValue,
      deliverIn: deliverIn ?? this.deliverIn,
      businessType: businessType ?? this.businessType,
      bookingType: bookingType ?? this.bookingType,
      confirmedDriver: confirmedDriver ?? this.confirmedDriver,
      isBookForOther: isBookForOther ?? this.isBookForOther,
    );
  }

  factory Bookings.fromJson(Map<String, dynamic> json) =>
      _$BookingsFromJson(json);

  Map<String, dynamic> toJson() => _$BookingsToJson(this);
}

@JsonSerializable()
class HistoryVehicleType {
  @JsonKey(name: '_id')
  final String? id;
  final String? name;
  final String? imageUrl;

  HistoryVehicleType({
    this.id,
    this.name,
    this.imageUrl,
  });

  factory HistoryVehicleType.fromJson(Map<String, dynamic> json) =>
      _$HistoryVehicleTypeFromJson(json);

  Map<String, dynamic> toJson() => _$HistoryVehicleTypeToJson(this);
}
