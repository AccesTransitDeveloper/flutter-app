import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/api/server_config.dart';
import '../../../models/responses/delivery/delivery_responses.dart';
import '../../../models/responses/delivery/merchant_menu_responses.dart';
import '../../../viewmodels/cart_viewmodel.dart';
import '../../../viewmodels/merchant_detail_viewmodel.dart';
import '../../widgets/app_text.dart';
import 'product_customize_sheet.dart';

/// Store menu / product-listing screen (mirrors GrabIT SDMerchantDetailView):
/// parallax/stretch banner + overlapping logo + delivery toggle + product
/// sections, with a fade-in sticky category bar (compact header + tabs) that
/// appears once the header scrolls away.
class MerchantDetailScreen extends ConsumerStatefulWidget {
  final Merchant merchant;
  final String? mainCategoryId;
  final String? cityId;
  final String? timezone;

  const MerchantDetailScreen({
    super.key,
    required this.merchant,
    this.mainCategoryId,
    this.cityId,
    this.timezone,
  });

  @override
  ConsumerState<MerchantDetailScreen> createState() =>
      _MerchantDetailScreenState();
}

class _MerchantDetailScreenState extends ConsumerState<MerchantDetailScreen> {
  static const double _bannerHeight = 200;

  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _tabScrollController = ScrollController();
  final _offset = ValueNotifier<double>(0);

  String _query = '';
  bool _isDelivery = true;

