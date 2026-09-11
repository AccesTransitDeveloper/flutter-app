import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/map/interface/map_interface.dart';
import '../../../core/map/widgets/map_host.dart';
import '../../../core/router/app_navigation.dart';
import '../../../core/map/providers/map_provider.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../models/requests/get_vehicle_types_request.dart';
import '../../../models/responses/booking/get_vehicle_type_response.dart';
import '../../../core/theme/app_theme.dart';
import '../../../viewmodels/add_stops_viewmodel.dart';
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
import '../../bottomsheets/switch_rider_bottom_sheet.dart';

class AddStopsScreen extends ConsumerStatefulWidget {
  final DestinationAddress pickupAddress;
  final DestinationAddress? destinationAddress;
  final RideType? rideType;
  final CitySetting? citySetting;
  final ScheduleRideResult? initialScheduleResult;
  final String? selectedVehicleTypeId;
  final RideForOtherResult? initialRideForOtherResult;

  const AddStopsScreen({
    super.key,
    required this.pickupAddress,
    this.destinationAddress,
    this.rideType,
    this.citySetting,
    this.initialScheduleResult,
    this.selectedVehicleTypeId,
    this.initialRideForOtherResult,
  });

  @override
  ConsumerState<AddStopsScreen> createState() => _AddStopsScreenState();
}

class _AddStopsScreenState extends ConsumerState<AddStopsScreen> {
  late AddStopsParams _params;
  final TextEditingController _searchController = TextEditingController();
  final AppSheetController _sheetController = AppSheetController();
  bool _mapInitialized = false;

  // Map manager - created once per screen instance
  late final MapInterface _mapManager;

  // Schedule state
  ScheduleRideResult? _scheduleResult;
  bool _isSheetExpanded = true;

  // Ride for other state
  RideForOtherResult? _rideForOtherResult;

  DriverSettings? get _driverSettings => widget.citySetting?.driverSetting;
  BusinessSettings? get _businessSettings => widget.citySetting?.businessSettings;

  bool get _isRideForOtherAvailable {
    final bs = widget.citySetting?.bookingSetting;
    final list = switch (widget.rideType) {
      RideType.normal => bs?.normal,
      RideType.rental => bs?.rental,
      RideType.sharing => bs?.share,
      RideType.fixGroup => bs?.fixGroupBooking,
      null => bs?.normal,
    };
    return list?.contains(BookingSettingConstant.allowRideForOther) == true;
  }

  bool get _isNowAvailable => SchedulePickerSegment.isNowAvailableFromBusiness(
        rideType: widget.rideType,
        businessSettings: _businessSettings,
      );

  bool get _isScheduleAvailable => SchedulePickerSegment.isScheduleAvailableFromBusiness(
        rideType: widget.rideType,
        businessSettings: _businessSettings,
      );

  bool get _isScheduleChipEnabled => _isNowAvailable || _isScheduleAvailable;

  /// Get default chip label based on availability
  String get _defaultChipLabel => _isNowAvailable ? 'Pickup now' : 'Later';

  /// Get default chip icon based on availability
  bool get _defaultIsNow => _isNowAvailable;

