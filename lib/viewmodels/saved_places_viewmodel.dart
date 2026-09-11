import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/localization/app_strings.dart';
import '../data/api/response_state.dart';
import '../data/repository/app_repository.dart';
import '../models/requests/get_vehicle_types_request.dart';
import '../models/responses/address/address_response.dart';

/// State class for SavedPlacesScreen
class SavedPlacesState {
  final bool isLoading;
  final List<SavedAddress> addresses;
  final String? error;
  final String? successMessage;
  final String? deletingAddressId;

  // Add/Edit mode state
  final bool isAddEditMode;
  final SavedAddress? editingAddress;
  final int? selectedAddressType;
  final String nickname;
  final DestinationAddress? selectedLocation;
  final bool isSaving;

  SavedPlacesState({
    this.isLoading = false,
    this.addresses = const [],
    this.error,
    this.successMessage,
    this.deletingAddressId,
    this.isAddEditMode = false,
    this.editingAddress,
    this.selectedAddressType,
    this.nickname = '',
    this.selectedLocation,
    this.isSaving = false,
  });

  SavedPlacesState copyWith({
    bool? isLoading,
    List<SavedAddress>? addresses,
    String? error,
    String? successMessage,
    String? deletingAddressId,
    bool? isAddEditMode,
    SavedAddress? editingAddress,
    int? selectedAddressType,
    String? nickname,
    DestinationAddress? selectedLocation,
    bool? isSaving,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearDeleting = false,
    bool clearEditingAddress = false,
    bool clearSelectedLocation = false,
  }) {
    return SavedPlacesState(
      isLoading: isLoading ?? this.isLoading,
      addresses: addresses ?? this.addresses,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
      deletingAddressId: clearDeleting ? null : (deletingAddressId ?? this.deletingAddressId),
      isAddEditMode: isAddEditMode ?? this.isAddEditMode,
      editingAddress: clearEditingAddress ? null : (editingAddress ?? this.editingAddress),
      selectedAddressType: selectedAddressType ?? this.selectedAddressType,
      nickname: nickname ?? this.nickname,
      selectedLocation: clearSelectedLocation ? null : (selectedLocation ?? this.selectedLocation),
      isSaving: isSaving ?? this.isSaving,
    );
  }

  /// Get home address if exists
  SavedAddress? get homeAddress => addresses
      .where((a) => a.addressType == AddressType.home)
      .firstOrNull;

  /// Get work address if exists
  SavedAddress? get workAddress => addresses
      .where((a) => a.addressType == AddressType.work)
      .firstOrNull;

  /// Get other (custom) addresses
  List<SavedAddress> get otherAddresses => addresses
      .where((a) => a.addressType != AddressType.home && a.addressType != AddressType.work)
      .toList();

  /// Check if save button should be enabled
  bool get canSave =>
      nickname.isNotEmpty && selectedLocation != null && !isSaving;

  /// Check if we're editing an existing address
  bool get isEditing => editingAddress != null;
}

/// ViewModel for SavedPlacesScreen
class SavedPlacesViewModel extends StateNotifier<SavedPlacesState> {
  final AppRepository _appRepository;

  SavedPlacesViewModel(this._appRepository) : super(SavedPlacesState()) {
    loadAddresses();
  }

  /// Load all saved addresses from API
  Future<void> loadAddresses() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final response = await _appRepository.getAddresses();

