import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../core/localization/app_strings.dart';
import '../core/localization/string_constants.dart';
import '../core/preferences/shared_preference_manager.dart';
import '../core/providers/app_providers.dart';
import '../data/api/response_state.dart';
import '../data/repository/app_repository.dart';
import '../models/responses/referral/referral_history_response.dart';

/// Referral screen state
class ReferralState {
  final String referralCode;
  final List<String> referralPolicy;
  final bool showReferralHistory;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const ReferralState({
    this.referralCode = '',
    this.referralPolicy = const [],
    this.showReferralHistory = false,
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  ReferralState copyWith({
    String? referralCode,
    List<String>? referralPolicy,
    bool? showReferralHistory,
    bool? isLoading,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return ReferralState(
      referralCode: referralCode ?? this.referralCode,
      referralPolicy: referralPolicy ?? this.referralPolicy,
      showReferralHistory: showReferralHistory ?? this.showReferralHistory,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

/// Referral screen ViewModel
class ReferralViewModel extends StateNotifier<ReferralState> {
  final SharedPreferenceManager _sharedPref;

  ReferralViewModel(this._sharedPref) : super(const ReferralState()) {
    _loadReferralData();
  }

  void _loadReferralData() {
    final entity = _sharedPref.getEntity();
    final setting = _sharedPref.getSetting();

    state = state.copyWith(
      referralCode: entity?.referralDetail?.referralCode ?? '',
      referralPolicy: setting?.referralPolicy ?? [],
      showReferralHistory: setting?.referralConfiguration?.isShowReferralHistory ?? false,
    );
  }

  /// Copy referral code to clipboard
  void copyReferralCode() {
    if (state.referralCode.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: state.referralCode));
      state = state.copyWith(
        successMessage: getString(appStr.successReferralCodeCopied, 'success_referral_code_copied'),
      );
      _clearSuccess();
    }
  }

  /// Share referral code
  void shareReferralCode() {
    if (state.referralCode.isNotEmpty) {
      final appName = getString(appStr.appName, 'app_name');

      // Get share message from API with placeholders replaced
      final message = getString(
        appStr.descriptionShareReferralCode,
        'description_share_referral_code',
      ).replacePlaceholders({
        StringConstant.appName: appName,
        StringConstant.referralCode: state.referralCode,
      });

      Share.share(message);
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Clear success
  void _clearSuccess() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        state = state.copyWith(clearSuccess: true);
      }
    });
  }
}

/// Referral list state
class ReferralListState {
  final List<ReferralUser> referrals;
  final bool isLoading;
  final String? error;

  const ReferralListState({
    this.referrals = const [],
    this.isLoading = false,
    this.error,
  });

  ReferralListState copyWith({
    List<ReferralUser>? referrals,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ReferralListState(
      referrals: referrals ?? this.referrals,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Referral list ViewModel
class ReferralListViewModel extends StateNotifier<ReferralListState> {
  final AppRepository _appRepository;

  ReferralListViewModel(this._appRepository) : super(const ReferralListState()) {
    loadReferralHistory();
  }

  /// Load referral history from API
  Future<void> loadReferralHistory() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final response = await _appRepository.getReferralHistory();

    switch (response) {
      case Success<ReferralHistoryResponse>():
        state = state.copyWith(
          isLoading: false,
          referrals: response.data?.referral?.referrals ?? [],
        );
      case Error():
        state = state.copyWith(
          isLoading: false,
          error: response.error?.message ?? 'Failed to load referrals',
        );
      case Loading():
        break;
    }
  }

  /// Refresh referral history
  Future<void> refresh() async {
    await loadReferralHistory();
  }
}

/// Provider for ReferralViewModel
final referralViewModelProvider =
    StateNotifierProvider.autoDispose<ReferralViewModel, ReferralState>((ref) {
  final sharedPref = ref.watch(sharedPreferenceManagerProvider).maybeWhen(
        data: (data) => data,
        orElse: () => throw Exception('SharedPreferences not initialized'),
      );
  return ReferralViewModel(sharedPref);
});

/// Provider for ReferralListViewModel
final referralListViewModelProvider =
    StateNotifierProvider.autoDispose<ReferralListViewModel, ReferralListState>((ref) {
  final appRepository = ref.watch(appRepositoryProvider);
  return ReferralListViewModel(appRepository);
});
