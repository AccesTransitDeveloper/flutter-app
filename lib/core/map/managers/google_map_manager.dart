import 'dart:ui' as ui;
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart' as places;
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:http/http.dart' as http;

import '../../../data/api/response_state.dart';
import '../../../data/repository/app_repository.dart';
import '../../../models/requests/get_vehicle_types_request.dart';
import '../../preferences/shared_preference_manager.dart';
import '../interface/map_interface.dart';
import '../models/map_types.dart';

/// Google Maps implementation of MapInterface.
class GoogleMapManager implements MapInterface {
  // ===========================================================================
  // MARK: - Dependencies
  // ===========================================================================

  final AppRepository _appRepository;
  final SharedPreferenceManager? _sharedPref;

  // ===========================================================================
  // MARK: - Map Controller & State
  // ===========================================================================

  gm.GoogleMapController? _controller;
  bool _buildCalled = false;
  void Function(void Function())? _setMapState;

  // ===========================================================================
  // MARK: - Camera State
  // ===========================================================================

  LatLng? _pendingCameraTarget;
  double? _pendingCameraZoom;
  double? _pendingCameraPitch;
  double? _pendingCameraBearing;
  List<LatLng>? _pendingBoundsPoints;
  double? _pendingBoundsPadding;
  OnCameraIdleCallback? _onCameraIdleCallback;

  // ===========================================================================
  // MARK: - Markers State
  // ===========================================================================

  Set<gm.Marker> _markers = {};
  Set<gm.Marker> _nearbyDriverMarkers = {};
  final Map<String, gm.BitmapDescriptor> _networkIconCache = {};

  // ===========================================================================
  // MARK: - Driver Animation State
  // ===========================================================================

  Timer? _driverAnimationTimer;
  LatLng? _previousDriverPosition;
  double _previousDriverBearing = 0;

  // ===========================================================================
  // MARK: - Polylines State
  // ===========================================================================

  Set<gm.Polyline> _polylines = {};
  gm.Polyline? _routePolyline;
  gm.Polyline? _driverPathPolyline;

  // ===========================================================================
  // MARK: - Map Padding State
  // ===========================================================================

  EdgeInsets _mapPadding = EdgeInsets.zero;
  String? _mapStyle;


  // ===========================================================================
  // MARK: - Places SDK State
  // ===========================================================================

  places.FlutterGooglePlacesSdk? _placesSdk;
  bool _startNewSession = true;

  // ===========================================================================
  // MARK: - Constructor
  // ===========================================================================

  GoogleMapManager({
    required AppRepository appRepository,
    SharedPreferenceManager? sharedPref,
  })  : _appRepository = appRepository,
        _sharedPref = sharedPref {
    _initPlacesSdk();
  }

  // ===========================================================================
  // MARK: - Public Getters
  // ===========================================================================

  Set<gm.Marker> get markers => _markers;
  Set<gm.Polyline> get polylines => _polylines;

  @override
  bool get isReady => _controller != null;

  @override
  set onCameraIdle(OnCameraIdleCallback? callback) {
    _onCameraIdleCallback = callback;
  }

  /// @deprecated Use build() directly - StatefulBuilder is now internal
  set onMapDataChanged(VoidCallback? callback) {
    // No-op - kept for backward compatibility during migration
  }

  // ===========================================================================
  // MARK: - Build & Lifecycle
  // ===========================================================================

  @override
  void setMapPadding(EdgeInsets padding) {
    _mapPadding = padding;
    _setMapState?.call(() {});
  }

  @override
  void showMarkerInfoWindow(String markerId) {
    _controller?.showMarkerInfoWindow(gm.MarkerId(markerId));
  }

  @override
  Widget build() {
    if (_buildCalled) {
      debugPrint('🗺️ GoogleMapManager.build() called AGAIN - THIS SHOULD NOT HAPPEN!');
    } else {
      debugPrint('🗺️ GoogleMapManager.build() called FIRST TIME');
      _buildCalled = true;
    }

    return StatefulBuilder(
      builder: (context, setMapState) {
        _setMapState = setMapState;
        return gm.GoogleMap(
          initialCameraPosition: const gm.CameraPosition(
            target: gm.LatLng(20.5937, 78.9629), // India center
            zoom: 5,
          ),
          markers: {..._markers, ..._nearbyDriverMarkers},
          polylines: _polylines,
          padding: _mapPadding,
          onMapCreated: _onMapCreated,
          onCameraIdle: _handleCameraIdle,
          style: _mapStyle,
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: false,
        );
      },
    );
  }

