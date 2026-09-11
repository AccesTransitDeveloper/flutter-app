import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/managers/location_manager.dart';
import '../core/map/interface/map_interface.dart';
import '../core/map/models/map_types.dart';
import '../core/preferences/shared_preference_manager.dart';
import '../core/providers/app_providers.dart';
import '../core/utils/address_validation_util.dart';
import '../models/requests/get_vehicle_types_request.dart';

/// Enum to track which location field is currently focused
enum LocationFocus { pickup, destination }

/// State class for PlanRideScreen
class PlanRideState {
  final DestinationAddress? pickupAddress;
  final DestinationAddress? destinationAddress;
  final LocationFocus currentFocus;
  final List<DestinationAddress> autocompleteResults;
  final List<DestinationAddress> recentAddresses;
  final bool isSearching;
  final bool isLoadingPlaceDetails;
  final String searchQuery;
  final bool isMapSelectionMode;
  final DestinationAddress? mapSelectionAddress;
  final bool isLoadingMapAddress;

  PlanRideState({
    this.pickupAddress,
    this.destinationAddress,
    this.currentFocus = LocationFocus.pickup,
    this.autocompleteResults = const [],
    this.recentAddresses = const [],
    this.isSearching = false,
    this.isLoadingPlaceDetails = false,
    this.searchQuery = '',
    this.isMapSelectionMode = false,
    this.mapSelectionAddress,
    this.isLoadingMapAddress = false,
  });

  PlanRideState copyWith({
    DestinationAddress? pickupAddress,
    DestinationAddress? destinationAddress,
    LocationFocus? currentFocus,
    List<DestinationAddress>? autocompleteResults,
    List<DestinationAddress>? recentAddresses,
    bool? isSearching,
    bool? isLoadingPlaceDetails,
    String? searchQuery,
    bool? isMapSelectionMode,
    DestinationAddress? mapSelectionAddress,
    bool? isLoadingMapAddress,
    bool clearPickup = false,
    bool clearDestination = false,
    bool clearMapSelectionAddress = false,
  }) {
    return PlanRideState(
      pickupAddress: clearPickup ? null : (pickupAddress ?? this.pickupAddress),
      destinationAddress: clearDestination ? null : (destinationAddress ?? this.destinationAddress),
      currentFocus: currentFocus ?? this.currentFocus,
      autocompleteResults: autocompleteResults ?? this.autocompleteResults,
      recentAddresses: recentAddresses ?? this.recentAddresses,
      isSearching: isSearching ?? this.isSearching,
      isLoadingPlaceDetails: isLoadingPlaceDetails ?? this.isLoadingPlaceDetails,
      searchQuery: searchQuery ?? this.searchQuery,
      isMapSelectionMode: isMapSelectionMode ?? this.isMapSelectionMode,
      mapSelectionAddress: clearMapSelectionAddress ? null : (mapSelectionAddress ?? this.mapSelectionAddress),
      isLoadingMapAddress: isLoadingMapAddress ?? this.isLoadingMapAddress,
    );
  }
}

/// ViewModel for PlanRideScreen
class PlanRideViewModel extends StateNotifier<PlanRideState> {
  final MapInterface _mapManager;
  final SharedPreferenceManager? _sharedPref;

  PlanRideViewModel({
    required MapInterface mapManager,
    SharedPreferenceManager? sharedPref,
    DestinationAddress? initialPickupAddress,
  })  : _mapManager = mapManager,
        _sharedPref = sharedPref,
        super(PlanRideState(
          pickupAddress: initialPickupAddress,
          currentFocus: initialPickupAddress != null
              ? LocationFocus.destination
              : LocationFocus.pickup,
        )) {
    _loadRecentAddresses();
  }

  void _loadRecentAddresses() {
    final recent = _sharedPref?.getRecentAddresses() ?? [];
    state = state.copyWith(recentAddresses: recent);
    debugPrint('🚗 PlanRideViewModel: Loaded ${recent.length} recent addresses');
  }

  void setFocus(LocationFocus focus) {
    if (state.currentFocus != focus) {
      state = state.copyWith(
        currentFocus: focus,
        autocompleteResults: state.recentAddresses,
        searchQuery: '',
      );
    }
  }

  void clearLocation(LocationFocus focus) {
    if (focus == LocationFocus.pickup) {
      state = state.copyWith(
        clearPickup: true,
        currentFocus: LocationFocus.pickup,
        autocompleteResults: state.recentAddresses,
        searchQuery: '',
      );
    } else {
      state = state.copyWith(
        clearDestination: true,
        currentFocus: LocationFocus.destination,
        autocompleteResults: state.recentAddresses,
        searchQuery: '',
      );
    }
  }

