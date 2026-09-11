import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/preferences/shared_preference_manager.dart';
import '../core/providers/app_providers.dart';
import '../models/responses/auth/entity_detail_response.dart';

/// Account screen state
class AccountState {
  final String? userName;
  final Entity? entity;
  final bool isLoading;
  final String? error;

  const AccountState({
    this.userName,
    this.entity,
    this.isLoading = false,
    this.error,
  });

  AccountState copyWith({
    String? userName,
    Entity? entity,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AccountState(
      userName: userName ?? this.userName,
      entity: entity ?? this.entity,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Account screen ViewModel
class AccountViewModel extends StateNotifier<AccountState> {
  final SharedPreferenceManager _sharedPref;

  AccountViewModel(this._sharedPref) : super(const AccountState()) {
    _loadUserData();
  }

  /// Load user data from shared preferences
  void _loadUserData() {
    final entity = _sharedPref.getEntity();
    if (entity != null) {
      final firstName = entity.firstName ?? '';
      final lastName = entity.lastName ?? '';
      final fullName = '$firstName $lastName'.trim();
      state = state.copyWith(
        userName: fullName.isNotEmpty ? fullName : null,
        entity: entity,
      );
    }
  }

  /// Refresh user data (call when returning to account screen)
  void refreshUserData() {
    _loadUserData();
  }
}

/// Provider for AccountViewModel
final accountViewModelProvider =
    StateNotifierProvider.autoDispose<AccountViewModel, AccountState>((ref) {
  final sharedPref = ref.watch(sharedPreferenceManagerProvider).maybeWhen(
        data: (data) => data,
        orElse: () => throw Exception('SharedPreferences not initialized'),
      );

  return AccountViewModel(sharedPref);
});
