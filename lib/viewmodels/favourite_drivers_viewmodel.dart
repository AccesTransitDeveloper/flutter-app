import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/api/response_state.dart';
import '../data/repository/app_repository.dart';
import '../models/responses/driver/favourite_driver_response.dart';

/// Favourite drivers list state
class FavouriteDriversState {
  final List<FavouriteDriver> drivers;
  final bool isLoading;
  final String? error;

  const FavouriteDriversState({
    this.drivers = const [],
    this.isLoading = false,
    this.error,
  });

  FavouriteDriversState copyWith({
    List<FavouriteDriver>? drivers,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return FavouriteDriversState(
      drivers: drivers ?? this.drivers,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Favourite drivers list ViewModel
class FavouriteDriversViewModel extends StateNotifier<FavouriteDriversState> {
  final AppRepository _appRepository;

  FavouriteDriversViewModel(this._appRepository)
      : super(const FavouriteDriversState()) {
    _loadFavouriteDrivers();
  }

  Future<void> _loadFavouriteDrivers() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final response = await _appRepository.getFavouriteDrivers();

    switch (response) {
      case Success<FavouriteDriverResponse>():
        state = state.copyWith(
          isLoading: false,
          drivers: response.data?.favouriteDrivers ?? [],
        );
      case Error():
        state = state.copyWith(
          isLoading: false,
          error: response.error?.message,
        );
      case Loading():
        break;
    }
  }

  /// Delete a favourite driver and refresh the list
  Future<void> deleteFavouriteDriver(String driverId) async {
    state = state.copyWith(isLoading: true);

    final response = await _appRepository.deleteFavouriteDriver(driverId);

    switch (response) {
      case Success():
        await _loadFavouriteDrivers();
      case Error():
        state = state.copyWith(
          isLoading: false,
          error: response.error?.message,
        );
      case Loading():
        break;
    }
  }

  /// Refresh for pull-to-refresh
  Future<void> refresh() async {
    await _loadFavouriteDrivers();
  }
}

/// Provider for FavouriteDriversViewModel
final favouriteDriversViewModelProvider = StateNotifierProvider.autoDispose<
    FavouriteDriversViewModel, FavouriteDriversState>((ref) {
  final appRepository = ref.watch(appRepositoryProvider);
  return FavouriteDriversViewModel(appRepository);
});
