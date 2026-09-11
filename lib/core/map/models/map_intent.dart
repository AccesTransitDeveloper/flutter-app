import 'map_types.dart';

/// Sealed class for map intents/commands.
/// Used with Riverpod to dispatch commands to the map manager.
sealed class MapIntent {
  const MapIntent();
}

/// Move camera to target
class MoveCameraIntent extends MapIntent {
  final LatLng target;
  final double? zoom;
  final bool animate;

  const MoveCameraIntent({
    required this.target,
    this.zoom,
    this.animate = true,
  });
}

/// Animate camera to fit bounds
class AnimateToBoundsIntent extends MapIntent {
  final List<LatLng> points;
  final double padding;

  const AnimateToBoundsIntent({
    required this.points,
    this.padding = 50.0,
  });
}

/// Update all markers
class SetMarkersIntent extends MapIntent {
  final Set<MapMarker> markers;

  const SetMarkersIntent(this.markers);
}

/// Add a single marker
class AddMarkerIntent extends MapIntent {
  final MapMarker marker;

  const AddMarkerIntent(this.marker);
}

/// Remove a marker
class RemoveMarkerIntent extends MapIntent {
  final String markerId;

  const RemoveMarkerIntent(this.markerId);
}

/// Update all polylines
class SetPolylinesIntent extends MapIntent {
  final List<MapPolyline> polylines;

  const SetPolylinesIntent(this.polylines);
}

/// Add a single polyline
class AddPolylineIntent extends MapIntent {
  final MapPolyline polyline;

  const AddPolylineIntent(this.polyline);
}

/// Remove a polyline
class RemovePolylineIntent extends MapIntent {
  final String polylineId;

  const RemovePolylineIntent(this.polylineId);
}

/// Clear all markers and polylines
class ClearMapIntent extends MapIntent {
  const ClearMapIntent();
}
