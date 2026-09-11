import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/providers/bottom_nav_visibility_provider.dart';
import '../../../core/router/app_navigation.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/api/server_config.dart';
import '../../../models/responses/delivery/delivery_responses.dart';
import '../../../viewmodels/delivery_viewmodel.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_text.dart';

/// Careem-style food-delivery home (delivery tab). The feed is built entirely
/// from the server dynamic groups — each group renders as its own section
/// (promo rail, restaurant rail, or the full recommended list) by childType.
class DeliveryScreen extends ConsumerStatefulWidget {
  const DeliveryScreen({super.key});

  @override
  ConsumerState<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends ConsumerState<DeliveryScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(deliveryViewModelProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _selectCategory(DeliveryCategory category) {
    if (category.id == null) return;
    ref.read(deliveryViewModelProvider.notifier).selectCategory(category.id!);
  }

  /// Open a store's menu / product-listing screen.
  void _openMerchant(Merchant merchant) {
    if ((merchant.id ?? '').isEmpty) return;
    final notifier = ref.read(deliveryViewModelProvider.notifier);
    context.navigateToMerchantDetail(
      merchant: merchant,
      mainCategoryId: ref.read(deliveryViewModelProvider).selectedCategoryId,
      cityId: notifier.cityId,
      timezone: notifier.timezone,
    );
  }

  /// Hide the bottom nav while scrolling down, reveal it when scrolling up.
  bool _onUserScroll(UserScrollNotification n) {
    final dir = n.direction;
    if (dir == ScrollDirection.reverse) {
      _setNavVisible(false);
    } else if (dir == ScrollDirection.forward) {
      _setNavVisible(true);
    }
    return false;
  }

  void _setNavVisible(bool visible) {
    final notifier = ref.read(bottomNavVisibleProvider.notifier);
    if (notifier.state != visible) notifier.state = visible;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(deliveryViewModelProvider);
    final colors = context.colors;

    return AppScaffold(
      // Immersive: gradient hero runs behind the status bar with light icons.
      systemUiOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      body: Column(
        children: [
          _HeroHeader(
            title: getString(appStr.headingDelivery, 'heading_delivery'),
            search: _searchBar(colors),
          ),
          Expanded(child: _buildBody(context, state, colors)),
        ],
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, DeliveryState state, AppColorPalette colors) {
    if (state.isCategoriesLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.isUnavailable) {
      return _centered(
          colors,
          getString(appStr.errorDeliveryNotAvailable,
              'error_delivery_not_available'));
    }

    final searching = _query.trim().isNotEmpty;

    return NotificationListener<UserScrollNotification>(
      onNotification: _onUserScroll,
      child: RefreshIndicator(
        onRefresh: () => ref.read(deliveryViewModelProvider.notifier).load(),
        child: ListView(
          padding: const EdgeInsets.only(
              top: AppDimens.paddingS, bottom: 96),
        children: [
          // While searching, collapse to a plain filtered restaurant list.
          if (searching)
            ..._searchResults(state, colors)
          else ...[
            if (state.categories.isNotEmpty) ...[
              const SizedBox(height: AppDimens.paddingS),
              _CategoryRow(
                categories: state.categories,
                selectedId: state.selectedCategoryId,
                onTap: _selectCategory,
              ),
            ],

            // Feed for the selected category — a shimmer skeleton while it
            // streams in (feels faster / more premium than a spinner).
            if (state.isFeedLoading)
              const _FeedSkeleton()
            else ...[
              for (final section
                  in state.sections.where((s) => !s.isAllMerchant))
                _buildRail(section),
              if (state.allRestaurants.isNotEmpty)
                _AllMerchantList(
                  title: state.sections
                          .where((s) => s.isAllMerchant)
                          .firstOrNull
                          ?.title ??
                      getString(appStr.headingAllRestaurants,
                          'heading_all_restaurants'),
                  merchants: state.allRestaurants,
                  onTap: _openMerchant,
                ),
              if (state.sections.isEmpty && state.allRestaurants.isEmpty)
                _centered(
                    colors,
                    getString(appStr.errorNoRestaurantsInCategory,
                        'error_no_restaurants_in_category')),
            ],
          ],
        ],
        ),
      ),
    );
  }

  /// Rail for a non-all-merchant group. Tag/promo/category/brand groups carry
  /// only image + name → a circular rail. Merchant groups (SELECTED_MERCHANT,
  /// TOP_RATED_MERCHANT, …) carry rating/time → restaurant cards.
  /// Each childType gets a design that fits its content (native
  /// QDeliveryMenuType). Layout (scroll vs static grid) and columns come from
  /// the group's viewType / maxColumnCount.
  Widget _buildRail(DeliveryGroup section) {
    final type = section.childType ?? '';
    final scroll = (section.grid?.viewType ?? '').toUpperCase() != 'STATIC';
    final columns = section.grid?.columns ?? 3;
    final items = section.products;
    final title = (section.header?.isShow ?? false) ? section.title : null;
    final primary = context.colors.colorPrimary;
    final secondary = context.colors.colorSecondary;

    Widget build(double h, double w, Widget Function(int) item,
            {Color? band}) =>
        _GroupSection(
          title: title,
          subtitle: section.subtitle,
          scroll: scroll,
          columns: columns,
          scrollHeight: h,
          scrollItemWidth: w,
          count: items.length,
          itemBuilder: item,
          background: band,
        );

    switch (type) {
      case 'MERCHANT_WITH_TAG': // cuisines → small circles (clean, no band)
        return build(128, 88, (i) => _CircleItem(item: items[i]));
      case 'PROMO_CODE': // offers → compact promo banners on a tinted zone
        return build(132, 188, (i) => _OfferCard(item: items[i]),
            band: secondary.withValues(alpha: 0.16));
      case 'BRAND': // brand logos → rounded squares (clean, no band)
        return build(112, 100, (i) => _BrandItem(item: items[i]));
      case 'CATEGORY':
      case 'GROUP':
      case 'PRODUCT': // sub-categories / dishes → image tiles (clean)
        return build(164, 120, (i) => _TileItem(item: items[i]));
      default: // TOP_RATED / SELECTED / OWN_PROMO merchants → cards on a tint
        return build(
            182,
            184,
            (i) => _RestaurantRailCard(
                merchant: items[i], onTap: () => _openMerchant(items[i])),
            band: primary.withValues(alpha: 0.09));
    }
  }

  List<Widget> _searchResults(DeliveryState state, AppColorPalette colors) {
    final q = _query.toLowerCase();
    final results = state.allRestaurants
        .where((m) => (m.name ?? '').toLowerCase().contains(q))
        .toList();
    if (results.isEmpty) {
      return [
        _centered(colors,
            getString(appStr.errorNoRestaurantsFound, 'error_no_restaurants_found'))
      ];
    }
    return [
      const SizedBox(height: AppDimens.padding),
      for (final m in results)
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppDimens.padding, 0, AppDimens.padding, AppDimens.padding),
          child: _RestaurantListCard(merchant: m, onTap: () => _openMerchant(m)),
        ),
    ];
  }

  Widget _searchBar(AppColorPalette colors) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: colors.colorBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.13),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: colors.colorPrimary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              style: TextStyle(fontSize: 14.5, color: colors.colorText),
              decoration: InputDecoration(
                hintText: getString(
                    appStr.hintSearchRestaurants, 'hint_search_restaurants'),
                hintStyle: TextStyle(fontSize: 14, color: colors.colorTextHint),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (_query.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() => _query = '');
              },
              child: Icon(Icons.close_rounded,
                  color: colors.colorTextHint, size: 20),
            ),
        ],
      ),
    );
  }

  Widget _centered(AppColorPalette colors, String message) {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.storefront_outlined,
                size: 64, color: colors.colorTextHint),
            const SizedBox(height: AppDimens.padding),
            AppText.body(message,
                color: colors.colorTextHint, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ── Hero header (brand gradient banner) ───────────────────────────

class _HeroHeader extends StatelessWidget {
  final String title;
  final Widget search;

  const _HeroHeader({required this.title, required this.search});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // Diagonal brand gradient: primary → a secondary blended toward primary so
    // it stays cohesive regardless of the server-supplied palette.
    final gradientEnd =
        Color.lerp(colors.colorSecondary, colors.colorPrimary, 0.35)!;
    final topInset = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
          AppDimens.padding, topInset + 12, AppDimens.padding, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.colorPrimary, gradientEnd],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: colors.colorPrimary.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: colors.colorButtonText,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 14),
          search,
        ],
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _SectionHeader({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppDimens.padding, AppDimens.paddingS, AppDimens.padding, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Gradient accent bar in the theme colour.
              Container(
                width: 4,
                height: 22,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      colors.colorPrimary,
                      colors.colorPrimary.withValues(alpha: 0.35),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Expanded(
                child: AppText.title(title,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    letterSpacing: -0.2),
              ),
            ],
          ),
          if ((subtitle ?? '').isNotEmpty) ...[
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: AppText.caption(subtitle!, color: colors.colorTextHint),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Categories (two-row horizontal grid) ──────────────────────────

class _CategoryRow extends StatelessWidget {
  final List<DeliveryCategory> categories;
  final String? selectedId;
  final void Function(DeliveryCategory) onTap;

  const _CategoryRow({
    required this.categories,
    required this.selectedId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 102,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.padding),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppDimens.padding),
        itemBuilder: (context, i) => _CategoryItem(
          category: categories[i],
          isSelected: categories[i].id == selectedId,
          onTap: () => onTap(categories[i]),
        ),
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final DeliveryCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryItem({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final primary = colors.colorPrimary;
    final imageUrl = ServerConfig.getFullImageUrl(category.imageUrl);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 84,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              height: 64,
              width: 64,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? primary.withValues(alpha: 0.12)
                    : colors.colorBackgroundGray.withValues(alpha: 0.5),
                border: isSelected
                    ? Border.all(color: primary, width: 2)
                    : null,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.28),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ]
                    : null,
              ),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                errorWidget: (_, _, _) =>
                    Icon(Icons.fastfood, color: colors.colorTextHint, size: 26),
              ),
            ),
            const SizedBox(height: 6),
            // Single line, auto-shrink so long names (e.g. "Restaurants")
            // never break mid-word onto a second line.
            SizedBox(
              width: double.infinity,
              height: 28,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  category.name ?? '',
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? primary : colors.colorText,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lay items out per the group's viewType: a horizontal scroll (SCROLL/SLIDER)
/// or a static wrapped grid with [columns] equal columns (STATIC — no scroll).
Widget _railBody({
  required bool scroll,
  required int columns,
  required double scrollHeight,
  required double scrollItemWidth,
  required int count,
  required Widget Function(int index) itemBuilder,
}) {
  if (scroll) {
    return SizedBox(
      height: scrollHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.padding),
        itemCount: count,
        separatorBuilder: (_, _) => const SizedBox(width: AppDimens.paddingM),
        itemBuilder: (context, i) =>
            SizedBox(width: scrollItemWidth, child: itemBuilder(i)),
      ),
    );
  }
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppDimens.padding),
    child: LayoutBuilder(
      builder: (context, c) {
        const spacing = AppDimens.paddingM;
        final cols = columns < 1 ? 1 : columns;
        final w = (c.maxWidth - (cols - 1) * spacing) / cols;
        return Wrap(
          spacing: spacing,
          runSpacing: AppDimens.padding,
          children: [
            for (int i = 0; i < count; i++)
              SizedBox(width: w, child: itemBuilder(i)),
          ],
        );
      },
    ),
  );
}