  final Map<String, GlobalKey> _sectionKeys = {};
  final Map<int, GlobalKey> _tabKeys = {};
  List<MenuSectionData> _sections = const [];
  int _activeTab = 0;
  bool _programmaticScroll = false;
  double _stickyHeight = 150;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _tabScrollController.dispose();
    _searchController.dispose();
    _offset.dispose();
    super.dispose();
  }

  MerchantMenuArgs get _args => (
        merchantId: widget.merchant.id ?? '',
        mainCategoryId: widget.mainCategoryId,
      );

  GlobalKey _sectionKey(String id) =>
      _sectionKeys.putIfAbsent(id, () => GlobalKey());
  GlobalKey _tabKey(int i) => _tabKeys.putIfAbsent(i, () => GlobalKey());
  String _sid(int i) => _sections[i].id;

  // ── Lazy-load category products as they approach the viewport ───
  void _maybeLoadVisibleCategories() {
    if (!mounted || _sections.isEmpty) return;
    final vh = MediaQuery.of(context).size.height;
    for (int i = 0; i < _sections.length; i++) {
      final s = _sections[i];
      if (!s.isCategory || s.isLoaded || s.isLoading) continue;
      final ctx = _sectionKeys[_sid(i)]?.currentContext;
      final box = ctx?.findRenderObject() as RenderBox?;
      if (box == null) continue;
      final dy = box.localToGlobal(Offset.zero).dy;
      if (dy < vh + 1200) {
        ref
            .read(merchantDetailViewModelProvider(_args).notifier)
            .loadCategory(s.id);
      }
    }
  }

  // ── Scroll → offset + active-tab sync ───────────────────────────
  void _onScroll() {
    _offset.value = _scrollController.offset;
    _maybeLoadVisibleCategories();
    if (_programmaticScroll || _sections.isEmpty) return;
    int active = 0;
    for (int i = 0; i < _sections.length; i++) {
      final ctx = _sectionKeys[_sid(i)]?.currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null) continue;
      final dy = box.localToGlobal(Offset.zero).dy;
      if (dy <= _stickyHeight + 12) {
        active = i;
      } else {
        break;
      }
    }
    if (active != _activeTab) {
      setState(() => _activeTab = active);
      _centerTab(active);
    }
  }

  Future<void> _scrollToSection(int i) async {
    // Kick off loading the target category so it's ready when we arrive.
    ref
        .read(merchantDetailViewModelProvider(_args).notifier)
        .loadCategory(_sections[i].id);
    final ctx = _sectionKeys[_sid(i)]?.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox;
    final target = _scrollController.offset +
        box.localToGlobal(Offset.zero).dy -
        _stickyHeight -
        8;
    setState(() => _activeTab = i);
    _centerTab(i);
    _programmaticScroll = true;
    await _scrollController.animateTo(
      target.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
    _programmaticScroll = false;
  }

  void _centerTab(int i) {
    final ctx = _tabKeys[i]?.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(ctx,
        alignment: 0.4,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut);
  }

  // ── Cart actions ────────────────────────────────────────────────
  String _simpleKey(DeliveryProduct p) =>
      '${p.id}|${p.defaultVariant?.id ?? ''}|';

  void _add(DeliveryProduct p) {
    if (p.isOutOfStock) return;
    if (p.hasVariants || p.hasModifiers) {
      _openSheet(p);
      return;
    }
    final v = p.defaultVariant;
    ref.read(cartProvider.notifier).addLine(
          merchantId: widget.merchant.id ?? '',
          merchantName: widget.merchant.name ?? '',
          timezone: widget.timezone,
          line: CartLine(
            productId: p.id ?? '',
            variantId: v?.id ?? '',
            qty: 1,
            basePrice: v?.effectivePrice ?? p.effectivePrice ?? 0,
            name: p.name ?? '',
            imageUrl: p.imageUrl,
            isVeg: p.isVeg,
            maxQty: v?.maxQtyAddInCart,
          ),
        );
  }

  void _inc(DeliveryProduct p) {
    if (p.hasVariants || p.hasModifiers) {
      _openSheet(p);
      return;
    }
    ref.read(cartProvider.notifier).increment(_simpleKey(p));
  }

  void _dec(DeliveryProduct p) =>
      ref.read(cartProvider.notifier).decrement(_simpleKey(p));

  void _openSheet(DeliveryProduct p) => showProductCustomizeSheet(
        context,
        product: p,
        merchant: widget.merchant,
        timezone: widget.timezone,
      );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final notifier = ref.read(merchantDetailViewModelProvider(_args).notifier);
    notifier.timezone ??= widget.timezone;
    final state = ref.watch(merchantDetailViewModelProvider(_args));
    final cart = ref.watch(cartProvider);
    final merchant = widget.merchant;
    final topInset = MediaQuery.of(context).padding.top;
    _stickyHeight = topInset + 100;

    final searching = _query.trim().isNotEmpty;
    final sections = state.sections;
    _sections = sections;
    if (_activeTab >= sections.length) _activeTab = 0;

    final showTabs = !searching && sections.length > 1;
    final showCartBar = cart.merchantId == merchant.id && !cart.isEmpty;

    // Load categories that are already near the viewport (initial + growth).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeLoadVisibleCategories();
    });

    return Scaffold(
      backgroundColor: colors.colorBackground,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              SliverToBoxAdapter(child: _banner(colors, merchant)),
              SliverToBoxAdapter(child: _sheetTop(colors, merchant)),
              if (state.isLoading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 60),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              else if (sections.isEmpty)
                SliverToBoxAdapter(child: _empty(colors, state.errorMessage))
              else if (searching)
                SliverToBoxAdapter(child: _searchResults(colors, sections, cart))
              else
                for (int i = 0; i < sections.length; i++)
                  SliverToBoxAdapter(
                    child: KeyedSubtree(
                      key: _sectionKey(_sid(i)),
                      child: _SectionView(
                        section: sections[i],
                        cart: cart,
                        onAdd: _add,
                        onInc: _inc,
                        onDec: _dec,
                      ),
                    ),
                  ),
              SliverToBoxAdapter(child: SizedBox(height: showCartBar ? 90 : 24)),
            ],
          ),
          // Fixed back button on the banner (visible before the sticky bar).
          Positioned(
            top: topInset + 6,
            left: 14,
            child: ValueListenableBuilder<double>(
              valueListenable: _offset,
              builder: (_, off, _) {
                final p = _stickyProgress(off);
                return Opacity(
                  opacity: (1 - p).clamp(0.0, 1.0),
                  child: _circleButton(
                      Icons.arrow_back, () => Navigator.of(context).pop()),
                );
              },
            ),
          ),
          // Fade-in sticky category bar.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ValueListenableBuilder<double>(
              valueListenable: _offset,
              builder: (_, off, _) {
                final p = _stickyProgress(off);
                if (p <= 0.01) return const SizedBox.shrink();
                return Transform.translate(
                  offset: Offset(0, (p - 1) * _stickyHeight),
                  child: Opacity(
                    opacity: p,
                    child: IgnorePointer(
                      ignoring: p < 0.7,
                      child: _stickyBar(colors, merchant, sections, showTabs),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: showCartBar ? _cartBar(colors, cart) : null,
    );
  }

  /// 0 = hidden, 1 = fully shown. Appears once the banner has scrolled away.
  double _stickyProgress(double off) {
    const appearAt = _bannerHeight - 40;
    const fullyAt = _bannerHeight + 40;
    return ((off - appearAt) / (fullyAt - appearAt)).clamp(0.0, 1.0);
  }

  /// Flat filtered list across all already-loaded sections' products.
  Widget _searchResults(
      AppColorPalette colors, List<MenuSectionData> sections, CartState cart) {
    final q = _query.trim().toLowerCase();
    final seen = <String>{};
    final results = <DeliveryProduct>[];
    for (final s in sections) {
      for (final p in s.products) {
        if ((p.name ?? '').toLowerCase().contains(q) &&
            seen.add(p.id ?? p.name ?? '')) {
          results.add(p);
        }
      }
    }
    if (results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Center(
          child: AppText.body('No items match "$_query"',
              color: colors.colorTextHint),
        ),
      );
    }
    return Column(
      children: [
        for (final p in results)
          _ProductRow(
            product: p,
            control: _CartControl(
              product: p,
              qty: cart.qtyForProduct(p.id ?? ''),
              onAdd: () => _add(p),
              onInc: () => _inc(p),
              onDec: () => _dec(p),
            ),
            onTap: () => _add(p),
          ),
      ],
    );
  }

  // ── Banner (parallax + stretch) ─────────────────────────────────
  Widget _banner(AppColorPalette colors, Merchant merchant) {
    final imageUrl = ServerConfig.getFullImageUrl(merchant.imageUrl);
    return ValueListenableBuilder<double>(
      valueListenable: _offset,
      builder: (_, off, _) {
        final stretch = off < 0 ? -off : 0.0;
        final scale = 1 + stretch / 200;
        final parallax = off > 0 ? off * 0.4 : 0.0;
        return SizedBox(
          height: _bannerHeight,
          width: double.infinity,
          child: Transform.translate(
            offset: Offset(0, parallax),
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.bottomCenter,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, _) =>
                        Container(color: colors.colorBackgroundGray),
                    errorWidget: (_, _, _) => Container(
                      color: colors.colorBackgroundGray,
                      child: Icon(Icons.storefront,
                          color: colors.colorTextHint, size: 56),
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black38, Colors.transparent],
                        stops: [0, 0.5],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── White sheet top: logo + name + toggle + search ──────────────
  Widget _sheetTop(AppColorPalette colors, Merchant merchant) {
    return Container(
      color: colors.colorBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppDimens.padding, 16, AppDimens.padding, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(merchant.name ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: colors.colorText)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if ((merchant.customerRate ?? 0) > 0) ...[
                      _ratingPill(merchant.customerRate!),
                      const SizedBox(width: 8),
                    ],
                    if (merchant.distance != null)
                      Text(
                          merchant.distance! >= 1000
                              ? '${(merchant.distance! / 1000).toStringAsFixed(2)} km'
                              : '${merchant.distance!.toInt()} m',
                          style: TextStyle(
                              fontSize: 12.5, color: colors.colorTextHint)),
                  ],
                ),
                if ((merchant.address ?? '').isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(merchant.address!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12.5, color: colors.colorTextHint)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          _prepAndToggleRow(colors, merchant),
          const SizedBox(height: 16),
          _searchBar(colors),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _prepAndToggleRow(AppColorPalette colors, Merchant merchant) {
    final mn = merchant.minPreparationTime?.toInt();
    final mx = merchant.maxPreparationTime?.toInt();
    final prep = (mn != null && mx != null)
        ? '$mn-$mx mins'
        : (mx != null ? '$mx mins' : '');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.padding),
      child: Row(
        children: [
          if (prep.isNotEmpty)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Preparing time',
                      style:
                          TextStyle(fontSize: 12, color: colors.colorTextHint)),
                  Text(prep,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: colors.colorText)),
                ],
              ),
            )
          else
            const Spacer(),
          Container(
            decoration: BoxDecoration(
              color: colors.colorText.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                _toggleBtn(colors, 'Delivery', _isDelivery,
                    () => setState(() => _isDelivery = true)),
                _toggleBtn(colors, 'Pickup', !_isDelivery,
                    () => setState(() => _isDelivery = false)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleBtn(
      AppColorPalette colors, String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? colors.colorPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: selected ? colors.colorButtonText : colors.colorText)),
      ),
    );
  }

  Widget _ratingPill(double rate) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFF267E3E),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, size: 13, color: Colors.white),
            const SizedBox(width: 2),
            Text(rate.toStringAsFixed(1),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800)),
          ],
        ),
      );

  Widget _searchBar(AppColorPalette colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.padding),
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: colors.colorBackgroundGray.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded, color: colors.colorPrimary, size: 21),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _query = v),
                style: TextStyle(fontSize: 14, color: colors.colorText),
                decoration: InputDecoration(
                  hintText: 'Search menu',
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
                    color: colors.colorTextHint, size: 19),
              ),
          ],
        ),
      ),
    );
  }

  // ── Sticky category bar (compact header + tabs) ─────────────────
  Widget _stickyBar(AppColorPalette colors, Merchant merchant,
      List<MenuSectionData> sections, bool showTabs) {
    final topInset = MediaQuery.of(context).padding.top;
    return Material(
      color: colors.colorBackground,
      elevation: 3,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: topInset),
          // Compact header.
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: colors.colorText),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(merchant.name ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: colors.colorText)),
                ),
              ],
            ),
          ),
          if (showTabs)
            SizedBox(
              height: 42,
              child: ListView.builder(
                controller: _tabScrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: sections.length,
                itemBuilder: (context, i) {
                  final selected = i == _activeTab;
                  return GestureDetector(
                    key: _tabKey(i),
                    onTap: () => _scrollToSection(i),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(sections[i].title,
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: selected
                                      ? FontWeight.w800
                                      : FontWeight.w500,
                                  color: selected
                                      ? colors.colorText
                                      : colors.colorTextHint)),
                          const SizedBox(height: 5),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 3,
                            width: selected ? 24 : 0,
                            decoration: BoxDecoration(
                                color: colors.colorPrimary,
                                borderRadius: BorderRadius.circular(2)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          Divider(
              height: 1,
              thickness: 1,
              color: colors.colorText.withValues(alpha: 0.06)),
        ],
      ),
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onTap) => Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 2,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: Icon(icon, color: Colors.black87, size: 20),
          ),
        ),
      );

  // ── Cart bar ────────────────────────────────────────────────────
  Widget _cartBar(AppColorPalette colors, CartState cart) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
        child: Material(
          color: colors.colorPrimary,
          borderRadius: BorderRadius.circular(16),
          elevation: 8,
          shadowColor: colors.colorPrimary.withValues(alpha: 0.5),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => context.push('/cart'),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                children: [
                  Icon(Icons.shopping_bag_outlined,
                      color: colors.colorButtonText, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    '${cart.totalQty} ${cart.totalQty == 1 ? 'item' : 'items'}',
                    style: TextStyle(
                        color: colors.colorButtonText,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  Text('View Cart',
                      style: TextStyle(
                          color: colors.colorButtonText,
                          fontSize: 15,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded,
                      color: colors.colorButtonText, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _empty(AppColorPalette colors, String? error) => Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.restaurant_menu, size: 56, color: colors.colorTextHint),
              const SizedBox(height: 12),
              AppText.body(error ?? 'No items available right now.',
                  color: colors.colorTextHint, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
}

// ── Menu section (product group or lazily-loaded category) ────────

class _SectionView extends StatelessWidget {
  final MenuSectionData section;
  final CartState cart;
  final void Function(DeliveryProduct) onAdd;
  final void Function(DeliveryProduct) onInc;
  final void Function(DeliveryProduct) onDec;

  const _SectionView({
    required this.section,
    required this.cart,
    required this.onAdd,
    required this.onInc,
    required this.onDec,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final products = section.products;
    final loaded = section.isLoaded;
    // A loaded, empty product group renders nothing (keeps the feed clean).
    if (!section.isCategory && products.isEmpty) return const SizedBox.shrink();

    Widget cell(DeliveryProduct p, {required bool card}) {
      final control = _CartControl(
        product: p,
        qty: cart.qtyForProduct(p.id ?? ''),
        onAdd: () => onAdd(p),
        onInc: () => onInc(p),
        onDec: () => onDec(p),
      );
      return card
          ? _ProductCard(product: p, control: control, onTap: () => onAdd(p))
          : _ProductRow(product: p, control: control, onTap: () => onAdd(p));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppDimens.padding, 18, AppDimens.padding, 4),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: colors.colorPrimary,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Expanded(
                child: AppText.title(section.title,
                    fontSize: 19, fontWeight: FontWeight.w800),
              ),
              if (loaded)
                AppText.caption('${products.length}',
                    color: colors.colorTextHint),
            ],
          ),
        ),
        if (!loaded)
          // Category not fetched yet — placeholder keeps scroll positions stable.
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (products.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(AppDimens.padding, 6, 0, 10),
            child: AppText.caption('No items in this category',
                color: colors.colorTextHint),
          )
        else if (section.scroll)
          SizedBox(
            height: 244,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(
                  AppDimens.padding, 10, AppDimens.padding, 6),
              itemCount: products.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, i) =>
                  SizedBox(width: 156, child: cell(products[i], card: true)),
            ),
          )
        else
          Column(
            children: [
              for (final p in products) cell(p, card: false),
            ],
          ),
      ],
    );
  }
}

