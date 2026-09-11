import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/preferences/shared_preference_manager.dart';
import '../core/providers/app_providers.dart';
import '../core/utils/date_utils.dart';
import '../data/api/response_state.dart';
import '../data/repository/app_repository.dart';
import '../models/requests/redeem_withdraw_request.dart';
import '../models/responses/redeem/redeem_point_response.dart';
import '../models/responses/auth/entity_detail_response.dart';
import '../models/requests/entity_detail_request.dart';

/// Redeem screen state
class RedeemState {
  final double totalRedeemPoints;
  final List<RedeemTransaction> transactions;
  final Map<String, List<RedeemTransaction>> groupedTransactions;
  final bool isLoading;
  final bool isLoadingMore;
  final bool isWithdrawing;
  final bool endReached;
  final String? error;
  final String? successMessage;
  final bool showWithdrawSheet;
  final String withdrawAmount;
  final String convertedPrice;
  final String? withdrawError;

  const RedeemState({
    this.totalRedeemPoints = 0,
    this.transactions = const [],
    this.groupedTransactions = const {},
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isWithdrawing = false,
    this.endReached = false,
    this.error,
    this.successMessage,
    this.showWithdrawSheet = false,
    this.withdrawAmount = '',
    this.convertedPrice = '',
    this.withdrawError,
  });

  RedeemState copyWith({
    double? totalRedeemPoints,
    List<RedeemTransaction>? transactions,
    Map<String, List<RedeemTransaction>>? groupedTransactions,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isWithdrawing,
    bool? endReached,
    String? error,
    String? successMessage,
    bool? showWithdrawSheet,
    String? withdrawAmount,
    String? convertedPrice,
    String? withdrawError,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearWithdrawError = false,
  }) {
    return RedeemState(
      totalRedeemPoints: totalRedeemPoints ?? this.totalRedeemPoints,
      transactions: transactions ?? this.transactions,
      groupedTransactions: groupedTransactions ?? this.groupedTransactions,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isWithdrawing: isWithdrawing ?? this.isWithdrawing,
      endReached: endReached ?? this.endReached,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
      showWithdrawSheet: showWithdrawSheet ?? this.showWithdrawSheet,
      withdrawAmount: withdrawAmount ?? this.withdrawAmount,
      convertedPrice: convertedPrice ?? this.convertedPrice,
      withdrawError: clearWithdrawError ? null : (withdrawError ?? this.withdrawError),
    );
  }
}

/// Redeem screen ViewModel
class RedeemViewModel extends StateNotifier<RedeemState> {
  final AppRepository _appRepository;
  final SharedPreferenceManager _sharedPref;

  int _currentPage = 1;
  bool _isFirstLoad = true;

  RedeemViewModel(this._appRepository, this._sharedPref) : super(const RedeemState()) {
    _loadInitialData();
  }

  void _loadInitialData() {
    final entity = _sharedPref.getEntity();
    final reward = entity?.reward ?? 0;
    state = state.copyWith(
      totalRedeemPoints: reward,
      convertedPrice: _calculateConvertedPrice('1'),
    );
    loadRewardPoints();
  }

  /// Load reward points transactions
  Future<void> loadRewardPoints() async {
    if (_isFirstLoad) {
      state = state.copyWith(isLoading: true, clearError: true);
    } else {
      state = state.copyWith(isLoadingMore: true);
    }

    final response = await _appRepository.getRewardPoints(page: _currentPage);

    switch (response) {
      case Success<RedeemPointResponse>():
        final newTransactions = response.data?.transactions ?? [];

        if (newTransactions.isEmpty) {
          state = state.copyWith(
            isLoading: false,
            isLoadingMore: false,
            endReached: true,
          );
        } else {
          List<RedeemTransaction> allTransactions;
          if (_currentPage == 1) {
            allTransactions = newTransactions;
          } else {
            allTransactions = [...state.transactions, ...newTransactions];
          }

          state = state.copyWith(
            isLoading: false,
            isLoadingMore: false,
            transactions: allTransactions,
            groupedTransactions: _groupTransactionsByMonth(allTransactions),
            endReached: false,
          );
          _currentPage++;
        }
        _isFirstLoad = false;

      case Error():
        state = state.copyWith(
          isLoading: false,
          isLoadingMore: false,
          error: response.error?.message ?? 'Failed to load transactions',
        );
        _isFirstLoad = false;

      case Loading():
        break;
    }
  }

  /// Load more transactions (pagination)
  void loadMore() {
    if (!state.isLoading && !state.isLoadingMore && !state.endReached) {
      loadRewardPoints();
    }
  }

  /// Refresh transactions
  Future<void> refresh() async {
    _currentPage = 1;
    _isFirstLoad = true;
    state = state.copyWith(
      transactions: [],
      groupedTransactions: {},
      endReached: false,
    );
    await loadRewardPoints();
  }

