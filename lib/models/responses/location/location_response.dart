import 'package:json_annotation/json_annotation.dart';

part 'location_response.g.dart';

@JsonSerializable()
class LocationResponse {
  @JsonKey(name: 'locations')
  final List<TripLocation?>? location;
  @JsonKey(fromJson: doubleFromJson)
  final double? distance;
  final CurrentRouteEstimation? currentRouteEstimation;
  @JsonKey(fromJson: intFromJson)
  final int? trafficTime;

  LocationResponse({
    this.location,
    this.distance,
    this.currentRouteEstimation,
    this.trafficTime,
  });

  factory LocationResponse.fromJson(Map<String, dynamic> json) =>
      _$LocationResponseFromJson(json);

  Map<String, dynamic> toJson() => _$LocationResponseToJson(this);
}

@JsonSerializable()
class TripLocation {
  @JsonKey(fromJson: doubleFromJson)
  final double? latitude;
  @JsonKey(fromJson: doubleFromJson)
  final double? longitude;
  @JsonKey(fromJson: intFromJson)
  final int? time;
  @JsonKey(fromJson: doubleFromJson)
  final double? speed;

  TripLocation({
    this.latitude,
    this.longitude,
    this.time,
    this.speed,
  });

  factory TripLocation.fromJson(Map<String, dynamic> json) =>
      _$TripLocationFromJson(json);

  Map<String, dynamic> toJson() => _$TripLocationToJson(this);
}

@JsonSerializable()
class CurrentRouteEstimation {
  @JsonKey(fromJson: intFromJson)
  final int? time;
  @JsonKey(fromJson: doubleFromJson)
  final double? distance;

  CurrentRouteEstimation({
    this.time,
    this.distance,
  });

  factory CurrentRouteEstimation.fromJson(Map<String, dynamic> json) =>
      _$CurrentRouteEstimationFromJson(json);

  Map<String, dynamic> toJson() => _$CurrentRouteEstimationToJson(this);
}

/// The location endpoint is inconsistent about number types — the same field
/// comes back as a JSON number on some responses and a quoted string on others,
/// and json_serializable's plain `as num?` cast threw on the string form,
/// failing the whole response ("type 'String' is not a subtype of type 'num?'").
double? doubleFromJson(Object? value) => switch (value) {
      num() => value.toDouble(),
      String() => double.tryParse(value),
      _ => null,
    };

int? intFromJson(Object? value) => switch (value) {
      num() => value.toInt(),
      String() => int.tryParse(value) ?? double.tryParse(value)?.toInt(),
      _ => null,
    };