  Future<void> searchPlaces(String query) async {
    state = state.copyWith(searchQuery: query);

    // Show recent addresses until 3 characters are typed
    if (query.length < 3) {
      state = state.copyWith(
        autocompleteResults: state.recentAddresses,
        isSearching: false,
      );
      return;
    }

    state = state.copyWith(isSearching: true);

    // Use pickup's countryCode and location to restrict/bias autocomplete results
    final pickup = state.pickupAddress;
    final results = await _mapManager.searchPlaces(
      query,
      countryCode: pickup?.countryCode,
      locationBias: pickup?.latitude != null && pickup?.longitude != null
          ? LatLng(pickup!.latitude!, pickup.longitude!)
          : null,
    );

    state = state.copyWith(
      autocompleteResults: results,
      isSearching: false,
    );
  }

  Future<void> selectPlace(DestinationAddress place) async {
    debugPrint('🚗 PlanRideViewModel: Selecting place ${place.address}');

    // If it's a recent address with coordinates, use it directly
    if (place.isRecentAddress == true &&
        place.latitude != null &&
        place.longitude != null) {
      _setSelectedAddress(place);
      return;
    }

    // Otherwise fetch full details from placeId
    if (place.placeId != null) {
      state = state.copyWith(isLoadingPlaceDetails: true);

      final details = await _mapManager.getPlaceDetails(place.placeId!);

      state = state.copyWith(isLoadingPlaceDetails: false);

      if (details != null) {
        _setSelectedAddress(details);
        // Reset session token after place selection
        _mapManager.resetAutocompleteSession();
      }
    }
  }

  void _setSelectedAddress(DestinationAddress address) {
    // Save to recent addresses
    _sharedPref?.addRecentAddress(address);
    _loadRecentAddresses();

    if (state.currentFocus == LocationFocus.pickup) {
      state = state.copyWith(
        pickupAddress: address,
        currentFocus: LocationFocus.destination,
        autocompleteResults: state.recentAddresses,
        searchQuery: '',
      );
    } else {
      state = state.copyWith(
        destinationAddress: address,
        autocompleteResults: state.recentAddresses,
        searchQuery: '',
      );
    }
  }

  void setPickupFromMap(DestinationAddress address) {
    _sharedPref?.addRecentAddress(address);
    _loadRecentAddresses();

    state = state.copyWith(
      pickupAddress: address,
      currentFocus: LocationFocus.destination,
    );
  }

  void setDestinationFromMap(DestinationAddress address) {
    _sharedPref?.addRecentAddress(address);
    _loadRecentAddresses();

    state = state.copyWith(destinationAddress: address);
  }

  Future<void> enterMapSelectionMode() async {
    state = state.copyWith(
      isMapSelectionMode: true,
      clearMapSelectionAddress: true,
    );
    // Set up camera idle listener
    _mapManager.onCameraIdle = _onCameraIdle;

    // Move camera to current address if available
    final currentAddress = state.currentFocus == LocationFocus.pickup
        ? state.pickupAddress
        : state.destinationAddress;

    if (currentAddress?.latitude != null && currentAddress?.longitude != null) {
      debugPrint('🚗 PlanRideViewModel: Moving camera to ${currentAddress!.latitude}, ${currentAddress.longitude}');
      await _mapManager.animateCamera(
        LatLng(currentAddress.latitude!, currentAddress.longitude!),
        zoom: 16,
      );
      // Camera animation will trigger onCameraIdle which will fetch address
    } else {
      // No current address - move to current GPS location first
      final result = await LocationManager.instance.getCurrentLocation();
      switch (result) {
        case LocationSuccess(location: final loc):
          await _mapManager.animateCamera(
            LatLng(loc.latitude, loc.longitude),
            zoom: 16,
          );
          // Camera animation will trigger onCameraIdle which will fetch address
        default:
          // Fallback: fetch address for current camera center
          _fetchAddressForCurrentCameraCenter();
      }
    }
  }

  /// Fetch address for current camera center position
  /// Used when entering map selection mode without a specific address to animate to
  Future<void> _fetchAddressForCurrentCameraCenter() async {
    // Small delay to ensure map is ready
    await Future.delayed(const Duration(milliseconds: 100));

    if (!state.isMapSelectionMode) return; // User may have exited

    final center = await _mapManager.getCameraCenter();
    if (center != null && state.isMapSelectionMode) {
      debugPrint('🚗 PlanRideViewModel: Fetching address for current camera center: $center');
      _fetchAddressForLocation(center.latitude, center.longitude);
    }
  }