  /// Show withdraw bottom sheet
  void showWithdrawSheet() {
    if (state.totalRedeemPoints > 0) {
      state = state.copyWith(
        showWithdrawSheet: true,
        withdrawAmount: '',
        convertedPrice: _calculateConvertedPrice('1'),
      );
    }
  }

  /// Hide withdraw bottom sheet
  void hideWithdrawSheet() {
    state = state.copyWith(
      showWithdrawSheet: false,
      withdrawAmount: '',
    );
  }

  /// Update withdraw amount
  void updateWithdrawAmount(String amount) {
    final hasExceeded = amount.isNotEmpty &&
        ((double.tryParse(amount) ?? 0) > state.totalRedeemPoints);

    state = state.copyWith(
      withdrawAmount: amount,
      convertedPrice: _calculateConvertedPrice(amount.isEmpty ? '1' : amount),
      withdrawError: hasExceeded ? 'Please enter valid redeem points' : null,
      clearWithdrawError: !hasExceeded,
      clearError: true,
    );
  }

  /// Withdraw reward points
  Future<void> withdrawPoints() async {
    if (state.withdrawAmount.isEmpty) {
      state = state.copyWith(error: 'Please enter redeem points');
      return;
    }

    final points = double.tryParse(state.withdrawAmount) ?? 0;
    final setting = _sharedPref.getSetting();
    final minPoints = setting?.rewardPointConfig?.minPointForWithdrawal ?? 0;

    if (points < minPoints) {
      state = state.copyWith(
        error: 'Minimum $minPoints points required for withdrawal',
      );
      return;
    }

    if (points > state.totalRedeemPoints) {
      state = state.copyWith(error: 'Please enter valid redeem points');
      return;
    }

    state = state.copyWith(isWithdrawing: true, clearError: true);

    final request = RedeemWithdrawRequest(rewardPoint: points);
    final response = await _appRepository.withdrawRewardPoints(request);

    switch (response) {
      case Success():
        state = state.copyWith(
          isWithdrawing: false,
          showWithdrawSheet: false,
          successMessage: 'Points redeemed successfully',
          withdrawAmount: '',
        );
        // Refresh entity and transactions
        await _refreshEntityDetail();
        _currentPage = 1;
        _isFirstLoad = true;
        await loadRewardPoints();

      case Error():
        state = state.copyWith(
          isWithdrawing: false,
          error: response.error?.message ?? 'Failed to withdraw points',
        );

      case Loading():
        break;
    }
  }

  /// Refresh entity detail to get updated reward points
  Future<void> _refreshEntityDetail() async {
    final request = EntityDetailRequest();
    final response = await _appRepository.getEntityDetail(request);

    switch (response) {
      case Success<EntityDetailResponse>():
        final entity = response.data?.entity;
        final setting = response.data?.setting;

        if (entity != null) {
          await _sharedPref.setEntity(entity);
        }
        if (setting != null) {
          await _sharedPref.setSetting(setting);
        }

        state = state.copyWith(
          totalRedeemPoints: entity?.reward ?? 0,
        );

      case Error():
        debugPrint('🔴 Failed to refresh entity detail');

      case Loading():
        break;
    }
  }

  /// Calculate converted price from points
  String _calculateConvertedPrice(String points) {
    final setting = _sharedPref.getSetting();
    final valuePerPoint = setting?.rewardPointConfig?.valueOfOneRewardPoint ?? 0;
    final currency = setting?.currencySign ?? '';

    final pointsValue = double.tryParse(points) ?? 0;
    final convertedValue = pointsValue * valuePerPoint;

    return '$currency${convertedValue.toStringAsFixed(2)}';
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Clear success message
  void clearSuccess() {
    state = state.copyWith(clearSuccess: true);
  }

  /// Group transactions by month
  Map<String, List<RedeemTransaction>> _groupTransactionsByMonth(
      List<RedeemTransaction> transactions) {
    final Map<String, List<RedeemTransaction>> grouped = {};

    for (final transaction in transactions) {
      if (transaction.createdAt != null) {
        final monthKey = AppDateUtils.getMonthYearFromString(transaction.createdAt);
        if (monthKey.isNotEmpty) {
          grouped.putIfAbsent(monthKey, () => []);
          grouped[monthKey]!.add(transaction);
        }
      }
    }

    return grouped;
  }
}

/// Provider for RedeemViewModel
final redeemViewModelProvider =
    StateNotifierProvider.autoDispose<RedeemViewModel, RedeemState>((ref) {
  final appRepository = ref.watch(appRepositoryProvider);
  final sharedPref = ref.watch(sharedPreferenceManagerProvider).maybeWhen(
        data: (data) => data,
        orElse: () => throw Exception('SharedPreferences not initialized'),
      );
  return RedeemViewModel(appRepository, sharedPref);
});