  @override
  void setMapStyle(String? styleJson) {
    _mapStyle = (styleJson != null && styleJson.isNotEmpty) ? styleJson : null;
    _notifyMapDataChanged();
  }

  @override
  void applyMapStyleFromSettings(Brightness brightness) {
    final setting = _sharedPref?.getSetting();
    final isDark = brightness == Brightness.dark;
    final style = isDark
        ? setting?.mapThemeSetting?.darkMode
        : setting?.mapThemeSetting?.lightMode;
    debugPrint('🗺️ applyMapStyleFromSettings: isDark=$isDark, hasStyle=${style != null}, styleLength=${style?.length ?? 0}');
    setMapStyle(style);
  }

  void _onMapCreated(gm.GoogleMapController controller) {
    debugPrint('🗺️ GoogleMapController created - MAP IS READY');
    _controller = controller;

    if (_pendingCameraTarget != null) {
      debugPrint('🗺️ Applying pending camera position: $_pendingCameraTarget zoom: $_pendingCameraZoom');
      _applyPendingCameraPosition();
    }

    if (_pendingBoundsPoints != null) {
      debugPrint('🗺️ Applying pending bounds: ${_pendingBoundsPoints!.length} points');
      _applyPendingBounds();
    }
  }

  void _notifyMapDataChanged() {
    _setMapState?.call(() {});
  }

  @override
  void setController(dynamic controller) {
    if (controller is gm.GoogleMapController) {
      _controller = controller;
      debugPrint('🗺️ GoogleMapManager.setController() - controller set');
    }
  }

  @override
  void handleCameraIdle() {
    _handleCameraIdle();
  }

  @override
  void detachView() {
    debugPrint('🗺️ GoogleMapManager.detachView()');
    _setMapState = null;
    _buildCalled = false;
    _controller?.dispose();
    _controller = null;
  }

  @override
  void dispose() {
    debugPrint('🗺️ GoogleMapManager.dispose()');
    detachView();
    _driverAnimationTimer?.cancel();
    _driverAnimationTimer = null;
    _onCameraIdleCallback = null;
  }

  // ===========================================================================
  // MARK: - Camera Operations
  // ===========================================================================

  @override
  Future<LatLng?> getCameraCenter() async {
    if (_controller == null) return null;
    try {
      final bounds = await _controller!.getVisibleRegion();
      final centerLat = (bounds.northeast.latitude + bounds.southwest.latitude) / 2;
      final centerLng = (bounds.northeast.longitude + bounds.southwest.longitude) / 2;
      return LatLng(centerLat, centerLng);
    } catch (e) {
      debugPrint('🗺️ getCameraCenter error (widget may be disposed): $e');
      return null;
    }
  }

  @override
  Future<void> animateCamera(
    LatLng target, {
    double? zoom,
    double? pitch,
    double? bearing,
    // Google's animateCamera has neither a duration nor a curve knob — both are
    // accepted for interface parity and ignored.
    int duration = 500,
    bool ease = false,
  }) async {
    _pendingCameraTarget = target;
    _pendingCameraZoom = zoom;
    _pendingCameraPitch = pitch;
    _pendingCameraBearing = bearing;
    _pendingBoundsPoints = null;
    _pendingBoundsPadding = null;

    if (_controller == null) {
      debugPrint('🗺️ animateCamera: controller is null, storing pending camera position');
      return;
    }

    try {
      final currentZoom = zoom ?? await _controller!.getZoomLevel();
      debugPrint('🗺️ animateCamera to $target zoom: $currentZoom');

      await _controller!.animateCamera(
        gm.CameraUpdate.newCameraPosition(
          gm.CameraPosition(
            target: gm.LatLng(target.latitude, target.longitude),
            zoom: currentZoom,
            // Google calls the pitch "tilt"; both default to flat/north-up when
            // the caller doesn't ask for a 3D camera.
            tilt: pitch ?? 0,
            bearing: bearing ?? 0,
          ),
        ),
      );
    } catch (e) {
      debugPrint('🗺️ animateCamera error (widget may be disposed): $e');
    }
  }

