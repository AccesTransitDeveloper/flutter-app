// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LocationResponse _$LocationResponseFromJson(Map<String, dynamic> json) =>
    LocationResponse(
      location: (json['locations'] as List<dynamic>?)
          ?.map(
            (e) => e == null
                ? null
                : TripLocation.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      distance: doubleFromJson(json['distance']),
      currentRouteEstimation: json['currentRouteEstimation'] == null
          ? null
          : CurrentRouteEstimation.fromJson(
              json['currentRouteEstimation'] as Map<String, dynamic>,
            ),
      trafficTime: intFromJson(json['trafficTime']),
    );

Map<String, dynamic> _$LocationResponseToJson(LocationResponse instance) =>
    <String, dynamic>{
      'locations': instance.location,
      'distance': instance.distance,
      'currentRouteEstimation': instance.currentRouteEstimation,
      'trafficTime': instance.trafficTime,
    };

TripLocation _$TripLocationFromJson(Map<String, dynamic> json) => TripLocation(
  latitude: doubleFromJson(json['latitude']),
  longitude: doubleFromJson(json['longitude']),
  time: intFromJson(json['time']),
  speed: doubleFromJson(json['speed']),
);

Map<String, dynamic> _$TripLocationToJson(TripLocation instance) =>
    <String, dynamic>{
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'time': instance.time,
      'speed': instance.speed,
    };

CurrentRouteEstimation _$CurrentRouteEstimationFromJson(
  Map<String, dynamic> json,
) => CurrentRouteEstimation(
  time: intFromJson(json['time']),
  distance: doubleFromJson(json['distance']),
);

Map<String, dynamic> _$CurrentRouteEstimationToJson(
  CurrentRouteEstimation instance,
) => <String, dynamic>{'time': instance.time, 'distance': instance.distance};
