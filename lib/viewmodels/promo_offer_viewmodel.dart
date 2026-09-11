import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/api/response_state.dart';
import '../data/repository/app_repository.dart';
import '../models/requests/promo_code_list_request.dart';
import '../models/requests/validate_promo_code_request.dart';
import '../models/responses/booking/promo_code_response.dart';

/// Promo offer screen state
class PromoOfferState {
  final List<PromoCodes> promoCodesList;
  final bool isLoading;
  final bool isDataLoading;
  final String? error;
  final String? snackBarMessage;
  final PromoDetail? selectedPromo;
  final bool isNavigateBack;

  const PromoOfferState({
    this.promoCodesList = const [],
    this.isLoading = false,
    this.isDataLoading = true,
    this.error,
    this.snackBarMessage,
    this.selectedPromo,
    this.isNavigateBack = false,
  });

  PromoOfferState copyWith({
    List<PromoCodes>? promoCodesList,
    bool? isLoading,
    bool? isDataLoading,
    String? error,
    String? snackBarMessage,
    PromoDetail? selectedPromo,
    bool? isNavigateBack,
    bool clearError = false,
    bool clearSnackBar = false,
    bool clearSelectedPromo = false,
  }) {
    return PromoOfferState(
      promoCodesList: promoCodesList ?? this.promoCodesList,
      isLoading: isLoading ?? this.isLoading,
      isDataLoading: isDataLoading ?? this.isDataLoading,
      error: clearError ? null : (error ?? this.error),
      snackBarMessage: clearSnackBar ? null : (snackBarMessage ?? this.snackBarMessage),
      selectedPromo: clearSelectedPromo ? null : (selectedPromo ?? this.selectedPromo),
      isNavigateBack: isNavigateBack ?? this.isNavigateBack,
    );
  }
}

/// Parameters needed to initialize the promo offer screen
class PromoOfferParams {
  final PromoCodeListRequest promoCodeListRequest;
  final int bookingTime;
  final int priceMode;
  final int paymentMode;
  final double? latitude;
  final double? longitude;

  const PromoOfferParams({
    required this.promoCodeListRequest,
    this.bookingTime = 0,
    this.priceMode = 0,
    this.paymentMode = 0,
    this.latitude,
    this.longitude,
  });
}

/// Promo offer ViewModel
class PromoOfferViewModel extends StateNotifier<PromoOfferState> {
  final AppRepository _appRepository;
  final PromoOfferParams params;

  PromoOfferViewModel(this._appRepository, this.params)
      : super(const PromoOfferState()) {
    loadPromoCodes();
  }

  /// Load promo codes from API
  Future<void> loadPromoCodes() async {
    state = state.copyWith(isLoading: true, isDataLoading: true, clearError: true);

    final response = await _appRepository.getPromoCodes(params.promoCodeListRequest);

    switch (response) {
      case Success<PromoCodeResponse>():
        state = state.copyWith(
          isLoading: false,
          isDataLoading: false,
          promoCodesList: response.data?.promoCodes ?? [],
        );
      case Error():
        state = state.copyWith(
          isLoading: false,
          isDataLoading: false,
          error: response.error?.message ?? 'Failed to load promo codes',
        );
      case Loading():
        break;
    }
  }

  /// Apply promo code
  Future<void> applyPromoCode(PromoCodes promoCode) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final bookingTime = params.bookingTime == 0
        ? DateTime.now().millisecondsSinceEpoch
        : params.bookingTime;

    final request = ValidatePromoCodeRequest(
      latitude: params.latitude,
      longitude: params.longitude,
      promoCode: promoCode.code,
      paymentMethod: params.paymentMode,
      cityId: params.promoCodeListRequest.cityId,
      bookingTime: bookingTime,
      vehicleTypeId: params.promoCodeListRequest.vehicleTypeId,
      priceMode: params.priceMode == 0 ? null : params.priceMode,
    );

    final response = await _appRepository.validatePromoCode(request);

    switch (response) {
      case Success<ValidatePromoCodeResponse>():
        state = state.copyWith(
          isLoading: false,
          selectedPromo: response.data?.promoDetail,
          isNavigateBack: true,
        );
      case Error():
        state = state.copyWith(
          isLoading: false,
          snackBarMessage: response.error?.message ?? 'Failed to validate promo code',
        );
      case Loading():
        break;
    }
  }

  /// Clear snack bar message
  void clearSnackBar() {
    state = state.copyWith(clearSnackBar: true);
  }

  /// Reset navigation state
  void resetNavigation() {
    state = state.copyWith(
      isNavigateBack: false,
      clearSelectedPromo: true,
    );
  }

  /// Refresh promo codes
  Future<void> refresh() async {
    await loadPromoCodes();
  }
}

/// Provider for PromoOfferViewModel
final promoOfferViewModelProvider = StateNotifierProvider.autoDispose
    .family<PromoOfferViewModel, PromoOfferState, PromoOfferParams>(
        (ref, params) {
  final appRepository = ref.watch(appRepositoryProvider);
  return PromoOfferViewModel(appRepository, params);
});