  @override
  void initState() {
    super.initState();

    // Initialize from navigation parameters
    _scheduleResult = widget.initialScheduleResult;
    _rideForOtherResult = widget.initialRideForOtherResult;

    // Create map manager instance for this screen
    _mapManager = ref.read(mapManagerProvider)();
    _params = AddStopsParams(
      pickupAddress: widget.pickupAddress,
      destinationAddress: widget.destinationAddress,
      maxStopLimit: widget.citySetting?.maxStopLimit ?? 0,
      mapManager: _mapManager,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _sheetController.dispose();
    _mapManager.dispose();
    super.dispose();
  }

  void _initializeMapIfNeeded(int primaryColor) {
    if (_mapInitialized) return;
    _mapInitialized = true;

    // Delay to ensure map controller is ready
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        final viewModel = ref.read(addStopsViewModelProvider(_params).notifier);
        viewModel.initializeMap(primaryColor: primaryColor);
      }
    });
  }

  void _onSetLocationOnMap() {
    final viewModel = ref.read(addStopsViewModelProvider(_params).notifier);
    viewModel.enterMapSelectionMode();
    _sheetController.collapse();
  }

  void _onSheetStateChanged(bool isExpanded) {
    setState(() { _isSheetExpanded = isExpanded; });
    // When sheet is dragged down (collapsed), enter map selection mode
    if (!isExpanded) {
      final state = ref.read(addStopsViewModelProvider(_params));
      if (state.isAddEditMode && !state.isMapSelectionMode) {
        final viewModel = ref.read(addStopsViewModelProvider(_params).notifier);
        viewModel.enterMapSelectionMode();
      }
    }
  }

  void _onConfirmMapSelection() {
    final viewModel = ref.read(addStopsViewModelProvider(_params).notifier);
    viewModel.confirmMapSelection();
  }

  void _onSearchChanged(String query) {
    final viewModel = ref.read(addStopsViewModelProvider(_params).notifier);
    viewModel.searchPlaces(query);
  }

  void _onPlaceSelected(DestinationAddress place) {
    final viewModel = ref.read(addStopsViewModelProvider(_params).notifier);
    viewModel.selectPlace(place);
  }

  void _onDone() {
    final viewModel = ref.read(addStopsViewModelProvider(_params).notifier);
    final state = ref.read(addStopsViewModelProvider(_params));

    final error = viewModel.validateStops();
    if (error != null) {
      context.showErrorSnackBar(error);
      return;
    }

    context.navigateToChooseRide(
      pickup: state.pickupAddress,
      destinations: state.stops,
      rideType: widget.rideType,
      citySetting: widget.citySetting,
      scheduleResult: _scheduleResult,
      selectedVehicleTypeId: widget.selectedVehicleTypeId,
      rideForOtherResult: _rideForOtherResult,
    );
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
      rideType: widget.rideType,
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

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final topPadding = MediaQuery.of(context).padding.top;
    final state = ref.watch(addStopsViewModelProvider(_params));
    final viewModel = ref.read(addStopsViewModelProvider(_params).notifier);

    return AppScaffold(
      body: Stack(
        children: [
          // Layer 1: Map (StatefulBuilder handled internally by manager)
          Positioned.fill(
            child: Builder(
              builder: (context) {
                _initializeMapIfNeeded(colors.colorPrimary.toARGB32());
                return MapHost(manager: _mapManager);
              },
            ),
          ),

          // Layer 2: Center pin (shown only in map selection mode)
          if (state.isAddEditMode)
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

          // Layer 3: Bottom sheet - two separate sheets based on mode
          if (!state.isAddEditMode)
            // Normal mode: Static bottom sheet with stops list
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: colors.colorBackground,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: _buildNormalContent(context, state),
                ),
              ),
            )
          else
            // Add/Edit mode: Draggable sheet starting expanded
            AppDraggableScrollableSheet(
              key: const ValueKey('add-edit-sheet'),
              controller: _sheetController,
              maxChildSize: 0.97,
              sheetColor: colors.colorBackground,
              initialState: AppSheetInitialState.expanded,
              isDraggable: true,
              collapsedContent: _buildMapSelectionContent(context, state),
              expandedContent: _buildSearchContent(context, state),
              onStateChanged: _onSheetStateChanged,
            ),

          // Layer 4: Back button (hidden when sheet is expanded in add/edit mode)
          if (!(state.isAddEditMode && _isSheetExpanded))
            Positioned(
              top: topPadding + AppDimens.padding,
              left: AppDimens.padding,
              child: GestureDetector(
                onTap: () {
                  if (state.isAddEditMode) {
                    viewModel.exitAddEditMode();
                    _searchController.clear();
                  } else {
                    context.goBack();
                  }
                },
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
    );
  }

  /// Normal mode content - stops list (non-draggable)
  Widget _buildNormalContent(BuildContext context, AddStopsState state) {
    final viewModel = ref.read(addStopsViewModelProvider(_params).notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.padding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: AppDimens.padding),
              child: AppText.title(
                'Add stops',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: AppDimens.paddingXL),

          // Stops list
          AppStopsListCard(
            pickupAddress: state.pickupAddress,
            stops: state.stops,
            noMoreStopsAllowed: state.noMoreStopsAllowed,
            onAddStopTap: () {
              setState(() { _isSheetExpanded = true; });
              viewModel.enterAddEditMode();
            },
            onStopTap: (index) {
              setState(() { _isSheetExpanded = true; });
              viewModel.enterAddEditMode(editingIndex: index);
            },
            onRemoveStop: (index) => viewModel.removeStop(index),
          ),

          const SizedBox(height: AppDimens.padding),

          // Chips row
          Row(
            children: [
              Opacity(
                opacity: _isScheduleChipEnabled ? 1.0 : 0.5,
                child: AppChip(
                  icon: (_scheduleResult?.isNow ?? _defaultIsNow)
                      ? Icons.access_time
                      : Icons.calendar_today_outlined,
                  label: _scheduleResult?.chipLabel ?? _defaultChipLabel,
                  onTap: _isScheduleChipEnabled ? _showScheduleBottomSheet : null,
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
            ],
          ),

          const SizedBox(height: AppDimens.paddingXL),

          // Done button
          AppFilledButton(
            text: 'Done',
            onPressed: state.stops.isNotEmpty
                ? () => _onDone()
                : null,
          ),

          const SizedBox(height: AppDimens.padding),
        ],
      ),
    );
  }

  /// Map selection content - collapsed state in add/edit mode
  Widget _buildMapSelectionContent(BuildContext context, AddStopsState state) {
    final colors = context.colors;
    final mapAddress = state.mapSelectionAddress;
    final addressText = mapAddress?.title ?? mapAddress?.address ?? '';
    final isLoading = state.isLoadingMapAddress;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.padding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          AppText.title(
            'Add stop on map',
            fontWeight: FontWeight.w600,
          ),
          const SizedBox(height: AppDimens.paddingXS),
          AppText.body(
            'Drag map to move pin',
            color: colors.colorText,
          ),
          const SizedBox(height: AppDimens.paddingXL),

          // Address display card
          GestureDetector(
            onTap: () {},
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
                    Icons.circle_outlined,
                    color: colors.colorText,
                    size: 20,
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
                            addressText.isNotEmpty
                                ? addressText
                                : 'Move map to select location',
                            color: addressText.isNotEmpty
                                ? colors.colorText
                                : colors.colorText,
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

          // Confirm button
          AppFilledButton(
            text: 'Confirm stop',
            onPressed: addressText.isNotEmpty && !isLoading
                ? _onConfirmMapSelection
                : null,
          ),

          const SizedBox(height: AppDimens.padding),
        ],
      ),
    );
  }

  /// Search content - expanded state in add/edit mode
  Widget _buildSearchContent(BuildContext context, AddStopsState state) {
    final colors = context.colors;
    final viewModel = ref.read(addStopsViewModelProvider(_params).notifier);

    // Determine which list to show
    final displayList = state.searchQuery.isNotEmpty
        ? state.searchResults
        : state.recentAddresses;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.padding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with back button and centered title
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  viewModel.exitAddEditMode();
                  _searchController.clear();
                },
                child: Icon(
                  Icons.arrow_back,
                  color: colors.colorText,
                  size: AppDimens.iconSize,
                ),
              ),
              Expanded(
                child: Center(
                  child: AppText.title(
                    'Add a stop',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Placeholder to balance the back button
              SizedBox(width: AppDimens.iconSize),
            ],
          ),
          const SizedBox(height: AppDimens.padding),

          // Search input
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.paddingM,
              vertical: AppDimens.paddingXS,
            ),
            decoration: BoxDecoration(
              color: colors.colorBackgroundGray,
              borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  color: colors.colorText,
                  size: 20,
                ),
                const SizedBox(width: AppDimens.paddingM),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(fontSize: 14, color: colors.colorText),
                    decoration: InputDecoration(
                      hintText: 'Enter stop location',
                      hintStyle:
                          TextStyle(fontSize: 14, color: colors.colorText),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: AppDimens.paddingS,
                      ),
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: colors.colorText,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close,
                          size: 14, color: colors.colorBackground),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: AppDimens.padding),

          // Loading indicator
          if (state.isSearching)
            const Padding(
              padding: EdgeInsets.all(AppDimens.padding),
              child: Center(child: CircularProgressIndicator()),
            ),

          // Places list
          if (!state.isSearching)
            ...displayList.map((place) => AppListItem(
                  icon: place.isRecentAddress == true
                      ? Icons.access_time
                      : Icons.location_on_outlined,
                  title: place.title ?? place.address ?? '',
                  subtitle: place.city,
                  onTap: () => _onPlaceSelected(place),
                )),

          if (!state.isSearching &&
              displayList.isEmpty &&
              state.searchQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppDimens.paddingXL),
              child: Center(
                child: AppText.body(
                  'No results found',
                  color: colors.colorText,
                ),
              ),
            ),

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

          const SizedBox(height: AppDimens.padding),
        ],
      ),
    );
  }

}
