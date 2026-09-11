// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'socket_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookingStatusData _$BookingStatusDataFromJson(Map<String, dynamic> json) =>
    BookingStatusData(
      bookingId: json['bookingId'] as String?,
      currentRouteEstimation: json['currentRouteEstimation'] == null
          ? null
          : CurrentRouteEstimation.fromJson(
              json['currentRouteEstimation'] as Map<String, dynamic>,
            ),
      driverId: json['driverId'] as String?,
      status: (json['status'] as num?)?.toInt(),
      isNoDriverFound: json['isNoDriverFound'] as bool?,
    );

Map<String, dynamic> _$BookingStatusDataToJson(BookingStatusData instance) =>
    <String, dynamic>{
      'bookingId': instance.bookingId,
      'currentRouteEstimation': instance.currentRouteEstimation,
      'driverId': instance.driverId,
      'status': instance.status,
      'isNoDriverFound': instance.isNoDriverFound,
    };

DriverLiveLocationResponse _$DriverLiveLocationResponseFromJson(
  Map<String, dynamic> json,
) => DriverLiveLocationResponse(
  distanceList: (json['distanceList'] as List<dynamic>?)
      ?.map(
        (e) => e == null ? null : Distance.fromJson(e as Map<String, dynamic>),
      )
      .toList(),
  locations: (json['locations'] as List<dynamic>?)
      ?.map(
        (e) => e == null ? null : Location.fromJson(e as Map<String, dynamic>),
      )
      .toList(),
);

Map<String, dynamic> _$DriverLiveLocationResponseToJson(
  DriverLiveLocationResponse instance,
) => <String, dynamic>{
  'distanceList': instance.distanceList,
  'locations': instance.locations,
};

Distance _$DistanceFromJson(Map<String, dynamic> json) => Distance(
  bookingId: json['bookingId'] as String?,
  distance: json['distance'] == null ? 0.0 : _parseDouble(json['distance']),
  trafficTime: json['trafficTime'] == null ? 0 : _parseInt(json['trafficTime']),
);

Map<String, dynamic> _$DistanceToJson(Distance instance) => <String, dynamic>{
  'bookingId': instance.bookingId,
  'distance': instance.distance,
  'trafficTime': instance.trafficTime,
};

Location _$LocationFromJson(Map<String, dynamic> json) => Location(
  bearing: (json['bearing'] as num?)?.toDouble(),
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
  speed: (json['speed'] as num?)?.toDouble(),
  time: (json['time'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$LocationToJson(Location instance) => <String, dynamic>{
  'bearing': instance.bearing,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'speed': instance.speed,
  'time': instance.time,
};

CurrentRouteEstimation _$CurrentRouteEstimationFromJson(
  Map<String, dynamic> json,
) => CurrentRouteEstimation(
  directionPath: json['directionPath'] as String?,
  distance: (json['distance'] as num?)?.toInt(),
  time: (json['time'] as num?)?.toInt(),
);

Map<String, dynamic> _$CurrentRouteEstimationToJson(
  CurrentRouteEstimation instance,
) => <String, dynamic>{
  'directionPath': instance.directionPath,
  'distance': instance.distance,
  'time': instance.time,
};

PaymentStatusResponse _$PaymentStatusResponseFromJson(
  Map<String, dynamic> json,
) => PaymentStatusResponse(
  bookingId: json['bookingId'] as String?,
  paymentStatus: (json['paymentStatus'] as num?)?.toInt(),
);

Map<String, dynamic> _$PaymentStatusResponseToJson(
  PaymentStatusResponse instance,
) => <String, dynamic>{
  'bookingId': instance.bookingId,
  'paymentStatus': instance.paymentStatus,
};
