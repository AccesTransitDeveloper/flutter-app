import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/api/response_state.dart';
import '../data/repository/app_repository.dart';
import '../models/requests/delivery/cart_requests.dart';
import '../models/requests/get_vehicle_types_request.dart';
import '../models/responses/delivery/cart_responses.dart';
import 'home_viewmodel.dart';

/// One line in the local delivery cart. Identity = product + variant + the exact
/// set of selected modifier options.
class CartLine {
  final String productId;
  final String variantId;
  final int qty;
  final List<CartModifierParam> modifiers;

  final double basePrice; // variant effective unit price (no modifiers)
  final double modifierPrice; // per-unit sum of selected option prices
  // Display fields.
  final String name;
  final String? imageUrl;
  final bool isVeg;
  final String? variantLabel;
  final String modifierSummary;
  final int? maxQty;

  const CartLine({
    required this.productId,
    required this.variantId,
    required this.qty,
    this.modifiers = const [],
    this.basePrice = 0,
    this.modifierPrice = 0,
    this.name = '',
    this.imageUrl,
    this.isVeg = false,
    this.variantLabel,
    this.modifierSummary = '',
    this.maxQty,
  });

  double get unitPrice => basePrice + modifierPrice;
  double get lineTotal => unitPrice * qty;

  /// Stable identity across qty changes.
  String get key {
    final opts = modifiers
        .expand((m) => m.options.map((o) => o.id))
        .toList()
      ..sort();
    return '$productId|$variantId|${opts.join(",")}';
  }

  CartLine copyWith({int? qty}) => CartLine(
        productId: productId,
        variantId: variantId,
        qty: qty ?? this.qty,
        modifiers: modifiers,
        basePrice: basePrice,
        modifierPrice: modifierPrice,
        name: name,
        imageUrl: imageUrl,
        isVeg: isVeg,
        variantLabel: variantLabel,
        modifierSummary: modifierSummary,
        maxQty: maxQty,
      );

  CartProductParam toParam() => CartProductParam(
        productId: productId,
        variantId: variantId,
        qty: qty,
        modifiers: modifiers,
        price: basePrice,
      );
}

class CartState {
  final String? merchantId;
  final String? merchantName;
  final List<CartLine> lines;
  final CartData? pricing; // server recalculation result
  final bool isRecalculating;
  final String? errorMessage;

  const CartState({
    this.merchantId,
    this.merchantName,
    this.lines = const [],
    this.pricing,
    this.isRecalculating = false,
    this.errorMessage,
  });

  bool get isEmpty => lines.isEmpty;
  int get totalQty => lines.fold(0, (s, l) => s + l.qty);
  int get lineCount => lines.length;
  double get localSubtotal => lines.fold(0.0, (s, l) => s + l.lineTotal);
  double get grandTotal => pricing?.total ?? localSubtotal;

