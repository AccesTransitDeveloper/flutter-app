import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/router/app_navigation.dart';
import '../../../core/map/interface/map_interface.dart';
import '../../../core/map/widgets/map_host.dart';
import '../../../core/map/models/map_types.dart';
import '../../../core/map/providers/map_provider.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../models/requests/get_vehicle_types_request.dart';
import '../../../models/requests/promo_code_list_request.dart';
import '../../../models/responses/booking/get_vehicle_type_response.dart';
import '../../../models/responses/booking/nearest_drivers_response.dart';
import '../../../models/responses/payment/card_response.dart';
import '../../../data/api/server_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../viewmodels/choose_ride_viewmodel.dart';
import '../../../viewmodels/main_viewmodel.dart';
import '../../../views/widgets/app_button.dart';
import '../../../views/widgets/app_scaffold.dart';
import '../../../views/widgets/app_text.dart';
import '../../bottomsheets/accessibility_filter_bottom_sheet.dart';
import '../../bottomsheets/bid_request_bottom_sheet.dart';
import '../../bottomsheets/fixed_rate_bottom_sheet.dart';
import '../../../models/ride_for_other_result.dart';
import '../../bottomsheets/schedule_ride_bottom_sheet.dart';
import '../../bottomsheets/surge_pricing_bottom_sheet.dart';
import '../../item/schedule_picker_segment.dart';
import 'choose_ride_select_vehicle.dart';
import 'choose_ride_select_package.dart';
import 'choose_ride_confirm_details.dart';
import 'choose_ride_confirm_pickup.dart';

/// Steps in the Choose Ride flow
enum ChooseRideStep { selectVehicle, confirmDetails, confirmPickup }

class ChooseRideScreen extends ConsumerStatefulWidget {
  final DestinationAddress pickupAddress;
  final List<DestinationAddress> destinations;
  final RideType? rideType;
  final CitySetting? citySetting;
  final ScheduleRideResult? scheduleResult;
  final String? selectedVehicleTypeId;
  final bool isDestinationLater;
  final RideForOtherResult? rideForOtherResult;

  const ChooseRideScreen({
    super.key,
    required this.pickupAddress,
    required this.destinations,
    this.rideType,
    this.citySetting,
    this.scheduleResult,
    this.selectedVehicleTypeId,
    this.isDestinationLater = false,
    this.rideForOtherResult,
  });

  @override
  ConsumerState<ChooseRideScreen> createState() => _ChooseRideScreenState();
}

