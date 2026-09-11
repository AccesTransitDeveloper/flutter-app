import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/responses/booking/accessibility_preference.dart';
import '../../../models/responses/booking/get_vehicle_type_response.dart';
import '../../../viewmodels/choose_ride_viewmodel.dart';
import '../../item/vehicle_item.dart';
import '../../widgets/app_text.dart';

/// Segment 1: Vehicle Selection
///
/// Displays available vehicles and lets user select one.
/// Supports two modes:
/// - Single type mode: Shows flat list of vehicles
/// - All types mode: Shows sections with headers (Normal, Sharing, Rental, etc.)
///
/// Fills CreateBookingRequest field: `vehiclePriceId`
class ChooseRideSelectVehicle extends StatelessWidget {
  /// Vehicle list for single type mode
  final List<NormalVehicles> vehicleList;

  /// Vehicle sections for all types mode (with headers)
  final List<VehicleSection> vehicleSections;

  /// True when showing all types with sections
  final bool isShowingAllTypes;

  /// Selected index for single type mode
  final int selectedIndex;

  /// Selected section index for all types mode
  final int selectedSectionIndex;

  /// Selected vehicle index within section for all types mode
  final int selectedVehicleIndex;

  final String? currencySign;
  final CountrySettings? countrySetting;
  final List<CustomPrice>? customPrices;
  final List<AccessibilityPreference>? accessibilities;
  final List<String>? selectedAccessibilityIds;
  final bool isLoading;
  final String? error;
  final ScrollController scrollController;

  /// Controller for the DraggableScrollableSheet to enable drag from header
  final DraggableScrollableController? sheetController;

  final ValueChanged<int> onVehicleSelected;

  /// Callback when a vehicle is selected in sections mode
  /// Parameters: sectionIndex, vehicleIndex
  final void Function(int sectionIndex, int vehicleIndex)? onSectionVehicleSelected;

  final VoidCallback onRetry;

  /// Whether this is a destination-later booking (hides prices)
  final bool isDestinationLater;

  /// Current ride type — rental hides prices on vehicle cards
  final RideType? rideType;

  /// vehicleTypeId → estimated arrival seconds from distance matrix
  final Map<String, int> vehicleDurations;

  /// Title text for the header
  final String title;

  /// Whether to show the header (handle, title, divider)
  final bool showHeader;