// ── Veg / non-veg indicator ───────────────────────────────────────

class _FoodTypeDot extends StatelessWidget {
  final DeliveryProduct product;
  const _FoodTypeDot({required this.product});

  @override
  Widget build(BuildContext context) {
    if (!product.hasFoodType) return const SizedBox.shrink();
    final color = product.isVeg
        ? const Color(0xFF3AA757)
        : product.isEgg
            ? const Color(0xFFF4A100)
            : const Color(0xFFD32F2F);
    return Container(
      width: 15,
      height: 15,
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Center(
        child: Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

// ── Price text ────────────────────────────────────────────────────

class _PriceText extends StatelessWidget {
  final DeliveryProduct product;
  const _PriceText({required this.product});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final price = product.price;
    if (price == null) return const SizedBox.shrink();
    if (product.hasDiscount) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_fmt(product.discountedPrice!),
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: colors.colorText)),
          const SizedBox(width: 6),
          Text(_fmt(price),
              style: TextStyle(
                  fontSize: 12,
                  color: colors.colorTextHint,
                  decoration: TextDecoration.lineThrough)),
        ],
      );
    }
    return Text(_fmt(price),
        style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w700, color: colors.colorText));
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
}

// ── Cart control (Add / stepper / customize) ──────────────────────

class _CartControl extends StatelessWidget {
  final DeliveryProduct product;
  final int qty;
  final VoidCallback onAdd;
  final VoidCallback onInc;
  final VoidCallback onDec;

