// Response models for the store-delivery cart-summary (`booking/delivery/cart`)
// and place-order (`booking/delivery`) calls, mirroring native QDCartResponseModel
// and PaymentIntentResponse.

double? _toD(dynamic v) => (v as num?)?.toDouble();
int? _toI(dynamic v) => (v as num?)?.toInt();

// ── Cart summary (recalculate) ────────────────────────────────────

class CartSummaryResponse {
  final CartData? data;

  const CartSummaryResponse({this.data});

  factory CartSummaryResponse.fromJson(Map<String, dynamic> data) =>
      CartSummaryResponse(data: CartData.fromJson(data));
}

class CartData {
  final List<CartProduct> availableProducts;
  final List<CartProduct> unavailableProducts;
  final List<CartCharge> charges;
  final List<CartCharge> taxPrices;
  final double? total;
  final String? vehiclePriceId;
  final int? totalTimeToDeliver; // seconds
  final bool isInsideDeliveryZone;

  const CartData({
    this.availableProducts = const [],
    this.unavailableProducts = const [],
    this.charges = const [],
    this.taxPrices = const [],
    this.total,
    this.vehiclePriceId,
    this.totalTimeToDeliver,
    this.isInsideDeliveryZone = true,
  });

  /// All bill rows (charges + taxes) in display order.
  List<CartCharge> get billRows => [...charges, ...taxPrices];

  factory CartData.fromJson(Map<String, dynamic> json) {
    List<CartProduct> products(String key) =>
        ((json[key] as List<dynamic>?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(CartProduct.fromJson)
            .toList();
    List<CartCharge> charges(String key) =>
        ((json[key] as List<dynamic>?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(CartCharge.fromJson)
            .toList();
    return CartData(
      availableProducts: products('availableProducts'),
      unavailableProducts: products('unavailableProducts'),
      charges: charges('charges'),
      taxPrices: charges('taxPrices'),
      total: _toD(json['total']),
      vehiclePriceId: json['vehiclePriceId'] as String?,
      totalTimeToDeliver: _toI(json['totalTimeToDeliver']),
      isInsideDeliveryZone:
          (json['isLocationInsideDeliveryZone'] as bool?) ?? true,
    );
  }
}

/// A cart item as returned by the server (used for the unavailable list + to
/// reconcile prices).
class CartProduct {
  final String? productId;
  final String? variantId;
  final String? name;
  final String? imageUrl;
  final double? price;
  final double? discountedPrice;
  final int? qty;
  final int? maxQtyAddInCart;

  const CartProduct({
    this.productId,
    this.variantId,
    this.name,
    this.imageUrl,
    this.price,
    this.discountedPrice,
    this.qty,
    this.maxQtyAddInCart,
  });

  factory CartProduct.fromJson(Map<String, dynamic> json) => CartProduct(
        productId: json['productId'] as String?,
        variantId: json['variantId'] as String?,
        name: json['name'] as String?,
        imageUrl: json['imageUrl'] as String?,
        price: _toD(json['price']),
        discountedPrice: _toD(json['discountedPrice']),
        qty: _toI(json['qty']),
        maxQtyAddInCart: _toI(json['maxQtyAddInCart']),
      );
}

/// One bill line: title + amount (with optional discounted amount).
class CartCharge {
  final String? title;
  final double? price;
  final double? discountedPrice;

  const CartCharge({this.title, this.price, this.discountedPrice});

  /// The amount actually charged for this row.
  double get amount => discountedPrice ?? price ?? 0;

  bool get isFree => amount == 0;

  factory CartCharge.fromJson(Map<String, dynamic> json) => CartCharge(
        title: json['title'] as String?,
        price: _toD(json['price']),
        discountedPrice: _toD(json['discountedPrice']),
      );
}

// ── Place order ───────────────────────────────────────────────────

class PlaceOrderResponse {
  final String? message;
  final String? orderId; // headerId
  final String? event;
  final String? errorCode;

  const PlaceOrderResponse({this.message, this.orderId, this.event, this.errorCode});

  factory PlaceOrderResponse.fromJson(Map<String, dynamic> json) {
    // The API client unwraps `data`; the created order id lives at the envelope
    // level as `headerId`, so also check the raw map defensively.
    return PlaceOrderResponse(
      message: json['message'] as String?,
      orderId: (json['headerId'] ?? json['orderId'] ?? json['_id']) as String?,
      event: json['event'] as String?,
      errorCode: json['errorCode'] as String?,
    );
  }
}
