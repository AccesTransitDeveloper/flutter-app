import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/map/interface/map_interface.dart';
import '../../../core/map/widgets/map_host.dart';
import '../../../core/router/app_navigation.dart';
import '../../../core/map/providers/map_provider.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../models/requests/get_vehicle_types_request.dart';
import '../../../models/ride_type_item.dart';
import '../../../models/responses/booking/get_vehicle_type_response.dart';
import '../../../core/theme/app_theme.dart';
import '../../../viewmodels/plan_ride_viewmodel.dart';
import '../../../views/widgets/app_address_input_card.dart';
import '../../../views/widgets/app_button.dart';
import '../../../views/widgets/app_chip.dart';
import '../../../views/widgets/app_draggable_scrollable_sheet.dart';
import '../../../views/widgets/app_list_item.dart';
import '../../../views/widgets/app_scaffold.dart';
import '../../../views/widgets/app_text.dart';
import '../../../views/item/schedule_picker_segment.dart';
import '../../../models/ride_for_other_result.dart';
import '../../bottomsheets/schedule_ride_bottom_sheet.dart';
import '../../bottomsheets/ride_type_bottom_sheet.dart';
import '../../bottomsheets/switch_rider_bottom_sheet.dart';

class PlanRideScreen extends ConsumerStatefulWidget {
  final DestinationAddress? initialPickupAddress;
  final RideType? rideType;
  final CitySetting? citySetting;
  final String? selectedVehicleTypeId;

  /// The ride types offered for this city. The picker used to live on the home
  /// screen; it now sits beside the "for me / for other" chip here, so the list
  /// travels with the navigation.
  final List<RideTypeItem> rideTypeItems;

  /// True when this is the app's landing screen rather than a pushed one. There
  /// is nothing to pop back to, so the header's back arrow is dropped and the
  /// sheet leaves room for the bottom nav bar.
  final bool isRoot;

  const PlanRideScreen({
    super.key,
    this.initialPickupAddress,
    this.rideType,
    this.citySetting,
    this.selectedVehicleTypeId,
    this.rideTypeItems = const [],
    this.isRoot = false,
  });

  @override
  ConsumerState<PlanRideScreen> createState() => _PlanRideScreenState();
}

class _PlanRideScreenState extends ConsumerState<PlanRideScreen> {
  final AppSheetController _sheetController = AppSheetController();

  // Text controllers for location fields
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();

  // Focus nodes
  final FocusNode _pickupFocusNode = FocusNode();
  final FocusNode _destinationFocusNode = FocusNode();

  // Map manager - created once per screen instance
  late final MapInterface _mapManager;
  late final PlanRideParams _params;

  // Schedule state
  ScheduleRideResult? _scheduleResult;
  bool _isSheetExpanded = true;

  // Defer mounting the GoogleMap platform view until the push transition
  // completes — inflating it mid-transition causes janky open animation.
  bool _showMap = false;

  /// How much of the screen the sheet currently covers, as a fraction.
  ///
  /// The my-location button used to sit at a hard-coded 280 from the bottom,
  /// which the taller "Set your pickup spot" sheet covered completely. Null
  /// until the sheet reports its first extent, so the button isn't drawn in the
  /// wrong place for a frame.
  final ValueNotifier<double?> _sheetExtent = ValueNotifier<double?>(null);

  /// Past this the sheet has taken over the screen and a map button is pointless.
  static const double _hideMapButtonsAboveExtent = 0.6;

  // Ride for other state
  RideForOtherResult? _rideForOtherResult;

  // The ride type is now chosen on this screen rather than handed in fixed from
  // home, so it (and the vehicle type that came with it) has to be mutable.
  RideType? _rideType;
  String? _selectedVehicleTypeId;

  DriverSettings? get _driverSettings => widget.citySetting?.driverSetting;
  BusinessSettings? get _businessSettings => widget.citySetting?.businessSettings;

  /// Whether adding stops (multiple locations) is allowed for the selected
  /// ride type. Driven by the MULTIPLE_LOCATION business setting flag, exactly
  /// like the native app (businessSetting.contains(.multipleLocation)).
  /// maxStopLimit is only the cap once this is enabled, not the on/off switch.
  bool get _isMultipleStopAllowed =>
      SchedulePickerSegment.isMultipleLocationAvailableFromBusiness(
        rideType: _rideType,
        businessSettings: _businessSettings,
      );

