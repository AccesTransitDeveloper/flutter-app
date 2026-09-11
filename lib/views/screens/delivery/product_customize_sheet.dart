import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/api/response_state.dart';
import '../../../data/repository/app_repository.dart';
import '../../../data/api/server_config.dart';
import '../../../models/requests/delivery/cart_requests.dart';
import '../../../models/requests/delivery/delivery_requests.dart';
import '../../../models/responses/delivery/delivery_responses.dart';
import '../../../models/responses/delivery/merchant_menu_responses.dart';
import '../../../viewmodels/cart_viewmodel.dart';

/// Bottom sheet to pick a product's variant + modifiers before adding to cart.
Future<void> showProductCustomizeSheet(
  BuildContext context, {
  required DeliveryProduct product,
  required Merchant merchant,
  String? timezone,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CustomizeSheet(
      product: product,
      merchant: merchant,
      timezone: timezone,
    ),
  );
}

class _CustomizeSheet extends ConsumerStatefulWidget {
  final DeliveryProduct product;
  final Merchant merchant;
  final String? timezone;

  const _CustomizeSheet({
    required this.product,
    required this.merchant,
    this.timezone,
  });

  @override
  ConsumerState<_CustomizeSheet> createState() => _CustomizeSheetState();
}

class _CustomizeSheetState extends ConsumerState<_CustomizeSheet> {
  DeliveryProduct? _detail;
  bool _loading = true;

  ProductVariant? _variant;
  int _qty = 1;
  // modifierId -> set of selected optionIds
  final Map<String, Set<String>> _selected = {};