  @override
  Future<void> fitBounds(List<LatLng> points, {double padding = 50}) async {
    if (points.isEmpty) {
      debugPrint('🗺️ fitBounds: no points');
      return;
    }

    _pendingBoundsPoints = List<LatLng>.from(points);
    _pendingBoundsPadding = padding;
    _pendingCameraTarget = null;
    _pendingCameraZoom = null;

    if (_controller == null) {
      debugPrint('🗺️ fitBounds: controller is null, storing pending bounds');
      return;
    }

    if (points.length == 1) {
      await animateCamera(points.first, zoom: 16);
      return;
    }

    await _applyFitBounds(points, padding);
  }

  Future<void> _handleCameraIdle() async {
    if (_onCameraIdleCallback == null || _controller == null) return;

    try {
      final center = await getCameraCenter();
      if (center != null && _onCameraIdleCallback != null) {
        debugPrint('🗺️ Camera idle at: $center');
        _onCameraIdleCallback!(center);
      }
    } catch (e) {
      debugPrint('🗺️ Camera idle error (widget may be disposed): $e');
    }
  }

  Future<void> _applyPendingCameraPosition() async {
    if (_pendingCameraTarget == null || _controller == null) return;

    final target = _pendingCameraTarget!;
    final zoom = _pendingCameraZoom ?? 16;

    debugPrint('🗺️ Moving camera to pending position: $target zoom: $zoom');
    await _controller!.animateCamera(
      gm.CameraUpdate.newCameraPosition(
        gm.CameraPosition(
          target: gm.LatLng(target.latitude, target.longitude),
          zoom: zoom,
          tilt: _pendingCameraPitch ?? 0,
          bearing: _pendingCameraBearing ?? 0,
        ),
      ),
    );
  }

  Future<void> _applyPendingBounds() async {
    if (_pendingBoundsPoints == null || _controller == null) return;

    final points = _pendingBoundsPoints!;
    final padding = _pendingBoundsPadding ?? 50;

    await Future.delayed(const Duration(milliseconds: 300));
    await _applyFitBounds(points, padding);
  }

  Future<void> _applyFitBounds(List<LatLng> points, double padding) async {
    if (_controller == null || points.isEmpty) return;

    if (points.length == 1) {
      await animateCamera(points.first, zoom: 16);
      return;
    }

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    final bounds = gm.LatLngBounds(
      southwest: gm.LatLng(minLat, minLng),
      northeast: gm.LatLng(maxLat, maxLng),
    );

    debugPrint('🗺️ fitBounds: $bounds with padding $padding');
    try {
      await _controller!.animateCamera(
        gm.CameraUpdate.newLatLngBounds(bounds, padding),
      );
    } catch (e) {
      debugPrint('🗺️ fitBounds error: $e');
    }
  }

  // ===========================================================================
  // MARK: - Markers (Public)
  // ===========================================================================

  @override
  void setMarkers(List<MapMarker> markers) {
    debugPrint('🗺️ setMarkers: ${markers.length} markers');
    _loadMarkersWithIcons(markers);
  }

  @override
  Future<void> addNearbyDriverMarkers(List<MapMarker> markers) async {
    debugPrint('🗺️ addNearbyDriverMarkers: ${markers.length} drivers');
    final Set<gm.Marker> newMarkers = {};
    for (final m in markers) {
      final icon = await _loadMarkerIcon(m);
      newMarkers.add(gm.Marker(
        markerId: gm.MarkerId(m.id),
        position: gm.LatLng(m.position.latitude, m.position.longitude),
        icon: icon,
        anchor: const Offset(0.5, 0.5),
      ));
    }
    _nearbyDriverMarkers = newMarkers;
    _notifyMapDataChanged();
  }

  @override
  void removeNearbyDriverMarkers() {
    debugPrint('🗺️ removeNearbyDriverMarkers');
    _nearbyDriverMarkers = {};
    _notifyMapDataChanged();
  }

  Future<void> _loadMarkersWithIcons(List<MapMarker> markers) async {
    final Set<gm.Marker> newMarkers = {};

    for (final m in markers) {
      final icon = await _loadMarkerIcon(m);

      if (m.id == 'driver') {
        _addDriverMarker(m, icon, newMarkers);
      } else {
        _addRegularMarker(m, icon, newMarkers);
      }
    }

    _markers = newMarkers;
    _notifyMapDataChanged();
  }

