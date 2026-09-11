import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/preferences/shared_preference_manager.dart';
import '../core/providers/app_providers.dart';
import '../core/utils/invoice_util.dart';
import '../data/api/response_state.dart';
import '../data/repository/app_repository.dart';
import '../models/common/filters_result.dart';
import '../models/requests/get_vehicle_types_request.dart';
import '../models/requests/fare_estimate_request.dart';
import '../models/ride_for_other_result.dart';
import '../models/requests/create_booking_request.dart';
import '../models/responses/booking/booking_detail_response.dart';
import '../models/responses/booking/get_vehicle_type_response.dart';
import '../models/responses/booking/fare_estimate_response.dart';
import '../models/requests/distance_matrix_request.dart';
import '../models/requests/find_nearest_drivers_request.dart';
import '../models/responses/booking/create_booking_response.dart';
import '../models/responses/booking/nearest_drivers_response.dart';
import '../models/responses/location/distance_matrix_response.dart';
import '../models/responses/payment/card_response.dart';

/// Represents a section of vehicles with a heading
class VehicleSection {
  final RideType rideType;
  final List<NormalVehicles> vehicles;

  const VehicleSection({
    required this.rideType,
    required this.vehicles,
  });

  String get title => rideType.getName();
}

/// Choose ride screen state
class ChooseRideState {
  final DestinationAddress pickupAddress;
  final List<DestinationAddress> destinations;
  /// Original rideType from params - null means user clicked "Get a Ride" (show all types)
  final RideType? initialRideType;
  /// Current rideType - updates when vehicle is selected
  final RideType? rideType;
  final bool isLoading;
  final String? error;
  final GetVehicleTypeResponse? vehicleTypeResponse;
  /// Used when rideType is NOT null (single type mode)
  final List<NormalVehicles> vehicleList;
  /// Used when rideType IS null (all types mode with sections)
  final List<VehicleSection> vehicleSections;
  /// Selected index for single type mode
  final int selectedIndex;
  /// Selected section index for all types mode
  final int selectedSectionIndex;
  /// Selected vehicle index within section for all types mode
  final int selectedVehicleIndex;
  final String? currencySign;
  final int? distance;
  final int? time;
  final CardResponse? selectedCard;
  final CardResponse? defaultCard;
  final FiltersResult? filtersResult;
  final PromoDetail? selectedPromo;
  final bool isFareLoading;
  final InvoiceDetail? updatedPriceDetail;
  final int? bookingTime;
  final bool isCreatingBooking;
  final CreateBookingResponse? createBookingResponse;
  final String? snackBarMessage;
  final bool isSnackBarError;
  /// Whether corporate booking is available for the user
  final bool isCorporateAvailable;
  /// Whether the user has selected corporate booking
  final bool isCorporateBooking;
  /// Whether bidding is available for the current ride type
  final bool isBiddingAvailable;
  /// Whether the user has activated bidding
  final bool isBidding;
  /// The bid price entered by the user
  final double? bidPrice;
  /// Whether rental package sub-step is active in vehicle selection
  final bool isShowingRentalPackages;
  /// Selected index within selectedVehicle.packageList
  final int selectedPackageIndex;
  /// Whether this is a destination-later booking (no destination set)
  final bool isDestinationLater;
  /// Optional note for the driver entered in confirm pickup.
  final String driverMessage;
  /// Nearby drivers fetched from find_nearest_driver API (for map pins)
  final List<NearestDriverItem> nearbyDrivers;
  /// vehicleTypeId → estimated driver arrival in seconds (from distance matrix)
  final Map<String, int> vehicleDurations;

  const ChooseRideState({
    required this.pickupAddress,
    required this.destinations,
    this.initialRideType,
    this.rideType,
    this.isLoading = false,
    this.error,
    this.vehicleTypeResponse,
    this.vehicleList = const [],
    this.vehicleSections = const [],
    this.selectedIndex = 0,
    this.selectedSectionIndex = 0,
    this.selectedVehicleIndex = 0,
    this.currencySign,
    this.distance,
    this.time,
    this.selectedCard,
    this.defaultCard,
    this.filtersResult,
    this.selectedPromo,
    this.isFareLoading = false,
    this.updatedPriceDetail,
    this.bookingTime,
    this.isCreatingBooking = false,
    this.createBookingResponse,
    this.snackBarMessage,
    this.isSnackBarError = false,
    this.isCorporateAvailable = false,
    this.isCorporateBooking = false,
    this.isBiddingAvailable = false,
    this.isBidding = false,
    this.bidPrice,
    this.isShowingRentalPackages = false,
    this.selectedPackageIndex = 0,
    this.isDestinationLater = false,
    this.driverMessage = '',
    this.nearbyDrivers = const [],
    this.vehicleDurations = const {},
  });

  /// Returns true if showing all types with sections (initialRideType is null)
  bool get isShowingAllTypes => initialRideType == null;

  /// Returns filtered vehicle list based on filtersResult
  List<NormalVehicles> get filteredVehicleList {
    final filters = filtersResult;
    final vehicles = vehicleList ?? [];
    if (filters == null || !filters.hasFilters) {
      return vehicles;
    }
    final isRental = rideType == RideType.rental;
    return _applyFilters(vehicles, filters, isRental: isRental);
  }

  /// Returns filtered vehicle sections based on filtersResult
  List<VehicleSection> get filteredVehicleSections {
    final filters = filtersResult;
    final sections = vehicleSections ?? [];
    if (filters == null || !filters.hasFilters) {
      return sections;
    }

    return sections.map((section) {
      final isRental = section.rideType == RideType.rental;
      final filteredVehicles = _applyFilters(section.vehicles, filters, isRental: isRental);
      return VehicleSection(
        rideType: section.rideType,
        vehicles: filteredVehicles,
      );
    }).where((section) => section.vehicles.isNotEmpty).toList();
  }

  List<NormalVehicles> _applyFilters(
    List<NormalVehicles> vehicles,
    FiltersResult filters, {
    bool isRental = false,
  }) {
    var filtered = vehicles;

    // Filter by passenger capacity (>= selected)
    final selectedCapacity = filters.selectedCapacity.firstOrNull;
    if (selectedCapacity != null) {
      final minCapacity = int.tryParse(selectedCapacity);
      if (minCapacity != null) {
        filtered = filtered.where((vehicle) {
          final capacity = vehicle.vehicleTypeDetail?.passengerCapacity ?? 0;
          return capacity >= minCapacity;
        }).toList();
      }
    }

    // Filter by luggage capacity (>= selected)
    final selectedLuggage = filters.selectedLuggageCapacity.firstOrNull;
    if (selectedLuggage != null) {
      final minLuggage = int.tryParse(selectedLuggage);
      if (minLuggage != null) {
        filtered = filtered.where((vehicle) {
          final luggage = vehicle.vehicleTypeDetail?.luggageCapacity ?? 0;
          return luggage >= minLuggage;
        }).toList();
      }
    }

    // Filter by accessibility
    final selectedAccessibility = filters.selectedAccessibility;
    if (selectedAccessibility.isNotEmpty) {
      if (isRental) {
        // Rental: filter packages within each vehicle, keep vehicles with matching packages
        filtered = filtered.map((vehicle) {
          final packages = vehicle.packageList ?? [];
          final filteredPackages = packages.where((pkg) {
            final accessibilityPrices = pkg.priceDetail?.accessibilityPrices ?? [];
            return selectedAccessibility.every((id) =>
                accessibilityPrices.any((price) => price.chargeId == id));
          }).toList();
          if (filteredPackages.isEmpty) return null;
          return NormalVehicles(
            cityId: vehicle.cityId,
            countryId: vehicle.countryId,
            id: vehicle.id,
            priceDetail: vehicle.priceDetail,
            vehicleTypeDetail: vehicle.vehicleTypeDetail,
            vehicleTypeId: vehicle.vehicleTypeId,
            isMinFareApplied: vehicle.isMinFareApplied,
            packageList: filteredPackages,
          );
        }).whereType<NormalVehicles>().toList();
      } else {
        // Normal: vehicle must have ALL selected accessibility IDs
        filtered = filtered.where((vehicle) {
          final accessibilityPrices = vehicle.priceDetail?.accessibilityPrices ?? [];
          return selectedAccessibility.every((id) =>
              accessibilityPrices.any((price) => price.chargeId == id));
        }).toList();
      }
    }

    return filtered;
  }

