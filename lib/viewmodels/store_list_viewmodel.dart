import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/api/response_state.dart';
import '../data/repository/app_repository.dart';
import '../models/requests/delivery/delivery_requests.dart';
import '../models/requests/get_vehicle_types_request.dart';
import '../models/responses/delivery/delivery_responses.dart';
import 'home_viewmodel.dart';

/// Params identifying which category's stores to load.
class StoreListParams {
  final String categoryId;
  final String categoryName;
  final String cityId;
  final String countryId;
  final String timezone;

  const StoreListParams({
    required this.categoryId,
    required this.categoryName,
    required this.cityId,
    required this.countryId,
    required this.timezone,
  });

  @override
  bool operator ==(Object other) =>
      other is StoreListParams &&
      other.categoryId == categoryId &&
      other.cityId == cityId &&
      other.countryId == countryId &&
      other.timezone == timezone;

  @override
  int get hashCode => Object.hash(categoryId, cityId, countryId, timezone);
}

class StoreListState {
  final bool isLoading;
  final String? errorMessage;
  final String searchText;

  /// Curated dynamic groups (rails), excluding the all-merchant list.
  final List<DeliveryGroup> groups;

  /// The main "all restaurants" list.
  final List<Merchant> allMerchants;

  const StoreListState({
    this.isLoading = true,
    this.errorMessage,
    this.searchText = '',
    this.groups = const [],
    this.allMerchants = const [],
  });

  /// All-merchant list filtered by search text (client-side).
  List<Merchant> get visibleMerchants {
    if (searchText.trim().isEmpty) return allMerchants;
    final q = searchText.toLowerCase();
    return allMerchants
        .where((m) => (m.name ?? '').toLowerCase().contains(q))
        .toList();
  }

  /// Hide curated rails while searching so the user sees plain results.
  bool get showGroups => searchText.trim().isEmpty && groups.isNotEmpty;

  StoreListState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? searchText,
    List<DeliveryGroup>? groups,
    List<Merchant>? allMerchants,
    bool clearError = false,
  }) {
    return StoreListState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      searchText: searchText ?? this.searchText,
      groups: groups ?? this.groups,
      allMerchants: allMerchants ?? this.allMerchants,
    );
  }
}

class StoreListViewModel extends StateNotifier<StoreListState> {
  final AppRepository _repository;
  final Ref _ref;
  final StoreListParams _params;

  StoreListViewModel(this._repository, this._ref, this._params)
      : super(const StoreListState()) {
    load();
  }

  DestinationAddress? get _address =>
      _ref.read(homeViewModelProvider).pickupAddress;

  void onSearchChanged(String value) {
    state = state.copyWith(searchText: value);
  }

  Future<void> load() async {
    final addr = _address;
    if (addr == null) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Location not available.');
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    // 1. Dynamic groups (native dynamic-group design).
    final groupResponse = await _repository.getDeliveryGroups(
      DynamicGroupRequest(
        destinationAddress: addr,
        mainCategoryId: _params.categoryId,
        cityId: _params.cityId,
        countryId: _params.countryId,
        timezone: _params.timezone,
      ),
    );

    List<DeliveryGroup> curated = const [];
    List<Merchant> allMerchants = const [];

    if (groupResponse is Success<GroupListResponse>) {
      final groups = groupResponse.data?.groups ?? const [];
      curated = groups
          .where((g) => !g.isAllMerchant && g.products.isNotEmpty)
          .toList();
      final allGroup = groups.where((g) => g.isAllMerchant).firstOrNull;
      allMerchants = allGroup?.products ?? const [];
    } else if (groupResponse is Error<GroupListResponse>) {
      debugPrint('🛒 StoreList groups error: ${groupResponse.message}');
    }

    // 2. Fallback: if the all-merchant list is empty, hit the flat merchants API.
    if (allMerchants.isEmpty) {
      final merchantResponse = await _repository.getDeliveryMerchants(
        DeliveryMerchantListRequest(
          destinationAddress: addr,
          mainCategoryId: _params.categoryId,
          cityId: _params.cityId,
          timezone: _params.timezone,
        ),
      );
      if (merchantResponse is Success<MerchantListResponse>) {
        allMerchants = merchantResponse.data?.merchants ?? const [];
      } else if (merchantResponse is Error<MerchantListResponse>) {
        debugPrint('🛒 StoreList merchants error: ${merchantResponse.message}');
      }
    }

    state = state.copyWith(
      isLoading: false,
      groups: curated,
      allMerchants: allMerchants,
    );
  }
}

final storeListViewModelProvider = StateNotifierProvider.autoDispose
    .family<StoreListViewModel, StoreListState, StoreListParams>((ref, params) {
  final repository = ref.watch(appRepositoryProvider);
  return StoreListViewModel(repository, ref, params);
});