  void exitMapSelectionMode() {
    state = state.copyWith(
      isMapSelectionMode: false,
      clearMapSelectionAddress: true,
    );
    // Remove camera idle listener
    _mapManager.onCameraIdle = null;
  }

  void _onCameraIdle(LatLng center) {
    if (!state.isMapSelectionMode) return;
    debugPrint('🚗 PlanRideViewModel: Camera idle at $center');
    _fetchAddressForLocation(center.latitude, center.longitude);
  }

  Future<void> _fetchAddressForLocation(double latitude, double longitude) async {
    state = state.copyWith(isLoadingMapAddress: true);

    final address = await _mapManager.getPlaceDetailWithCoordinates(latitude, longitude);

    state = state.copyWith(
      mapSelectionAddress: address,
      isLoadingMapAddress: false,
    );
  }

  void confirmMapSelection() {
    final address = state.mapSelectionAddress;
    if (address == null) return;

    _sharedPref?.addRecentAddress(address);
    _loadRecentAddresses();

    if (state.currentFocus == LocationFocus.pickup) {
      state = state.copyWith(
        pickupAddress: address,
        isMapSelectionMode: false,
        currentFocus: LocationFocus.destination,
        clearMapSelectionAddress: true,
      );
    } else {
      state = state.copyWith(
        destinationAddress: address,
        isMapSelectionMode: false,
        clearMapSelectionAddress: true,
      );
    }

    // Remove camera idle listener
    _mapManager.onCameraIdle = null;
  }

  bool get canProceed =>
      state.pickupAddress != null && state.destinationAddress != null;

  /// Validate addresses before proceeding to ChooseRide.
  /// Returns error message or null if valid.
  String? validateAddresses({bool isDestinationLater = false}) {
    return AddressValidationUtil.validateRideAddresses(
      pickupAddress: state.pickupAddress,
      stops: const [],
      dropoffAddress: state.destinationAddress,
      isDestinationLater: isDestinationLater,
    );
  }

  /// Move camera to current GPS location
  /// On screen open, if no pickup is set yet, fetch the device's current
  /// location, reverse-geocode it, and use it as the pickup address so the
  /// pickup field is pre-filled. The result is stored in state (persisted),
  /// not just shown transiently.
  Future<void> initPickupFromCurrentLocation() async {
    if (state.pickupAddress != null) return; // already have a pickup
    final result = await LocationManager.instance.getCurrentLocation();
    switch (result) {
      case LocationSuccess(location: final loc):
        final address = await _mapManager.getPlaceDetailWithCoordinates(
          loc.latitude,
          loc.longitude,
        );
        // Guard again — the user may have picked a location while we waited.
        if (state.pickupAddress == null) {
          state = state.copyWith(
            pickupAddress: address,
            currentFocus: LocationFocus.destination,
          );
        }
      default:
        break;
    }
  }

  Future<void> moveToCurrentLocation() async {
    final locationManager = LocationManager.instance;
    final result = await locationManager.getCurrentLocation();

    switch (result) {
      case LocationSuccess(location: final loc):
        debugPrint('🚗 PlanRideViewModel: Moving to current location ${loc.latitude}, ${loc.longitude}');
        await _mapManager.animateCamera(
          LatLng(loc.latitude, loc.longitude),
          zoom: 16,
        );
      case LocationPermissionDenied(permissionResult: final permission):
        debugPrint('🚗 PlanRideViewModel: Location permission denied: $permission');
      case LocationServiceDisabled():
        debugPrint('🚗 PlanRideViewModel: Location services disabled');
      case LocationError(message: final msg):
        debugPrint('🚗 PlanRideViewModel: Location error: $msg');
    }
  }
}

/// Parameters for PlanRideViewModel provider
class PlanRideParams {
  final DestinationAddress? initialPickupAddress;
  final MapInterface mapManager;

  const PlanRideParams({
    this.initialPickupAddress,
    required this.mapManager,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlanRideParams &&
          runtimeType == other.runtimeType &&
          initialPickupAddress == other.initialPickupAddress &&
          mapManager == other.mapManager;

  @override
  int get hashCode => initialPickupAddress.hashCode ^ mapManager.hashCode;
}

/// Provider for PlanRideViewModel
/// Requires PlanRideParams with mapManager instance created by the screen
final planRideViewModelProvider = StateNotifierProvider.autoDispose
    .family<PlanRideViewModel, PlanRideState, PlanRideParams>(
  (ref, params) {
    final sharedPref = ref.watch(sharedPreferenceManagerProvider).maybeWhen(
          data: (data) => data,
          orElse: () => null,
        );

    return PlanRideViewModel(
      mapManager: params.mapManager,
      sharedPref: sharedPref,
      initialPickupAddress: params.initialPickupAddress,
    );
  },
);
