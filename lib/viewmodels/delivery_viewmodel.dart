import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/api/response_state.dart';
import '../data/repository/app_repository.dart';
import '../models/requests/delivery/delivery_requests.dart';
import '../models/requests/get_vehicle_types_request.dart';
import '../models/responses/delivery/delivery_responses.dart';
import 'home_viewmodel.dart';

/// State for the Delivery tab. Categories load first (shown immediately); the
/// feed for the currently selected category streams in after.
class DeliveryState {
  final bool isCategoriesLoading;
  final bool isFeedLoading;
  final String? errorMessage;
  final bool isUnavailable;

  final List<DeliveryCategory> categories;
  final String? selectedCategoryId;
  final List<DeliveryGroup> sections;
  final List<Merchant> allRestaurants;

  const DeliveryState({
    this.isCategoriesLoading = true,
    this.isFeedLoading = false,
    this.errorMessage,
    this.isUnavailable = false,
    this.categories = const [],
    this.selectedCategoryId,
    this.sections = const [],
    this.allRestaurants = const [],
  });

  DeliveryState copyWith({
    bool? isCategoriesLoading,
    bool? isFeedLoading,
    String? errorMessage,
    bool? isUnavailable,
    List<DeliveryCategory>? categories,
    String? selectedCategoryId,
    List<DeliveryGroup>? sections,
    List<Merchant>? allRestaurants,
    bool clearError = false,
  }) {
    return DeliveryState(
      isCategoriesLoading: isCategoriesLoading ?? this.isCategoriesLoading,
      isFeedLoading: isFeedLoading ?? this.isFeedLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isUnavailable: isUnavailable ?? this.isUnavailable,
      categories: categories ?? this.categories,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      sections: sections ?? this.sections,
      allRestaurants: allRestaurants ?? this.allRestaurants,
    );
  }
}

class DeliveryViewModel extends StateNotifier<DeliveryState> {
  final AppRepository _repository;
  final Ref _ref;

  String? cityId;
  String? timezone;
  String? countryId;

  DeliveryViewModel(this._repository, this._ref) : super(const DeliveryState());

  DestinationAddress? get address =>
      _ref.read(homeViewModelProvider).pickupAddress;

  String? get _homeCountryId => _ref.read(homeViewModelProvider).countryId;

  /// Load categories (fast), then the feed for the first category.
  Future<void> load() async {
    final addr = address;
    if (addr == null || addr.latitude == null || addr.longitude == null) {
      state = state.copyWith(
        isCategoriesLoading: false,
        errorMessage: 'Location not available. Please set your location first.',
      );
      return;
    }

    state = state.copyWith(
        isCategoriesLoading: true, clearError: true, isUnavailable: false);

    // 1. Check delivery availability.
    final checkResponse = await _repository.checkDeliveryBusiness(
      CheckDeliveryBusinessRequest(destinationAddress: addr),
    );
    switch (checkResponse) {
      case Success<CheckDeliveryBusinessResponse>():
        cityId = checkResponse.data?.citySetting?.cityId;
        timezone = checkResponse.data?.citySetting?.timezone;
        countryId = checkResponse.data?.countryId ?? _homeCountryId;
        if (cityId == null || cityId!.isEmpty) {
          state = state.copyWith(isCategoriesLoading: false, isUnavailable: true);
          return;
        }
      case Error<CheckDeliveryBusinessResponse>():
        state = state.copyWith(
            isCategoriesLoading: false,
            isUnavailable: true,
            errorMessage: checkResponse.message);
        return;
      case Loading():
        return;
    }

    // 2. Categories — show as soon as they arrive.
    final categoryResponse = await _repository.getDeliveryCategories(
      DeliveryCategoryRequest(countryId: countryId, cityId: cityId),
    );
    final categories = categoryResponse is Success<DeliveryCategoryResponse>
        ? (categoryResponse.data?.mainCategories ?? const [])
        : const <DeliveryCategory>[];

    final firstId = categories.isNotEmpty ? categories.first.id : null;
    state = state.copyWith(
      isCategoriesLoading: false,
      categories: categories,
      selectedCategoryId: firstId,
      isFeedLoading: firstId != null,
      sections: const [],
      allRestaurants: const [],
    );

    // 3. Feed for the first category.
    if (firstId != null) await _loadFeed(firstId);
  }

  /// Switch category — loads only that category's feed.
  Future<void> selectCategory(String categoryId) async {
    if (categoryId == state.selectedCategoryId) return;
    state = state.copyWith(
      selectedCategoryId: categoryId,
      isFeedLoading: true,
      sections: const [],
      allRestaurants: const [],
      clearError: true,
    );
    await _loadFeed(categoryId);
  }

  Future<void> _loadFeed(String categoryId) async {
    final addr = address;
    if (addr == null) {
      state = state.copyWith(isFeedLoading: false);
      return;
    }

    final feed = await _loadCategoryFeed(addr, categoryId);

    // Ignore stale responses (user switched category meanwhile).
    if (state.selectedCategoryId != categoryId) return;

    debugPrint('🛒 Feed for $categoryId: ${feed.groups.length} groups, '
        '${feed.restaurants.length} restaurants');
    state = state.copyWith(
      isFeedLoading: false,
      sections: feed.groups,
      allRestaurants: feed.restaurants,
    );
  }

  /// Load one category's dynamic groups + its full restaurant list.
  Future<({List<DeliveryGroup> groups, List<Merchant> restaurants})>
      _loadCategoryFeed(DestinationAddress addr, String categoryId) async {
    var groups = <DeliveryGroup>[];
    var restaurants = <Merchant>[];

    final groupResponse = await _repository.getDeliveryGroups(
      DynamicGroupRequest(
        destinationAddress: addr,
        mainCategoryId: categoryId,
        cityId: cityId!,
        countryId: countryId ?? '',
        timezone: timezone ?? '',
      ),
    );
    if (groupResponse is Success<GroupListResponse>) {
      final all = groupResponse.data?.groups ?? const [];
      groups = all
          .where((g) => g.isActive && (g.products.isNotEmpty || g.isAllMerchant))
          .toList();
      restaurants =
          all.where((g) => g.isAllMerchant).firstOrNull?.products ?? const [];
    }

    if (restaurants.isEmpty) {
      final merchantResponse = await _repository.getDeliveryMerchants(
        DeliveryMerchantListRequest(
          destinationAddress: addr,
          mainCategoryId: categoryId,
          cityId: cityId!,
          timezone: timezone ?? '',
        ),
      );
      if (merchantResponse is Success<MerchantListResponse>) {
        restaurants = merchantResponse.data?.merchants ?? const [];
      }
    }

    return (groups: groups, restaurants: restaurants);
  }
}

final deliveryViewModelProvider =
    StateNotifierProvider.autoDispose<DeliveryViewModel, DeliveryState>((ref) {
  final repository = ref.watch(appRepositoryProvider);
  return DeliveryViewModel(repository, ref);
});
