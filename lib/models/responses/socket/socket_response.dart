import 'package:json_annotation/json_annotation.dart';

part 'socket_response.g.dart';

double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

@JsonSerializable()
class BookingStatusData {
  final String? bookingId;
  final CurrentRouteEstimation? currentRouteEstimation;
  final String? driverId;
  final int? status;
  final bool? isNoDriverFound;

  BookingStatusData({
    this.bookingId,
    this.currentRouteEstimation,
    this.driverId,
    this.status,
    this.isNoDriverFound,
  });

  factory BookingStatusData.fromJson(Map<String, dynamic> json) =>
      _$BookingStatusDataFromJson(json);

  Map<String, dynamic> toJson() => _$BookingStatusDataToJson(this);
}

@JsonSerializable()
class DriverLiveLocationResponse {
  final List<Distance?>? distanceList;
  final List<Location?>? locations;

  DriverLiveLocationResponse({
    this.distanceList,
    this.locations,
  });

  factory DriverLiveLocationResponse.fromJson(Map<String, dynamic> json) =>
      _$DriverLiveLocationResponseFromJson(json);

  Map<String, dynamic> toJson() => _$DriverLiveLocationResponseToJson(this);
}

@JsonSerializable()
class Distance {
  final String? bookingId;
  @JsonKey(fromJson: _parseDouble)
  final double distance;
  @JsonKey(fromJson: _parseInt)
  final int trafficTime;

  Distance({
    this.bookingId,
    this.distance = 0.0,
    this.trafficTime = 0,
  });

  factory Distance.fromJson(Map<String, dynamic> json) =>
      _$DistanceFromJson(json);

  Map<String, dynamic> toJson() => _$DistanceToJson(this);

  @override
  String toString() =>
      'Distance(bookingId: $bookingId, distance: $distance, trafficTime: $trafficTime)';
}

@JsonSerializable()
class Location {
  final double? bearing;
  final double? latitude;
  final double? longitude;
  final double? speed;
  @JsonKey(defaultValue: 0)
  final int time;

  Location({
    this.bearing,
    this.latitude,
    this.longitude,
    this.speed,
    this.time = 0,
  });

  factory Location.fromJson(Map<String, dynamic> json) =>
      _$LocationFromJson(json);

  Map<String, dynamic> toJson() => _$LocationToJson(this);
}

@JsonSerializable()
class CurrentRouteEstimation {
  final String? directionPath;
  final int? distance;
  final int? time;

  CurrentRouteEstimation({
    this.directionPath,
    this.distance,
    this.time,
  });

  factory CurrentRouteEstimation.fromJson(Map<String, dynamic> json) =>
      _$CurrentRouteEstimationFromJson(json);

  Map<String, dynamic> toJson() => _$CurrentRouteEstimationToJson(this);
}

@JsonSerializable()
class PaymentStatusResponse {
  final String? bookingId;
  final int? paymentStatus;

  PaymentStatusResponse({
    this.bookingId,
    this.paymentStatus,
  });

  factory PaymentStatusResponse.fromJson(Map<String, dynamic> json) =>
      _$PaymentStatusResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentStatusResponseToJson(this);
}
