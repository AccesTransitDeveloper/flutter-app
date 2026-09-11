import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/api/response_state.dart';
import '../data/repository/app_repository.dart';
import '../models/requests/delivery/delivery_requests.dart';
import '../models/responses/delivery/merchant_menu_responses.dart';

/// Arguments identifying which merchant's menu to load. Used as the family key.
typedef MerchantMenuArgs = ({String merchantId, String? mainCategoryId});

/// One section of the menu — either a server product group (e.g. "Recommended")
/// whose products are already loaded, or a category (from the CATEGORY group's
/// childs) whose products are lazily fetched on demand.
class MenuSectionData {
  final String id;
  final String title;
  final bool isCategory;
  final String? categoryId;
  final MenuGroup? group; // for non-category (product) groups
  final List<DeliveryProduct> products;
  final bool isLoading;
  final bool isLoaded;

  const MenuSectionData({
    required this.id,
    required this.title,
    this.isCategory = false,
    this.categoryId,
    this.group,
    this.products = const [],
    this.isLoading = false,
    this.isLoaded = true,
  });

  /// Product groups may be a horizontal scroll (e.g. "Recommended"); category
  /// sections are always a vertical list.
  bool get scroll => !isCategory && (group?.grid?.isScroll ?? false);

  MenuSectionData copyWith({
    List<DeliveryProduct>? products,
    bool? isLoading,
    bool? isLoaded,
  }) {
    return MenuSectionData(
      id: id,
      title: title,
      isCategory: isCategory,
      categoryId: categoryId,
      group: group,
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}

class MerchantDetailState {
  final bool isLoading;
  final String? errorMessage;
  final List<MenuSectionData> sections;

  const MerchantDetailState({
    this.isLoading = true,
    this.errorMessage,
    this.sections = const [],
  });

  MerchantDetailState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<MenuSectionData>? sections,
    bool clearError = false,
  }) {
    return MerchantDetailState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      sections: sections ?? this.sections,
    );
  }
}

class MerchantDetailViewModel extends StateNotifier<MerchantDetailState> {
  final AppRepository _repository;
  final MerchantMenuArgs _args;
  String? timezone;

  MerchantDetailViewModel(this._repository, this._args)
      : super(const MerchantDetailState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final response = await _repository.getMerchantMenu(
      MerchantMenuRequest(
        merchantId: _args.merchantId,
        mainCategoryId: _args.mainCategoryId,
      ),
    );

    switch (response) {
      case Success<MenuResponse>():
        final groups = (response.data?.groups ?? const <MenuGroup>[])
            .where((g) => g.isActive)
            .toList();
        state = state.copyWith(
            isLoading: false, sections: _buildSections(groups));
      case Error<MenuResponse>():
        state = state.copyWith(
            isLoading: false,
            errorMessage: response.message ?? 'Failed to load menu');
      case Loading():
        break;
    }
  }

  /// A CATEGORY group's childs each become a lazily-loaded category section.
  /// Product groups with a shown title become eager sections; an untitled
  /// product group is only surfaced when there are no categories to browse
  /// (so merchants that ship all products in one untitled group still show).
  List<MenuSectionData> _buildSections(List<MenuGroup> groups) {
    final hasCategories = groups.any((g) =>
        (g.childType ?? '').toUpperCase() == 'CATEGORY' &&
        g.products.isNotEmpty);
    final sections = <MenuSectionData>[];
    for (final g in groups) {
      final type = (g.childType ?? '').toUpperCase();
      if (type == 'CATEGORY') {
        for (final cat in g.products) {
          final id = cat.id ?? '';
          if (id.isEmpty || (cat.name ?? '').isEmpty) continue;
          sections.add(MenuSectionData(
            id: id,
            title: cat.name!,
            isCategory: true,
            categoryId: id,
            isLoaded: false,
          ));
        }
      } else if (g.products.isNotEmpty) {
        final titled =
            (g.header?.isShow ?? false) && (g.title ?? '').isNotEmpty;
        if (!titled && hasCategories) continue;
        sections.add(MenuSectionData(
          id: g.id ?? 'grp${sections.length}',
          title: titled ? g.title! : 'Menu',
          group: g,
          products: g.products,
          isLoaded: true,
        ));
      }
    }
    return sections;
  }

  /// Fetch a category's products on demand (once).
  Future<void> loadCategory(String sectionId) async {
    final idx = state.sections.indexWhere((s) => s.id == sectionId);
    if (idx < 0) return;
    final section = state.sections[idx];
    if (!section.isCategory ||
        section.isLoaded ||
        section.isLoading ||
        section.categoryId == null) {
      return;
    }
    _replace(idx, section.copyWith(isLoading: true));

    final response = await _repository.getCategoryProducts(
      CategoryProductsRequest(
        merchantId: _args.merchantId,
        categoryId: section.categoryId!,
        timezone: timezone,
      ),
    );
    final products = response is Success<ProductListResponse>
        ? (response.data?.products ?? const <DeliveryProduct>[])
        : const <DeliveryProduct>[];

    final current = state.sections.indexWhere((s) => s.id == sectionId);
    if (current < 0) return;
    _replace(
        current,
        state.sections[current]
            .copyWith(isLoading: false, isLoaded: true, products: products));
  }

  void _replace(int idx, MenuSectionData section) {
    final list = [...state.sections];
    if (idx < 0 || idx >= list.length) return;
    list[idx] = section;
    state = state.copyWith(sections: list);
  }
}

final merchantDetailViewModelProvider = StateNotifierProvider.autoDispose
    .family<MerchantDetailViewModel, MerchantDetailState, MerchantMenuArgs>(
  (ref, args) =>
      MerchantDetailViewModel(ref.watch(appRepositoryProvider), args)..load(),
);