// ── Section wrapper (header + scroll / static body) ───────────────

class _GroupSection extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final bool scroll;
  final int columns;
  final double scrollHeight;
  final double scrollItemWidth;
  final int count;
  final Widget Function(int) itemBuilder;

  /// Optional soft tint behind the whole section. Rendered full-bleed as a
  /// top-down fade so the section reads as its own highlighted zone.
  final Color? background;

  const _GroupSection({
    required this.title,
    required this.subtitle,
    required this.scroll,
    required this.columns,
    required this.scrollHeight,
    required this.scrollItemWidth,
    required this.count,
    required this.itemBuilder,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    final showHeader = (title ?? '').isNotEmpty;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader) _SectionHeader(title: title!, subtitle: subtitle),
        SizedBox(
            height: showHeader ? AppDimens.paddingM : AppDimens.paddingS),
        _railBody(
          scroll: scroll,
          columns: columns,
          scrollHeight: scrollHeight,
          scrollItemWidth: scrollItemWidth,
          count: count,
          itemBuilder: itemBuilder,
        ),
      ],
    );

    if (background == null) return content;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.only(top: 8, bottom: AppDimens.padding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [background!, background!.withValues(alpha: 0)],
        ),
      ),
      child: content,
    );
  }
}

// ── Cuisine circle (MERCHANT_WITH_TAG) ────────────────────────────