    switch (response) {
      case Success(data: final data):
        state = state.copyWith(
          isLoading: false,
          addresses: data?.addresses ?? [],
        );
        debugPrint('📍 SavedPlacesViewModel: Loaded ${data?.addresses?.length ?? 0} addresses');

      default:
        state = state.copyWith(
          isLoading: false,
          error: response.message ?? 'Failed to load addresses',
        );
        debugPrint('📍 SavedPlacesViewModel: Error loading addresses - ${response.message}');
    }
  }

  /// Delete an address by ID
  Future<void> deleteAddress(String addressId) async {
    state = state.copyWith(deletingAddressId: addressId);

    final response = await _appRepository.deleteAddress(addressId);

    switch (response) {
      case Success():
        // Remove from local list
        final updatedAddresses = state.addresses
            .where((a) => a.id != addressId)
            .toList();
        state = state.copyWith(
          addresses: updatedAddresses,
          clearDeleting: true,
          successMessage: 'Address deleted',
        );
        debugPrint('📍 SavedPlacesViewModel: Address deleted successfully');

      default:
        state = state.copyWith(
          clearDeleting: true,
          error: response.message ?? 'Failed to delete address',
        );
        debugPrint('📍 SavedPlacesViewModel: Error deleting address - ${response.message}');
    }
  }

  // ==================== Add/Edit Mode Methods ====================

  /// Enter add mode with a specific address type
  void enterAddMode(int addressType) {
    String defaultNickname = '';
    if (addressType == AddressType.home) {
      defaultNickname = 'Home';
    } else if (addressType == AddressType.work) {
      defaultNickname = 'Work';
    }

    state = state.copyWith(
      isAddEditMode: true,
      clearEditingAddress: true,
      selectedAddressType: addressType,
      nickname: defaultNickname,
      clearSelectedLocation: true,
    );
    debugPrint('📍 SavedPlacesViewModel: Entered add mode for type $addressType');
  }

  /// Enter edit mode with an existing address
  void enterEditMode(SavedAddress address) {
    state = state.copyWith(
      isAddEditMode: true,
      editingAddress: address,
      selectedAddressType: address.addressType ?? AddressType.other,
      nickname: address.title ?? '',
      selectedLocation: address.toDestinationAddress(),
    );
    debugPrint('📍 SavedPlacesViewModel: Entered edit mode for address ${address.id}');
  }

  /// Exit add/edit mode
  void exitAddEditMode() {
    state = state.copyWith(
      isAddEditMode: false,
      clearEditingAddress: true,
      selectedAddressType: null,
      nickname: '',
      clearSelectedLocation: true,
      isSaving: false,
    );
    debugPrint('📍 SavedPlacesViewModel: Exited add/edit mode');
  }

  /// Update nickname
  void setNickname(String nickname) {
    state = state.copyWith(nickname: nickname);
  }

  /// Set selected location from location picker
  void setSelectedLocation(DestinationAddress location) {
    state = state.copyWith(selectedLocation: location);
    debugPrint('📍 SavedPlacesViewModel: Selected location - ${location.address}');
  }

  /// Validate address fields before saving
  bool _validateAddress() {
    if (state.nickname.trim().isEmpty) {
      state = state.copyWith(
        error: getString(null, 'error_please_enter_address_title'),
      );
      return false;
    }
    if (state.selectedLocation?.address == null ||
        state.selectedLocation!.address!.isEmpty) {
      state = state.copyWith(
        error: getString(null, 'error_please_enter_address'),
      );
      return false;
    }
    return true;
  }

  /// Save the address (add or update)
  Future<bool> saveAddress() async {
    if (state.isSaving) return false;
    if (!_validateAddress()) return false;

    state = state.copyWith(isSaving: true, clearError: true);

    final address = DestinationAddress(
      address: state.selectedLocation?.address,
      title: state.nickname,
      addressType: state.selectedAddressType,
      city: state.selectedLocation?.city,
      country: state.selectedLocation?.country,
      countryCode: state.selectedLocation?.countryCode,
      latitude: state.selectedLocation?.latitude,
      longitude: state.selectedLocation?.longitude,
      note: state.selectedLocation?.note,
      placeId: state.selectedLocation?.placeId,
      postalCode: state.selectedLocation?.postalCode,
      metadata: state.selectedLocation?.metadata,
    );

    ResponseState<AddressResponse> response;

    if (state.isEditing && state.editingAddress?.id != null) {
      // Update existing address
      response = await _appRepository.updateAddress(
        state.editingAddress!.id!,
        address,
      );
    } else {
      // Add new address
      response = await _appRepository.addAddress(address);
    }

    switch (response) {
      case Success():
        state = state.copyWith(
          isSaving: false,
          successMessage: '${state.nickname} has been ${state.isEditing ? 'updated' : 'added'}',
        );
        debugPrint('📍 SavedPlacesViewModel: Address saved successfully');
        // Reload addresses to get fresh data
        await loadAddresses();
        exitAddEditMode();
        return true;

      default:
        state = state.copyWith(
          isSaving: false,
          error: response.message ?? 'Failed to save address',
        );
        debugPrint('📍 SavedPlacesViewModel: Error saving address - ${response.message}');
        return false;
    }
  }

  /// Refresh addresses list
  Future<void> refresh() async {
    await loadAddresses();
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Clear success message
  void clearSuccessMessage() {
    state = state.copyWith(clearSuccess: true);
  }
}

/// Provider for SavedPlacesViewModel
final savedPlacesViewModelProvider =
    StateNotifierProvider<SavedPlacesViewModel, SavedPlacesState>(
  (ref) {
    final appRepository = ref.watch(appRepositoryProvider);
    return SavedPlacesViewModel(appRepository);
  },
);