  const _CartControl({
    required this.product,
    required this.qty,
    required this.onAdd,
    required this.onInc,
    required this.onDec,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (product.isOutOfStock) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: colors.colorBackgroundGray,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text('Out of stock',
            style: TextStyle(
                color: colors.colorTextHint,
                fontSize: 11.5,
                fontWeight: FontWeight.w700)),
      );
    }

    final customizable = product.hasVariants || product.hasModifiers;

    if (!customizable && qty > 0) {
      return Container(
        decoration: BoxDecoration(
          color: colors.colorPrimary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _step(colors, Icons.remove, onDec),
            SizedBox(
              width: 26,
              child: Text('$qty',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: colors.colorButtonText,
                      fontSize: 15,
                      fontWeight: FontWeight.w800)),
            ),
            _step(colors, Icons.add, onInc),
          ],
        ),
      );
    }

    final label = customizable
        ? (product.hasVariants
            ? '${product.variants.length} options'
            : 'Customize')
        : 'ADD';
    return Material(
      color: colors.colorBackground,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onAdd,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.colorPrimary, width: 1.3),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (customizable && qty > 0) ...[
                Text('$qty',
                    style: TextStyle(
                        color: colors.colorPrimary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800)),
                const SizedBox(width: 5),
                Container(
                    width: 1,
                    height: 12,
                    color: colors.colorPrimary.withValues(alpha: 0.4)),
                const SizedBox(width: 5),
              ],
              Text(label,
                  style: TextStyle(
                      color: colors.colorPrimary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3)),
              if (!customizable) ...[
                const SizedBox(width: 3),
                Icon(Icons.add, size: 15, color: colors.colorPrimary),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _step(AppColorPalette colors, IconData icon, VoidCallback onTap) =>
      InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Icon(icon, size: 16, color: colors.colorButtonText),
        ),
      );
}