  bool get _isRideForOtherAvailable {
    final bs = widget.citySetting?.bookingSetting;
    final list = switch (_rideType) {
      RideType.normal => bs?.normal,
      RideType.rental => bs?.rental,
      RideType.sharing => bs?.share,
      RideType.fixGroup => bs?.fixGroupBooking,
      null => bs?.normal,
    };
    return list?.contains(BookingSettingConstant.allowRideForOther) == true;
  }

  bool get _isNowAvailable => SchedulePickerSegment.isNowAvailableFromBusiness(
        rideType: _rideType,
        businessSettings: _businessSettings,
      );

  bool get _isScheduleAvailable => SchedulePickerSegment.isScheduleAvailableFromBusiness(
        rideType: _rideType,
        businessSettings: _businessSettings,
      );

  bool get _isScheduleChipEnabled => _isNowAvailable || _isScheduleAvailable;

  bool get _isDestinationLaterAvailable {
    final settings = _businessSettings;
    if (settings == null) return false;
    final settingsList = switch (_rideType) {
      RideType.normal => settings.normal,
      RideType.rental => settings.rental,
      RideType.sharing => settings.share,
      RideType.fixGroup => settings.fixGroupBooking,
      null => settings.normal,
    };
    return settingsList?.contains('DESTINATION_LATER') == true;
  }

  /// Get default chip label based on availability
  String get _defaultChipLabel => _isNowAvailable ? 'Pickup now' : 'Later';

  /// Get default chip icon based on availability
  bool get _defaultIsNow => _isNowAvailable;