class _CircleItem extends StatelessWidget {
  final Merchant item;

  const _CircleItem({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final imageUrl = ServerConfig.getFullImageUrl(item.imageUrl);
    return Column(
      children: [
        ClipOval(
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            height: 84,
            width: 84,
            fit: BoxFit.cover,
            placeholder: (_, _) => Container(
                height: 84, width: 84, color: colors.colorBackgroundGray),
            errorWidget: (_, _, _) => Container(
              height: 84,
              width: 84,
              color: colors.colorBackgroundGray,
              child: Icon(Icons.local_offer_outlined,
                  color: colors.colorTextHint, size: 26),
            ),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          height: 28,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              item.name ?? '',
              maxLines: 1,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.colorText,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Offer card (PROMO_CODE) — banner image + name ─────────────────

class _OfferCard extends StatelessWidget {
  final Merchant item;
  const _OfferCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final imageUrl = ServerConfig.getFullImageUrl(item.imageUrl);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 1.5,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (_, _) => Container(color: colors.colorBackgroundGray),
              errorWidget: (_, _, _) => Container(
                color: colors.colorBackgroundGray,
                child: Icon(Icons.local_offer,
                    color: colors.colorTextHint, size: 26),
              ),
            ),
            const _BottomScrim(radius: 16),
            // Promo name overlaid on the scrim.
            Positioned(
              left: 10,
              right: 10,
              bottom: 8,
              child: Text(
                item.name ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Brand logo (BRAND) — rounded square ───────────────────────────

class _BrandItem extends StatelessWidget {
  final Merchant item;
  const _BrandItem({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final imageUrl = ServerConfig.getFullImageUrl(item.imageUrl);
    return Column(
      children: [
        Container(
          height: 80,
          width: 80,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colors.colorBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.colorText.withValues(alpha: 0.1)),
          ),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            errorWidget: (_, _, _) =>
                Icon(Icons.storefront, color: colors.colorTextHint, size: 28),
          ),
        ),
        const SizedBox(height: 6),
        AppText.caption(item.name ?? '',
            textAlign: TextAlign.center,
            fontWeight: FontWeight.w600,
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

// ── Category / group / product tile ───────────────────────────────

class _TileItem extends StatelessWidget {
  final Merchant item;
  const _TileItem({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final imageUrl = ServerConfig.getFullImageUrl(item.imageUrl);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: AspectRatio(
            aspectRatio: 1,
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (_, _) => Container(color: colors.colorBackgroundGray),
              errorWidget: (_, _, _) => Container(
                color: colors.colorBackgroundGray,
                child: Icon(Icons.category_outlined,
                    color: colors.colorTextHint, size: 28),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        AppText.caption(item.name ?? '',
            fontWeight: FontWeight.w600,
            maxLines: 2,
            overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

// ── Restaurant card (merchant types; optional rank / offer badge) ─

class _RestaurantRailCard extends StatelessWidget {
  final Merchant merchant;
  final VoidCallback? onTap;

  const _RestaurantRailCard({required this.merchant, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final imageUrl = ServerConfig.getFullImageUrl(merchant.imageUrl);
    final closed = merchant.isOpen == false;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: AspectRatio(
            aspectRatio: 220 / 140,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, _) =>
                        Container(color: colors.colorBackgroundGray),
                    errorWidget: (_, _, _) => Container(
                      color: colors.colorBackgroundGray,
                      child: Icon(Icons.storefront,
                          color: colors.colorTextHint, size: 36),
                    ),
                  ),
                ),
                // Subtle bottom gradient for legibility of on-image badges.
                const _BottomScrim(radius: 18),
                if (closed)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Center(
                      child: Text(
                          getString(
                              appStr.descriptionClosed, 'description_closed'),
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w700)),
                    ),
                  ),
                if (merchant.customerRate != null && merchant.customerRate! > 0)
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: _RatingBadge(merchant.customerRate!, onImage: true),
                  ),
                const Positioned(top: 8, right: 8, child: _Heart()),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        AppText.body(merchant.name ?? '',
            fontWeight: FontWeight.w700,
            fontSize: 15,
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        _MetaRow(merchant: merchant),
        ],
      ),
    );
  }
}

/// A soft dark gradient at the bottom of a card image so white badges stay
/// legible on light photos.
class _BottomScrim extends StatelessWidget {
  final double radius;
  const _BottomScrim({required this.radius});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.center,
              colors: [Colors.black.withValues(alpha: 0.28), Colors.transparent],
            ),
          ),
        ),
      ),
    );
  }
}

// ── All restaurants (vertical list) ───────────────────────────────

class _AllMerchantList extends StatelessWidget {
  final String title;
  final List<Merchant> merchants;
  final void Function(Merchant)? onTap;

  const _AllMerchantList(
      {required this.title, required this.merchants, this.onTap});

  @override
  Widget build(BuildContext context) {
    if (merchants.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: title),
        const SizedBox(height: AppDimens.paddingM),
        for (final m in merchants)
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppDimens.padding, 0, AppDimens.padding, AppDimens.padding),
            child: _RestaurantListCard(
                merchant: m, onTap: onTap == null ? null : () => onTap!(m)),
          ),
      ],
    );
  }
}

class _RestaurantListCard extends StatelessWidget {
  final Merchant merchant;
  final VoidCallback? onTap;