  CartState copyWith({
    String? merchantId,
    String? merchantName,
    List<CartLine>? lines,
    CartData? pricing,
    bool? isRecalculating,
    String? errorMessage,
    bool clearError = false,
    bool clearPricing = false,
  }) {
    return CartState(
      merchantId: merchantId ?? this.merchantId,
      merchantName: merchantName ?? this.merchantName,
      lines: lines ?? this.lines,
      pricing: clearPricing ? null : (pricing ?? this.pricing),
      isRecalculating: isRecalculating ?? this.isRecalculating,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  int qtyForKey(String key) {
    for (final l in lines) {
      if (l.key == key) return l.qty;
    }
    return 0;
  }

  /// Total qty of a product across all its variant/modifier lines.
  int qtyForProduct(String productId) =>
      lines.where((l) => l.productId == productId).fold(0, (s, l) => s + l.qty);
}

class CartNotifier extends StateNotifier<CartState> {
  final AppRepository _repository;
  final Ref _ref;

  DestinationAddress? _address;
  String? _timezone;

  CartNotifier(this._repository, this._ref) : super(const CartState());

  DestinationAddress? get _pickup =>
      _ref.read(homeViewModelProvider).pickupAddress;

  /// Add a line (or bump its qty). Switching merchant replaces the cart.
  void addLine({
    required String merchantId,
    required String merchantName,
    required CartLine line,
    DestinationAddress? address,
    String? timezone,
  }) {
    if (address != null) _address = address;
    if (timezone != null) _timezone = timezone;

    final differentMerchant =
        state.merchantId != null && state.merchantId != merchantId;

    if (differentMerchant || state.isEmpty) {
      state = CartState(
        merchantId: merchantId,
        merchantName: merchantName,
        lines: [line],
      );
    } else {
      final lines = [...state.lines];
      final idx = lines.indexWhere((l) => l.key == line.key);
      if (idx >= 0) {
        lines[idx] = lines[idx].copyWith(qty: lines[idx].qty + line.qty);
      } else {
        lines.add(line);
      }
      state = state.copyWith(
        merchantId: merchantId,
        merchantName: merchantName,
        lines: lines,
      );
    }
    _recalculate();
  }

  void increment(String key) {
    final lines = [...state.lines];
    final idx = lines.indexWhere((l) => l.key == key);
    if (idx < 0) return;
    final l = lines[idx];
    if (l.maxQty != null && l.qty >= l.maxQty!) return;
    lines[idx] = l.copyWith(qty: l.qty + 1);
    state = state.copyWith(lines: lines);
    _recalculate();
  }

  void decrement(String key) {
    final lines = [...state.lines];
    final idx = lines.indexWhere((l) => l.key == key);
    if (idx < 0) return;
    final l = lines[idx];
    if (l.qty <= 1) {
      lines.removeAt(idx);
    } else {
      lines[idx] = l.copyWith(qty: l.qty - 1);
    }
    _updateLines(lines);
  }

  void removeLine(String key) {
    _updateLines(state.lines.where((l) => l.key != key).toList());
  }

  void clear() {
    state = const CartState();
  }

  void _updateLines(List<CartLine> lines) {
    if (lines.isEmpty) {
      state = const CartState();
      return;
    }
    state = state.copyWith(lines: lines);
    _recalculate();
  }

  Future<void> _recalculate() async {
    if (state.isEmpty || state.merchantId == null) {
      state = state.copyWith(clearPricing: true);
      return;
    }
    final address = _address ?? _pickup;
    if (address == null) return;

    state = state.copyWith(isRecalculating: true, clearError: true);
    final response = await _repository.getDeliveryCartSummary(
      CartSummaryRequest(
        merchantId: state.merchantId!,
        products: state.lines.map((l) => l.toParam()).toList(),
        destinationAddress: address,
        timezone: _timezone,
      ),
    );
    switch (response) {
      case Success<CartSummaryResponse>():
        state = state.copyWith(
            isRecalculating: false, pricing: response.data?.data);
      case Error<CartSummaryResponse>():
        state = state.copyWith(
            isRecalculating: false, errorMessage: response.message);
      case Loading():
        break;
    }
  }

  /// Place the order (cash by default). Returns the created order id (or null on
  /// success without an id); throws nothing — check [CartState.errorMessage].
  Future<PlaceOrderOutcome> placeOrder({
    int paymentMode = 1, // cash
    String customerNote = '',
    double tipPrice = 0,
    String promoCode = '',
  }) async {
    final address = _address ?? _pickup;
    if (state.merchantId == null || address == null || state.isEmpty) {
      return const PlaceOrderOutcome(success: false, message: 'Cart is empty');
    }
    final response = await _repository.placeDeliveryOrder(
      CreateOrderRequest(
        merchantId: state.merchantId!,
        products: state.lines.map((l) => l.toParam()).toList(),
        destinationAddress: address,
        paymentMode: paymentMode,
        customerNote: customerNote,
        tipPrice: tipPrice,
        promoCode: promoCode,
      ),
    );
    switch (response) {
      case Success<PlaceOrderResponse>():
        final id = response.bookingId ?? response.data?.orderId;
        clear();
        return PlaceOrderOutcome(success: true, orderId: id);
      case Error<PlaceOrderResponse>():
        return PlaceOrderOutcome(success: false, message: response.message);
      case Loading():
        return const PlaceOrderOutcome(success: false);
    }
  }
}

class PlaceOrderOutcome {
  final bool success;
  final String? orderId;
  final String? message;
  const PlaceOrderOutcome({required this.success, this.orderId, this.message});
}

/// Global (non-autoDispose) so the cart survives navigation between screens.
final cartProvider =
    StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier(ref.watch(appRepositoryProvider), ref);
});
