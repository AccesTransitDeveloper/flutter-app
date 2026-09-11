// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_history_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookingHistoryResponse _$BookingHistoryResponseFromJson(
  Map<String, dynamic> json,
) => BookingHistoryResponse(
  bookings: (json['bookings'] as List<dynamic>?)
      ?.map((e) => Bookings.fromJson(e as Map<String, dynamic>))
      .toList(),
  dataCount: (json['dataCount'] as num?)?.toInt(),
);

Map<String, dynamic> _$BookingHistoryResponseToJson(
  BookingHistoryResponse instance,
) => <String, dynamic>{
  'bookings': instance.bookings,
  'dataCount': instance.dataCount,
};

Bookings _$BookingsFromJson(Map<String, dynamic> json) => Bookings(
  id: json['_id'] as String?,
  uniqueId: json['uniqueId'] as String?,
  status: (json['status'] as num?)?.toInt(),
  countryId: json['countryId'] as String?,
  vehicleTypeId: json['vehicleTypeId'] as String?,
  bookingTime: (json['bookingTime'] as num?)?.toInt(),
  completedAt: (json['completedAt'] as num?)?.toInt(),
  timezone: json['timezone'] as String?,
  currencySign: json['currencySign'] as String?,
  total: (json['total'] as num?)?.toDouble(),
  setCurrencySign: (json['setCurrencySign'] as num?)?.toInt(),
  decimalPointValue: (json['decimalPointValue'] as num?)?.toInt(),
  vehicleType: json['vehicleType'] == null
      ? null
      : HistoryVehicleType.fromJson(
          json['vehicleType'] as Map<String, dynamic>,
        ),
  bookingPrice: json['bookingPrice'] as String?,
  completedTimeValue: json['completedTimeValue'] as String?,
  deliverIn: json['deliverIn'] as String?,
  businessType: (json['businessType'] as num?)?.toInt(),
  bookingType: (json['bookingType'] as num?)?.toInt(),
  confirmedDriver: json['confirmedDriver'] == null
      ? null
      : ConfirmedDriver.fromJson(
          json['confirmedDriver'] as Map<String, dynamic>,
        ),
  isBookForOther: json['isBookForOther'] as bool?,
);

Map<String, dynamic> _$BookingsToJson(Bookings instance) => <String, dynamic>{
  '_id': instance.id,
  'uniqueId': instance.uniqueId,
  'status': instance.status,
  'countryId': instance.countryId,
  'vehicleTypeId': instance.vehicleTypeId,
  'bookingTime': instance.bookingTime,
  'completedAt': instance.completedAt,
  'timezone': instance.timezone,
  'currencySign': instance.currencySign,
  'total': instance.total,
  'setCurrencySign': instance.setCurrencySign,
  'decimalPointValue': instance.decimalPointValue,
  'vehicleType': instance.vehicleType,
  'bookingPrice': instance.bookingPrice,
  'completedTimeValue': instance.completedTimeValue,
  'deliverIn': instance.deliverIn,
  'businessType': instance.businessType,
  'bookingType': instance.bookingType,
  'confirmedDriver': instance.confirmedDriver,
  'isBookForOther': instance.isBookForOther,
};

HistoryVehicleType _$HistoryVehicleTypeFromJson(Map<String, dynamic> json) =>
    HistoryVehicleType(
      id: json['_id'] as String?,
      name: json['name'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );

Map<String, dynamic> _$HistoryVehicleTypeToJson(HistoryVehicleType instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'name': instance.name,
      'imageUrl': instance.imageUrl,
    };
