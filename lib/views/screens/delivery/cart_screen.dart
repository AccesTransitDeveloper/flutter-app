import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/app_navigation.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/api/server_config.dart';
import '../../../viewmodels/cart_viewmodel.dart';
import '../../../viewmodels/home_viewmodel.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_text.dart';

/// Delivery cart + checkout — items, bill summary, address, place order.
class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final _noteController = TextEditingController();
  bool _placing = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

  Future<void> _placeOrder() async {
    setState(() => _placing = true);
    final outcome = await ref.read(cartProvider.notifier).placeOrder(
          customerNote: _noteController.text.trim(),
        );
    if (!mounted) return;
    setState(() => _placing = false);
    if (outcome.success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Order placed successfully 🎉')));
      context.navigateToHome();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(outcome.message ?? 'Could not place the order')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final cart = ref.watch(cartProvider);
    final address = ref.watch(homeViewModelProvider).pickupAddress;

    return AppScaffold(
      appBar: AppBar(
        backgroundColor: colors.colorBackground,
        foregroundColor: colors.colorText,
        elevation: 0,
        title: AppText.title(cart.merchantName ?? 'Cart',
            fontWeight: FontWeight.w800, fontSize: 19),
      ),
      body: cart.isEmpty
          ? _empty(colors)
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 16),
                    children: [
                      _addressCard(colors, address?.address ?? address?.title),
                      _itemsCard(colors, cart),
                      _noteCard(colors),
                      _billCard(colors, cart),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                _placeOrderBar(colors, cart),
              ],
            ),
    );
  }

  Widget _empty(AppColorPalette colors) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_bag_outlined,
                size: 64, color: colors.colorTextHint),
            const SizedBox(height: 12),
            AppText.body('Your cart is empty', color: colors.colorTextHint),
          ],
        ),
      );

  // ── Address ─────────────────────────────────────────────────────
  Widget _addressCard(AppColorPalette colors, String? address) {
    return _card(
      colors,
      child: Row(
        children: [
          Icon(Icons.location_on, color: colors.colorPrimary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Delivering to',
                    style:
                        TextStyle(fontSize: 12, color: colors.colorTextHint)),
                const SizedBox(height: 2),
                Text(address ?? 'Set your delivery address',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colors.colorText)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Items ───────────────────────────────────────────────────────
  Widget _itemsCard(AppColorPalette colors, CartState cart) {
    return _card(
      colors,
      child: Column(
        children: [
          for (int i = 0; i < cart.lines.length; i++) ...[
            if (i > 0)
              Divider(height: 20, color: colors.colorText.withValues(alpha: 0.06)),
            _itemRow(colors, cart.lines[i]),
          ],
          if (cart.pricing?.unavailableProducts.isNotEmpty ?? false) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Some items are unavailable and were not added.',
                style: TextStyle(
                    fontSize: 12,
                    color: colors.colorWarning,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _itemRow(AppColorPalette colors, CartLine line) {
    final imageUrl = ServerConfig.getFullImageUrl(line.imageUrl);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if ((line.imageUrl ?? '').isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              height: 48,
              width: 48,
              fit: BoxFit.cover,
              errorWidget: (_, _, _) => Container(
                  height: 48, width: 48, color: colors.colorBackgroundGray),
            ),
          )
        else
          _vegDot(line.isVeg),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(line.name,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colors.colorText)),
              if ((line.variantLabel ?? '').isNotEmpty ||
                  line.modifierSummary.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  [
                    if ((line.variantLabel ?? '').isNotEmpty) line.variantLabel!,
                    if (line.modifierSummary.isNotEmpty) line.modifierSummary,
                  ].join(' • '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: colors.colorTextHint),
                ),
              ],
              const SizedBox(height: 6),
              Text(_fmt(line.lineTotal),
                  style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: colors.colorText)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _lineStepper(colors, line),
      ],
    );
  }

  Widget _vegDot(bool isVeg) {
    final color = isVeg ? const Color(0xFF3AA757) : const Color(0xFFD32F2F);
    return Container(
      width: 16,
      height: 16,
      margin: const EdgeInsets.only(top: 2),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Center(
        child: Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      ),
    );
  }

  Widget _lineStepper(AppColorPalette colors, CartLine line) {
    final notifier = ref.read(cartProvider.notifier);
    return Container(
      decoration: BoxDecoration(
        color: colors.colorPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: colors.colorPrimary.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _stepBtn(colors, Icons.remove, () => notifier.decrement(line.key)),
          SizedBox(
            width: 24,
            child: Text('${line.qty}',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: colors.colorPrimary)),
          ),
          _stepBtn(colors, Icons.add, () => notifier.increment(line.key)),
        ],
      ),
    );
  }

  Widget _stepBtn(AppColorPalette colors, IconData icon, VoidCallback onTap) =>
      InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 16, color: colors.colorPrimary),
        ),
      );

  // ── Note ────────────────────────────────────────────────────────
  Widget _noteCard(AppColorPalette colors) {
    return _card(
      colors,
      child: Row(
        children: [
          Icon(Icons.edit_note_rounded, color: colors.colorTextHint, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _noteController,
              style: TextStyle(fontSize: 14, color: colors.colorText),
              decoration: InputDecoration(
                hintText: 'Add a note for the store (optional)',
                hintStyle: TextStyle(fontSize: 13.5, color: colors.colorTextHint),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bill ────────────────────────────────────────────────────────
  Widget _billCard(AppColorPalette colors, CartState cart) {
    final pricing = cart.pricing;
    return _card(
      colors,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bill details',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: colors.colorText)),
          const SizedBox(height: 10),
          if (cart.isRecalculating && pricing == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (pricing != null) ...[
            for (final row in pricing.billRows)
              _billRow(colors, row.title ?? '', row.amount,
                  free: row.isFree),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                        color: colors.colorText.withValues(alpha: 0.12)),
                  ),
                ),
                child: const SizedBox(width: double.infinity, height: 1),
              ),
            ),
            _billRow(colors, 'To pay', pricing.total ?? cart.grandTotal,
                bold: true),
          ] else
            _billRow(colors, 'Item total', cart.localSubtotal, bold: true),
        ],
      ),
    );
  }

  Widget _billRow(AppColorPalette colors, String title, double amount,
      {bool bold = false, bool free = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(title,
                style: TextStyle(
                    fontSize: bold ? 15 : 13.5,
                    fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                    color: bold ? colors.colorText : colors.colorTextHint)),
          ),
          Text(free ? 'Free' : _fmt(amount),
              style: TextStyle(
                  fontSize: bold ? 15 : 13.5,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                  color: free ? const Color(0xFF3AA757) : colors.colorText)),
        ],
      ),
    );
  }

  // ── Place order bar ─────────────────────────────────────────────
  Widget _placeOrderBar(AppColorPalette colors, CartState cart) {
    final total = cart.grandTotal;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Total',
                    style:
                        TextStyle(fontSize: 12, color: colors.colorTextHint)),
                Text(_fmt(total),
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: colors.colorText)),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Material(
                color: colors.colorPrimary,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _placing ? null : _placeOrder,
                  child: Container(
                    height: 52,
                    alignment: Alignment.center,
                    child: _placing
                        ? SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: colors.colorButtonText),
                          )
                        : Text('Place order',
                            style: TextStyle(
                                color: colors.colorButtonText,
                                fontSize: 16,
                                fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(AppColorPalette colors, {required Widget child}) => Container(
        margin:
            const EdgeInsets.fromLTRB(AppDimens.padding, 10, AppDimens.padding, 0),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.colorBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colors.colorText.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      );
}
