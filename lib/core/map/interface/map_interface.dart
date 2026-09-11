import 'package:flutter/widgets.dart';

import '../../../models/requests/get_vehicle_types_request.dart';
import '../models/map_types.dart';

/// Callback for when camera stops moving
typedef OnCameraIdleCallback = void Function(LatLng center);

/// Abstract interface for map operations.
/// Each map provider (Google, Mapbox, Apple, OpenStreet) implements this.
///
/// The map widget is built ONCE and controlled via commands.
/// This prevents rebuilds that cause ANR.
abstract class MapInterface {
  /// Build the map widget - called ONCE by MapHost
  Widget build();

  /// Set callback for when camera stops moving (map idle)
  set onCameraIdle(OnCameraIdleCallback? callback);

  /// Get current map center coordinates
  Future<LatLng?> getCameraCenter();

  /// Animate camera to target position.
  ///
  /// [pitch] tilts the camera off vertical (0 = straight down, 60 = strongly
  /// tilted); a non-zero pitch is what makes the 3D building geometry visible.
  /// [bearing] rotates the map so that heading points up.
  /// [duration] is the animation length in milliseconds. Keep it at or below
  /// the interval between calls when following a moving target, otherwise each
  /// animation is cut short by the next one and the motion stutters.
  ///
  /// [ease] swaps the "fly" curve for a plain ease. The fly curve arcs the zoom
  /// out and back in — sensible for one long jump, but when it runs several
  /// times a second to follow a moving car that arc reads as a wobble.
  Future<void> animateCamera(
    LatLng target, {
    double? zoom,
    double? pitch,
    double? bearing,
    int duration = 500,
    bool ease = false,
  });

  /// Reverse geocode coordinates to get place details
  Future<DestinationAddress> getPlaceDetailWithCoordinates(
    double latitude,
    double longitude,
  );

  /// Search for places using autocomplete
  /// [countryCode] - ISO 3166-1 Alpha-2 code to restrict results (e.g. "US", "IN")
  /// [locationBias] - LatLng to bias results toward
  Future<List<DestinationAddress>> searchPlaces(
    String query, {
    String? countryCode,
    LatLng? locationBias,
  });

  /// Get full place details from a place ID
  Future<DestinationAddress?> getPlaceDetails(String placeId);

  /// Reset autocomplete session token (call after place selection)
  void resetAutocompleteSession();

  /// Check if map is ready
  bool get isReady;

  /// Set map controller from external widget
  void setController(dynamic controller);

  /// Handle camera idle event from external widget
  void handleCameraIdle();

  /// Set markers on the map
  void setMarkers(List<MapMarker> markers);

  /// Set polyline on the map (route polyline)
  void setPolyline(MapPolyline? polyline);

  /// Set driver's traveled path polyline (shown alongside route polyline)
  void setDriverPathPolyline(MapPolyline? polyline);

  /// Set map padding (to account for overlapping UI like bottom sheets)
  void setMapPadding(EdgeInsets padding);

  /// Fit camera to show all markers
  Future<void> fitBounds(List<LatLng> points, {double padding = 50});

  /// Show info window for a marker by its ID
  void showMarkerInfoWindow(String markerId);

  /// Set map style JSON string (Google Maps style format)
  void setMapStyle(String? styleJson);

  /// Apply map style from settings based on current brightness
  void applyMapStyleFromSettings(Brightness brightness);

  /// Detach the current map view from this manager without clearing map data.
  /// Use this when the hosting widget is disposed but the owning screen
  /// still intends to reuse the same manager later.
  void detachView();

  /// Add nearby driver markers on the map (shown on choose ride screen)
  Future<void> addNearbyDriverMarkers(List<MapMarker> markers);

  /// Remove all nearby driver markers from the map
  void removeNearbyDriverMarkers();

  /// Dispose resources
  void dispose();
}
