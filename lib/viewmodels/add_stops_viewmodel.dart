import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/map/interface/map_interface.dart';
import '../core/map/models/map_types.dart';
import '../core/managers/location_manager.dart';
import '../core/preferences/shared_preference_manager.dart';
import '../core/providers/app_providers.dart';
import '../core/utils/address_validation_util.dart';
import '../data/api/response_state.dart';
import '../data/repository/app_repository.dart';
import '../models/requests/get_vehicle_types_request.dart';

/// State class for AddStopsScreen
class AddStopsState {
  final DestinationAddress pickupAddress;
  final List<DestinationAddress> stops;
  final int maxStopLimit;
  final bool isLoadingRoute;
  final String? routePolyline;
  final String? errorMessage;

  // Add/Edit mode state - when true, sheet is draggable with search content
  final bool isAddEditMode;
  // Map selection mode state - when in add/edit mode and sheet is collapsed
  final bool isMapSelectionMode;
  final DestinationAddress? mapSelectionAddress;
  final bool isLoadingMapAddress;
  final int? editingStopIndex; // null means adding new stop, otherwise editing at index

  // Search state for expanded mode
  final List<DestinationAddress> searchResults;
  final List<DestinationAddress> recentAddresses;
  final bool isSearching;
  final String searchQuery;

  AddStopsState({
    required this.pickupAddress,
    this.stops = const [],
    this.maxStopLimit = 0,
    this.isLoadingRoute = false,
    this.routePolyline,
    this.errorMessage,
    this.isAddEditMode = false,
    this.isMapSelectionMode = false,
    this.mapSelectionAddress,
    this.isLoadingMapAddress = false,
    this.editingStopIndex,
    this.searchResults = const [],
    this.recentAddresses = const [],
    this.isSearching = false,
    this.searchQuery = '',
  });

  /// Whether the max stop limit has been reached (no more stops can be added)
  bool get noMoreStopsAllowed =>
      maxStopLimit > 0 && stops.length >= maxStopLimit;

