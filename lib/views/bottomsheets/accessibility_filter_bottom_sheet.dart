import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme.dart';
import '../../models/common/filters_result.dart';
import '../../models/responses/booking/get_vehicle_type_response.dart';
import '../../viewmodels/accessibility_filter_viewmodel.dart';
import '../widgets/app_button.dart';
import '../widgets/filter_chip_group.dart';

class AccessibilityFilterBottomSheet extends ConsumerStatefulWidget {
  final GetVehicleTypeResponse? vehicleTypeResponse;
  final RideType? rideType;
  final FiltersResult? currentFilters;

  const AccessibilityFilterBottomSheet({
    super.key,
    this.vehicleTypeResponse,
    this.rideType,
    this.currentFilters,
  });

  /// Shows the accessibility filter bottom sheet and returns the result
  static Future<FiltersResult?> show({
    required BuildContext context,
    GetVehicleTypeResponse? vehicleTypeResponse,
    RideType? rideType,
    FiltersResult? currentFilters,
  }) {
    return showModalBottomSheet<FiltersResult>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AccessibilityFilterBottomSheet(
        vehicleTypeResponse: vehicleTypeResponse,
        rideType: rideType,
        currentFilters: currentFilters,
      ),
    );
  }

  @override
  ConsumerState<AccessibilityFilterBottomSheet> createState() =>
      _AccessibilityFilterBottomSheetState();
}

class _AccessibilityFilterBottomSheetState
    extends ConsumerState<AccessibilityFilterBottomSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel =
          ref.read(accessibilityFilterViewModelProvider.notifier);
      viewModel.initializeFromVehicleResponse(
        widget.vehicleTypeResponse,
        widget.rideType,
      );
      viewModel.restorePreviousSelections(widget.currentFilters);
    });
  }

  void _onApply() {
    final viewModel = ref.read(accessibilityFilterViewModelProvider.notifier);
    final result = viewModel.buildFiltersResult();
    Navigator.pop(context, result);
  }

  void _onClear() {
    ref.read(accessibilityFilterViewModelProvider.notifier).clearAllFilters();
  }

  void _onExit() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = ref.watch(accessibilityFilterViewModelProvider);
    final viewModel = ref.read(accessibilityFilterViewModelProvider.notifier);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: colors.colorBackground,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimens.paddingL),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          _buildHeader(colors),

          // Divider
          Divider(height: 1, color: colors.colorBackgroundGray),

          // Content
          Flexible(
            child: state.hasAnySection
                ? SingleChildScrollView(
                    padding: const EdgeInsets.all(AppDimens.padding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Accessibility section
                        if (state.isShowAccessibility)
                          FilterChipGroup(
                            title: 'Accessibility Preference',
                            items: state.accessibilityList,
                            isSelected: (item) => item.isSelected,
                            getLabel: (item) => item.accessibility ?? '',
                            onItemTap: viewModel.toggleAccessibility,
                            isMultiSelect: true,
                          ),

                        // Language section
                        if (state.isShowLanguage)
                          FilterChipGroup(
                            title: 'Language Preference',
                            items: state.languageList,
                            isSelected: (item) => item.isSelected,
                            getLabel: (item) => item.name ?? '',
                            onItemTap: viewModel.selectLanguage,
                          ),

                        // Gender section
                        if (state.isAllowGenderSelection)
                          FilterChipGroup(
                            title: 'Gender Preference',
                            items: state.genderList,
                            isSelected: (item) => item.isSelected,
                            getLabel: (item) => item.name,
                            onItemTap: viewModel.selectGender,
                          ),

                        // Capacity section
                        if (state.isShowCapacity)
                          FilterChipGroup(
                            title: 'Passenger Capacity',
                            items: state.capacityList,
                            isSelected: (item) => item.isSelected,
                            getLabel: (item) => item.name,
                            onItemTap: viewModel.selectCapacity,
                          ),

                        // Luggage capacity section
                        if (state.isShowLuggageCapacity)
                          FilterChipGroup(
                            title: 'Luggage Capacity',
                            items: state.luggageCapacityList,
                            isSelected: (item) => item.isSelected,
                            getLabel: (item) => item.name,
                            onItemTap: viewModel.selectLuggageCapacity,
                          ),
                      ],
                    ),
                  )
                : _buildEmptyState(colors),
          ),

          // Bottom buttons
          _buildBottomButtons(colors),
        ],
      ),
    );
  }

  Widget _buildHeader(AppColorPalette colors) {
    return Padding(
      padding: const EdgeInsets.all(AppDimens.padding),
      child: Row(
        children: [
          GestureDetector(
            onTap: _onExit,
            child: Icon(
              Icons.arrow_back,
              color: colors.colorText,
              size: AppDimens.iconSize,
            ),
          ),
          const SizedBox(width: AppDimens.padding),
          Expanded(
            child: Text(
              'Filters',
              style: TextStyle(
                fontSize: AppTypos.textL,
                fontWeight: FontWeight.w600,
                color: colors.colorText,
              ),
            ),
          ),
          GestureDetector(
            onTap: _onClear,
            child: Text(
              'Clear Filter',
              style: TextStyle(
                fontSize: AppTypos.text,
                fontWeight: FontWeight.w500,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppColorPalette colors) {
    return Padding(
      padding: const EdgeInsets.all(AppDimens.paddingXL),
      child: Center(
        child: Text(
          'No filters available',
          style: TextStyle(
            fontSize: AppTypos.textM,
            color: colors.colorTextHint,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButtons(AppColorPalette colors) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.padding),
        child: Row(
          children: [
            Expanded(
              child: AppFilledButton(
                text: 'Apply',
                onPressed: _onApply,
              ),
            ),
            const SizedBox(width: AppDimens.paddingM),
            Expanded(
              child: AppOutlinedButton(
                text: 'Exit',
                onPressed: _onExit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
