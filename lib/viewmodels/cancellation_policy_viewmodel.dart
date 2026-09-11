import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/api/response_state.dart';
import '../data/repository/app_repository.dart';
import '../models/responses/booking/cancellation_policy_response.dart';

/// Cancellation policy screen state
class CancellationPolicyState {
  final List<String> policyItems;
  final bool isLoading;
  final String? error;

  const CancellationPolicyState({
    this.policyItems = const [],
    this.isLoading = false,
    this.error,
  });

  CancellationPolicyState copyWith({
    List<String>? policyItems,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return CancellationPolicyState(
      policyItems: policyItems ?? this.policyItems,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Cancellation policy ViewModel
class CancellationPolicyViewModel extends StateNotifier<CancellationPolicyState> {
  final AppRepository _appRepository;
  final String vehiclePriceId;

  CancellationPolicyViewModel(this._appRepository, this.vehiclePriceId)
      : super(const CancellationPolicyState()) {
    loadCancellationPolicy();
  }

  /// Load cancellation policy from API
  Future<void> loadCancellationPolicy() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final response = await _appRepository.getCancellationPolicy(vehiclePriceId);

    switch (response) {
      case Success<CancellationPolicyResponse>():
        state = state.copyWith(
          isLoading: false,
          policyItems: response.data?.cancellationPolicy ?? [],
        );
      case Error():
        state = state.copyWith(
          isLoading: false,
          error: response.error?.message ?? 'Failed to load cancellation policy',
        );
      case Loading():
        break;
    }
  }

  /// Refresh cancellation policy
  Future<void> refresh() async {
    await loadCancellationPolicy();
  }
}

/// Provider for CancellationPolicyViewModel
final cancellationPolicyViewModelProvider = StateNotifierProvider.autoDispose
    .family<CancellationPolicyViewModel, CancellationPolicyState, String>(
        (ref, vehiclePriceId) {
  final appRepository = ref.watch(appRepositoryProvider);
  return CancellationPolicyViewModel(appRepository, vehiclePriceId);
});