  AddStopsState copyWith({
    DestinationAddress? pickupAddress,
    List<DestinationAddress>? stops,
    int? maxStopLimit,
    bool? isLoadingRoute,
    String? routePolyline,
    String? errorMessage,
    bool? isAddEditMode,
    bool? isMapSelectionMode,
    DestinationAddress? mapSelectionAddress,
    bool? isLoadingMapAddress,
    int? editingStopIndex,
    List<DestinationAddress>? searchResults,
    List<DestinationAddress>? recentAddresses,
    bool? isSearching,
    String? searchQuery,
    bool clearRoutePolyline = false,
    bool clearError = false,
    bool clearMapSelectionAddress = false,
    bool clearEditingStopIndex = false,
  }) {
    return AddStopsState(
      pickupAddress: pickupAddress ?? this.pickupAddress,
      stops: stops ?? this.stops,
      maxStopLimit: maxStopLimit ?? this.maxStopLimit,
      isLoadingRoute: isLoadingRoute ?? this.isLoadingRoute,
      routePolyline: clearRoutePolyline ? null : (routePolyline ?? this.routePolyline),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isAddEditMode: isAddEditMode ?? this.isAddEditMode,
      isMapSelectionMode: isMapSelectionMode ?? this.isMapSelectionMode,
      mapSelectionAddress: clearMapSelectionAddress ? null : (mapSelectionAddress ?? this.mapSelectionAddress),
      isLoadingMapAddress: isLoadingMapAddress ?? this.isLoadingMapAddress,
      editingStopIndex: clearEditingStopIndex ? null : (editingStopIndex ?? this.editingStopIndex),
      searchResults: searchResults ?? this.searchResults,
      recentAddresses: recentAddresses ?? this.recentAddresses,
      isSearching: isSearching ?? this.isSearching,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  /// Get all locations in order (pickup + stops)
  List<DestinationAddress> get allLocations => [pickupAddress, ...stops];

  /// Check if we have at least pickup and one destination
  bool get hasValidRoute => stops.isNotEmpty;
}

/// ViewModel for AddStopsScreen
class AddStopsViewModel extends StateNotifier<AddStopsState> {
  final MapInterface _mapManager;
  final AppRepository _appRepository;
  final SharedPreferenceManager? _sharedPref;
  int? _primaryColor;

  AddStopsViewModel({
    required MapInterface mapManager,
    required AppRepository appRepository,
    SharedPreferenceManager? sharedPref,
    required DestinationAddress pickupAddress,
    DestinationAddress? destinationAddress,
    int maxStopLimit = 0,
  })  : _mapManager = mapManager,
        _appRepository = appRepository,
        _sharedPref = sharedPref,
        super(AddStopsState(
          pickupAddress: pickupAddress,
          stops: destinationAddress != null ? [destinationAddress] : [],
          maxStopLimit: maxStopLimit,
        )) {
    // _fetchDirections(); // TODO: Uncomment when billing issue resolved
  }

  /// Initialize map with markers and fit camera to show all locations
  /// Should be called after map is created
  /// [primaryColor] - The primary color to tint the marker icons
  void initializeMap({required int primaryColor}) {
    _primaryColor = primaryColor;
    _updateMarkersAndFitBounds();
  }

  /// Add a new stop (respects maxStopLimit)
  void addStop(DestinationAddress stop) {
    if (state.noMoreStopsAllowed) return;
    final newStops = [...state.stops, stop];
    state = state.copyWith(stops: newStops);
    _updateMarkersAndFitBounds();
    // _fetchDirections(); // TODO: Uncomment when billing issue resolved
  }

  /// Update a stop at index
  void updateStop(int index, DestinationAddress newAddress) {
    if (index < 0 || index >= state.stops.length) return;
    final newStops = [...state.stops];
    newStops[index] = newAddress;
    state = state.copyWith(stops: newStops);
    _updateMarkersAndFitBounds();
    // _fetchDirections(); // TODO: Uncomment when billing issue resolved
  }

  /// Remove a stop at index
  void removeStop(int index) {
    if (index < 0 || index >= state.stops.length) return;
    final newStops = [...state.stops]..removeAt(index);
    state = state.copyWith(stops: newStops);
    if (newStops.isNotEmpty) {
      _updateMarkersAndFitBounds();
      // _fetchDirections(); // TODO: Uncomment when billing issue resolved
    } else {
      _clearRoute();
    }
  }

  /// Reorder stops
  void reorderStops(int oldIndex, int newIndex) {
    final newStops = [...state.stops];
    final item = newStops.removeAt(oldIndex);
    newStops.insert(newIndex, item);
    state = state.copyWith(stops: newStops);
    _updateMarkersAndFitBounds();
    // _fetchDirections(); // TODO: Uncomment when billing issue resolved
  }

  /// Enter add/edit mode - sheet becomes draggable with search content
  /// [editingIndex] - null for adding new stop, index for editing existing stop
  void enterAddEditMode({int? editingIndex}) {
    // Load recent addresses
    final recent = _sharedPref?.getRecentAddresses() ?? [];

    state = state.copyWith(
      isAddEditMode: true,
      isMapSelectionMode: false,
      editingStopIndex: editingIndex,
      recentAddresses: recent,
      searchResults: recent,
      searchQuery: '',
      clearMapSelectionAddress: true,
    );

    debugPrint('🛣️ AddStopsViewModel: Entered add/edit mode, editingIndex: $editingIndex');
  }

  /// Exit add/edit mode and return to normal mode
  void exitAddEditMode() {
    state = state.copyWith(
      isAddEditMode: false,
      isMapSelectionMode: false,
      clearMapSelectionAddress: true,
      clearEditingStopIndex: true,
      searchResults: const [],
      searchQuery: '',
      isSearching: false,
    );
    // Remove camera idle listener
    _mapManager.onCameraIdle = null;
    debugPrint('🛣️ AddStopsViewModel: Exited add/edit mode');
  }

  /// Enter map selection mode (collapsed state in add/edit mode)
  Future<void> enterMapSelectionMode() async {
    state = state.copyWith(
      isMapSelectionMode: true,
      clearMapSelectionAddress: true,
    );

    // Set up camera idle listener
    _mapManager.onCameraIdle = _onCameraIdle;

    // Move camera to current GPS location
    final result = await LocationManager.instance.getCurrentLocation();
    switch (result) {
      case LocationSuccess(location: final loc):
        await _mapManager.animateCamera(
          LatLng(loc.latitude, loc.longitude),
          zoom: 16,
        );
      default:
        break;
    }

    debugPrint('🛣️ AddStopsViewModel: Entered map selection mode');
  }

  /// Exit map selection mode (expand back to search)
  void exitMapSelectionMode() {
    state = state.copyWith(
      isMapSelectionMode: false,
      clearMapSelectionAddress: true,
    );
    // Remove camera idle listener
    _mapManager.onCameraIdle = null;
    debugPrint('🛣️ AddStopsViewModel: Exited map selection mode');
  }

  void _onCameraIdle(LatLng center) {
    if (!state.isAddEditMode || !state.isMapSelectionMode) return;
    debugPrint('🛣️ AddStopsViewModel: Camera idle at $center');
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

  /// Confirm the map selection and add/update the stop
  void confirmMapSelection() {
    final address = state.mapSelectionAddress;
    if (address == null) return;

    // Save to recent addresses
    _sharedPref?.addRecentAddress(address);

    if (state.editingStopIndex != null) {
      // Update existing stop
      updateStop(state.editingStopIndex!, address);
    } else {
      // Add new stop
      addStop(address);
    }

    // Exit add/edit mode completely
    exitAddEditMode();
  }

  /// Search for places
  Future<void> searchPlaces(String query) async {
    state = state.copyWith(searchQuery: query);

    if (query.length < 3) {
      state = state.copyWith(
        searchResults: state.recentAddresses,
        isSearching: false,
      );
      return;
    }

    state = state.copyWith(isSearching: true);

    // Use pickup's countryCode and location to restrict/bias autocomplete results
    final pickup = state.pickupAddress;
    final results = await _mapManager.searchPlaces(
      query,
      countryCode: pickup.countryCode,
      locationBias: pickup.latitude != null && pickup.longitude != null
          ? LatLng(pickup.latitude!, pickup.longitude!)
          : null,
    );

    state = state.copyWith(
      searchResults: results,
      isSearching: false,
    );
  }

  /// Validate all stops before proceeding to ChooseRide.
  /// Returns error message or null if valid.
  String? validateStops() {
    return AddressValidationUtil.validateRideAddresses(
      pickupAddress: state.pickupAddress,
      stops: state.stops,
    );
  }

  /// Select a place from search results or recent addresses
  Future<void> selectPlace(DestinationAddress place) async {
    // If it's a recent address with coordinates, use it directly
    if (place.isRecentAddress == true &&
        place.latitude != null &&
        place.longitude != null) {
      _addOrUpdateStop(place);
      return;
    }

    // Otherwise fetch full details from placeId
    if (place.placeId != null) {
      state = state.copyWith(isSearching: true);

      final details = await _mapManager.getPlaceDetails(place.placeId!);

      state = state.copyWith(isSearching: false);

      if (details != null) {
        // Save to recent addresses
        _sharedPref?.addRecentAddress(details);
        _mapManager.resetAutocompleteSession();
        _addOrUpdateStop(details);
      }
    }
  }

  /// Add or update stop and exit add/edit mode
  void _addOrUpdateStop(DestinationAddress address) {
    if (state.editingStopIndex != null) {
      updateStop(state.editingStopIndex!, address);
    } else {
      addStop(address);
    }
    exitAddEditMode();
  }

  /// Fetch directions from Google Directions API
  Future<void> _fetchDirections() async {
    if (!state.hasValidRoute) return;

    final pickup = state.pickupAddress;
    if (pickup.latitude == null || pickup.longitude == null) return;

    final allStops = state.stops;
    final lastStop = allStops.last;
    if (lastStop.latitude == null || lastStop.longitude == null) return;

    state = state.copyWith(isLoadingRoute: true, clearError: true);

    final setting = _sharedPref?.getSetting();
    final apiKey = setting?.mapKey?.geocodingApiKey;

    if (apiKey == null || apiKey.isEmpty) {
      debugPrint('🛣️ AddStopsViewModel: API key not found');
      state = state.copyWith(
        isLoadingRoute: false,
        errorMessage: 'API key not found',
      );
      return;
    }

    // Build origin, destination, and waypoints
    final origin = '${pickup.latitude},${pickup.longitude}';
    final destination = '${lastStop.latitude},${lastStop.longitude}';

    // Waypoints are all stops except the last one
    List<String>? waypoints;
    if (allStops.length > 1) {
      waypoints = allStops
          .sublist(0, allStops.length - 1)
          .where((s) => s.latitude != null && s.longitude != null)
          .map((s) => '${s.latitude},${s.longitude}')
          .toList();
    }

    debugPrint('🛣️ AddStopsViewModel: Fetching directions');
    debugPrint('   Origin: $origin');
    debugPrint('   Destination: $destination');
    debugPrint('   Waypoints: $waypoints');

    final response = await _appRepository.getDirections(
      origin: origin,
      destination: destination,
      waypoints: waypoints,
      apiKey: apiKey,
    );

    switch (response) {
      case Success():
        final routes = response.data?.routes;
        if (routes != null && routes.isNotEmpty) {
          final polyline = routes.first.overviewPolyline?.points;
          debugPrint('🛣️ AddStopsViewModel: Got route polyline');

          state = state.copyWith(
            isLoadingRoute: false,
            routePolyline: polyline,
          );

          // Decode polyline and update map
          if (polyline != null) {
            _updateMapWithRoute(polyline);
          }
        } else {
          state = state.copyWith(
            isLoadingRoute: false,
            errorMessage: 'No route found',
          );
        }

      default:
        debugPrint('🛣️ AddStopsViewModel: Error: ${response.message}');
        state = state.copyWith(
          isLoadingRoute: false,
          errorMessage: response.message ?? 'Failed to get directions',
        );
    }
  }

  /// Update map with route polyline and markers
  void _updateMapWithRoute(String encodedPolyline) {
    // Set polyline on map using factory that decodes internally
    _mapManager.setPolyline(MapPolyline.fromEncoded(
      encoded: encodedPolyline,
      color: _primaryColor ?? 0xFF4285F4, // Primary color or fallback to Google Blue
    ));

    // Set markers
    final markers = <MapMarker>[];
    final allLocations = state.allLocations;

    for (int i = 0; i < allLocations.length; i++) {
      final loc = allLocations[i];
      if (loc.latitude == null || loc.longitude == null) continue;

      String title;
      if (i == 0) {
        title = 'Pickup';
      } else {
        title = 'Stop $i';
      }

      markers.add(MapMarker(
        id: 'marker_$i',
        position: LatLng(loc.latitude!, loc.longitude!),
        title: title,
        snippet: loc.title ?? loc.address,
      ));
    }

    _mapManager.setMarkers(markers);

    // Fit camera to show all points
    final boundsPoints = allLocations
        .where((loc) => loc.latitude != null && loc.longitude != null)
        .map((loc) => LatLng(loc.latitude!, loc.longitude!))
        .toList();

    if (boundsPoints.isNotEmpty) {
      _mapManager.fitBounds(boundsPoints, padding: 80);
    }
  }

  void _clearRoute() {
    state = state.copyWith(clearRoutePolyline: true);
    _mapManager.setPolyline(null);
    _mapManager.setMarkers([]);
  }

  /// Update markers and fit camera bounds (without fetching directions)
  void _updateMarkersAndFitBounds() {
    final markers = <MapMarker>[];
    final allLocations = state.allLocations;
    final lastIndex = allLocations.length - 1;

    for (int i = 0; i < allLocations.length; i++) {
      final loc = allLocations[i];
      if (loc.latitude == null || loc.longitude == null) continue;

      String title;
      String? iconAsset;
      int? stopNumber;

      if (i == 0) {
        // First = Pickup
        title = 'Pickup';
        iconAsset = 'assets/images/ic_pickup.png';
      } else if (i == lastIndex) {
        // Last = Destination
        title = 'Destination';
        iconAsset = 'assets/images/ic_drop_off.png';
      } else {
        // Middle = Stop (numbered square marker)
        title = 'Stop $i';
        stopNumber = i; // Use stop number for numbered square markers
      }

      markers.add(MapMarker(
        id: 'marker_$i',
        position: LatLng(loc.latitude!, loc.longitude!),
        title: title,
        snippet: loc.title ?? loc.address,
        iconAsset: iconAsset,
        iconWidth: 32,
        iconHeight: 32,
        iconColor: _primaryColor,
        stopNumber: stopNumber,
      ));
    }

    _mapManager.setMarkers(markers);

    // Fit camera to show all points
    final boundsPoints = allLocations
        .where((loc) => loc.latitude != null && loc.longitude != null)
        .map((loc) => LatLng(loc.latitude!, loc.longitude!))
        .toList();

    if (boundsPoints.isNotEmpty) {
      _mapManager.fitBounds(boundsPoints, padding: 80);
    }
  }
}

/// Provider for AddStopsViewModel
final addStopsViewModelProvider = StateNotifierProvider.autoDispose
    .family<AddStopsViewModel, AddStopsState, AddStopsParams>(
  (ref, params) {
    final appRepository = ref.watch(appRepositoryProvider);
    final sharedPref = ref.watch(sharedPreferenceManagerProvider).maybeWhen(
          data: (data) => data,
          orElse: () => null,
        );

    return AddStopsViewModel(
      mapManager: params.mapManager,
      appRepository: appRepository,
      sharedPref: sharedPref,
      pickupAddress: params.pickupAddress,
      destinationAddress: params.destinationAddress,
      maxStopLimit: params.maxStopLimit,
    );
  },
);

/// Parameters for AddStopsViewModel provider
class AddStopsParams {
  final DestinationAddress pickupAddress;
  final DestinationAddress? destinationAddress;
  final int maxStopLimit;
  final MapInterface mapManager;

  const AddStopsParams({
    required this.pickupAddress,
    this.destinationAddress,
    this.maxStopLimit = 0,
    required this.mapManager,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AddStopsParams &&
          runtimeType == other.runtimeType &&
          pickupAddress == other.pickupAddress &&
          destinationAddress == other.destinationAddress &&
          maxStopLimit == other.maxStopLimit &&
          mapManager == other.mapManager;

  @override
  int get hashCode => pickupAddress.hashCode ^ destinationAddress.hashCode ^ maxStopLimit.hashCode ^ mapManager.hashCode;
}