  ChooseRideState copyWith({
    DestinationAddress? pickupAddress,
    List<DestinationAddress>? destinations,
    RideType? initialRideType,
    RideType? rideType,
    bool? isLoading,
    String? error,
    GetVehicleTypeResponse? vehicleTypeResponse,
    List<NormalVehicles>? vehicleList,
    List<VehicleSection>? vehicleSections,
    int? selectedIndex,
    int? selectedSectionIndex,
    int? selectedVehicleIndex,
    String? currencySign,
    int? distance,
    int? time,
    CardResponse? selectedCard,
    CardResponse? defaultCard,
    FiltersResult? filtersResult,
    PromoDetail? selectedPromo,
    bool? isFareLoading,
    InvoiceDetail? updatedPriceDetail,
    int? bookingTime,
    bool? isCreatingBooking,
    CreateBookingResponse? createBookingResponse,
    String? snackBarMessage,
    bool? isSnackBarError,
    bool clearSnackBar = false,
    bool clearError = false,
    bool clearRideType = false,
    bool clearSelectedCard = false,
    bool clearDefaultCard = false,
    bool clearFiltersResult = false,
    bool clearSelectedPromo = false,
    bool clearUpdatedPriceDetail = false,
    bool clearCreateBookingResponse = false,
    bool? isCorporateAvailable,
    bool? isCorporateBooking,
    bool? isBiddingAvailable,
    bool? isBidding,
    double? bidPrice,
    bool clearBidding = false,
    bool? isShowingRentalPackages,
    int? selectedPackageIndex,
    bool clearRentalPackages = false,
    bool? isDestinationLater,
    String? driverMessage,
    List<NearestDriverItem>? nearbyDrivers,
    Map<String, int>? vehicleDurations,
  }) {
    return ChooseRideState(
      pickupAddress: pickupAddress ?? this.pickupAddress,
      destinations: destinations ?? this.destinations,
      initialRideType: initialRideType ?? this.initialRideType,
      rideType: clearRideType ? null : (rideType ?? this.rideType),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      vehicleTypeResponse: vehicleTypeResponse ?? this.vehicleTypeResponse,
      vehicleList: vehicleList ?? this.vehicleList,
      vehicleSections: vehicleSections ?? this.vehicleSections,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      selectedSectionIndex: selectedSectionIndex ?? this.selectedSectionIndex,
      selectedVehicleIndex: selectedVehicleIndex ?? this.selectedVehicleIndex,
      currencySign: currencySign ?? this.currencySign,
      distance: distance ?? this.distance,
      time: time ?? this.time,
      selectedCard: clearSelectedCard ? null : (selectedCard ?? this.selectedCard),
      defaultCard: clearDefaultCard ? null : (defaultCard ?? this.defaultCard),
      filtersResult: clearFiltersResult ? null : (filtersResult ?? this.filtersResult),
      selectedPromo: clearSelectedPromo ? null : (selectedPromo ?? this.selectedPromo),
      isFareLoading: isFareLoading ?? this.isFareLoading,
      updatedPriceDetail: clearUpdatedPriceDetail ? null : (updatedPriceDetail ?? this.updatedPriceDetail),
      bookingTime: bookingTime ?? this.bookingTime,
      isCreatingBooking: isCreatingBooking ?? this.isCreatingBooking,
      createBookingResponse: clearCreateBookingResponse ? null : (createBookingResponse ?? this.createBookingResponse),
      snackBarMessage: clearSnackBar ? null : (snackBarMessage ?? this.snackBarMessage),
      isSnackBarError: clearSnackBar ? false : (isSnackBarError ?? this.isSnackBarError),
      isCorporateAvailable: isCorporateAvailable ?? this.isCorporateAvailable,
      isCorporateBooking: isCorporateBooking ?? this.isCorporateBooking,
      isBiddingAvailable: clearBidding ? false : (isBiddingAvailable ?? this.isBiddingAvailable),
      isBidding: clearBidding ? false : (isBidding ?? this.isBidding),
      bidPrice: clearBidding ? null : (bidPrice ?? this.bidPrice),
      isShowingRentalPackages: clearRentalPackages ? false : (isShowingRentalPackages ?? this.isShowingRentalPackages),
      selectedPackageIndex: clearRentalPackages ? 0 : (selectedPackageIndex ?? this.selectedPackageIndex),
      isDestinationLater: isDestinationLater ?? this.isDestinationLater,
      driverMessage: driverMessage ?? this.driverMessage,
      nearbyDrivers: nearbyDrivers ?? this.nearbyDrivers,
      vehicleDurations: vehicleDurations ?? this.vehicleDurations,
    );
  }
}

/// Parameters for ChooseRideViewModel
class ChooseRideParams {
  final DestinationAddress pickupAddress;
  final List<DestinationAddress> destinations;
  final RideType? rideType;
  final String? selectedVehicleTypeId;
  final bool isDestinationLater;

  const ChooseRideParams({
    required this.pickupAddress,
    required this.destinations,
    this.rideType,
    this.selectedVehicleTypeId,
    this.isDestinationLater = false,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChooseRideParams &&
        other.pickupAddress == pickupAddress &&
        listEquals(other.destinations, destinations) &&
        other.rideType == rideType &&
        other.selectedVehicleTypeId == selectedVehicleTypeId &&
        other.isDestinationLater == isDestinationLater;
  }

  @override
  int get hashCode =>
      pickupAddress.hashCode ^ destinations.hashCode ^ rideType.hashCode ^ selectedVehicleTypeId.hashCode ^ isDestinationLater.hashCode;
}

/// ChooseRideViewModel - manages vehicle type selection and API calls
class ChooseRideViewModel extends StateNotifier<ChooseRideState> {
  final AppRepository _appRepository;
  final SharedPreferenceManager _sharedPref;

  /// Stored corporate ID from approved entity typeIds
  String _corporateId = '';

  /// Vehicle type ID pre-selected from home screen
  final String? _selectedVehicleTypeId;

  ChooseRideViewModel(
    this._appRepository,
    this._sharedPref,
    ChooseRideParams params,
  ) : _selectedVehicleTypeId = params.selectedVehicleTypeId,
      super(ChooseRideState(
          pickupAddress: params.pickupAddress,
          destinations: params.destinations,
          initialRideType: params.rideType,
          rideType: params.rideType,
          isDestinationLater: params.isDestinationLater,
        ));

  /// Load vehicle types from API
  Future<void> loadVehicleTypes() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Get country code from entity in shared preferences
      final entity = _sharedPref.getEntity();
      final countryCode = state.pickupAddress.countryCode ?? entity?.countryCode ?? '';

      final request = GetVehicleTypesRequest(
        countryCode: countryCode,
        pickupAddress: state.pickupAddress,
        destinationAddresses: state.destinations,
        businessType: BusinessType.taxi,
      );

      debugPrint('🚗 ChooseRideViewModel - Loading vehicle types for initialRideType: ${state.initialRideType}');

      final response = await _appRepository.getVehicleTypes(request);