  @override
  void initState() {
    super.initState();

    // Home no longer picks a booking type, so default to the first one on
    // offer rather than leaving the dropdown — and everything keyed off the
    // ride type — empty.
    final defaultRideType = _visibleRideTypes.firstOrNull;
    _rideType = widget.rideType ?? defaultRideType?.type;
    _selectedVehicleTypeId = widget.selectedVehicleTypeId ??
        (widget.rideType == null
            ? defaultRideType?.vehicleType?.vehicleTypeId
            : null);

    // Create map manager instance for this screen
    _mapManager = ref.read(mapManagerProvider)();
    _params = PlanRideParams(
      initialPickupAddress: widget.initialPickupAddress,
      mapManager: _mapManager,
    );

    // Set initial pickup address from parameter
    if (widget.initialPickupAddress?.address != null) {
      _pickupController.text = widget.initialPickupAddress!.address!;
    }

    // Listen to focus changes
    _pickupFocusNode.addListener(_onPickupFocusChange);
    _destinationFocusNode.addListener(_onDestinationFocusChange);

    // If no pickup was passed in, pre-fill it with the current location.
    if (widget.initialPickupAddress == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref
            .read(planRideViewModelProvider(_params).notifier)
            .initPickupFromCurrentLocation();
      });
    }

    // Mount the map only after the entrance transition has finished so the
    // sheet/route animation stays smooth.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final animation = ModalRoute.of(context)?.animation;
      if (animation == null || animation.isCompleted) {
        setState(() => _showMap = true);
        return;
      }
      void statusListener(AnimationStatus status) {
        if (status == AnimationStatus.completed) {
          animation.removeStatusListener(statusListener);
          if (mounted) setState(() => _showMap = true);
        }
      }
      animation.addStatusListener(statusListener);
    });
  }

  void _onPickupFocusChange() {
    if (_pickupFocusNode.hasFocus) {
      final viewModel = ref.read(planRideViewModelProvider(_params).notifier);
      viewModel.setFocus(LocationFocus.pickup);
    }
  }

  void _onDestinationFocusChange() {
    if (_destinationFocusNode.hasFocus) {
      final viewModel = ref.read(planRideViewModelProvider(_params).notifier);
      viewModel.setFocus(LocationFocus.destination);
    }
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _destinationController.dispose();
    _pickupFocusNode.removeListener(_onPickupFocusChange);
    _destinationFocusNode.removeListener(_onDestinationFocusChange);
    _pickupFocusNode.dispose();
    _destinationFocusNode.dispose();
    _sheetController.dispose();
    _sheetExtent.dispose();
    _mapManager.dispose();
    super.dispose();
  }

  void _onSetLocationOnMap() {
    final viewModel = ref.read(planRideViewModelProvider(_params).notifier);
    viewModel.enterMapSelectionMode();
    _sheetController.collapse();
  }

  void _onSheetStateChanged(bool isExpanded) {
    setState(() { _isSheetExpanded = isExpanded; });
    // When sheet is dragged down (collapsed), enter map selection mode
    if (!isExpanded) {
      final state = ref.read(planRideViewModelProvider(_params));
      if (!state.isMapSelectionMode) {
        final viewModel = ref.read(planRideViewModelProvider(_params).notifier);
        viewModel.enterMapSelectionMode();
      }
    }
  }

  void _onConfirmMapSelection() {
    final stateBefore = ref.read(planRideViewModelProvider(_params));
    final viewModel = ref.read(planRideViewModelProvider(_params).notifier);

    viewModel.confirmMapSelection();

    // Always expand sheet first, then check if we can navigate
    _sheetController.expand();

    // Use post frame callback to ensure state is updated, then check if we can navigate
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final stateAfter = ref.read(planRideViewModelProvider(_params));

      // Update text controller with new address from map selection
      if (stateBefore.currentFocus == LocationFocus.pickup) {
        _pickupController.text = stateAfter.pickupAddress?.address ?? '';
      } else {
        _destinationController.text = stateAfter.destinationAddress?.address ?? '';
      }

      if (stateAfter.pickupAddress != null && stateAfter.destinationAddress != null) {
        _navigateToChooseRideIfReady();
      }
      // If not ready, sheet is already expanded for user to fill missing address
    });
  }

  void _onConfirmLocation() {
    final state = ref.read(planRideViewModelProvider(_params));
    final viewModel = ref.read(planRideViewModelProvider(_params).notifier);

    // Always expand sheet first
    _sheetController.expand();

    // Check if both addresses are available - navigate
    if (state.pickupAddress != null && state.destinationAddress != null) {
      _navigateToChooseRideIfReady();
      return;
    }

    // Otherwise, switch focus to the missing field
    if (state.currentFocus == LocationFocus.pickup) {
      viewModel.setFocus(LocationFocus.destination);
      _destinationFocusNode.requestFocus();
    } else {
      viewModel.setFocus(LocationFocus.pickup);
      _pickupFocusNode.requestFocus();
    }
  }

  void _onDestinationLater() {
    final viewModel = ref.read(planRideViewModelProvider(_params).notifier);
    final state = ref.read(planRideViewModelProvider(_params));
    final pickup = state.pickupAddress;
    if (pickup == null) return;

    final error = viewModel.validateAddresses(isDestinationLater: true);
    if (error != null) {
      context.showErrorSnackBar(error);
      return;
    }

    context.navigateToChooseRide(
      pickup: pickup,
      destinations: const [],
      rideType: _rideType,
      citySetting: widget.citySetting,
      scheduleResult: _scheduleResult,
      selectedVehicleTypeId: _selectedVehicleTypeId,
      isDestinationLater: true,
      rideForOtherResult: _rideForOtherResult,
    );
  }

  Future<DestinationAddress?> _resolveAiAddress(String? text) async {
    final query = text?.trim() ?? '';
    if (query.length < 3) return null;
    final matches = await _mapManager.searchPlaces(query);
    for (final match in matches) {
      if (match.placeId == null) continue;
      final details = await _mapManager.getPlaceDetails(match.placeId!);
      if (details?.latitude != null && details?.longitude != null) return details;
    }
    return null;
  }

  Future<void> _handleAiSuggestion() async {
    final suggestion = await context.navigateToAiAssistant();
    if (!mounted || suggestion == null) return;
    DestinationAddress? pickup;
    DestinationAddress? destination;
    try {
      pickup = await _resolveAiAddress(suggestion.pickup);
      destination = await _resolveAiAddress(suggestion.destination);
    } catch (_) {
      // The existing booking form remains usable if the places provider is
      // temporarily unavailable.
    }
    if (!mounted) return;
    if (pickup == null || destination == null) {
      final viewModel =
          ref.read(planRideViewModelProvider(_params).notifier);
      context.showErrorSnackBar(
        'We could not verify one of those addresses. '
        'Please correct it manually.',
      );
      if (pickup != null) {
        viewModel.setPickupFromMap(pickup);
        _pickupController.text = pickup.address ?? '';
      } else {
        viewModel.clearLocation(LocationFocus.pickup);
        _pickupController.text = suggestion.pickup?.trim() ?? '';
      }
      if (destination != null) {
        viewModel.setDestinationFromMap(destination);
        _destinationController.text = destination.address ?? '';
      } else {
        viewModel.clearLocation(LocationFocus.destination);
        _destinationController.text = suggestion.destination?.trim() ?? '';
      }
      return;
    }
    final vm = ref.read(planRideViewModelProvider(_params).notifier);
    vm.setPickupFromMap(pickup);
    vm.setDestinationFromMap(destination);
    _pickupController.text = pickup.address ?? '';
    _destinationController.text = destination.address ?? '';
    context.showSnackBar(
      'Addresses are ready. Choose your time and ride type below.',
    );
  }

  void _navigateToChooseRideIfReady() {
    final viewModel = ref.read(planRideViewModelProvider(_params).notifier);
    final state = ref.read(planRideViewModelProvider(_params));

    if (state.pickupAddress != null && state.destinationAddress != null) {
      final error = viewModel.validateAddresses();
      if (error != null) {
        context.showErrorSnackBar(error);
        return;
      }

      context.navigateToChooseRide(
        pickup: state.pickupAddress!,
        destinations: [state.destinationAddress!],
        rideType: _rideType,
        citySetting: widget.citySetting,
        scheduleResult: _scheduleResult,
        selectedVehicleTypeId: _selectedVehicleTypeId,
        rideForOtherResult: _rideForOtherResult,
      );
    }
  }

  void _onClearLocation(LocationFocus focus) {
    final viewModel = ref.read(planRideViewModelProvider(_params).notifier);
    viewModel.clearLocation(focus);

    if (focus == LocationFocus.pickup) {
      _pickupController.clear();
      _pickupFocusNode.requestFocus();
    } else {
      _destinationController.clear();
      _destinationFocusNode.requestFocus();
    }
  }

  void _onSearchChanged(String query) {
    final viewModel = ref.read(planRideViewModelProvider(_params).notifier);
    viewModel.searchPlaces(query);
  }

  Future<void> _showSwitchRiderBottomSheet() async {
    if (!_isRideForOtherAvailable) return;

    final result = await SwitchRiderBottomSheet.show(
      context: context,
      initialResult: _rideForOtherResult,
      defaultCountryCode: '+91',
    );
    if (result != null && mounted) {
      setState(() {
        _rideForOtherResult = result;
      });
    }
  }

  Future<void> _showScheduleBottomSheet() async {
    if (!_isScheduleChipEnabled) return;

    final result = await ScheduleRideBottomSheet.show(
      context: context,
      initialOption: _scheduleResult?.option ?? ScheduleOption.now,
      rideType: _rideType,
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

  Future<void> _onPlaceSelected(DestinationAddress place) async {
    final viewModel = ref.read(planRideViewModelProvider(_params).notifier);
    final state = ref.read(planRideViewModelProvider(_params));

    // Update text controller based on focus
    if (state.currentFocus == LocationFocus.pickup) {
      _pickupController.text = place.address ?? place.title ?? '';
    } else {
      _destinationController.text = place.address ?? place.title ?? '';
    }

    FocusScope.of(context).unfocus();

    // Await selectPlace so getPlaceDetails completes before we check state
    await viewModel.selectPlace(place);

    if (!mounted) return;

    final stateAfter = ref.read(planRideViewModelProvider(_params));
    if (stateAfter.pickupAddress != null && stateAfter.destinationAddress != null) {
      _navigateToChooseRideIfReady();
    } else {
      // Need the other address - focus on it
      if (state.currentFocus == LocationFocus.pickup) {
        _destinationFocusNode.requestFocus();
      } else {
        _pickupFocusNode.requestFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final topPadding = MediaQuery.of(context).padding.top;
    final state = ref.watch(planRideViewModelProvider(_params));

    // Sync text controllers with state only when field is not focused (not being edited)
    // This restores values after returning from navigation without overwriting manual edits
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_pickupFocusNode.hasFocus &&
          state.pickupAddress?.address != null &&
          _pickupController.text.isEmpty) {
        _pickupController.text = state.pickupAddress!.address!;
      }
      if (!_destinationFocusNode.hasFocus &&
          state.destinationAddress?.address != null &&
          _destinationController.text.isEmpty) {
        _destinationController.text = state.destinationAddress!.address!;
      }
    });

    return AppScaffold(
      body: NotificationListener<DraggableScrollableNotification>(
        onNotification: (notification) {
          _sheetExtent.value = notification.extent;
          return false;
        },
        child: Stack(
        children: [
          // Layer 1: Map (deferred until the entrance transition completes)
          Positioned.fill(
            child: _showMap
                ? MapHost(manager: _mapManager)
                : ColoredBox(color: colors.colorBackground),
          ),

          // Layer 2: Map pin (centered, shown when in map selection mode)
          if (state.isMapSelectionMode)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              bottom: 100,
              child: IgnorePointer(
                child: Center(
                  child: Image.asset(
                    'assets/images/ic_set_location.png',
                    width: 40,
                    height: 40,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.location_on,
                      color: colors.colorPrimary,
                      size: 48,
                    ),
                  ),
                ),
              ),
            ),

          // Layer 3: My location button, riding just above the sheet.
          ValueListenableBuilder<double?>(
            valueListenable: _sheetExtent,
            builder: (context, extent, child) {
              if (extent == null || extent > _hideMapButtonsAboveExtent) {
                return const SizedBox.shrink();
              }
              return Positioned(
                right: AppDimens.padding,
                bottom: MediaQuery.of(context).size.height * extent +
                    AppDimens.padding,
                child: child!,
              );
            },
            child: GestureDetector(
              onTap: () {
                final viewModel = ref.read(planRideViewModelProvider(_params).notifier);
                viewModel.moveToCurrentLocation();
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.colorBackground,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colors.colorText.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.my_location,
                  color: colors.colorText,
                  size: AppDimens.iconSize,
                ),
              ),
            ),
          ),

          // Layer 4: Bottom sheet
          AppDraggableScrollableSheet(
            controller: _sheetController,
            maxChildSize: 0.95,
            sheetColor: colors.colorBackground,
            initialState: AppSheetInitialState.expanded,
            collapsedContent: _buildCollapsedContent(context, state),
            expandedContent: _buildExpandedContent(context, state),
            onStateChanged: _onSheetStateChanged,
          ),

          // Layer 5: Back button (hidden when sheet is expanded)
          if (!_isSheetExpanded)
            Positioned(
              top: topPadding + AppDimens.padding,
              left: AppDimens.padding,
              child: GestureDetector(
                onTap: () => context.goBack(),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colors.colorBackground,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_back,
                    color: colors.colorPrimary,
                    size: AppDimens.iconSize,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsedContent(BuildContext context, PlanRideState state) {
    final colors = context.colors;
    final isPickupFocus = state.currentFocus == LocationFocus.pickup;

    // In map selection mode, show the address from map
    if (state.isMapSelectionMode) {
      final mapAddress = state.mapSelectionAddress;
      final addressText = mapAddress?.title ?? mapAddress?.address ?? '';
      final isLoading = state.isLoadingMapAddress;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.padding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText.title(
              isPickupFocus ? 'Set your pickup spot' : 'Set your destination',
              fontWeight: FontWeight.w600,
            ),
            const SizedBox(height: AppDimens.paddingXS),
            AppText.body(
              'Drag map to move pin',
              color: colors.colorText,
            ),
            const SizedBox(height: AppDimens.paddingXL),
            GestureDetector(
              onTap: () {
                final viewModel = ref.read(planRideViewModelProvider(_params).notifier);
                viewModel.exitMapSelectionMode();
                _sheetController.expand();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.padding,
                  vertical: AppDimens.paddingM,
                ),
                decoration: BoxDecoration(
                  color: colors.colorBackgroundGray,
                  borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.circle,
                      color: colors.colorText,
                      size: 10,
                    ),
                    const SizedBox(width: AppDimens.paddingM),
                    Expanded(
                      child: isLoading
                          ? Row(
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colors.colorText,
                                  ),
                                ),
                                const SizedBox(width: AppDimens.paddingS),
                                AppText.body(
                                  'Getting address...',
                                  color: colors.colorText,
                                ),
                              ],
                            )
                          : AppText.body(
                              addressText.isNotEmpty ? addressText : 'Move map to select location',
                              color: addressText.isNotEmpty ? colors.colorText : colors.colorText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                    ),
                    Icon(
                      Icons.search,
                      color: colors.colorText,
                      size: AppDimens.iconSize,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppDimens.padding),
            AppFilledButton(
              text: isPickupFocus ? 'Confirm pickup' : 'Confirm destination',
              onPressed: addressText.isNotEmpty && !isLoading ? _onConfirmMapSelection : null,
            ),
          ],
        ),
      );
    }

    // Normal collapsed state (not in map selection mode)
    final currentAddress = isPickupFocus
        ? state.pickupAddress?.address
        : state.destinationAddress?.address;
    final hasAddress = currentAddress != null && currentAddress.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.padding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText.title(
            isPickupFocus ? 'Set your pickup spot' : 'Set your destination',
            fontWeight: FontWeight.w600,
          ),
          const SizedBox(height: AppDimens.paddingXS),
          AppText.body(
            'Drag map to move pin',
            color: colors.colorText,
          ),
          const SizedBox(height: AppDimens.paddingXL),
          GestureDetector(
            onTap: () => _sheetController.expand(),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.padding,
                vertical: AppDimens.paddingM,
              ),
              decoration: BoxDecoration(
                color: colors.colorBackgroundGray,
                borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
              ),
              child: Row(
                children: [
                  Icon(
                    isPickupFocus ? Icons.circle : Icons.square,
                    color: colors.colorText,
                    size: 10,
                  ),
                  const SizedBox(width: AppDimens.paddingM),
                  Expanded(
                    child: AppText.body(
                      hasAddress ? currentAddress : (isPickupFocus ? 'Set pickup' : 'Set destination'),
                      color: hasAddress ? colors.colorText : colors.colorText,
                    ),
                  ),
                  Icon(
                    Icons.search,
                    color: colors.colorText,
                    size: AppDimens.iconSize,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppDimens.padding),
          AppFilledButton(
            text: isPickupFocus ? 'Confirm pickup' : 'Confirm destination',
            onPressed: _onConfirmLocation,
          ),
        ],
      ),
    );
  }

  /// The booking types on offer. Chosen on the home screen's suggestions grid
  /// before; now picked from a dropdown beside the ride-for and schedule chips.
  List<RideTypeItem> get _visibleRideTypes =>
      widget.rideTypeItems.where((item) => item.isVisible).toList();

  RideTypeItem? get _selectedRideTypeItem {
    for (final item in _visibleRideTypes) {
      if (item.type == _rideType) return item;
    }
    return null;
  }

  Future<void> _showRideTypeBottomSheet() async {
    final items = _visibleRideTypes;
    if (items.isEmpty) return;

    final result = await RideTypeBottomSheet.show(
      context: context,
      items: items,
      selectedType: _rideType,
    );
    if (result != null && mounted) _onRideTypeSelected(result);
  }

  void _onRideTypeSelected(RideTypeItem item) {
    if (item.type == _rideType) return;
    setState(() {
      _rideType = item.type;
      // The vehicle type travelled with the ride type when this was picked on
      // home; keep them in step so the fare screen still gets the right one.
      _selectedVehicleTypeId = item.vehicleType?.vehicleTypeId;
      // Availability of "now"/schedule and ride-for-other differs per ride
      // type, so a stale choice here could be one the new type doesn't allow.
      _scheduleResult = null;
      _rideForOtherResult = null;
    });
  }

  Widget _buildExpandedContent(BuildContext context, PlanRideState state) {
    final colors = context.colors;

    // Determine which list to show
    final displayList = state.searchQuery.isNotEmpty
        ? state.autocompleteResults
        : state.recentAddresses;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              if (widget.isRoot)
                const SizedBox(width: AppDimens.iconSize)
              else
                GestureDetector(
                  onTap: () => context.goBack(),
                  child: Icon(
                    Icons.arrow_back,
                    color: colors.colorText,
                    size: AppDimens.iconSize,
                  ),
                ),
              const Spacer(),
              AppText.title(
                'Plan your ride',
                fontWeight: FontWeight.w600,
              ),
              const Spacer(),
              const SizedBox(width: AppDimens.iconSize),
            ],
          ),
          const SizedBox(height: AppDimens.paddingXL),

          // Chips. Scrolls horizontally because the ride types were added
          // alongside the existing two — on a narrow phone the row overflows.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Opacity(
                  opacity: _isScheduleChipEnabled ? 1.0 : 0.5,
                  child: AppChip(
                    icon: (_scheduleResult?.isNow ?? _defaultIsNow)
                        ? Icons.access_time
                        : Icons.calendar_today_outlined,
                    label: _scheduleResult?.chipLabel ?? _defaultChipLabel,
                    onTap:
                        _isScheduleChipEnabled ? _showScheduleBottomSheet : null,
                  ),
                ),
                const SizedBox(width: AppDimens.paddingM),
                if (_isRideForOtherAvailable)
                  AppChip(
                    icon: Icons.person_outline,
                    label: _rideForOtherResult?.chipLabel ?? 'For me',
                    onTap: _showSwitchRiderBottomSheet,
                  )
                else
                  AppChip(icon: Icons.person_outline, label: 'For me'),
                if (_visibleRideTypes.isNotEmpty) ...[
                  const SizedBox(width: AppDimens.paddingM),
                  AppChip(
                    icon: Icons.local_taxi_outlined,
                    label: _selectedRideTypeItem?.typeName ?? 'Ride type',
                    onTap: _showRideTypeBottomSheet,
                  ),
                ],
                if (widget.isRoot) ...[
                  const SizedBox(width: AppDimens.paddingM),
                  AppChip(
                    icon: Icons.auto_awesome,
                    label: 'AT AI',
                    onTap: _handleAiSuggestion,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppDimens.padding),

          // Location input card with plus button outside
          AppAddressInputCard(
            pickupController: _pickupController,
            destinationController: _destinationController,
            pickupFocusNode: _pickupFocusNode,
            destinationFocusNode: _destinationFocusNode,
            isPickupFocused: state.currentFocus == LocationFocus.pickup,
            isDestinationFocused: state.currentFocus == LocationFocus.destination,
            onSearchChanged: _onSearchChanged,
            onClearPickup: () => _onClearLocation(LocationFocus.pickup),
            onClearDestination: () => _onClearLocation(LocationFocus.destination),
            // Hide the "+" entirely when the ride type doesn't allow multiple
            // stops (mirrors native buttonType = .none), otherwise enable it
            // once a pickup is set.
            showAddButton: _isMultipleStopAllowed,
            isAddButtonEnabled: state.pickupAddress != null,
            onAddStopTap: () {
              final currentState = ref.read(planRideViewModelProvider(_params));
              if (currentState.pickupAddress != null && _isMultipleStopAllowed) {
                context.navigateToAddStops(
                  pickup: currentState.pickupAddress!,
                  destination: currentState.destinationAddress,
                  rideType: _rideType,
                  citySetting: widget.citySetting,
                  scheduleResult: _scheduleResult,
                  selectedVehicleTypeId: _selectedVehicleTypeId,
                  rideForOtherResult: _rideForOtherResult,
                );
              }
            },
          ),
          const SizedBox(height: AppDimens.paddingXL),

          // Loading indicator
          if (state.isSearching || state.isLoadingPlaceDetails)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppDimens.paddingM),
              child: Center(child: CircularProgressIndicator()),
            ),

          // Places list
          if (!state.isSearching && !state.isLoadingPlaceDetails)
            ...displayList.map((place) => AppListItem(
                  icon: place.isRecentAddress == true
                      ? Icons.access_time
                      : Icons.location_on_outlined,
                  title: place.title ?? place.address ?? '',
                  subtitle: place.city,
                  onTap: () => _onPlaceSelected(place),
                )),

          const SizedBox(height: AppDimens.padding),
          Divider(color: colors.colorText.withValues(alpha: 0.2)),

          // Action items
          AppListItem(
            icon: Icons.location_on_outlined,
            title: 'Set location on map',
            onTap: _onSetLocationOnMap,
          ),
          AppListItem(
            icon: Icons.star_border,
            title: 'Saved places',
            onTap: () async {
              final result = await context.navigateToSavedPlacesForResult();
              if (result != null) {
                _onPlaceSelected(result);
              }
            },
          ),
          if (_isDestinationLaterAvailable)
            AppListItem(
              icon: Icons.schedule,
              title: getString(
                appStr.buttonSetDestinationLater,
                'button_set_destination_later',
              ),
              onTap: _onDestinationLater,
            ),
        ],
      ),
    );
  }

}
