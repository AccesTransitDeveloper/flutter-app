/// Request model for Google Routes Distance Matrix API
/// POST gmaps/routes/distanceMatrix/v2:computeRouteMatrix
class DistanceMatrixRequest {
  final List<DistanceMatrixWaypoint> origins;
  final List<DistanceMatrixWaypoint> destinations;

  DistanceMatrixRequest({
    required this.origins,
    required this.destinations,
  });

  Map<String, dynamic> toJson() => {
        'origins': origins.map((o) => o.toJson()).toList(),
        'destinations': destinations.map((d) => d.toJson()).toList(),
      };
}

class DistanceMatrixWaypoint {
  final double latitude;
  final double longitude;

  DistanceMatrixWaypoint({required this.latitude, required this.longitude});

  Map<String, dynamic> toJson() => {
        'waypoint': {
          'location': {
            'latLng': {
              'latitude': latitude,
              'longitude': longitude,
            }
          }
        }
      };
}