  DeliveryProduct get _p => _detail ?? widget.product;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final res = await ref.read(appRepositoryProvider).getProductDetail(
          widget.product.id ?? '',
          ProductDetailRequest(
            merchantId: widget.merchant.id ?? '',
            timezone: widget.timezone,
          ),
        );
    final fetched =
        res is Success<ProductDetailResponse> ? res.data?.product : null;
    if (!mounted) return;
    setState(() {
      // Prefer fetched detail; fall back to the product from the menu.
      _detail = (fetched != null &&
              (fetched.variants.isNotEmpty || fetched.modifiers.isNotEmpty))
          ? fetched
          : widget.product;
      _loading = false;
      _initSelection();
    });
  }

  void _initSelection() {
    final p = _p;
    _variant = p.defaultVariant;
    for (final m in p.modifiers) {
      final pre = m.options
          .where((o) => o.isDefaultSelected)
          .map((o) => o.id ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();
      _selected[m.id ?? ''] = pre;
    }
  }

  double get _basePrice => _variant?.effectivePrice ?? _p.effectivePrice ?? 0;

  double get _modifierPrice {
    double sum = 0;
    for (final m in _p.modifiers) {
      final sel = _selected[m.id ?? ''] ?? const {};
      for (final o in m.options) {
        if (sel.contains(o.id)) sum += o.price ?? 0;
      }
    }
    return sum;
  }

  double get _unitTotal => _basePrice + _modifierPrice;
  double get _total => _unitTotal * _qty;

  bool get _isValid {
    for (final m in _p.modifiers) {
      final sel = _selected[m.id ?? ''] ?? const {};
      if (m.minRange > 0 && sel.length < m.minRange) return false;
    }
    return true;
  }

  void _toggleOption(ProductModifier m, ProductModifierOption o) {
    final id = m.id ?? '';
    final oid = o.id ?? '';
    final sel = {...(_selected[id] ?? <String>{})};
    if (m.isSingleChoice) {
      sel
        ..clear()
        ..add(oid);
    } else {
      if (sel.contains(oid)) {
        sel.remove(oid);
      } else {
        if (m.maxRange > 0 && sel.length >= m.maxRange) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('You can select up to ${m.maxRange}'),
              duration: const Duration(milliseconds: 900)));
          return;
        }
        sel.add(oid);
      }
    }
    setState(() => _selected[id] = sel);
  }

  void _add() {
    final p = _p;
    final modifiers = <CartModifierParam>[];
    final summary = <String>[];
    for (final m in p.modifiers) {
      final sel = _selected[m.id ?? ''] ?? const {};
      if (sel.isEmpty) continue;
      final opts = <CartModifierOptionParam>[];
      for (final o in m.options) {
        if (sel.contains(o.id)) {
          opts.add(CartModifierOptionParam(
              id: o.id ?? '', name: o.name ?? '', price: o.price ?? 0, qty: 1));
          summary.add(o.name ?? '');
        }
      }
      if (opts.isNotEmpty) {
        modifiers.add(CartModifierParam(id: m.id ?? '', options: opts));
      }
    }

    final line = CartLine(
      productId: p.id ?? '',
      variantId: _variant?.id ?? '',
      qty: _qty,
      modifiers: modifiers,
      basePrice: _basePrice,
      modifierPrice: _modifierPrice,
      name: p.name ?? '',
      imageUrl: p.imageUrl,
      isVeg: p.isVeg,
      variantLabel: _variant?.unitLabel ?? _variant?.name,
      modifierSummary: summary.join(', '),
      maxQty: _variant?.maxQtyAddInCart,
    );

    ref.read(cartProvider.notifier).addLine(
          merchantId: widget.merchant.id ?? '',
          merchantName: widget.merchant.name ?? '',
          line: line,
          timezone: widget.timezone,
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final p = _p;
    return Container(
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: BoxDecoration(
        color: colors.colorBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: _loading
          ? const SizedBox(
              height: 280,
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _grabber(colors),
                Flexible(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                    children: [
                      _headerRow(colors, p),
                      if (p.variants.length > 1) ...[
                        const SizedBox(height: 18),
                        _sectionLabel(colors, 'Choose a size'),
                        const SizedBox(height: 8),
                        _variantChips(colors, p),
                      ],
                      for (final m in p.modifiers) ...[
                        const SizedBox(height: 18),
                        _modifierGroup(colors, m),
                      ],
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
                _bottomBar(colors),
              ],
            ),
    );
  }

  Widget _grabber(AppColorPalette colors) => Container(
        margin: const EdgeInsets.only(top: 10, bottom: 6),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: colors.colorTextHint.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(2),
        ),
      );

  Widget _headerRow(AppColorPalette colors, DeliveryProduct p) {
    final imageUrl = ServerConfig.getFullImageUrl(p.imageUrl);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if ((p.imageUrl ?? '').isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              height: 64,
              width: 64,
              fit: BoxFit.cover,
              errorWidget: (_, _, _) => Container(
                  height: 64, width: 64, color: colors.colorBackgroundGray),
            ),
          ),
        if ((p.imageUrl ?? '').isNotEmpty) const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p.name ?? '',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: colors.colorText)),
              if ((p.description ?? '').isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(p.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style:
                        TextStyle(fontSize: 12.5, color: colors.colorTextHint)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(AppColorPalette colors, String text) => Text(text,
      style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: colors.colorText));

  Widget _variantChips(AppColorPalette colors, DeliveryProduct p) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final v in p.variants)
          GestureDetector(
            onTap: () => setState(() => _variant = v),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: _variant?.id == v.id
                    ? colors.colorPrimary.withValues(alpha: 0.1)
                    : colors.colorBackgroundGray.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _variant?.id == v.id
                      ? colors.colorPrimary
                      : Colors.transparent,
                  width: 1.4,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(v.unitLabel ?? v.name ?? '',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _variant?.id == v.id
                              ? colors.colorPrimary
                              : colors.colorText)),
                  if (v.effectivePrice != null) ...[
                    const SizedBox(width: 6),
                    Text(_fmt(v.effectivePrice!),
                        style: TextStyle(
                            fontSize: 12.5, color: colors.colorTextHint)),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _modifierGroup(AppColorPalette colors, ProductModifier m) {
    final sel = _selected[m.id ?? ''] ?? const {};
    final subtitle = m.isSingleChoice
        ? (m.isRequired ? 'Select any one' : 'Optional')
        : m.maxRange > 0
            ? 'Select up to ${m.maxRange}'
            : 'Select any';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _sectionLabel(colors, m.name ?? '')),
            if (m.isRequired)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.colorPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('Required',
                    style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: colors.colorPrimary)),
              ),
          ],
        ),
        const SizedBox(height: 2),
        Text(subtitle,
            style: TextStyle(fontSize: 12, color: colors.colorTextHint)),
        const SizedBox(height: 6),
        for (final o in m.options)
          _optionRow(colors, m, o, sel.contains(o.id)),
      ],
    );
  }

  Widget _optionRow(AppColorPalette colors, ProductModifier m,
      ProductModifierOption o, bool selected) {
    return InkWell(
      onTap: () => _toggleOption(m, o),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              m.isSingleChoice
                  ? (selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked)
                  : (selected
                      ? Icons.check_box_rounded
                      : Icons.check_box_outline_blank),
              color: selected ? colors.colorPrimary : colors.colorTextHint,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(o.name ?? '',
                  style: TextStyle(fontSize: 14, color: colors.colorText)),
            ),
            if ((o.price ?? 0) > 0)
              Text('+ ${_fmt(o.price!)}',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.colorTextHint)),
          ],
        ),
      ),
    );
  }

  Widget _bottomBar(AppColorPalette colors) {
    final canAdd = _isValid && !_p.isOutOfStock;
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: colors.colorBackground,
        boxShadow: [
          BoxShadow(
            color: colors.colorText.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          _qtyStepper(colors),
          const SizedBox(width: 14),
          Expanded(
            child: Material(
              color: canAdd ? colors.colorPrimary : colors.colorTextHint,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: canAdd ? _add : null,
                child: Container(
                  height: 50,
                  alignment: Alignment.center,
                  child: Text(
                    'Add  •  ${_fmt(_total)}',
                    style: TextStyle(
                        color: colors.colorButtonText,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _qtyStepper(AppColorPalette colors) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.colorPrimary.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          _stepBtn(colors, Icons.remove,
              () => setState(() => _qty = _qty > 1 ? _qty - 1 : 1)),
          SizedBox(
            width: 30,
            child: Text('$_qty',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: colors.colorText)),
          ),
          _stepBtn(colors, Icons.add, () => setState(() => _qty++)),
        ],
      ),
    );
  }

  Widget _stepBtn(AppColorPalette colors, IconData icon, VoidCallback onTap) =>
      InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Icon(icon, size: 18, color: colors.colorPrimary),
        ),
      );

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
}
