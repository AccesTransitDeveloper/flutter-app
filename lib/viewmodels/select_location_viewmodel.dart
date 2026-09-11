import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/managers/location_manager.dart';
import '../core/map/interface/map_interface.dart';
import '../core/map/models/map_types.dart';
import '../models/requests/get_vehicle_types_request.dart';

/// State class for SelectLocationScreen
/// Only shows search results (autocomplete) and "Set location on map"
class SelectLocationState {
  final bool isSearching;
  final bool isLoadingMapAddress;
  final bool isMapSelectionMode;
  final String searchQuery;
  final List<DestinationAddress> searchResults;
  final DestinationAddress? mapSelectionAddress;
  final LatLng? currentLocation;
  final DestinationAddress? initialAddress;

  SelectLocationState({
    this.isSearching = false,
    this.isLoadingMapAddress = false,
    this.isMapSelectionMode = false,
    this.searchQuery = '',
    this.searchResults = const [],
    this.mapSelectionAddress,
    this.currentLocation,
    this.initialAddress,
  });

  SelectLocationState copyWith({
    bool? isSearching,
    bool? isLoadingMapAddress,
    bool? isMapSelectionMode,
    String? searchQuery,
    List<DestinationAddress>? searchResults,
    DestinationAddress? mapSelectionAddress,
    LatLng? currentLocation,
    DestinationAddress? initialAddress,
    bool clearMapSelectionAddress = false,
    bool clearInitialAddress = false,
  }) {
    return SelectLocationState(
      isSearching: isSearching ?? this.isSearching,
      isLoadingMapAddress: isLoadingMapAddress ?? this.isLoadingMapAddress,
      isMapSelectionMode: isMapSelectionMode ?? this.isMapSelectionMode,
      searchQuery: searchQuery ?? this.searchQuery,
      searchResults: searchResults ?? this.searchResults,
      mapSelectionAddress: clearMapSelectionAddress ? null : (mapSelectionAddress ?? this.mapSelectionAddress),
      currentLocation: currentLocation ?? this.currentLocation,
      initialAddress: clearInitialAddress ? null : (initialAddress ?? this.initialAddress),
    );
  }
}

/// ViewModel for SelectLocationScreen
/// Only handles search results (autocomplete) and map selection
class SelectLocationViewModel extends StateNotifier<SelectLocationState> {
  final MapInterface _mapManager;
  final String? _countryCode;

  SelectLocationViewModel({
    required MapInterface mapManager,
    String? countryCode,
  })  : _mapManager = mapManager,
        _countryCode = countryCode,
        super(SelectLocationState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    await _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    final locationManager = LocationManager.instance;
    final result = await locationManager.getCurrentLocation();

    switch (result) {
      case LocationSuccess(location: final loc):
        state = state.copyWith(
          currentLocation: LatLng(loc.latitude, loc.longitude),
        );
        debugPrint('📍 SelectLocationViewModel: Current location ${loc.latitude}, ${loc.longitude}');
      default:
        debugPrint('📍 SelectLocationViewModel: Could not get current location');
    }
  }

  Future<void> searchPlaces(String query) async {
    state = state.copyWith(searchQuery: query);

    // Only search when 3+ characters are typed
    if (query.length < 3) {
      state = state.copyWith(
        searchResults: [],
        isSearching: false,
      );
      return;
    }

    state = state.copyWith(isSearching: true);

    final results = await _mapManager.searchPlaces(
      query,
      countryCode: _countryCode,
      locationBias: state.currentLocation,
    );

    state = state.copyWith(
      searchResults: results,
      isSearching: false,
    );
  }

  Future<DestinationAddress?> getPlaceDetails(DestinationAddress place) async {
    // If it has coordinates already, return it
    if (place.latitude != null && place.longitude != null) {
      return place;
    }

    // Otherwise fetch details from placeId
    if (place.placeId != null) {
      final details = await _mapManager.getPlaceDetails(place.placeId!);
      if (details != null) {
        _mapManager.resetAutocompleteSession();
        return details;
      }
    }
    return null;
  }

  /// Set initial address for editing mode
  void setInitialAddress(DestinationAddress address) {
    state = state.copyWith(initialAddress: address);
    debugPrint('📍 SelectLocationViewModel: Initial address set - ${address.address}');
  }