// ── Product row (vertical list) ───────────────────────────────────

class _ProductRow extends StatelessWidget {
  final DeliveryProduct product;
  final Widget control;
  final VoidCallback onTap;
  const _ProductRow(
      {required this.product, required this.control, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final imageUrl = ServerConfig.getFullImageUrl(product.imageUrl);
    final hasImage = (product.imageUrl ?? '').isNotEmpty;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.padding, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FoodTypeDot(product: product),
                  const SizedBox(height: 6),
                  Text(product.name ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: colors.colorText)),
                  const SizedBox(height: 5),
                  _PriceText(product: product),
                  if ((product.description ?? '').isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(product.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12.5,
                            height: 1.3,
                            color: colors.colorTextHint)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 14),
            SizedBox(
              width: 112,
              child: Column(
                children: [
                  if (hasImage)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        height: 100,
                        width: 112,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => Container(
                            height: 100,
                            width: 112,
                            color: colors.colorBackgroundGray),
                        errorWidget: (_, _, _) => Container(
                          height: 100,
                          width: 112,
                          color: colors.colorBackgroundGray,
                          child:
                              Icon(Icons.fastfood, color: colors.colorTextHint),
                        ),
                      ),
                    ),
                  Transform.translate(
                    offset: Offset(0, hasImage ? -14 : 0),
                    child: SizedBox(
                      width: 112,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.center,
                        child: control,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Product card (horizontal scroll) ──────────────────────────────

class _ProductCard extends StatelessWidget {
  final DeliveryProduct product;
  final Widget control;
  final VoidCallback onTap;
  const _ProductCard(
      {required this.product, required this.control, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final imageUrl = ServerConfig.getFullImageUrl(product.imageUrl);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 132,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    height: 132,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, _) =>
                        Container(color: colors.colorBackgroundGray),
                    errorWidget: (_, _, _) => Container(
                      color: colors.colorBackgroundGray,
                      child: Icon(Icons.fastfood, color: colors.colorTextHint),
                    ),
                  ),
                ),
                Positioned(right: 8, bottom: -10, child: control),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _FoodTypeDot(product: product),
              if (product.hasFoodType) const SizedBox(width: 6),
              Expanded(
                child: Text(product.name ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colors.colorText)),
              ),
            ],
          ),
          const SizedBox(height: 5),
          _PriceText(product: product),
        ],
      ),
    );
  }
}
