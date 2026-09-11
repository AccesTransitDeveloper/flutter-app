import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../models/common/filters_result.dart';
import '../models/responses/booking/accessibility_preference.dart';
import '../models/responses/booking/get_vehicle_type_response.dart';
import '../models/responses/booking/speaking_language.dart';

/// Generic filter option for gender, capacity, etc.
class FilterOption {
  final String id;
  final String name;
  final bool isSelected;

  const FilterOption({
    required this.id,
    required this.name,
    this.isSelected = false,
  });

  FilterOption copyWith({bool? isSelected}) {
    return FilterOption(
      id: id,
      name: name,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

/// Accessibility filter state
class AccessibilityFilterState {
  final List<AccessibilityPreference> accessibilityList;
  final List<SpeakingLanguage> languageList;
  final List<FilterOption> genderList;
  final List<FilterOption> capacityList;
  final List<FilterOption> luggageCapacityList;

  // Visibility flags
  final bool isShowAccessibility;
  final bool isShowLanguage;
  final bool isAllowGenderSelection;
  final bool isShowCapacity;
  final bool isShowLuggageCapacity;

  const AccessibilityFilterState({
    this.accessibilityList = const [],
    this.languageList = const [],
    this.genderList = const [],
    this.capacityList = const [],
    this.luggageCapacityList = const [],
    this.isShowAccessibility = false,
    this.isShowLanguage = false,
    this.isAllowGenderSelection = false,
    this.isShowCapacity = false,
    this.isShowLuggageCapacity = false,
  });

  /// Check if any filter section is visible
  bool get hasAnySection =>
      isShowAccessibility ||
      isShowLanguage ||
      isAllowGenderSelection ||
      isShowCapacity ||
      isShowLuggageCapacity;

  AccessibilityFilterState copyWith({
    List<AccessibilityPreference>? accessibilityList,
    List<SpeakingLanguage>? languageList,
    List<FilterOption>? genderList,
    List<FilterOption>? capacityList,
    List<FilterOption>? luggageCapacityList,
    bool? isShowAccessibility,
    bool? isShowLanguage,
    bool? isAllowGenderSelection,
    bool? isShowCapacity,
    bool? isShowLuggageCapacity,
  }) {
    return AccessibilityFilterState(
      accessibilityList: accessibilityList ?? this.accessibilityList,
      languageList: languageList ?? this.languageList,
      genderList: genderList ?? this.genderList,
      capacityList: capacityList ?? this.capacityList,
      luggageCapacityList: luggageCapacityList ?? this.luggageCapacityList,
      isShowAccessibility: isShowAccessibility ?? this.isShowAccessibility,
      isShowLanguage: isShowLanguage ?? this.isShowLanguage,
      isAllowGenderSelection:
          isAllowGenderSelection ?? this.isAllowGenderSelection,
      isShowCapacity: isShowCapacity ?? this.isShowCapacity,
      isShowLuggageCapacity:
          isShowLuggageCapacity ?? this.isShowLuggageCapacity,
    );
  }
}

/// Accessibility filter view model
class AccessibilityFilterViewModel
    extends StateNotifier<AccessibilityFilterState> {
  AccessibilityFilterViewModel() : super(const AccessibilityFilterState());

  /// Initialize filter data from vehicle type response
  void initializeFromVehicleResponse(
    GetVehicleTypeResponse? response,
    RideType? rideType,
  ) {
    if (response == null) return;

    // Get vehicle list based on ride type
    final vehicleList = _getVehicleListByRideType(response, rideType);

    // Extract unique capacities
    final capacitySet = <int>{};
    final luggageCapacitySet = <int>{};
    for (final vehicle in vehicleList) {
      final passengerCapacity = vehicle.vehicleTypeDetail?.passengerCapacity;
      final luggageCapacity = vehicle.vehicleTypeDetail?.luggageCapacity;
      if (passengerCapacity != null) capacitySet.add(passengerCapacity);
      if (luggageCapacity != null) luggageCapacitySet.add(luggageCapacity);
    }

    // Sort and convert to FilterOption
    final capacityList = capacitySet.toList()..sort();
    final luggageCapacityList = luggageCapacitySet.toList()..sort();

    // Check booking settings for capacity visibility
    final bookingSetting = response.citySetting?.bookingSetting;
    final settingList = _getBookingSettingList(bookingSetting, rideType);

    // Initialize gender list
    final genderList = [
      const FilterOption(id: 'MALE', name: 'Male'),
      const FilterOption(id: 'FEMALE', name: 'Female'),
    ];

    state = state.copyWith(
      accessibilityList: response.accessibilities ?? [],
      languageList: response.countrySetting?.speakingLanguages ?? [],
      genderList: genderList,
      capacityList: capacityList
          .map((c) => FilterOption(id: c.toString(), name: c.toString()))
          .toList(),
      luggageCapacityList: luggageCapacityList
          .map((c) => FilterOption(id: c.toString(), name: c.toString()))
          .toList(),
      isShowAccessibility: (response.accessibilities ?? []).isNotEmpty,
      isShowLanguage:
          (response.countrySetting?.speakingLanguages ?? []).isNotEmpty,
      isAllowGenderSelection:
          response.countrySetting?.isAllowGenderSelection == true,
      isShowCapacity:
          settingList?.contains(BookingSettingConstant.showPassengerCapacity) == true,
      isShowLuggageCapacity:
          settingList?.contains(BookingSettingConstant.showLuggageCapacity) == true,
    );
  }

  /// Get vehicle list based on ride type
  List<NormalVehicles> _getVehicleListByRideType(
    GetVehicleTypeResponse response,
    RideType? rideType,
  ) {
    return switch (rideType) {
      RideType.normal => response.normalList ?? [],
      RideType.rental => response.rentalList ?? [],
      RideType.sharing => response.shareList ?? [],
      RideType.fixGroup => response.fixGroupBookingList ?? [],
      null => [
          ...response.normalList ?? [],
          ...response.rentalList ?? [],
          ...response.shareList ?? [],
          ...response.fixGroupBookingList ?? [],
        ],
    };
  }

  /// Get booking setting list for ride type
  List<String>? _getBookingSettingList(
    BusinessSettings? settings,
    RideType? rideType,
  ) {
    return switch (rideType) {
      RideType.normal => settings?.normal,
      RideType.rental => settings?.rental,
      RideType.sharing => settings?.share,
      RideType.fixGroup => settings?.fixGroupBooking,
      null => settings?.normal,
    };
  }

  /// Restore previous selections from FiltersResult
  void restorePreviousSelections(FiltersResult? filters) {
    if (filters == null) return;

    // Restore accessibility selections (multi-select)
    final updatedAccessibility = state.accessibilityList.map((item) {
      final isSelected = filters.selectedAccessibility.contains(item.id);
      return item.copyWith(isSelected: isSelected);
    }).toList();

    // Restore language selection (single-select)
    final updatedLanguage = state.languageList.map((item) {
      final isSelected = filters.selectedLanguage.contains(item.code);
      return item.copyWith(isSelected: isSelected);
    }).toList();

    // Restore gender selection (single-select)
    final updatedGender = state.genderList.map((item) {
      final isSelected = filters.selectedGender.contains(item.id);
      return item.copyWith(isSelected: isSelected);
    }).toList();

    // Restore capacity selection (single-select)
    final updatedCapacity = state.capacityList.map((item) {
      final isSelected = filters.selectedCapacity.contains(item.id);
      return item.copyWith(isSelected: isSelected);
    }).toList();

    // Restore luggage capacity selection (single-select)
    final updatedLuggageCapacity = state.luggageCapacityList.map((item) {
      final isSelected = filters.selectedLuggageCapacity.contains(item.id);
      return item.copyWith(isSelected: isSelected);
    }).toList();

    state = state.copyWith(
      accessibilityList: updatedAccessibility,
      languageList: updatedLanguage,
      genderList: updatedGender,
      capacityList: updatedCapacity,
      luggageCapacityList: updatedLuggageCapacity,
    );
  }

  /// Toggle accessibility selection (multi-select)
  void toggleAccessibility(int index) {
    if (index < 0 || index >= state.accessibilityList.length) return;

    final updatedList = state.accessibilityList.asMap().entries.map((entry) {
      if (entry.key == index) {
        return entry.value.copyWith(isSelected: !entry.value.isSelected);
      }
      return entry.value;
    }).toList();

    state = state.copyWith(accessibilityList: updatedList);
  }

  /// Select language (single-select)
  void selectLanguage(int index) {
    if (index < 0 || index >= state.languageList.length) return;

    final updatedList = state.languageList.asMap().entries.map((entry) {
      return entry.value.copyWith(isSelected: entry.key == index);
    }).toList();

    state = state.copyWith(languageList: updatedList);
  }

  /// Select gender (single-select)
  void selectGender(int index) {
    if (index < 0 || index >= state.genderList.length) return;

    final updatedList = state.genderList.asMap().entries.map((entry) {
      return entry.value.copyWith(isSelected: entry.key == index);
    }).toList();

    state = state.copyWith(genderList: updatedList);
  }

  /// Select capacity (single-select)
  void selectCapacity(int index) {
    if (index < 0 || index >= state.capacityList.length) return;

    final updatedList = state.capacityList.asMap().entries.map((entry) {
      return entry.value.copyWith(isSelected: entry.key == index);
    }).toList();

    state = state.copyWith(capacityList: updatedList);
  }

  /// Select luggage capacity (single-select)
  void selectLuggageCapacity(int index) {
    if (index < 0 || index >= state.luggageCapacityList.length) return;

    final updatedList = state.luggageCapacityList.asMap().entries.map((entry) {
      return entry.value.copyWith(isSelected: entry.key == index);
    }).toList();

    state = state.copyWith(luggageCapacityList: updatedList);
  }

  /// Clear all filter selections
  void clearAllFilters() {
    state = state.copyWith(
      accessibilityList:
          state.accessibilityList.map((e) => e.copyWith(isSelected: false)).toList(),
      languageList:
          state.languageList.map((e) => e.copyWith(isSelected: false)).toList(),
      genderList:
          state.genderList.map((e) => e.copyWith(isSelected: false)).toList(),
      capacityList:
          state.capacityList.map((e) => e.copyWith(isSelected: false)).toList(),
      luggageCapacityList: state.luggageCapacityList
          .map((e) => e.copyWith(isSelected: false))
          .toList(),
    );
  }

  /// Build FiltersResult from current selections
  FiltersResult buildFiltersResult() {
    return FiltersResult(
      selectedAccessibility: state.accessibilityList
          .where((e) => e.isSelected)
          .map((e) => e.id ?? '')
          .where((id) => id.isNotEmpty)
          .toList(),
      selectedLanguage: state.languageList
          .where((e) => e.isSelected)
          .map((e) => e.code ?? '')
          .where((code) => code.isNotEmpty)
          .toList(),
      selectedGender: state.genderList
          .where((e) => e.isSelected)
          .map((e) => e.id)
          .toList(),
      selectedCapacity: state.capacityList
          .where((e) => e.isSelected)
          .map((e) => e.id)
          .toList(),
      selectedLuggageCapacity: state.luggageCapacityList
          .where((e) => e.isSelected)
          .map((e) => e.id)
          .toList(),
    );
  }
}

/// Provider for accessibility filter view model
final accessibilityFilterViewModelProvider = StateNotifierProvider.autoDispose<
    AccessibilityFilterViewModel, AccessibilityFilterState>(
  (ref) => AccessibilityFilterViewModel(),
);