  void _addRegularMarker(
    MapMarker marker,
    gm.BitmapDescriptor icon,
    Set<gm.Marker> markers,
  ) {
    markers.add(gm.Marker(
      markerId: gm.MarkerId(marker.id),
      position: gm.LatLng(marker.position.latitude, marker.position.longitude),
      icon: icon,
      infoWindow: gm.InfoWindow(
        title: marker.title,
        snippet: marker.snippet,
      ),
    ));
  }

  // ===========================================================================
  // MARK: - Driver Marker Animation
  // ===========================================================================

  void _addDriverMarker(
    MapMarker marker,
    gm.BitmapDescriptor icon,
    Set<gm.Marker> markers,
  ) {
    final newPosition = marker.position;
    final bearing = _calculateBearing(_previousDriverPosition, newPosition);

    if (_previousDriverPosition != null) {
      _animateDriverMarker(
        from: _previousDriverPosition!,
        to: newPosition,
        icon: icon,
        startBearing: _previousDriverBearing,
        endBearing: bearing,
        otherMarkers: markers,
      );
    } else {
      markers.add(_createDriverMarker(newPosition, icon, bearing));
      _animateCameraToDriver(newPosition, bearing);
    }

    _previousDriverPosition = newPosition;
    _previousDriverBearing = bearing;
  }

  gm.Marker _createDriverMarker(
    LatLng position,
    gm.BitmapDescriptor icon,
    double bearing,
  ) {
    return gm.Marker(
      markerId: const gm.MarkerId('driver'),
      position: gm.LatLng(position.latitude, position.longitude),
      icon: icon,
      rotation: bearing,
      anchor: const Offset(0.5, 0.5),
      flat: true,
    );
  }

  void _animateDriverMarker({
    required LatLng from,
    required LatLng to,
    required gm.BitmapDescriptor icon,
    required double startBearing,
    required double endBearing,
    required Set<gm.Marker> otherMarkers,
  }) {
    _driverAnimationTimer?.cancel();

    const animationDuration = Duration(milliseconds: 1300);
    const frameRate = Duration(milliseconds: 16);
    final totalFrames = animationDuration.inMilliseconds ~/ frameRate.inMilliseconds;

    int currentFrame = 0;

    _driverAnimationTimer = Timer.periodic(frameRate, (timer) {
      currentFrame++;
      final progress = (currentFrame / totalFrames).clamp(0.0, 1.0);

      if (progress >= 1.0) {
        timer.cancel();
        _updateDriverMarkerPosition(to, icon, endBearing, otherMarkers);
        _moveCameraToPosition(to, endBearing);
      } else {
        final lat = from.latitude + (to.latitude - from.latitude) * progress;
        final lng = from.longitude + (to.longitude - from.longitude) * progress;
        final bearing = _interpolateBearing(startBearing, endBearing, progress);

        final currentPos = LatLng(lat, lng);
        _updateDriverMarkerPosition(currentPos, icon, bearing, otherMarkers);
        _moveCameraToPosition(currentPos, bearing);
      }
    });
  }

  void _updateDriverMarkerPosition(
    LatLng position,
    gm.BitmapDescriptor icon,
    double bearing,
    Set<gm.Marker> otherMarkers,
  ) {
    final driverMarker = _createDriverMarker(position, icon, bearing);
    _markers = {...otherMarkers, driverMarker};
    _notifyMapDataChanged();
  }

  void _moveCameraToPosition(LatLng position, double bearing) {
    if (_controller == null) return;

    _controller!.moveCamera(
      gm.CameraUpdate.newCameraPosition(
        gm.CameraPosition(
          target: gm.LatLng(position.latitude, position.longitude),
          zoom: 16,
          bearing: bearing,
          tilt: 0,
        ),
      ),
    );
  }

  Future<void> _animateCameraToDriver(LatLng position, double bearing) async {
    if (_controller == null) return;

    try {
      await _controller!.animateCamera(
        gm.CameraUpdate.newCameraPosition(
          gm.CameraPosition(
            target: gm.LatLng(position.latitude, position.longitude),
            zoom: 16,
            bearing: bearing,
            tilt: 0,
          ),
        ),
      );
    } catch (e) {
      debugPrint('🗺️ animateCameraToDriver error: $e');
    }
  }