  /// Enter map selection mode
  /// If initial address is provided (editing), move camera to that location
  /// Otherwise, move camera to current location
  Future<void> enterMapSelectionMode() async {
    debugPrint('📍 SelectLocationViewModel: enterMapSelectionMode called');
    debugPrint('📍 SelectLocationViewModel: initialAddress = ${state.initialAddress?.address}, lat: ${state.initialAddress?.latitude}, lng: ${state.initialAddress?.longitude}');
    debugPrint('📍 SelectLocationViewModel: currentLocation = ${state.currentLocation}');

    // Set callback first before any camera animation
    _mapManager.onCameraIdle = _onCameraIdle;

    // Move camera to initial address if editing, otherwise to current location
    final initial = state.initialAddress;
    if (initial != null && initial.latitude != null && initial.longitude != null) {
      debugPrint('📍 SelectLocationViewModel: Moving to initial address ${initial.latitude}, ${initial.longitude}');
      // Set initial address as the current map selection address and enter map mode
      state = state.copyWith(
        isMapSelectionMode: true,
        mapSelectionAddress: initial,
      );
      await _mapManager.animateCamera(
        LatLng(initial.latitude!, initial.longitude!),
        zoom: 16,
      );
    } else if (state.currentLocation != null) {
      debugPrint('📍 SelectLocationViewModel: Moving to current location ${state.currentLocation}');
      state = state.copyWith(
        isMapSelectionMode: true,
        clearMapSelectionAddress: true,
      );
      await _mapManager.animateCamera(
        state.currentLocation!,
        zoom: 16,
      );
    } else {
      debugPrint('📍 SelectLocationViewModel: No initial address and no current location');
      // No initial address and no current location - just enter map mode
      state = state.copyWith(
        isMapSelectionMode: true,
        clearMapSelectionAddress: true,
      );
    }
  }

  void exitMapSelectionMode() {
    state = state.copyWith(
      isMapSelectionMode: false,
    );
    _mapManager.onCameraIdle = null;
  }

  void _onCameraIdle(LatLng center) {
    if (!state.isMapSelectionMode) return;
    debugPrint('📍 SelectLocationViewModel: Camera idle at $center');
    _fetchAddressForLocation(center.latitude, center.longitude);
  }

  Future<void> _fetchAddressForLocation(double latitude, double longitude) async {
    state = state.copyWith(isLoadingMapAddress: true);

    final address = await _mapManager.getPlaceDetailWithCoordinates(latitude, longitude);

    debugPrint('📍 SelectLocationViewModel: Fetched address - title: ${address.title}, address: ${address.address}');

    // Only update state if still in map selection mode (user might have exited)
    if (state.isMapSelectionMode) {
      state = state.copyWith(
        mapSelectionAddress: address,
        isLoadingMapAddress: false,
      );
    }
  }

  DestinationAddress? confirmMapSelection() {
    final address = state.mapSelectionAddress;
    if (address == null) return null;

    state = state.copyWith(
      isMapSelectionMode: false,
      clearMapSelectionAddress: true,
    );
    _mapManager.onCameraIdle = null;

    return address;
  }

  Future<void> moveToCurrentLocation() async {
    final locationManager = LocationManager.instance;
    final result = await locationManager.getCurrentLocation();

    switch (result) {
      case LocationSuccess(location: final loc):
        debugPrint('📍 SelectLocationViewModel: Moving to current location ${loc.latitude}, ${loc.longitude}');
        await _mapManager.animateCamera(
          LatLng(loc.latitude, loc.longitude),
          zoom: 16,
        );
      case LocationPermissionDenied(permissionResult: final permission):
        debugPrint('📍 SelectLocationViewModel: Location permission denied: $permission');
      case LocationServiceDisabled():
        debugPrint('📍 SelectLocationViewModel: Location services disabled');
      case LocationError(message: final msg):
        debugPrint('📍 SelectLocationViewModel: Location error: $msg');
    }
  }

  /// Calculate distance from current location to an address in miles
  double? calculateDistanceMiles(DestinationAddress address) {
    if (state.currentLocation == null ||
        address.latitude == null ||
        address.longitude == null) {
      return null;
    }

    final distanceMeters = LocationManager.instance.calculateDistance(
      state.currentLocation!.latitude,
      state.currentLocation!.longitude,
      address.latitude!,
      address.longitude!,
    );

    // Convert meters to miles
    return distanceMeters / 1609.344;
  }
}

/// Parameters for SelectLocationViewModel provider
class SelectLocationParams {
  final MapInterface mapManager;
  final String? countryCode;

  const SelectLocationParams({
    required this.mapManager,
    this.countryCode,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SelectLocationParams &&
          runtimeType == other.runtimeType &&
          mapManager == other.mapManager &&
          countryCode == other.countryCode;

  @override
  int get hashCode => mapManager.hashCode ^ countryCode.hashCode;
}

/// Provider for SelectLocationViewModel
/// Requires SelectLocationParams with mapManager and optional countryCode
final selectLocationViewModelProvider = StateNotifierProvider.autoDispose
    .family<SelectLocationViewModel, SelectLocationState, SelectLocationParams>(
  (ref, params) {
    return SelectLocationViewModel(
      mapManager: params.mapManager,
      countryCode: params.countryCode,
    );
  },
);
