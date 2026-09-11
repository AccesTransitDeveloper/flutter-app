/// Response element from Google Routes Distance Matrix API.
/// Each element corresponds to one destination (driver location).
/// duration is returned as "123s" — strip "s" and parse to int for seconds.
class RouteDistanceMatrix {
  final double? distanceMeters;
  final String? duration; // e.g. "123s"
  final int? destinationIndex;

  RouteDistanceMatrix({
    this.distanceMeters,
    this.duration,
    this.destinationIndex,
  });

  factory RouteDistanceMatrix.fromJson(Map<String, dynamic> json) {
    return RouteDistanceMatrix(
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble(),
      duration: json['duration'] as String?,
      destinationIndex: json['destinationIndex'] as int?,
    );
  }

  /// Parsed duration in seconds (strips "s" suffix from API string)
  int get durationSeconds {
    final raw = duration?.replaceAll('s', '') ?? '';
    return int.tryParse(raw) ?? 0;
  }
}