  double _calculateBearing(LatLng? from, LatLng to) {
    if (from == null) return 0;

    final lat1 = from.latitude * (math.pi / 180);
    final lat2 = to.latitude * (math.pi / 180);
    final dLon = (to.longitude - from.longitude) * (math.pi / 180);

    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) - math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    var bearing = math.atan2(y, x) * (180 / math.pi);
    bearing = (bearing + 360) % 360;

    return bearing;
  }

  double _interpolateBearing(double from, double to, double progress) {
    var diff = to - from;

    if (diff > 180) {
      diff -= 360;
    } else if (diff < -180) {
      diff += 360;
    }

    var result = from + diff * progress;
    return (result + 360) % 360;
  }

  // ===========================================================================
  // MARK: - Marker Icon Loading
  // ===========================================================================

  Future<gm.BitmapDescriptor> _loadMarkerIcon(MapMarker marker) async {
    try {
      if (marker.stopNumber != null && marker.iconColor != null) {
        return await _createNumberedMarkerIcon(
          marker.stopNumber!,
          Color(marker.iconColor!),
          marker.iconWidth ?? 32,
          marker.iconHeight ?? 32,
        );
      }

      if (marker.iconUrl != null && marker.iconUrl!.isNotEmpty) {
        final networkIcon = await _loadNetworkMarkerIcon(
          marker.iconUrl!,
          marker.iconWidth ?? 40,
          marker.iconHeight ?? 40,
        );
        if (networkIcon != null) {
          return networkIcon;
        }
        if (marker.iconAsset != null) {
          return await _loadAssetIcon(marker);
        }
      }

      if (marker.iconAsset != null) {
        return await _loadAssetIcon(marker);
      }
    } catch (e) {
      debugPrint('🗺️ Failed to load marker icon: ${marker.iconAsset ?? marker.iconUrl}, error: $e');
    }

    return gm.BitmapDescriptor.defaultMarker;
  }

  Future<gm.BitmapDescriptor> _loadAssetIcon(MapMarker marker) async {
    if (marker.iconColor != null) {
      return await _loadTintedMarkerIcon(
        marker.iconAsset!,
        Color(marker.iconColor!),
        marker.iconWidth ?? 32,
        marker.iconHeight ?? 32,
      );
    }
    return await gm.BitmapDescriptor.asset(
      ImageConfiguration(
        size: Size(marker.iconWidth ?? 40, marker.iconHeight ?? 40),
      ),
      marker.iconAsset!,
    );
  }

  Future<gm.BitmapDescriptor?> _loadNetworkMarkerIcon(
    String url,
    double width,
    double height,
  ) async {
    final cacheKey = '$url-$width-$height';
    if (_networkIconCache.containsKey(cacheKey)) {
      return _networkIconCache[cacheKey]!;
    }

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final originalCodec = await ui.instantiateImageCodec(response.bodyBytes);
        final originalFrame = await originalCodec.getNextFrame();
        final originalImage = originalFrame.image;

        final originalWidth = originalImage.width.toDouble();
        final originalHeight = originalImage.height.toDouble();
        final aspectRatio = originalWidth / originalHeight;

        int targetWidth;
        int targetHeight;

        if (aspectRatio > 1) {
          targetWidth = width.toInt();
          targetHeight = (width / aspectRatio).toInt();
        } else {
          targetHeight = height.toInt();
          targetWidth = (height * aspectRatio).toInt();
        }

        final codec = await ui.instantiateImageCodec(
          response.bodyBytes,
          targetWidth: targetWidth,
          targetHeight: targetHeight,
        );
        final frame = await codec.getNextFrame();
        final image = frame.image;

        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        final bytes = byteData!.buffer.asUint8List();

        final icon = gm.BitmapDescriptor.bytes(bytes);
        _networkIconCache[cacheKey] = icon;
        return icon;
      }
    } catch (e) {
      debugPrint('🗺️ Failed to load network icon: $url, error: $e');
    }

    return null;
  }

  Future<gm.BitmapDescriptor> _createNumberedMarkerIcon(
    int number,
    Color color,
    double width,
    double height,
  ) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final paint = Paint()..color = color;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, width, height),
      const Radius.circular(4),
    );
    canvas.drawRRect(rect, paint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: number.toString(),
        style: TextStyle(
          color: Colors.white,
          fontSize: height * 0.6,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final textX = (width - textPainter.width) / 2;
    final textY = (height - textPainter.height) / 2;
    textPainter.paint(canvas, Offset(textX, textY));

    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), height.toInt());

    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    return gm.BitmapDescriptor.bytes(bytes);
  }

  Future<gm.BitmapDescriptor> _loadTintedMarkerIcon(
    String assetPath,
    Color tintColor,
    double width,
    double height,
  ) async {
    final data = await rootBundle.load(assetPath);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width.toInt(),
      targetHeight: height.toInt(),
    );
    final frame = await codec.getNextFrame();
    final image = frame.image;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final paint = Paint()
      ..colorFilter = ColorFilter.mode(tintColor, BlendMode.srcIn);

    canvas.drawImage(image, Offset.zero, paint);

    final picture = recorder.endRecording();
    final tintedImage = await picture.toImage(width.toInt(), height.toInt());

    final byteData = await tintedImage.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    return gm.BitmapDescriptor.bytes(bytes);
  }

  // ===========================================================================
  // MARK: - Polylines
  // ===========================================================================

  @override
  void setPolyline(MapPolyline? polyline) {
    if (polyline == null) {
      debugPrint('🗺️ setPolyline: clearing route polyline');
      _routePolyline = null;
    } else {
      debugPrint('🗺️ setPolyline: ${polyline.points.length} points');
      _routePolyline = _createGooglePolyline(polyline);
    }
    _updateCombinedPolylines();
  }

  @override
  void setDriverPathPolyline(MapPolyline? polyline) {
    if (polyline == null) {
      debugPrint('🗺️ setDriverPathPolyline: clearing driver path polyline');
      _driverPathPolyline = null;
    } else {
      debugPrint('🗺️ setDriverPathPolyline: ${polyline.points.length} points');
      _driverPathPolyline = _createGooglePolyline(polyline);
    }
    _updateCombinedPolylines();
  }

  gm.Polyline _createGooglePolyline(MapPolyline polyline) {
    return gm.Polyline(
      polylineId: gm.PolylineId(polyline.id),
      points: polyline.points
          .map((p) => gm.LatLng(p.latitude, p.longitude))
          .toList(),
      color: Color(polyline.color),
      width: polyline.width.toInt(),
    );
  }

  void _updateCombinedPolylines() {
    final Set<gm.Polyline> combined = {};
    if (_routePolyline != null) {
      combined.add(_routePolyline!);
    }
    if (_driverPathPolyline != null) {
      combined.add(_driverPathPolyline!);
    }
    _polylines = combined;
    _notifyMapDataChanged();
  }

  // ===========================================================================
  // MARK: - Places SDK
  // ===========================================================================

  void _initPlacesSdk() {
    final setting = _sharedPref?.getSetting();
    final apiKey = setting?.mapKey?.placesAutoCompleteApiKey;

    if (apiKey != null && apiKey.isNotEmpty) {
      _placesSdk = places.FlutterGooglePlacesSdk(apiKey);
      debugPrint('🗺️ Places SDK initialized');
    } else {
      debugPrint('🗺️ Places API key not found, SDK not initialized');
    }
  }

  @override
  void resetAutocompleteSession() {
    _startNewSession = true;
    debugPrint('🗺️ resetAutocompleteSession');
  }

  @override
  Future<List<DestinationAddress>> searchPlaces(
    String query, {
    String? countryCode,
    LatLng? locationBias,
  }) async {
    if (query.isEmpty) return [];

    debugPrint('🗺️ searchPlaces: $query, countryCode: $countryCode');

    if (_placesSdk == null) {
      debugPrint('🗺️ Places SDK not initialized');
      return [];
    }

    try {
      // Build location bias from provided coordinates
      places.LatLngBounds? bias;
      if (locationBias != null) {
        // Create a ~10km bias area around the point
        const offset = 0.05; // ~5km in degrees
        bias = places.LatLngBounds(
          southwest: places.LatLng(
            lat: locationBias.latitude - offset,
            lng: locationBias.longitude - offset,
          ),
          northeast: places.LatLng(
            lat: locationBias.latitude + offset,
            lng: locationBias.longitude + offset,
          ),
        );
      }

      final response = await _placesSdk!.findAutocompletePredictions(
        query,
        newSessionToken: _startNewSession,
        countries: countryCode != null ? [countryCode] : null,
        locationBias: bias,
      );

      _startNewSession = false;

      final predictions = response.predictions;
      if (predictions.isNotEmpty) {
        debugPrint('🗺️ searchPlaces found ${predictions.length} results');
        return predictions.map((p) => DestinationAddress(
          address: p.fullText,
          placeId: p.placeId,
          title: p.primaryText,
          city: p.secondaryText,
        )).toList();
      }
      return [];
    } catch (e) {
      debugPrint('🗺️ searchPlaces error: $e');
      return [];
    }
  }

  @override
  Future<DestinationAddress?> getPlaceDetails(String placeId) async {
    debugPrint('🗺️ getPlaceDetails: $placeId');

    if (_placesSdk == null) {
      debugPrint('🗺️ Places SDK not initialized');
      return null;
    }

    try {
      final response = await _placesSdk!.fetchPlace(
        placeId,
        fields: [
          places.PlaceField.Address,
          places.PlaceField.AddressComponents,
          places.PlaceField.Location,
          places.PlaceField.Name,
        ],
      );

      final result = response.place;
      if (result != null) {
        String? city;
        String? countryCode;
        String? country;
        String? postalCode;

        final addressComponents = result.addressComponents;
        if (addressComponents != null) {
          for (final component in addressComponents) {
            final types = component.types;
            if (types.contains('locality')) {
              city = component.name;
            } else if (types.contains('country')) {
              countryCode = component.shortName;
              country = component.name;
            } else if (types.contains('postal_code')) {
              postalCode = component.shortName;
            }
          }
        }

        final destination = DestinationAddress(
          address: result.address,
          latitude: result.latLng?.lat,
          longitude: result.latLng?.lng,
          city: city,
          countryCode: countryCode,
          country: country,
          postalCode: postalCode,
          placeId: placeId,
          title: result.name,
        );

        debugPrint('🗺️ getPlaceDetails success: ${destination.address}');
        return destination;
      }
      return null;
    } catch (e) {
      debugPrint('🗺️ getPlaceDetails error: $e');
      return null;
    }
  }

  @override
  Future<DestinationAddress> getPlaceDetailWithCoordinates(
    double latitude,
    double longitude,
  ) async {
    debugPrint('🗺️ getPlaceDetailWithCoordinates: $latitude, $longitude');

    final setting = _sharedPref?.getSetting();
    final apiKey = setting?.mapKey?.geocodingApiKey;

    if (apiKey == null || apiKey.isEmpty) {
      debugPrint('🗺️ Geocoding API key not found');
      return DestinationAddress(
        latitude: latitude,
        longitude: longitude,
      );
    }

    final response = await _appRepository.reverseGeocode(
      latitude: latitude,
      longitude: longitude,
      apiKey: apiKey,
    );

    switch (response) {
      case Success():
        final results = response.data?.results;
        if (results != null && results.isNotEmpty) {
          final firstResult = results.first;

          String? city;
          String? countryCode;
          String? country;
          String? postalCode;

          final addressComponents = firstResult.addressComponents;
          if (addressComponents != null) {
            for (final component in addressComponents) {
              final types = component.types;
              if (types != null) {
                if (types.contains('locality')) {
                  city = component.longName;
                } else if (types.contains('country')) {
                  countryCode = component.shortName;
                  country = component.longName;
                } else if (types.contains('postal_code')) {
                  postalCode = component.shortName;
                }
              }
            }
          }

          final destination = DestinationAddress(
            address: firstResult.formattedAddress,
            latitude: latitude,
            longitude: longitude,
            city: city,
            countryCode: countryCode,
            country: country,
            postalCode: postalCode,
            placeId: firstResult.placeId,
          );

          debugPrint('🗺️ getPlaceDetailWithCoordinates success: ${destination.address}, city: $city, countryCode: $countryCode');
          return destination;
        }
        return DestinationAddress(
          latitude: latitude,
          longitude: longitude,
        );

      default:
        debugPrint('🗺️ getPlaceDetailWithCoordinates error: ${response.message}');
        return DestinationAddress(
          latitude: latitude,
          longitude: longitude,
        );
    }
  }
}