class _ChooseRideScreenState extends ConsumerState<ChooseRideScreen>
    with WidgetsBindingObserver {
  late final MapInterface _mapManager;
  late final ChooseRideParams _params;
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  final TextEditingController _driverMessageController = TextEditingController();

  // Current step in the flow
  ChooseRideStep _currentStep = ChooseRideStep.selectVehicle;

  // Schedule state
  ScheduleRideResult? _scheduleResult;

  DriverSettings? get _driverSettings => widget.citySetting?.driverSetting;
  BusinessSettings? get _businessSettings => widget.citySetting?.businessSettings;

  /// Check if schedule is available for given ride type using BusinessSettings
  bool _isScheduleAvailable(RideType? rideType) {
    return SchedulePickerSegment.isScheduleAvailableFromBusiness(
      rideType: rideType,
      businessSettings: _businessSettings,
    );
  }

  /// Check if NOW is available for given ride type using BusinessSettings
  bool _isNowAvailable(RideType? rideType) {
    return SchedulePickerSegment.isNowAvailableFromBusiness(
      rideType: rideType,
      businessSettings: _businessSettings,
    );
  }

  @override
  void initState() {
    super.initState();
    _mapManager = ref.read(mapManagerProvider)();
    _params = ChooseRideParams(
      pickupAddress: widget.pickupAddress,
      destinations: widget.destinations,
      rideType: widget.rideType,
      selectedVehicleTypeId: widget.selectedVehicleTypeId,
      isDestinationLater: widget.isDestinationLater,
    );

    // Add lifecycle observer
    WidgetsBinding.instance.addObserver(this);

    // Initialize schedule result from widget parameter
    _scheduleResult = widget.scheduleResult;

    // Load vehicle types on init and listen for changes to update map
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadVehicleTypes();
    });
  }

  bool _mapUpdated = false;

  /// Called when state changes to update map
  void _checkAndUpdateMap(ChooseRideState state) {
    if (_mapUpdated) return;

    // For destination-later: show pickup marker once vehicle data is loaded
    if (state.isDestinationLater && state.vehicleTypeResponse != null) {
      _mapUpdated = true;
      _showPickupOnMap(state);
      return;
    }

    final directionPath = state.vehicleTypeResponse?.directionPath;
    if (directionPath != null && directionPath.isNotEmpty) {
      _mapUpdated = true;
      _updateMapWithRoute(state);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sheetController.dispose();
    _driverMessageController.dispose();
    _mapManager.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // App came to foreground - reload vehicle types
      _loadVehicleTypes();
    }
  }

  void _loadVehicleTypes() {
    final viewModel = ref.read(chooseRideViewModelProvider(_params).notifier);
    viewModel.loadVehicleTypes();
  }

  /// Show only the pickup marker on map (for destination-later bookings)
  void _showPickupOnMap(ChooseRideState state) {
    final pickup = state.pickupAddress;
    if (pickup.latitude == null || pickup.longitude == null) return;

    final primaryColor = context.colors.colorPrimary.toARGB32();
    final pos = LatLng(pickup.latitude!, pickup.longitude!);

    _mapManager.setMarkers([
      MapMarker(
        id: 'pickup',
        position: pos,
        title: 'Pickup',
        snippet: pickup.title ?? pickup.address,
        iconAsset: 'assets/images/ic_pickup.png',
        iconWidth: 32,
        iconHeight: 32,
        iconColor: primaryColor,
      ),
    ]);

    final screenHeight = MediaQuery.of(context).size.height;
    _mapManager.setMapPadding(
      EdgeInsets.only(bottom: screenHeight * 0.45),
    );
    Future.delayed(const Duration(milliseconds: 300), () {
      _mapManager.fitBounds([pos], padding: 80);
    });
  }

  /// Zoom map to pickup location and show info window (for confirm pickup step)
  void _zoomToPickup(ChooseRideState state) {
    final pickup = state.pickupAddress;
    if (pickup.latitude == null || pickup.longitude == null) return;

    final pos = LatLng(pickup.latitude!, pickup.longitude!);
    final screenHeight = MediaQuery.of(context).size.height;
    _mapManager.setMapPadding(
      EdgeInsets.only(bottom: screenHeight * 0.35),
    );
    Future.delayed(const Duration(milliseconds: 300), () {
      _mapManager.fitBounds([pos], padding: 80);
      _mapManager.showMarkerInfoWindow('pickup');
    });
  }

  /// Update nearby driver markers on map from state.
  /// Uses the selected vehicle type's mapPinUrl (same pin for all drivers of that type),
  /// matching iOS behavior: strVehicleMapPinUrl applied to every driver marker.
  void _updateNearbyDriverMarkers(List<NearestDriverItem> drivers) {
    _mapManager.removeNearbyDriverMarkers();
    if (drivers.isEmpty) return;

    // Use vehicle type's mapPinUrl (relative) → full URL, fallback to local asset
    final vm = ref.read(chooseRideViewModelProvider(_params).notifier);
    final rawPinUrl = vm.selectedVehicle?.vehicleTypeDetail?.mapPinUrl;
    final iconUrl = rawPinUrl != null && rawPinUrl.isNotEmpty
        ? ServerConfig.getFullImageUrl(rawPinUrl)
        : null;

    final markers = drivers.map((driver) {
      final coords = driver.location?.coordinates;
      if (coords == null || coords.length < 2) return null;
      final driverId = driver.id ?? driver.socketId ?? '${driver.uniqueId}';
      return MapMarker(
        id: 'driver_$driverId',
        position: LatLng(coords[1], coords[0]), // GeoJSON: [lng, lat]
        iconUrl: iconUrl,
        iconAsset: 'assets/images/ic_car_pin.png',
        iconWidth: 40,
        iconHeight: 40,
      );
    }).whereType<MapMarker>().toList();

    _mapManager.addNearbyDriverMarkers(markers);
  }

  /// Update map with route polyline and markers
  void _updateMapWithRoute(ChooseRideState state) {
    final directionPath = state.vehicleTypeResponse?.directionPath;
    if (directionPath == null || directionPath.isEmpty) return;

    // Get primary color from theme
    final primaryColor = context.colors.colorPrimary.toARGB32();

    // Draw polyline from encoded string
    _mapManager.setPolyline(MapPolyline.fromEncoded(
      encoded: directionPath,
      color: primaryColor,
    ));

    // Create markers for pickup and destinations
    final markers = <MapMarker>[];

    // Pickup marker
    final pickup = state.pickupAddress;
    if (pickup.latitude != null && pickup.longitude != null) {
      markers.add(MapMarker(
        id: 'pickup',
        position: LatLng(pickup.latitude!, pickup.longitude!),
        title: 'Pickup',
        snippet: pickup.title ?? pickup.address,
        iconAsset: 'assets/images/ic_pickup.png',
        iconWidth: 32,
        iconHeight: 32,
        iconColor: primaryColor,
      ));
    }

    // Destination markers
    final destinations = state.destinations;
    final lastIndex = destinations.length - 1;
    for (int i = 0; i < destinations.length; i++) {
      final dest = destinations[i];
      if (dest.latitude == null || dest.longitude == null) continue;

      if (i == lastIndex) {
        // Final destination
        markers.add(MapMarker(
          id: 'destination_$i',
          position: LatLng(dest.latitude!, dest.longitude!),
          title: 'Destination',
          snippet: dest.title ?? dest.address,
          iconAsset: 'assets/images/ic_drop_off.png',
          iconWidth: 32,
          iconHeight: 32,
          iconColor: primaryColor,
        ));
      } else {
        // Intermediate stop
        markers.add(MapMarker(
          id: 'stop_$i',
          position: LatLng(dest.latitude!, dest.longitude!),
          title: '',
          snippet: dest.title ?? dest.address,
          stopNumber: i + 1,
          iconColor: primaryColor,
        ));
      }
    }

    _mapManager.setMarkers(markers);

    // Fit camera to show all points
    final boundsPoints = <LatLng>[];
    if (pickup.latitude != null && pickup.longitude != null) {
      boundsPoints.add(LatLng(pickup.latitude!, pickup.longitude!));
    }
    for (final dest in destinations) {
      if (dest.latitude != null && dest.longitude != null) {
        boundsPoints.add(LatLng(dest.latitude!, dest.longitude!));
      }
    }
    if (boundsPoints.isNotEmpty) {
      // Set bottom padding to account for the bottom sheet (~45% of screen)
      final screenHeight = MediaQuery.of(context).size.height;
      _mapManager.setMapPadding(
        EdgeInsets.only(bottom: screenHeight * 0.45),
      );
      // Delay fitBounds so the map processes the padding change first.
      // 48 is breathing room around the pickup/destination pins — Mapbox fits
      // the bounds inside this inset, so the pins stay on screen while the
      // route sits closer than the old 80 allowed.
      Future.delayed(const Duration(milliseconds: 300), () {
        _mapManager.fitBounds(boundsPoints, padding: 48);
      });
    }
  }

  /// Check if there are any vehicles available (in either mode)
  bool _hasVehicles(ChooseRideState state) {
    if (state.isShowingAllTypes) {
      return state.filteredVehicleSections.isNotEmpty;
    }
    return state.filteredVehicleList.isNotEmpty;
  }

  /// Handle back button press based on current step
  void _handleBackPress() {
    if (_currentStep == ChooseRideStep.confirmPickup) {
      // Go back to confirm details
      setState(() {
        _currentStep = ChooseRideStep.confirmDetails;
      });
    } else if (_currentStep == ChooseRideStep.confirmDetails) {
      // Go back to vehicle selection
      setState(() {
        _currentStep = ChooseRideStep.selectVehicle;
      });
    } else {
      // If showing rental packages, go back to vehicle list
      final state = ref.read(chooseRideViewModelProvider(_params));
      if (state.isShowingRentalPackages) {
        final viewModel = ref.read(chooseRideViewModelProvider(_params).notifier);
        viewModel.hideRentalPackages();
        return;
      }
      // Exit the screen
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chooseRideViewModelProvider(_params));

    ref.listen<ChooseRideState>(
      chooseRideViewModelProvider(_params),
      (previous, next) {
        if (previous?.nearbyDrivers != next.nearbyDrivers) {
          _updateNearbyDriverMarkers(next.nearbyDrivers);
        }
      },
    );

    final canExitScreen =
        _currentStep == ChooseRideStep.selectVehicle && !state.isShowingRentalPackages;

    return PopScope(
      canPop: canExitScreen,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackPress();
      },
      child: AppScaffold(
        body: Stack(
          children: [
          // Layer 1: Map (StatefulBuilder handled internally by manager)
          // Non-interactive in confirmPickup step
          Positioned.fill(
            child: IgnorePointer(
              ignoring: _currentStep == ChooseRideStep.confirmPickup,
              child: MapHost(manager: _mapManager),
            ),
          ),

          // Layer 2: Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + AppDimens.paddingM,
            left: AppDimens.padding,
            child: AppBackButton(
              onPressed: _handleBackPress,
            ),
          ),

          // Layer 3: Filter button (only show in vehicle selection step, hide during rental packages)
          if (_currentStep == ChooseRideStep.selectVehicle)
            Consumer(
              builder: (context, ref, child) {
                final state = ref.watch(chooseRideViewModelProvider(_params));
                if (state.isShowingRentalPackages) return const SizedBox.shrink();
                return Positioned(
                  top: MediaQuery.of(context).padding.top + AppDimens.paddingM,
                  right: AppDimens.padding,
                  child: AppFilterButton(
                    hasActiveFilters: state.filtersResult?.hasFilters ?? false,
                    filterCount: state.filtersResult?.filterCount ?? 0,
                    onPressed: () => _showFilterBottomSheet(state),
                  ),
                );
              },
            ),

          // Layer 4: Bottom content based on current step
          Consumer(
            builder: (context, ref, child) {
              // Update map when direction path is available
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _checkAndUpdateMap(state);
              });

              // Step 1: Vehicle Selection - DraggableScrollableSheet
              if (_currentStep == ChooseRideStep.selectVehicle) {
                return DraggableScrollableSheet(
                  controller: _sheetController,
                  initialChildSize: 0.45,
                  minChildSize: 0.45,
                  maxChildSize: 0.85,
                  snap: true,
                  snapSizes: const [0.45, 0.85],
                  builder: (context, scrollController) {
                    return _buildSheetContent(scrollController, state);
                  },
                );
              }

              // Step 2: Confirm Details - Static bottom container
              if (_currentStep == ChooseRideStep.confirmDetails) {
                return _buildConfirmDetailsContent(state);
              }

              // Step 3: Confirm Pickup - Static bottom container
              return _buildConfirmPickupContent(state);
            },
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildSheetContent(
      ScrollController scrollController, ChooseRideState state) {
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.colorBackground,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Segment 1: Vehicle Selection or Rental Package Selection
          Expanded(
            child: state.isShowingRentalPackages
                ? ChooseRideSelectPackage(
                    vehicle: ref.read(chooseRideViewModelProvider(_params).notifier).selectedVehicle!,
                    packageList: ref.read(chooseRideViewModelProvider(_params).notifier).selectedVehicle?.packageList ?? [],
                    selectedPackageIndex: state.selectedPackageIndex,
                    currencySign: state.currencySign,
                    countrySetting: state.vehicleTypeResponse?.countrySetting,
                    customPrices: state.vehicleTypeResponse?.customPrices,
                    accessibilities: state.vehicleTypeResponse?.accessibilities,
                    selectedAccessibilityIds: state.filtersResult?.selectedAccessibility,
                    scrollController: scrollController,
                    sheetController: _sheetController,
                    onPackageSelected: (index) {
                      final viewModel =
                          ref.read(chooseRideViewModelProvider(_params).notifier);
                      viewModel.setSelectedPackageIndex(index);
                    },
                    onBack: () {
                      final viewModel =
                          ref.read(chooseRideViewModelProvider(_params).notifier);
                      viewModel.hideRentalPackages();
                    },
                  )
                : ChooseRideSelectVehicle(
                    vehicleList: state.filteredVehicleList,
                    vehicleSections: state.filteredVehicleSections,
                    isShowingAllTypes: state.isShowingAllTypes,
                    selectedIndex: state.selectedIndex,
                    selectedSectionIndex: state.selectedSectionIndex,
                    selectedVehicleIndex: state.selectedVehicleIndex,
                    currencySign: state.currencySign,
                    countrySetting: state.vehicleTypeResponse?.countrySetting,
                    customPrices: state.vehicleTypeResponse?.customPrices,
                    accessibilities: state.vehicleTypeResponse?.accessibilities,
                    selectedAccessibilityIds: state.filtersResult?.selectedAccessibility,
                    isDestinationLater: state.isDestinationLater,
                    rideType: state.rideType,
                    vehicleDurations: state.vehicleDurations,
                    isLoading: state.isLoading,
                    error: state.error,
                    scrollController: scrollController,
                    sheetController: _sheetController,
                    onVehicleSelected: (index) {
                      final viewModel =
                          ref.read(chooseRideViewModelProvider(_params).notifier);
                      viewModel.setSelectedIndex(index);
                    },
                    onSectionVehicleSelected: (sectionIndex, vehicleIndex) {
                      final viewModel =
                          ref.read(chooseRideViewModelProvider(_params).notifier);
                      viewModel.setSelectedSectionVehicle(sectionIndex, vehicleIndex);
                    },
                    onRetry: _loadVehicleTypes,
                  ),
          ),

          // Bottom area (fixed at bottom of sheet) - only show if vehicles available
          if (_hasVehicles(state))
            SafeArea(
              top: false,
              child: Builder(
                builder: (context) {
                  final viewModel = ref.read(chooseRideViewModelProvider(_params).notifier);
                  final vehicleName = state.isShowingRentalPackages
                      ? viewModel.selectedRentalPackage?.packageName ?? ''
                      : viewModel.selectedVehicle?.vehicleTypeDetail?.name ?? '';
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Corporate toggle option
                      if (state.isCorporateAvailable)
                        _buildCorporateToggle(colors, state.isCorporateBooking),

                      // Divider above payment (full width, no padding)
                      if (state.selectedCard != null && !state.isCorporateBooking)
                        Divider(
                          color: colors.colorBackgroundGray,
                          height: 1,
                          thickness: 1,
                        ),

                      Padding(
                        padding: const EdgeInsets.only(
                          left: AppDimens.padding,
                          right: AppDimens.padding,
                          bottom: AppDimens.padding,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Payment Selection - hide when corporate is selected
                            if (state.selectedCard != null && !state.isCorporateBooking)
                              _buildPaymentRow(colors, state.selectedCard!),

                            // Choose button with vehicle name and optional schedule button
                            Row(
                              children: [
                                Expanded(
                                  child: AppFilledButton(
                                    text: 'Choose $vehicleName',
                                    enabled: !state.isLoading,
                                    onPressed: () => _onChoosePressed(state.rideType),
                                  ),
                                ),
                                if (_isScheduleAvailable(state.rideType)) ...[
                                  const SizedBox(width: AppDimens.paddingM),
                                  GestureDetector(
                                    onTap: () => _showScheduleBottomSheet(state.rideType),
                                    child: Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: colors.colorBackgroundGray,
                                        borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
                                      ),
                                      child: Icon(
                                        _scheduleResult?.isNow ?? _isNowAvailable(state.rideType)
                                            ? Icons.access_time
                                            : Icons.calendar_today_outlined,
                                        color: colors.colorButtonBackground,
                                        size: AppDimens.iconSize,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showFilterBottomSheet(ChooseRideState state) async {
    final viewModel = ref.read(chooseRideViewModelProvider(_params).notifier);

    final result = await AccessibilityFilterBottomSheet.show(
      context: context,
      vehicleTypeResponse: state.vehicleTypeResponse,
      rideType: state.rideType,
      currentFilters: state.filtersResult,
    );

    if (result != null) {
      viewModel.setFiltersResult(result);
    }
  }

  Future<void> _navigateToPayment({bool isFromConfirmDetails = false}) async {
    final viewModel = ref.read(chooseRideViewModelProvider(_params).notifier);
    final state = ref.read(chooseRideViewModelProvider(_params));

    final result = await context.navigateToPayment(
      isComeFromBooking: true,
      vehicleTypePaymentSetting: viewModel.vehiclePaymentSetting,
      selectedPaymentGateway: state.selectedCard?.paymentGatewayType,
      totalAmount: viewModel.selectedVehicleTotalPrice,
      isCorporateBooking: state.isCorporateBooking,
      selectedPaymentMethod: state.selectedCard,
    );

    // Update selected card if user selected a new payment method
    if (result != null) {
      if (isFromConfirmDetails) {
        // In confirm details, changing payment clears promo and recalculates fare
        viewModel.onPaymentMethodChanged(result);
      } else {
        viewModel.setSelectedCard(result);
      }
    }
  }

  Future<void> _navigateToPromoScreen() async {
    final viewModel = ref.read(chooseRideViewModelProvider(_params).notifier);
    final state = ref.read(chooseRideViewModelProvider(_params));

    final vehicle = viewModel.selectedVehicle;
    if (vehicle == null) return;

    final bookingTime = state.bookingTime ?? DateTime.now().millisecondsSinceEpoch;

    final promoCodeListRequest = PromoCodeListRequest(
      cityId: state.vehicleTypeResponse?.citySetting?.cityId,
      countryId: vehicle.countryId,
      vehicleTypeId: vehicle.vehicleTypeId,
      priceMode: state.rideType?.value,
    );

    final result = await context.navigateToPromoOffer(
      promoCodeListRequest: promoCodeListRequest,
      bookingTime: bookingTime,
      priceMode: state.rideType?.value ?? 0,
      paymentMode: state.selectedCard?.paymentGatewayType ?? 0,
      latitude: state.pickupAddress.latitude,
      longitude: state.pickupAddress.longitude,
    );

    if (result != null) {
      viewModel.setSelectedPromo(result);
    }
  }

  Future<void> _showScheduleBottomSheet(RideType? rideType) async {
    final isScheduleAvailable = _isScheduleAvailable(rideType);
    final isNowAvailable = _isNowAvailable(rideType);

    // If neither option is available, don't show anything
    if (!isScheduleAvailable && !isNowAvailable) return;

    // Always show the options bottom sheet
    final result = await ScheduleRideBottomSheet.show(
      context: context,
      initialOption: _scheduleResult?.option ?? (isNowAvailable ? ScheduleOption.now : ScheduleOption.later),
      rideType: rideType,
      driverSettings: _driverSettings,
      businessSettings: _businessSettings,
      initialScheduleResult: _scheduleResult?.scheduleResult,
    );

    if (result != null && mounted) {
      setState(() {
        _scheduleResult = result;
      });
    }
  }

  /// Handle Choose button press
  /// If only SCHEDULE is available and no time selected, prompt for schedule first
  /// For rental vehicles with packages, first show package selection
  Future<void> _onChoosePressed(RideType? rideType) async {
    final viewModel = ref.read(chooseRideViewModelProvider(_params).notifier);
    final state = ref.read(chooseRideViewModelProvider(_params));

    // If rental vehicle with packages and not yet showing packages, show packages first
    if (viewModel.isRentalVehicleSelected &&
        viewModel.hasRentalPackages &&
        !state.isShowingRentalPackages) {
      viewModel.showRentalPackages();
      return;
    }

    final isNowAvailable = _isNowAvailable(rideType);
    final isScheduleAvailable = _isScheduleAvailable(rideType);

    // If only SCHEDULE is available (no NOW) and no schedule time selected
    if (!isNowAvailable && isScheduleAvailable && _scheduleResult == null) {
      // Prompt for schedule time first
      final scheduleResult = await SchedulePickerSegment.show(
        context: context,
        rideType: rideType,
        driverSettings: _driverSettings,
        initialDate: null,
      );

      if (scheduleResult == null || !mounted) return;

      setState(() {
        _scheduleResult = ScheduleRideResult(
          option: ScheduleOption.later,
          scheduleResult: scheduleResult,
        );
      });
    }

    // Go to confirm details step
    setState(() {
      _currentStep = ChooseRideStep.confirmDetails;
    });

    // Set booking time and call fare estimate when entering section 2.
    // Interpret the picked wall-clock time in the selected city's timezone so
    // the epoch is correct even when the city differs from the device timezone
    // (matches the native user app behaviour). "Now" bookings keep device-local epoch.
    final pickedDateTime = _scheduleResult?.scheduleResult?.dateTime;
    final bookingTime = pickedDateTime == null
        ? null
        : AppDateUtils.wallClockToEpochMillis(
            pickedDateTime,
            widget.citySetting?.timezone,
          );
    viewModel.setBookingTime(bookingTime);
    viewModel.getFareEstimate();
  }

  /// Build confirm details content (static bottom container - wrap content)
  Widget _buildConfirmDetailsContent(ChooseRideState state) {
    final colors = context.colors;
    final viewModel = ref.read(chooseRideViewModelProvider(_params).notifier);

    return Align(
      alignment: Alignment.bottomCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Confirm details segment
          ChooseRideConfirmDetails(
            selectedVehicle: viewModel.selectedVehicle,
            currencySign: state.currencySign,
            countrySetting: state.vehicleTypeResponse?.countrySetting,
            totalPrice: viewModel.totalPriceWithPromo,
            tripDuration: state.vehicleTypeResponse?.time,
            onBack: _handleBackPress,
            customPrices: state.vehicleTypeResponse?.customPrices,
            accessibilities: state.vehicleTypeResponse?.accessibilities,
            selectedAccessibilityIds: state.filtersResult?.selectedAccessibility,
            updatedPriceDetail: state.updatedPriceDetail,
            selectedPromo: state.selectedPromo,
            onApplyPromo: _navigateToPromoScreen,
            onRemovePromo: viewModel.removePromo,
            selectedRentalPackage: viewModel.selectedRentalPackage,
            isRental: viewModel.isRentalVehicleSelected && state.isShowingRentalPackages,
            onChangePackage: () {
              setState(() {
                _currentStep = ChooseRideStep.selectVehicle;
              });
              // isShowingRentalPackages is still true, so packages show
            },
            // Bidding
            isBiddingAvailable: state.isBiddingAvailable &&
                (_scheduleResult == null || _scheduleResult!.isNow),
            isBidding: state.isBidding,
            bidPrice: state.bidPrice,
            onBiddingToggle: _onBiddingToggleTapped,
            onRemoveBid: viewModel.removeBid,
            isDestinationLater: state.isDestinationLater,
            rideForOtherResult: widget.rideForOtherResult,
          ),

          // Bottom buttons
          Container(
            color: colors.colorBackground,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Corporate toggle option
                  if (state.isCorporateAvailable)
                    _buildCorporateToggle(colors, state.isCorporateBooking),

                  // Divider above payment (full width, no padding)
                  if (state.selectedCard != null && !state.isCorporateBooking)
                    Divider(
                      color: colors.colorBackgroundGray,
                      height: 1,
                      thickness: 1,
                    ),

                  Padding(
                    padding: const EdgeInsets.only(
                      left: AppDimens.padding,
                      right: AppDimens.padding,
                      bottom: AppDimens.padding,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Payment row - hide when corporate is selected
                        if (state.selectedCard != null && !state.isCorporateBooking)
                          _buildPaymentRow(
                            colors,
                            state.selectedCard!,
                            isFromConfirmDetails: true,
                          ),

                        // Confirm button with schedule option
                        Row(
                          children: [
                            Expanded(
                              child: AppFilledButton(
                                text: viewModel.isRentalVehicleSelected && state.isShowingRentalPackages
                                    ? 'Choose ${viewModel.selectedRentalPackage?.packageName ?? ''}'
                                    : 'Choose ${viewModel.selectedVehicle?.vehicleTypeDetail?.name ?? ''}',
                                enabled: !state.isLoading,
                                onPressed: _onConfirmPressed,
                              ),
                            ),
                            if (_isScheduleAvailable(state.rideType) && !state.isBidding) ...[
                              const SizedBox(width: AppDimens.paddingM),
                              GestureDetector(
                                onTap: () => _showScheduleBottomSheet(state.rideType),
                                child: Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: colors.colorBackgroundGray,
                                    borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
                                  ),
                                  child: Icon(
                                    _scheduleResult?.isNow ?? _isNowAvailable(state.rideType)
                                        ? Icons.access_time
                                        : Icons.calendar_today_outlined,
                                    color: colors.colorButtonBackground,
                                    size: AppDimens.iconSize,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Handle confirm button press - go to confirm pickup step
  void _onConfirmPressed() {
    setState(() {
      _currentStep = ChooseRideStep.confirmPickup;
    });
    final state = ref.read(chooseRideViewModelProvider(_params));
    _zoomToPickup(state);
  }

  /// Build confirm pickup content (static bottom container - wrap content)
  Widget _buildConfirmPickupContent(ChooseRideState state) {
    if (_driverMessageController.text != state.driverMessage) {
      _driverMessageController.value = TextEditingValue(
        text: state.driverMessage,
        selection: TextSelection.collapsed(offset: state.driverMessage.length),
      );
    }

    return Align(
      alignment: Alignment.bottomCenter,
      child: ChooseRideConfirmPickup(
        driverMessageController: _driverMessageController,
        onDriverMessageChanged: ref
            .read(chooseRideViewModelProvider(_params).notifier)
            .updateDriverMessage,
        isLoading: state.isCreatingBooking,
        onConfirm: _onConfirmPickupPressed,
      ),
    );
  }

  /// Handle confirm pickup button press (creates the booking)
  Future<void> _onConfirmPickupPressed() async {
    final viewModel = ref.read(chooseRideViewModelProvider(_params).notifier);
    final state = ref.read(chooseRideViewModelProvider(_params));

    // 1. Check if payment method is selected (skip for corporate - corporate pays)
    if (!state.isCorporateBooking && state.selectedCard == null) {
      _navigateToPayment();
      return;
    }

    // 2. Check wallet balance if wallet payment is selected (skip for corporate)
    if (!state.isCorporateBooking && viewModel.hasInsufficientWalletBalance) {
      if (mounted) {
        context.showErrorSnackBar('Insufficient wallet balance. Please add funds or choose a different payment method.');
      }
      return;
    }

    // 3. Check for surge pricing
    final surgeUnit = viewModel.surgeUnit;
    if (surgeUnit != null && surgeUnit > 1) {
      if (!mounted) return;
      final confirmed = await SurgePricingBottomSheet.show(
        context: context,
        surgeUnit: surgeUnit.toStringAsFixed(1),
      );

      if (confirmed != true) {
        // User cancelled surge pricing
        return;
      }
    }

    // 4. Check if fix fare is available (skip if bidding — bidding implies fix fare)
    bool isFixFare = false;
    if (viewModel.isFixFareAvailable && !state.isBidding) {
      if (!mounted) return;
      final wantsFixFare = await FixedRateBottomSheet.show(context: context);
      isFixFare = wantsFixFare == true;
    }

    // 5. Create the booking
    final response = await viewModel.createBooking(
      isFixFare: isFixFare,
      rideForOtherResult: widget.rideForOtherResult,
    );

    if (!mounted) return;

    // Show snackbar from state (viewmodel sets it via showSnackBar)
    final viewModelState = ref.read(chooseRideViewModelProvider(_params));
    if (viewModelState.snackBarMessage != null) {
      if (viewModelState.isSnackBarError) {
        context.showErrorSnackBar(viewModelState.snackBarMessage!);
      } else {
        context.showSnackBar(viewModelState.snackBarMessage!);
      }
      ref.read(chooseRideViewModelProvider(_params).notifier).clearSnackBar();
    }

    if (response != null) {
      // Booking created successfully - refresh entity and pop back to home
      ref.read(mainViewModelProvider.notifier).refreshEntityDetail();
      context.pop();
      context.pop(); // Pop choose ride screen and plan ride screen
    }
  }

  Widget _buildCorporateToggle(AppColorPalette colors, bool isSelected) {
    return GestureDetector(
      onTap: () {
        final viewModel = ref.read(chooseRideViewModelProvider(_params).notifier);
        viewModel.toggleCorporateBooking();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.padding,
          vertical: AppDimens.paddingS,
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_box : Icons.check_box_outline_blank,
              color: isSelected ? colors.colorPrimary : colors.colorText,
              size: 24,
            ),
            const SizedBox(width: AppDimens.paddingM),
            Expanded(
              child: AppText.body(
                getString(
                  appStr.descriptionWouldYouPayByCorporate,
                  'description_would_you_pay_by_corporate',
                ),
                fontWeight: FontWeight.w500,
                color: colors.colorText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Handle bidding toggle tap
  Future<void> _onBiddingToggleTapped() async {
    final viewModel = ref.read(chooseRideViewModelProvider(_params).notifier);
    final shouldShowBottomSheet = viewModel.toggleBidding();

    if (!shouldShowBottomSheet) return;

    // Show bid request bottom sheet
    final state = ref.read(chooseRideViewModelProvider(_params));
    final totalPrice = viewModel.selectedVehicleTotalPrice;
    final minBidPrice = viewModel.calculateMinBidPrice(totalPrice);
    final bidSettingInfo = viewModel.currentBidSetting;
    final currencySign = state.currencySign ?? '';
    final decimalPointValue =
        state.vehicleTypeResponse?.countrySetting?.decimalPointValue ?? 2;

    if (!mounted) return;

    final bidAmount = await BidRequestBottomSheet.show(
      context: context,
      currentPrice: totalPrice,
      minBidPrice: minBidPrice,
      currencySign: currencySign,
      decimalPointValue: decimalPointValue,
      isAllowStepper:
          bidSettingInfo?.isAllowIncrementDecrementStepper == true,
      stepperAmount: bidSettingInfo?.incrementDecrementStepper ?? 1.0,
    );

    if (bidAmount != null) {
      viewModel.confirmBid(bidAmount);
    }
  }

  Widget _buildPaymentRow(
    AppColorPalette colors,
    CardResponse selectedCard, {
    bool isFromConfirmDetails = false,
  }) {
    return GestureDetector(
      onTap: () => _navigateToPayment(isFromConfirmDetails: isFromConfirmDetails),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppDimens.paddingM,
        ),
        child: Row(
          children: [
            Icon(
              Icons.credit_card,
              color: colors.colorText,
              size: 24,
            ),
            const SizedBox(width: AppDimens.paddingM),
            Expanded(
              child: AppText.body(
                selectedCard.cardName ?? '',
                fontWeight: FontWeight.w500,
                color: colors.colorText,
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: colors.colorText,
            ),
          ],
        ),
      ),
    );
  }
}