      switch (response) {
        case Success<GetVehicleTypeResponse>(data: final data):
          if (data == null) {
            state = state.copyWith(isLoading: false, error: 'No data received');
            return;
          }

          final currencySign = data.countrySetting?.currencySign;

          if (state.initialRideType == null) {
            // Show ALL vehicle types with sections
            final sections = _buildVehicleSections(data, excludeSharing: state.isDestinationLater);
            final orderedSections = _moveSelectedVehicleSectionToTop(
              sections,
              _selectedVehicleTypeId,
            );
            debugPrint('🚗 ChooseRideViewModel - Loaded ${sections.length} sections');

            // Auto-select matching vehicle or default to first
            int autoSectionIndex = 0;
            int autoVehicleIndex = 0;
            RideType? autoSelectedRideType;

            if (orderedSections.isNotEmpty && orderedSections.first.vehicles.isNotEmpty) {
              autoSelectedRideType = orderedSections.first.rideType;
            }

            if (_selectedVehicleTypeId != null) {
              for (int s = 0; s < orderedSections.length; s++) {
                for (int v = 0; v < orderedSections[s].vehicles.length; v++) {
                  if (orderedSections[s].vehicles[v].vehicleTypeId == _selectedVehicleTypeId) {
                    autoSectionIndex = s;
                    autoVehicleIndex = v;
                    autoSelectedRideType = orderedSections[s].rideType;
                    debugPrint('🚗 ChooseRideViewModel - Pre-selected vehicle found at section $s, vehicle $v');
                    break;
                  }
                }
                if (autoSectionIndex != 0 || autoVehicleIndex != 0) break;
              }
            }

            state = state.copyWith(
              isLoading: false,
              vehicleTypeResponse: data,
              vehicleSections: orderedSections,
              vehicleList: const [],
              currencySign: currencySign,
              distance: data.distance,
              time: data.time,
              rideType: autoSelectedRideType,
              selectedSectionIndex: autoSectionIndex,
              selectedVehicleIndex: autoVehicleIndex,
            );

            // Load cards and check corporate availability
            getCards();
            _checkCorporateAvailability();
            _checkBiddingAvailability();

            // Fetch nearby drivers for auto-selected vehicle (matches iOS: always calls with vehicleTypeId)
            final autoVehicle = orderedSections.elementAtOrNull(autoSectionIndex)
                ?.vehicles.elementAtOrNull(autoVehicleIndex);
            final initVehicleTypeId = autoVehicle?.vehicleTypeId;
            final initCityId = autoVehicle?.cityId;
            if (initVehicleTypeId != null && initCityId != null) {
              _fetchNearbyDriversForVehicle(initVehicleTypeId, initCityId);
            }
            // iOS onAppearDataSet: if showDriverEstimation is set, proactively fetch time estimates
            if (_isShowDriverEstimationEnabled() && initCityId != null) {
              _fetchNearbyDriversForTimeEstimation(initCityId);
            }
          } else {
            // Show only selected ride type
            final vehicleList = _moveSelectedVehicleToTop(
              _getVehicleListByRideType(data, state.rideType!),
              _selectedVehicleTypeId,
            );
            debugPrint('🚗 ChooseRideViewModel - Loaded ${vehicleList.length} vehicles');

            // Auto-select matching vehicle or default to first
            int autoSelectedIndex = 0;
            if (_selectedVehicleTypeId != null) {
              final matchIndex = vehicleList.indexWhere(
                (v) => v.vehicleTypeId == _selectedVehicleTypeId,
              );
              if (matchIndex >= 0) {
                autoSelectedIndex = matchIndex;
                debugPrint('🚗 ChooseRideViewModel - Pre-selected vehicle found at index $matchIndex');
              }
            }

            state = state.copyWith(
              isLoading: false,
              vehicleTypeResponse: data,
              vehicleList: vehicleList,
              vehicleSections: const [],
              currencySign: currencySign,
              distance: data.distance,
              time: data.time,
              selectedIndex: autoSelectedIndex,
            );

            // Load cards and check corporate availability
            getCards();
            _checkCorporateAvailability();
            _checkBiddingAvailability();

            // Fetch nearby drivers for auto-selected vehicle (matches iOS: always calls with vehicleTypeId)
            final autoVehicle = vehicleList.elementAtOrNull(autoSelectedIndex);
            final initVehicleTypeId = autoVehicle?.vehicleTypeId;
            final initCityId = autoVehicle?.cityId;
            if (initVehicleTypeId != null && initCityId != null) {
              _fetchNearbyDriversForVehicle(initVehicleTypeId, initCityId);
            }
            // iOS onAppearDataSet: if showDriverEstimation is set, proactively fetch time estimates
            if (_isShowDriverEstimationEnabled() && initCityId != null) {
              _fetchNearbyDriversForTimeEstimation(initCityId);
            }
          }

        case Error<GetVehicleTypeResponse>(error: final error):
          debugPrint('🔴 ChooseRideViewModel - Error: ${error?.message}');
          state = state.copyWith(
            isLoading: false,
            error: error?.message,
          );

        case Loading<GetVehicleTypeResponse>():
          // Already handled
          break;
      }
    } catch (e) {
      debugPrint('🔴 ChooseRideViewModel - Exception: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Build vehicle sections for all ride types (when rideType is null)
  /// Only includes sections that have vehicles, hides empty sections
  List<VehicleSection> _buildVehicleSections(GetVehicleTypeResponse response, {bool excludeSharing = false}) {
    final sections = <VehicleSection>[];

    // Normal vehicles
    if (response.normalList != null && response.normalList!.isNotEmpty) {
      sections.add(VehicleSection(
        rideType: RideType.normal,
        vehicles: response.normalList!,
      ));
    }

    // Sharing vehicles — excluded when destination is not set
    if (!excludeSharing && response.shareList != null && response.shareList!.isNotEmpty) {
      sections.add(VehicleSection(
        rideType: RideType.sharing,
        vehicles: response.shareList!,
      ));
    }

    // Rental vehicles
    if (response.rentalList != null && response.rentalList!.isNotEmpty) {
      sections.add(VehicleSection(
        rideType: RideType.rental,
        vehicles: response.rentalList!,
      ));
    }

    // Fix Group vehicles
    // if (response.fixGroupBookingList != null && response.fixGroupBookingList!.isNotEmpty) {
    //   sections.add(VehicleSection(
    //     rideType: RideType.fixGroup,
    //     vehicles: response.fixGroupBookingList!,
    //   ));
    // }

    return sections;
  }

  /// Get vehicle list based on ride type (single type mode)
  List<NormalVehicles> _getVehicleListByRideType(
    GetVehicleTypeResponse response,
    RideType rideType,
  ) {
    return switch (rideType) {
      RideType.normal => response.normalList ?? [],
      RideType.sharing => response.shareList ?? [],
      RideType.rental => response.rentalList ?? [],
      // RideType.fixGroup => response.fixGroupBookingList ?? [],
      RideType.fixGroup => const [],
    };
  }

  List<NormalVehicles> _moveSelectedVehicleToTop(
    List<NormalVehicles> vehicles,
    String? selectedVehicleTypeId,
  ) {
    if (selectedVehicleTypeId == null || vehicles.isEmpty) return vehicles;

    final selectedIndex = vehicles.indexWhere(
      (vehicle) => vehicle.vehicleTypeId == selectedVehicleTypeId,
    );
    if (selectedIndex <= 0) return vehicles;

    final reordered = List<NormalVehicles>.from(vehicles);
    final selectedVehicle = reordered.removeAt(selectedIndex);
    reordered.insert(0, selectedVehicle);
    return reordered;
  }

  List<VehicleSection> _moveSelectedVehicleSectionToTop(
    List<VehicleSection> sections,
    String? selectedVehicleTypeId,
  ) {
    if (selectedVehicleTypeId == null || sections.isEmpty) return sections;

    final reorderedSections = sections
        .map((section) => VehicleSection(
              rideType: section.rideType,
              vehicles: _moveSelectedVehicleToTop(
                section.vehicles,
                selectedVehicleTypeId,
              ),
            ))
        .toList();

    final selectedSectionIndex = reorderedSections.indexWhere(
      (section) => section.vehicles.isNotEmpty &&
          section.vehicles.first.vehicleTypeId == selectedVehicleTypeId,
    );

    if (selectedSectionIndex <= 0) return reorderedSections;

    final selectedSection = reorderedSections.removeAt(selectedSectionIndex);
    reorderedSections.insert(0, selectedSection);
    return reorderedSections;
  }

  /// Set selected vehicle index (single type mode)
  /// Note: index is from filtered list
  /// Clears promo and updatedPriceDetail since they are vehicle-specific
  void setSelectedIndex(int index) {
    final filteredList = state.filteredVehicleList;
    if (index >= 0 && index < filteredList.length) {
      state = state.copyWith(
        selectedIndex: index,
        clearSelectedPromo: true,
        clearUpdatedPriceDetail: true,
        clearRentalPackages: true,
        clearBidding: true,
      );
      _checkBiddingAvailability();

      // Fetch nearby drivers for selected vehicle type
      final vehicle = filteredList[index];
      final vehicleTypeId = vehicle.vehicleTypeId;
      final cityId = vehicle.cityId;
      if (vehicleTypeId != null && cityId != null) {
        _fetchNearbyDriversForVehicle(vehicleTypeId, cityId);
      }
    }
  }

  /// Set selected vehicle in sections mode (all types mode)
  /// Also updates rideType based on selected section
  /// Re-fetches cards if rideType changes (payment gateways may differ)
  /// Clears promo and updatedPriceDetail since they are vehicle-specific
  /// Note: indices are from filtered sections
  void setSelectedSectionVehicle(int sectionIndex, int vehicleIndex) {
    final filteredSections = state.filteredVehicleSections;
    if (sectionIndex < 0 || sectionIndex >= filteredSections.length) return;
    final section = filteredSections[sectionIndex];
    if (vehicleIndex < 0 || vehicleIndex >= section.vehicles.length) return;

    // Check if rideType is changing (only in all types mode)
    final previousRideType = state.rideType;
    final newRideType = section.rideType;
    final rideTypeChanged = state.initialRideType == null &&
        previousRideType != newRideType;

    state = state.copyWith(
      selectedSectionIndex: sectionIndex,
      selectedVehicleIndex: vehicleIndex,
      rideType: newRideType,
      clearSelectedPromo: true,
      clearUpdatedPriceDetail: true,
      clearRentalPackages: true,
      clearBidding: true,
    );

    // Re-fetch cards and re-check corporate if rideType changed
    if (rideTypeChanged) {
      debugPrint('🚗 ChooseRideViewModel - RideType changed from $previousRideType to $newRideType, re-fetching cards');
      getCards();
      _checkCorporateAvailability();
    }
    // Always re-check bidding after clearing (availability doesn't change per vehicle, only per rideType)
    _checkBiddingAvailability();

    // Fetch nearby drivers for selected vehicle type
    final vehicle = section.vehicles[vehicleIndex];
    final vehicleTypeId = vehicle.vehicleTypeId;
    final cityId = vehicle.cityId;
    if (vehicleTypeId != null && cityId != null) {
      _fetchNearbyDriversForVehicle(vehicleTypeId, cityId);
    }
  }

  /// Get currently selected vehicle (works in both modes)
  /// Uses filtered lists to match UI display
  NormalVehicles? get selectedVehicle {
    if (state.isShowingAllTypes) {
      // Sections mode - use filtered sections
      final filteredSections = state.filteredVehicleSections;
      if (filteredSections.isEmpty) return null;
      if (state.selectedSectionIndex >= filteredSections.length) return null;
      final section = filteredSections[state.selectedSectionIndex];
      if (state.selectedVehicleIndex >= section.vehicles.length) return null;
      return section.vehicles[state.selectedVehicleIndex];
    } else {
      // Single type mode - use filtered list
      final filteredList = state.filteredVehicleList;
      if (filteredList.isEmpty) return null;
      if (state.selectedIndex >= filteredList.length) return null;
      return filteredList[state.selectedIndex];
    }
  }

  /// Whether current selection is a rental vehicle
  bool get isRentalVehicleSelected => state.rideType == RideType.rental;

  /// Whether selected rental vehicle has packages
  bool get hasRentalPackages =>
      selectedVehicle?.packageList?.isNotEmpty == true;

  /// Get currently selected rental package
  RentalPack? get selectedRentalPackage {
    final packages = selectedVehicle?.packageList;
    if (packages == null || packages.isEmpty) return null;
    if (state.selectedPackageIndex >= packages.length) return null;
    return packages[state.selectedPackageIndex];
  }

  /// Get effective vehiclePriceId - uses package.id for rental with packages, vehicle.id otherwise
  String? get effectiveVehiclePriceId {
    if (isRentalVehicleSelected && hasRentalPackages && state.isShowingRentalPackages) {
      return selectedRentalPackage?.id;
    }
    return selectedVehicle?.id;
  }

  /// Show rental packages sub-step
  void showRentalPackages() {
    state = state.copyWith(
      isShowingRentalPackages: true,
      selectedPackageIndex: 0,
    );
  }

  /// Hide rental packages and go back to vehicle list
  void hideRentalPackages() {
    state = state.copyWith(clearRentalPackages: true);
  }

  /// Set selected rental package index
  void setSelectedPackageIndex(int index) {
    final packages = selectedVehicle?.packageList;
    if (packages == null || index < 0 || index >= packages.length) return;
    state = state.copyWith(
      selectedPackageIndex: index,
      clearSelectedPromo: true,
      clearUpdatedPriceDetail: true,
      clearBidding: true,
    );
    _checkBiddingAvailability();
  }

  /// Get total price for selected vehicle including accessibility amount
  double get selectedVehicleTotalPrice {
    final vehicle = selectedVehicle;
    if (vehicle == null) return 0.0;

    final basePrice = vehicle.priceDetail?.total ?? 0.0;
    final accessibilityAmount = _calculateAccessibilityAmount(
      vehicle.priceDetail?.accessibilityPrices,
      state.filtersResult?.selectedAccessibility,
    );
    return basePrice + accessibilityAmount;
  }

  /// Calculate total accessibility amount from selected accessibility prices
  double _calculateAccessibilityAmount(
    List<PriceData>? accessibilityPrices,
    List<String>? selectedIds,
  ) {
    if (accessibilityPrices == null || accessibilityPrices.isEmpty) return 0;
    if (selectedIds == null || selectedIds.isEmpty) return 0;

    double total = 0;
    for (final price in accessibilityPrices) {
      if (selectedIds.contains(price.chargeId)) {
        total += price.price ?? 0;
      }
    }
    return total;
  }

  /// Check if corporate booking is available based on business settings and entity typeIds
  /// Matches Kotlin's setTripOptions() corporate check
  void _checkCorporateAvailability() {
    final businessSettings = _getBusinessSettings();
    final allowCorporate = businessSettings?.contains(BookingSettingConstant.allowCorporateBooking) == true;

    if (!allowCorporate) {
      state = state.copyWith(isCorporateAvailable: false, isCorporateBooking: false);
      return;
    }

    // Check entity typeIds for approved corporate
    final entity = _sharedPref.getEntity();
    final typeIds = entity?.typeIds;
    if (typeIds == null || typeIds.isEmpty) {
      state = state.copyWith(isCorporateAvailable: false, isCorporateBooking: false);
      return;
    }

    for (final typeId in typeIds) {
      if (typeId.status == EntityTypeStatus.approve) {
        _corporateId = typeId.typeId ?? '';
        state = state.copyWith(isCorporateAvailable: true);
        debugPrint('🚗 ChooseRideViewModel - Corporate available, corporateId: $_corporateId');
        return;
      }
    }

    state = state.copyWith(isCorporateAvailable: false, isCorporateBooking: false);
  }

  /// Get booking settings list for current ride type (AllowCorporateBooking etc.)
  /// Note: bookingSetting (not businessSettings) contains these flags
  List<String>? _getBusinessSettings() {
    final businessSettings = state.vehicleTypeResponse?.citySetting?.bookingSetting;
    return switch (state.rideType) {
      RideType.normal => businessSettings?.normal,
      RideType.rental => businessSettings?.rental,
      RideType.sharing => businessSettings?.share,
      RideType.fixGroup => businessSettings?.fixGroupBooking,
      null => businessSettings?.normal,
    };
  }

  /// Toggle corporate booking on/off
  /// When corporate is selected: clear payment card (corporate pays)
  /// When corporate is deselected: restore default payment method (cash)
  void toggleCorporateBooking() {
    final isCurrentlySelected = state.isCorporateBooking;

    if (isCurrentlySelected) {
      // Deselecting corporate - restore cash payment
      final paymentSetting = _getVehiclePaymentType(state.vehicleTypeResponse);
      final isCash = paymentSetting?.isCash == true;
      final card = CardResponse(
        id: isCash ? PaymentGatewayType.cash.name : '',
        cardName: PaymentGatewayType.cash.getName(),
        paymentGatewayType: PaymentGatewayType.cash.value,
      );
      state = state.copyWith(
        selectedCard: card,
        isCorporateBooking: false,
        clearSelectedPromo: true,
      );
    } else {
      // Selecting corporate - clear payment card and promo
      state = state.copyWith(
        clearSelectedCard: true,
        isCorporateBooking: true,
        clearSelectedPromo: true,
      );
    }
  }

  /// Check if bidding is available for current ride type
  /// Reads from businessSettings (JSON key 'businessSetting'), same field as isFixFareAvailable
  /// Bidding is not available for destination-later bookings
  void _checkBiddingAvailability() {
    // Suppress bidding for destination-later or rental bookings (matching Kotlin behavior)
    if (state.isDestinationLater || isRentalVehicleSelected) {
      state = state.copyWith(clearBidding: true);
      return;
    }

    final businessSettings = state.vehicleTypeResponse?.citySetting?.businessSettings;
    debugPrint('🎯 _checkBiddingAvailability - businessSettings: $businessSettings, rideType: ${state.rideType}');
    if (businessSettings == null) {
      debugPrint('🎯 _checkBiddingAvailability - businessSettings is NULL, clearing bidding');
      state = state.copyWith(clearBidding: true);
      return;
    }

    final settingsList = switch (state.rideType) {
      RideType.normal => businessSettings.normal,
      RideType.rental => businessSettings.rental,
      RideType.sharing => businessSettings.share,
      RideType.fixGroup => businessSettings.fixGroupBooking,
      null => businessSettings.normal,
    };

    debugPrint('🎯 _checkBiddingAvailability - settingsList: $settingsList');
    // Two separate switches, and both have to be on. BIDDING in businessSetting
    // says the city runs bidding at all; bidSetting[type].isCustomerCanBid is
    // the admin toggle for whether the *customer* may bid. Only the first was
    // checked here, so turning the customer toggle off left the bid row on
    // screen. Native gates on isCustomerCanBid
    // (ChooseRideViewModel.kt: checkCustomerCanBid).
    final available = settingsList?.contains('BIDDING') == true &&
        currentBidSetting?.isCustomerCanBid == true;
    debugPrint('🎯 _checkBiddingAvailability - available: $available');
    if (!available) {
      state = state.copyWith(clearBidding: true);
      return;
    }
    state = state.copyWith(isBiddingAvailable: true);
  }

  /// Returns true if ShowNearestDriver is enabled for the current ride type's booking settings.
  /// Matches iOS: checks the selected ride type's bookingSetting list only.
  bool _isShowNearestDriverEnabled() {
    return _getBusinessSettings()?.contains(BookingSettingConstant.showNearestDriver) == true;
  }

  /// Fetch nearby drivers for all vehicle types (called after vehicle types load)
  /// Stores full list for initial map display

  /// Fetch nearby drivers for a specific vehicle type (called on vehicle selection)
  /// Clears existing markers immediately (matches iOS removeNearbyDriverMarker before API call),
  /// then replaces with result for the selected type.
  Future<void> _fetchNearbyDriversForVehicle(
      String vehicleTypeId, String cityId) async {
    if (!_isShowNearestDriverEnabled()) return;

    // Clear immediately so screen removes stale markers before new ones arrive
    state = state.copyWith(nearbyDrivers: const []);

    final pickup = state.pickupAddress;
    final request = FindNearestDriversRequest(
      cityId: cityId,
      vehicleTypeId: vehicleTypeId,
      bookingType: state.rideType?.value,
      pickupAddress: PickupAddress(
        latitude: pickup.latitude,
        longitude: pickup.longitude,
      ),
    );

    final response = await _appRepository.findNearestDrivers(request);
    if (response case Success<NearestDriversResponse>(data: final data)) {
      final drivers = data?.drivers ?? [];
      debugPrint('🚗 Nearby drivers (vehicleType=$vehicleTypeId): ${drivers.length}');
      state = state.copyWith(nearbyDrivers: drivers);

      // iOS fallback: if no nearby drivers found, fetch all drivers for time estimation
      if (drivers.isEmpty) {
        _fetchNearbyDriversForTimeEstimation(cityId);
      }
    }
  }

  /// Returns true if ShowDriverEstimation is enabled for current ride type.
  bool _isShowDriverEstimationEnabled() {
    return _getBusinessSettings()?.contains(BookingSettingConstant.showDriverEstimation) == true;
  }

  /// Fetches all nearby drivers (no vehicleTypeId filter), then calls the Google
  /// Routes Distance Matrix API to calculate estimated arrival time per vehicle type.
  /// Matches iOS wsFetchNearbyDriverForTimeEstimation + setDistanceMatrixData.
  Future<void> _fetchNearbyDriversForTimeEstimation(String cityId) async {
    final pickup = state.pickupAddress;
    if (pickup.latitude == null || pickup.longitude == null) return;

    // Step 1: Fetch all nearby drivers (no vehicleTypeId, no bookingType)
    final driversResponse = await _appRepository.findNearestDrivers(
      FindNearestDriversRequest(
        cityId: cityId,
        pickupAddress: PickupAddress(
          latitude: pickup.latitude,
          longitude: pickup.longitude,
        ),
      ),
    );

    List<NearestDriverItem> allDrivers = [];
    if (driversResponse case Success<NearestDriversResponse>(data: final d)) {
      allDrivers = d?.drivers ?? [];
    }
    if (allDrivers.isEmpty) return;

    // Step 2: Deduplicate by vehicleTypeId — one location per type (iOS logic)
    final Map<String, NearestDriverItem> uniqueByType = {};
    for (final driver in allDrivers) {
      final typeId = driver.vehicleTypeId;
      if (typeId != null && !uniqueByType.containsKey(typeId)) {
        uniqueByType[typeId] = driver;
      }
    }

    // Step 3: Build ordered destination list (index must match destinationIndex in response)
    final orderedEntries = uniqueByType.entries.toList();
    final destinations = <DistanceMatrixWaypoint>[];
    final indexToTypeId = <int, String>{};

    for (int i = 0; i < orderedEntries.length; i++) {
      final coords = orderedEntries[i].value.location?.coordinates;
      if (coords == null || coords.length < 2) continue;
      destinations.add(DistanceMatrixWaypoint(
        latitude: coords[1],  // GeoJSON: [lng, lat]
        longitude: coords[0],
      ));
      indexToTypeId[destinations.length - 1] = orderedEntries[i].key;
    }
    if (destinations.isEmpty) return;

    // Step 4: Get Google API key from app settings
    final apiKey = _sharedPref.getSetting()?.mapKey?.distanceMatrixApiKey ?? '';
    if (apiKey.isEmpty) {
      debugPrint('🚗 Distance matrix skipped: no API key');
      return;
    }

    // Step 5: Call distance matrix (origin = pickup, destinations = driver locations)
    final dmResponse = await _appRepository.getDistanceMatrix(
      DistanceMatrixRequest(
        origins: [DistanceMatrixWaypoint(
          latitude: pickup.latitude!,
          longitude: pickup.longitude!,
        )],
        destinations: destinations,
      ),
      apiKey: apiKey,
    );

    if (dmResponse case Success<List<RouteDistanceMatrix>>(data: final elements)) {
      if (elements == null || elements.isEmpty) return;

      // Step 6: Map destinationIndex → duration seconds
      final Map<String, int> driverDurations = {};
      for (final el in elements) {
        final typeId = indexToTypeId[el.destinationIndex ?? 0];
        if (typeId == null) continue;
        driverDurations[typeId] = el.durationSeconds;
      }

      // Step 7: Match to all vehicles (with fallback types), matching iOS setDistanceMatrixData
      final Map<String, int> vehicleDurations = {};
      for (final vehicle in _getAllVehicles()) {
        final vehicleTypeId = vehicle.vehicleTypeId;
        if (vehicleTypeId == null) continue;

        // Exact match
        if (driverDurations.containsKey(vehicleTypeId)) {
          vehicleDurations[vehicleTypeId] = driverDurations[vehicleTypeId]!;
          continue;
        }

        // Fallback types match (iOS: ride.vehicleTypeDetail?.fallbackTypes)
        for (final fallback in vehicle.vehicleTypeDetail?.fallbackTypes ?? []) {
          final fbId = fallback?.vehicleTypeId;
          if (fbId != null && driverDurations.containsKey(fbId)) {
            vehicleDurations[vehicleTypeId] = driverDurations[fbId]!;
            break;
          }
        }
      }

      debugPrint('🚗 Vehicle durations from distance matrix: $vehicleDurations');
      state = state.copyWith(vehicleDurations: vehicleDurations);
    }
  }

  /// All vehicles across all sections (or flat list in single-type mode)
  List<NormalVehicles> _getAllVehicles() {
    if (state.isShowingAllTypes) {
      return state.vehicleSections.expand((s) => s.vehicles).toList();
    }
    return state.vehicleList;
  }

  /// Get BidSettingInfo for current ride type from citySetting.bidSetting
  BidSettingInfo? get currentBidSetting {
    final bidSetting = state.vehicleTypeResponse?.citySetting?.bidSetting;
    if (bidSetting == null) return null;

    return switch (state.rideType) {
      RideType.normal => bidSetting.normal,
      RideType.rental => bidSetting.rental,
      RideType.sharing => bidSetting.share,
      RideType.fixGroup => bidSetting.fixGroupBooking,
      null => bidSetting.normal,
    };
  }

  /// Calculate minimum bid price based on bid settings
  /// Formula: total - (total * customerMinBid / 100)
  double calculateMinBidPrice(double totalPrice) {
    final minBidPercentage = currentBidSetting?.customerMinBid ?? 0;
    return totalPrice - (totalPrice * minBidPercentage / 100);
  }

  /// Toggle bidding on/off
  /// Returns true if the UI should show the BidRequestBottomSheet (isCustomerCanBid)
  bool toggleBidding() {
    if (state.isBidding) {
      removeBid();
      return false;
    }

    final isCustomerCanBid = currentBidSetting?.isCustomerCanBid == true;
    if (isCustomerCanBid) {
      // UI should show BidRequestBottomSheet
      return true;
    } else {
      // Auto-set bid to vehicle total price (no bottom sheet)
      final totalPrice = selectedVehicleTotalPrice;
      state = state.copyWith(
        isBidding: true,
        bidPrice: totalPrice,
      );
      return false;
    }
  }

  /// Confirm bid with the given amount
  void confirmBid(double amount) {
    state = state.copyWith(
      isBidding: true,
      bidPrice: amount,
    );
  }

  /// Remove bid and restore normal flow
  void removeBid() {
    state = state.copyWith(
      isBidding: false,
      bidPrice: null,
    );
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Get payment settings based on ride type
  VehicleTypePaymentSetting? _getVehiclePaymentType(GetVehicleTypeResponse? response) {
    final rideType = state.rideType;
    final paymentSetting = response?.citySetting?.paymentSetting;

    return switch (rideType) {
      RideType.normal => paymentSetting?.normal,
      RideType.rental => paymentSetting?.rental,
      RideType.sharing => paymentSetting?.share,
      RideType.fixGroup => paymentSetting?.fixGroupBooking,
      null => paymentSetting?.normal,
    };
  }

  /// Public getter for current vehicle payment settings (for payment screen navigation)
  VehicleTypePaymentSetting? get vehiclePaymentSetting =>
      _getVehiclePaymentType(state.vehicleTypeResponse);

  /// Update selected card (used when returning from payment screen)
  void setSelectedCard(CardResponse card) {
    state = state.copyWith(selectedCard: card);
  }

  /// Update filters result (used when returning from filter bottom sheet)
  /// Resets selection indices to avoid out-of-bounds after filtering
  void setFiltersResult(FiltersResult filters) {
    state = state.copyWith(
      filtersResult: filters,
      selectedIndex: 0,
      selectedSectionIndex: 0,
      selectedVehicleIndex: 0,
    );

    // Update rideType based on first filtered section (if in all types mode)
    if (state.isShowingAllTypes) {
      final filteredSections = state.filteredVehicleSections;
      if (filteredSections.isNotEmpty) {
        state = state.copyWith(rideType: filteredSections.first.rideType);
      }
    }
  }

  /// Clear all filters and reset selection
  void clearFilters() {
    state = state.copyWith(
      clearFiltersResult: true,
      selectedIndex: 0,
      selectedSectionIndex: 0,
      selectedVehicleIndex: 0,
    );

    // Update rideType based on first section (if in all types mode)
    if (state.isShowingAllTypes && state.vehicleSections.isNotEmpty) {
      state = state.copyWith(rideType: state.vehicleSections.first.rideType);
    }
  }

  /// Check if current selectedCard is still valid in new payment options
  /// If valid, keep it; otherwise call setDefaultPaymentMethod
  void _validateAndSetPaymentMethod(
    VehicleTypePaymentSetting? paymentSetting, [
    List<CardResponse>? cards,
  ]) {
    final currentCard = state.selectedCard;

    // If no current card, just set default
    if (currentCard == null) {
      setDefaultPaymentMethod();
      return;
    }

    // Check if current card is still valid
    bool isCurrentCardValid = false;

    // Check if it's cash
    if (currentCard.id == PaymentGatewayType.cash.name) {
      isCurrentCardValid = paymentSetting?.isCash == true;
    }
    // Check if it's wallet
    else if (currentCard.id == PaymentGatewayType.wallet.name) {
      isCurrentCardValid = paymentSetting?.isWallet == true;
    }
    // Check if it's a card from the list
    else if (cards != null) {
      isCurrentCardValid = cards.any((card) => card.id == currentCard.id);
    }

    // If current card is not valid in new options, set new default
    if (!isCurrentCardValid) {
      debugPrint('🚗 ChooseRideViewModel - Current selectedCard not valid, setting new default');
      setDefaultPaymentMethod();
    } else {
      debugPrint('🚗 ChooseRideViewModel - Current selectedCard still valid, keeping it');
    }
  }

  /// Set default payment method based on available options
  /// Sets selectedCard to null if nothing is available
  void setDefaultPaymentMethod() {
    final paymentSetting = _getVehiclePaymentType(state.vehicleTypeResponse);
    final isCashAvailable = paymentSetting?.isCash == true;
    final isWalletAvailable = paymentSetting?.isWallet == true;

    CardResponse? paymentMethod;

    if (state.defaultCard != null) {
      paymentMethod = CardResponse(
        id: state.defaultCard?.id,
        cardName: state.defaultCard?.cardName,
        paymentGatewayType: state.defaultCard?.paymentGatewayType,
      );
    } else if (isCashAvailable) {
      paymentMethod = CardResponse(
        id: PaymentGatewayType.cash.name,
        cardName: PaymentGatewayType.cash.getName(),
        paymentGatewayType: PaymentGatewayType.cash.value,
      );
    } else if (isWalletAvailable) {
      paymentMethod = CardResponse(
        id: PaymentGatewayType.wallet.name,
        cardName: PaymentGatewayType.wallet.getName(),
        paymentGatewayType: PaymentGatewayType.wallet.value,
      );
    }

    // Set selectedCard (null if nothing available - UI handles null by hiding)
    state = state.copyWith(
      selectedCard: paymentMethod,
      clearSelectedCard: paymentMethod == null,
    );
  }

  /// Load available cards based on payment gateways for current ride type
  /// If current selectedCard is still valid, keeps it; otherwise sets new default
  Future<void> getCards() async {
    final paymentSetting = _getVehiclePaymentType(state.vehicleTypeResponse);
    final paymentGateways = paymentSetting?.paymentGateways;

    // Build comma-separated string of payment gateway types
    final paymentGatewayTypes = paymentGateways
            ?.where((g) => g != null)
            .map((g) => g.toString())
            .join(',') ??
        '';

    // Get country ID from shared preferences
    final countryId = _sharedPref.getEntity()?.countryId ?? '';

    // If no gateways or countryId, clear defaultCard and set payment method
    if (paymentGatewayTypes.isEmpty || countryId.isEmpty) {
      debugPrint('🔴 ChooseRideViewModel - No payment gateways or country ID');
      state = state.copyWith(clearDefaultCard: true);
      _validateAndSetPaymentMethod(paymentSetting);
      return;
    }

    debugPrint('🚗 ChooseRideViewModel - Loading cards for paymentGateways: $paymentGatewayTypes');

    try {
      final response = await _appRepository.getCards(
        countryId: countryId,
        paymentGatewayTypes: paymentGatewayTypes,
      );

      switch (response) {
        case Success<GetCardsResponse>(data: final data):
          final cards = data?.cards ?? [];
          debugPrint('🚗 ChooseRideViewModel - Loaded ${cards.length} cards');

          // Find default card
          CardResponse? defaultCard;
          for (final card in cards) {
            if (card.isDefault == true) {
              defaultCard = card.copyWith(
                cardName: '${card.cardType ?? ''}**** ${card.lastFour}',
              );
              break;
            }
          }

          state = state.copyWith(defaultCard: defaultCard);
          _validateAndSetPaymentMethod(paymentSetting, cards);

        case Error<GetCardsResponse>(error: final error):
          debugPrint('🔴 ChooseRideViewModel - Error loading cards: ${error?.message}');
          state = state.copyWith(clearDefaultCard: true);
          _validateAndSetPaymentMethod(paymentSetting);

        case Loading<GetCardsResponse>():
          break;
      }
    } catch (e) {
      debugPrint('🔴 ChooseRideViewModel - Exception loading cards: $e');
      state = state.copyWith(clearDefaultCard: true);
      state = state.copyWith(defaultCard: null);
      _validateAndSetPaymentMethod(paymentSetting);
    }
  }

  /// Set booking time (used when entering section 2)
  void setBookingTime(int? bookingTime) {
    state = state.copyWith(bookingTime: bookingTime);
  }

  /// Set selected promo and call fare estimate
  void setSelectedPromo(PromoDetail? promoDetail) {
    if (promoDetail == null) return;

    // Format promo applied string
    final countrySetting = state.vehicleTypeResponse?.countrySetting;
    final decimalPointValue = countrySetting?.decimalPointValue ?? 2;
    final currencySign = countrySetting?.currencySign ?? '';

    String amount;
    if (promoDetail.discountType == 1) {
      // Fixed amount
      amount = '$currencySign${promoDetail.discount?.toStringAsFixed(decimalPointValue) ?? '0'}';
    } else {
      // Percentage
      amount = '${promoDetail.discount?.toStringAsFixed(0) ?? '0'}%';
    }

    final updatedPromo = PromoDetail(
      id: promoDetail.id,
      code: promoDetail.code,
      discount: promoDetail.discount,
      discountType: promoDetail.discountType,
      promoBonus: promoDetail.promoBonus,
      promoAppliedStr: 'Promo code applied! You saved $amount',
    );

    state = state.copyWith(selectedPromo: updatedPromo);
    getFareEstimate();
  }

  /// Remove selected promo and call fare estimate
  void removePromo() {
    state = state.copyWith(clearSelectedPromo: true);
    getFareEstimate();
  }

  /// Called when payment method changes - clears promo and calls fare estimate
  void onPaymentMethodChanged(CardResponse card) {
    state = state.copyWith(
      selectedCard: card,
      clearSelectedPromo: true,
    );
    getFareEstimate();
  }

  /// Get fare estimate from API
  Future<void> getFareEstimate() async {
    final vehicle = selectedVehicle;
    if (vehicle == null) return;

    state = state.copyWith(isFareLoading: true);

    final bookingTime = state.bookingTime ?? DateTime.now().millisecondsSinceEpoch;

    // Get selected accessibility IDs
    final selectedAccessibilityIds = state.filtersResult?.selectedAccessibility ?? [];

    final request = FareEstimateRequest(
      countryCode: state.pickupAddress.countryCode,
      vehiclePriceId: effectiveVehiclePriceId,
      businessType: BusinessType.taxi,
      priceMode: state.rideType?.value,
      pickupAddress: state.pickupAddress,
      destinationAddresses: state.destinations,
      promoCodeId: state.selectedPromo?.id,
      bookingTime: bookingTime,
      paymentMode: state.selectedCard?.paymentGatewayType,
      accessibilityIds: selectedAccessibilityIds.isNotEmpty ? selectedAccessibilityIds : null,
    );

    debugPrint('🚗 ChooseRideViewModel - Getting fare estimate with promoCodeId: ${state.selectedPromo?.id}');

    try {
      final response = await _appRepository.getFareEstimate(request);

      switch (response) {
        case Success<FareEstimateResponse>(data: final data):
          debugPrint('🚗 ChooseRideViewModel - Fare estimate success');
          state = state.copyWith(
            isFareLoading: false,
            updatedPriceDetail: data?.priceDetail,
          );

        case Error<FareEstimateResponse>(error: final error):
          debugPrint('🔴 ChooseRideViewModel - Fare estimate error: ${error?.message}');
          state = state.copyWith(isFareLoading: false);

        case Loading<FareEstimateResponse>():
          break;
      }
    } catch (e) {
      debugPrint('🔴 ChooseRideViewModel - Fare estimate exception: $e');
      state = state.copyWith(isFareLoading: false);
    }
  }

  /// Get current price detail (updated from fare estimate or original from vehicle/package)
  InvoiceDetail? get currentPriceDetail {
    if (state.updatedPriceDetail != null) return state.updatedPriceDetail;
    if (isRentalVehicleSelected && hasRentalPackages && state.isShowingRentalPackages) {
      return selectedRentalPackage?.priceDetail;
    }
    return selectedVehicle?.priceDetail;
  }

  /// Get total price including promo discount
  double get totalPriceWithPromo {
    final priceDetail = currentPriceDetail;
    if (isRentalVehicleSelected && hasRentalPackages && state.isShowingRentalPackages) {
      final basePrice = priceDetail?.total ?? selectedRentalPackage?.priceDetail?.total ?? 0.0;
      final accessibilityAmount = _calculateAccessibilityAmount(
        selectedRentalPackage?.priceDetail?.accessibilityPrices,
        state.filtersResult?.selectedAccessibility,
      );
      return basePrice + accessibilityAmount;
    }
    if (priceDetail?.total != null) return priceDetail!.total!;
    return selectedVehicleTotalPrice;
  }

  /// Get surge unit from price charges if surge pricing is active
  /// Returns null if no surge pricing
  double? get surgeUnit {
    final priceDetail = currentPriceDetail;
    if (priceDetail == null) return null;

    // Check in charges for surge price
    final surgeCharge = priceDetail.charges?.firstWhere(
      (charge) => charge.title == PriceType.surgePrice,
      orElse: () => PriceData(),
    );

    if (surgeCharge?.title == PriceType.surgePrice) {
      return surgeCharge?.unit;
    }

    return null;
  }

  /// Check if fix fare is available for current ride type
  /// Fix fare is not available for destination-later or rental bookings
  bool get isFixFareAvailable {
    if (state.isDestinationLater) return false;
    if (isRentalVehicleSelected) return false;

    final businessSettings = state.vehicleTypeResponse?.citySetting?.businessSettings;
    if (businessSettings == null) return false;

    final settingsList = switch (state.rideType) {
      RideType.normal => businessSettings.normal,
      RideType.rental => businessSettings.rental,
      RideType.sharing => businessSettings.share,
      RideType.fixGroup => businessSettings.fixGroupBooking,
      null => businessSettings.normal,
    };

    return settingsList?.contains('FIX_FARE') == true;
  }

  /// Get user's wallet balance (credit)
  double get walletBalance {
    final entity = _sharedPref.getEntity();
    return entity?.credit ?? 0.0;
  }

  /// Check if wallet has sufficient balance for the ride
  bool get hasInsufficientWalletBalance {
    final selectedCard = state.selectedCard;
    if (selectedCard?.id != PaymentGatewayType.wallet.name) return false;

    return walletBalance < totalPriceWithPromo;
  }

  /// Create booking with the selected vehicle and options
  /// Returns CreateBookingResponse on success, null on error
  Future<CreateBookingResponse?> createBooking({
    bool isFixFare = false,
    RideForOtherResult? rideForOtherResult,
  }) async {
    final vehicle = selectedVehicle;
    if (vehicle == null) {
      showSnackBar('No vehicle selected', isError: true);
      return null;
    }

    state = state.copyWith(
      isCreatingBooking: true,
      clearCreateBookingResponse: true,
    );

    try {
      final bookingTime = state.bookingTime ?? DateTime.now().millisecondsSinceEpoch;
      final selectedAccessibilityIds = state.filtersResult?.selectedAccessibility;
      final selectedLanguages = state.filtersResult?.selectedLanguage;
      final selectedGender = state.filtersResult?.selectedGender.firstOrNull;

      // Get card ID if using a payment card (not cash/wallet)
      String? cardId;
      final selectedCard = state.selectedCard;
      if (selectedCard != null &&
          selectedCard.id != PaymentGatewayType.cash.name &&
          selectedCard.id != PaymentGatewayType.wallet.name) {
        cardId = selectedCard.id;
      }

      final isBookForOther = rideForOtherResult != null && !rideForOtherResult.isForMe;
      final trimmedDriverMessage = state.driverMessage.trim();

      final request = CreateBookingRequest(
        bookingTime: bookingTime,
        bookingType: state.rideType?.value,
        businessType: BusinessType.taxi,
        paymentMode: state.isCorporateBooking
            ? PaymentGatewayType.cash.value
            : selectedCard?.paymentGatewayType,
        cardId: state.isCorporateBooking ? null : cardId,
        pickupAddress: state.pickupAddress,
        destinationAddresses: state.destinations,
        vehiclePriceId: effectiveVehiclePriceId,
        isFixFare: isFixFare || state.isBidding,
        isBidding: state.isBidding,
        bidPrice: state.isBidding ? state.bidPrice : null,
        promoCodeId: state.selectedPromo?.id,
        accessibilityIds: selectedAccessibilityIds?.isNotEmpty == true ? selectedAccessibilityIds : null,
        speakingLanguages: selectedLanguages?.isNotEmpty == true ? selectedLanguages : null,
        customerNote: trimmedDriverMessage.isNotEmpty ? trimmedDriverMessage : null,
        preferredGender: selectedGender,
        corporateId: state.isCorporateBooking ? _corporateId : null,
        isBookForOther: isBookForOther ? true : null,
        customerDetail: isBookForOther ? rideForOtherResult.toCustomerDetail() : null,
        // Route/estimate data — sent to match the native iOS app.
        estimatedTime: state.vehicleTypeResponse?.time ?? 0,
        estimatedDistance: state.vehicleTypeResponse?.distance ?? 0,
        directionPath: state.vehicleTypeResponse?.directionPath ?? '',
        isApplePay: false,
      );

      debugPrint('🚗 ChooseRideViewModel - Creating booking with isFixFare: $isFixFare');

      final response = await _appRepository.createBooking(request);

      switch (response) {
        case Success<CreateBookingResponse>(data: final data, :final message):
          debugPrint('🚗 ChooseRideViewModel - Booking created successfully: $message');
          // API may return just {"message": "..."} without data field
          // In that case, create an empty response object to indicate success
          final responseData = data ?? CreateBookingResponse();
          state = state.copyWith(
            isCreatingBooking: false,
            createBookingResponse: responseData,
          );
          if (message != null) {
            showSnackBar(message);
          }
          return responseData;

        case Error<CreateBookingResponse>(error: final error):
          debugPrint('🔴 ChooseRideViewModel - Booking error: ${error?.message}');
          state = state.copyWith(isCreatingBooking: false);
          showSnackBar(error?.message ?? 'Failed to create booking', isError: true);
          return null;

        case Loading<CreateBookingResponse>():
          return null;
      }
    } catch (e) {
      debugPrint('🔴 ChooseRideViewModel - Booking exception: $e');
      state = state.copyWith(isCreatingBooking: false);
      showSnackBar(e.toString(), isError: true);
      return null;
    }
  }

  /// Show snackbar message
  void showSnackBar(String message, {bool isError = false}) {
    state = state.copyWith(
      snackBarMessage: message,
      isSnackBarError: isError,
    );
  }

  /// Clear snackbar message
  void clearSnackBar() {
    state = state.copyWith(clearSnackBar: true);
  }

  /// Update the optional note sent to the driver with the booking request.
  void updateDriverMessage(String value) {
    state = state.copyWith(driverMessage: value);
  }
}

/// Provider for ChooseRideViewModel
final chooseRideViewModelProvider = StateNotifierProvider.autoDispose
    .family<ChooseRideViewModel, ChooseRideState, ChooseRideParams>(
  (ref, params) {
    final appRepository = ref.watch(appRepositoryProvider);
    final sharedPref = ref.watch(sharedPreferenceManagerProvider).maybeWhen(
          data: (data) => data,
          orElse: () => throw Exception('SharedPreferences not initialized'),
        );

    return ChooseRideViewModel(appRepository, sharedPref, params);
  },
);