  const _RestaurantListCard({required this.merchant, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final imageUrl = ServerConfig.getFullImageUrl(merchant.imageUrl);
    final hasRate = merchant.customerRate != null && merchant.customerRate! > 0;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.colorBackground,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: colors.colorText.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  height: 100,
                  width: 100,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => Container(
                      height: 100, width: 100, color: colors.colorBackgroundGray),
                  errorWidget: (_, _, _) => Container(
                    height: 100,
                    width: 100,
                    color: colors.colorBackgroundGray,
                    child: Icon(Icons.storefront,
                        color: colors.colorTextHint, size: 32),
                  ),
                ),
              ),
              if (hasRate)
                Positioned(
                  left: 6,
                  bottom: 6,
                  child: _RatingBadge(merchant.customerRate!, onImage: true),
                ),
            ],
          ),
          const SizedBox(width: AppDimens.paddingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AppText.body(merchant.name ?? '',
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    const _Heart(),
                  ],
                ),
                if ((merchant.description ?? '').isNotEmpty) ...[
                  const SizedBox(height: 3),
                  AppText.caption(merchant.description!,
                      color: colors.colorTextHint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 8),
                _MetaRow(merchant: merchant),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}

// ── Shared bits ───────────────────────────────────────────────────

class _Heart extends StatelessWidget {
  const _Heart();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: const Icon(Icons.favorite_border, size: 17, color: Colors.black87),
    );
  }
}