  const ChooseRideSelectVehicle({
    super.key,
    required this.vehicleList,
    this.vehicleSections = const [],
    this.isShowingAllTypes = false,
    required this.selectedIndex,
    this.selectedSectionIndex = 0,
    this.selectedVehicleIndex = 0,
    required this.currencySign,
    required this.countrySetting,
    this.customPrices,
    this.accessibilities,
    this.selectedAccessibilityIds,
    this.isDestinationLater = false,
    this.rideType,
    this.vehicleDurations = const {},
    required this.isLoading,
    required this.error,
    required this.scrollController,
    this.sheetController,
    required this.onVehicleSelected,
    this.onSectionVehicleSelected,
    required this.onRetry,
    this.title = 'Choose a ride',
    this.showHeader = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      children: [
        // Header (handle, title, divider) - outside scroll view for drag-to-collapse
        if (showHeader)
          _DraggableHeader(
            sheetController: sheetController,
            scrollController: scrollController,
            child: _buildHeader(context, colors),
          ),

        // Scrollable content
        Expanded(
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              // Content
              if (isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (error != null)
                SliverFillRemaining(
                  child: _buildErrorState(context, error!),
                )
              else if (_isEmpty)
                SliverFillRemaining(
                  child: _buildEmptyState(context),
                )
              else
                _buildVehicleList(context),
            ],
          ),
        ),
      ],
    );
  }

  bool get _isEmpty {
    if (isShowingAllTypes) {
      return vehicleSections.isEmpty;
    }
    return vehicleList.isEmpty;
  }

  Widget _buildHeader(BuildContext context, AppColorPalette colors) {
    return Column(
      children: [
        // Handle
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: AppDimens.paddingM),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.colorText.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),

        // Title
        Padding(
          padding: const EdgeInsets.all(AppDimens.padding),
          child: AppText.title(
            title,
            fontWeight: FontWeight.w600,
          ),
        ),

        // Divider
        Divider(
          height: 1,
          color: colors.colorText.withValues(alpha: 0.1),
        ),
      ],
    );
  }

  Widget _buildVehicleList(BuildContext context) {
    if (isShowingAllTypes) {
      return _buildSectionsList(context);
    } else {
      return _buildFlatList(context);
    }
  }

  /// Build flat list for single ride type mode
  Widget _buildFlatList(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(AppDimens.padding),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final vehicle = vehicleList[index];
            return VehicleItem(
              index: index,
              vehicle: vehicle,
              isSelected: selectedIndex == index,
              currencySign: currencySign,
              countrySetting: countrySetting,
              customPrices: customPrices,
              accessibilities: accessibilities,
              selectedAccessibilityIds: selectedAccessibilityIds,
              isDestinationLater: isDestinationLater,
              isRental: rideType == RideType.rental,
              durationSeconds: vehicleDurations[vehicle.vehicleTypeId],
              onTap: () => onVehicleSelected(index),
            );
          },
          childCount: vehicleList.length,
        ),
      ),
    );
  }

  /// Build sectioned list for all ride types mode
  Widget _buildSectionsList(BuildContext context) {
    final items = _buildSectionItems();

    return SliverPadding(
      padding: const EdgeInsets.all(AppDimens.padding),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = items[index];
            if (item is _SectionHeader) {
              return _buildSectionHeader(context, item.title);
            } else if (item is _VehicleItemData) {
              final isSelected = item.sectionIndex == selectedSectionIndex &&
                  item.vehicleIndex == selectedVehicleIndex;
              return VehicleItem(
                index: item.vehicleIndex,
                vehicle: item.vehicle,
                isSelected: isSelected,
                currencySign: currencySign,
                countrySetting: countrySetting,
                customPrices: customPrices,
                accessibilities: accessibilities,
                selectedAccessibilityIds: selectedAccessibilityIds,
                isDestinationLater: isDestinationLater,
                isRental: item.sectionRideType == RideType.rental,
                durationSeconds: vehicleDurations[item.vehicle.vehicleTypeId],
                onTap: () => onSectionVehicleSelected?.call(item.sectionIndex, item.vehicleIndex),
              );
            }
            return const SizedBox.shrink();
          },
          childCount: items.length,
        ),
      ),
    );
  }

  /// Build list of section items (headers and vehicles)
  List<dynamic> _buildSectionItems() {
    final items = <dynamic>[];

    for (int sectionIndex = 0; sectionIndex < vehicleSections.length; sectionIndex++) {
      final section = vehicleSections[sectionIndex];

      // Add header
      items.add(_SectionHeader(title: section.title));

      // Add vehicles
      for (int vehicleIndex = 0; vehicleIndex < section.vehicles.length; vehicleIndex++) {
        items.add(_VehicleItemData(
          sectionIndex: sectionIndex,
          vehicleIndex: vehicleIndex,
          vehicle: section.vehicles[vehicleIndex],
          sectionRideType: section.rideType,
        ));
      }
    }

    return items;
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.only(
        top: AppDimens.paddingM,
        bottom: AppDimens.paddingS,
      ),
      child: AppText.body(
        title,
        fontWeight: FontWeight.w600,
        color: colors.colorText,
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    final colors = context.colors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.padding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: colors.colorText,
              size: 48,
            ),
            const SizedBox(height: AppDimens.padding),
            AppText.body(
              getString(appStr.errorUnableToLoadVehicles, 'error_unable_to_load_vehicles'),
              fontWeight: FontWeight.w600,
              color: colors.colorText,
            ),
            const SizedBox(height: AppDimens.paddingS),
            AppText.body(
              error,
              color: colors.colorText,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.padding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.directions_car_outlined,
              color: colors.colorText,
              size: 48,
            ),
            const SizedBox(height: AppDimens.padding),
            AppText.body(
              getString(appStr.errorNoVehiclesAvailable, 'error_no_vehicles_available'),
              fontWeight: FontWeight.w600,
              color: colors.colorText,
            ),
            const SizedBox(height: AppDimens.paddingS),
            AppText.body(
              getString(appStr.errorNoVehiclesDescription, 'error_no_vehicles_description'),
              color: colors.colorText,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Internal class for section header
class _SectionHeader {
  final String title;
  const _SectionHeader({required this.title});
}

/// Internal class for vehicle item data
class _VehicleItemData {
  final int sectionIndex;
  final int vehicleIndex;
  final NormalVehicles vehicle;
  final RideType? sectionRideType;
  const _VehicleItemData({
    required this.sectionIndex,
    required this.vehicleIndex,
    required this.vehicle,
    this.sectionRideType,
  });
}

/// Draggable header widget that controls the sheet via drag gestures
class _DraggableHeader extends StatefulWidget {
  final DraggableScrollableController? sheetController;
  final ScrollController scrollController;
  final Widget child;

  const _DraggableHeader({
    required this.sheetController,
    required this.scrollController,
    required this.child,
  });

  @override
  State<_DraggableHeader> createState() => _DraggableHeaderState();
}

class _DraggableHeaderState extends State<_DraggableHeader> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: _onDragUpdate,
      onVerticalDragEnd: _onDragEnd,
      child: widget.child,
    );
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final controller = widget.sheetController;
    if (controller == null) return;

    // Calculate new size based on drag delta
    final screenHeight = MediaQuery.of(context).size.height;
    final delta = -details.delta.dy / screenHeight;
    final newSize = (controller.size + delta).clamp(0.45, 0.9);

    controller.jumpTo(newSize);
  }

  void _onDragEnd(DragEndDetails details) {
    final controller = widget.sheetController;
    if (controller == null) return;

    // Snap to nearest position based on velocity and current position
    final velocity = details.primaryVelocity ?? 0;
    final currentSize = controller.size;

    double targetSize;
    if (velocity < -500) {
      // Fast swipe up - expand
      targetSize = 0.9;
    } else if (velocity > 500) {
      // Fast swipe down - collapse
      targetSize = 0.45;
    } else {
      // Snap to nearest
      targetSize = currentSize > 0.675 ? 0.9 : 0.45;
    }

    controller.animateTo(
      targetSize,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );

    // Scroll content to top when collapsing
    if (targetSize == 0.45 && widget.scrollController.hasClients) {
      widget.scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }
}