/// Zomato-style filled rating badge (green background, white text).
class _RatingBadge extends StatelessWidget {
  static const _green = Color(0xFF267E3E);

  final double rate;
  final bool onImage;

  const _RatingBadge(this.rate, {this.onImage = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
      decoration: BoxDecoration(
        color: _green,
        borderRadius: BorderRadius.circular(8),
        border: onImage
            ? Border.all(color: Colors.white.withValues(alpha: 0.85), width: 1)
            : null,
        boxShadow: onImage
            ? [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 5,
                    offset: const Offset(0, 2))
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 12, color: Colors.white),
          const SizedBox(width: 2),
          Text(rate.toStringAsFixed(1),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

/// Muted "time • distance" meta. Width-aware: on narrow cards (e.g. the
/// 3-column offer grid) the distance is dropped so nothing gets clipped.
class _MetaRow extends StatelessWidget {
  final Merchant merchant;

  const _MetaRow({required this.merchant});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final time = _time(merchant);
    final dist = merchant.distance != null ? _distance(merchant.distance!) : '';

    return LayoutBuilder(
      builder: (context, c) {
        final compact = c.maxWidth < 150;
        final bits = <String>[
          if (time.isNotEmpty) time,
          if (!compact && dist.isNotEmpty) dist,
        ];
        if (bits.isEmpty) return const SizedBox.shrink();
        return Text(bits.join('  •  '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: colors.colorTextHint));
      },
    );
  }
}

String _time(Merchant m) {
  final mn = m.minPreparationTime?.toInt();
  final mx = m.maxPreparationTime?.toInt();
  if (mn != null && mx != null) return '$mn - $mx mins';
  if (mx != null) return '$mx mins';
  if (mn != null) return '$mn mins';
  return '';
}

String _distance(double meters) => meters >= 1000
    ? '${(meters / 1000).toStringAsFixed(1)} km'
    : '${meters.toInt()} m';

// ── Shimmer skeleton (feed loading) ───────────────────────────────

class _FeedSkeleton extends StatelessWidget {
  const _FeedSkeleton();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    Widget box(double w, double h, [double r = 10]) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(r)),
        );

    return Shimmer.fromColors(
      baseColor: colors.colorBackgroundGray,
      highlightColor: colors.colorBackground,
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            box(150, 20),
            const SizedBox(height: 14),
            Row(children: [
              box(220, 150, 16),
              const SizedBox(width: 12),
              box(220, 150, 16),
            ]),
            const SizedBox(height: 26),
            box(120, 20),
            const SizedBox(height: 14),
            Row(children: [
              for (var i = 0; i < 4; i++) ...[
                const _CircleSkeleton(),
                const SizedBox(width: 16),
              ],
            ]),
          ],
        ),
      ),
    );
  }
}

class _CircleSkeleton extends StatelessWidget {
  const _CircleSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        CircleAvatar(radius: 40, backgroundColor: Colors.white),
        SizedBox(height: 8),
        SizedBox(
          width: 56,
          height: 10,
          child: DecoratedBox(decoration: BoxDecoration(color: Colors.white)),
        ),
      ],
    );
  }
}
