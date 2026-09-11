import '../get_vehicle_types_request.dart';

/// One product line sent to the cart-summary / place-order endpoints.
/// Identity = productId + variantId + modifiers.
class CartProductParam {
  final String productId;
  final String variantId;
  final int qty;
  final List<CartModifierParam> modifiers;
  final double? price; // included for cart-summary; omitted for create-order

  const CartProductParam({
    required this.productId,
    required this.variantId,
    required this.qty,
    this.modifiers = const [],
    this.price,
  });

  Map<String, dynamic> toJson({bool includePrice = true}) => {
        'productId': productId,
        'variantId': variantId,
        'qty': qty,
        'modifiers': modifiers.map((m) => m.toJson()).toList(),
        if (includePrice && price != null) 'price': price,
      };
}

class CartModifierParam {
  final String id;
  final List<CartModifierOptionParam> options;

  const CartModifierParam({required this.id, this.options = const []});

  Map<String, dynamic> toJson() => {
        'id': id,
        'options': options.map((o) => o.toJson()).toList(),
      };
}

class CartModifierOptionParam {
  final String id;
  final String name;
  final double price;
  final int qty;

  const CartModifierOptionParam({
    required this.id,
    required this.name,
    required this.price,
    required this.qty,
  });

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'price': price, 'qty': qty};
}

/// POST booking/delivery/cart — recalculate availability + price for the whole
/// local cart. Sent on every add / update / remove.
class CartSummaryRequest {
  final String merchantId;
  final List<CartProductParam> products;
  final DestinationAddress destinationAddress;
  final String promoCode;
  final double? tipPrice;
  final double? bookingTime; // epoch millis
  final int bookingType; // 5 = delivery
  final int? paymentMode;
  final String? timezone;

  const CartSummaryRequest({
    required this.merchantId,
    required this.products,
    required this.destinationAddress,
    this.promoCode = '',
    this.tipPrice,
    this.bookingTime,
    this.bookingType = 5,
    this.paymentMode,
    this.timezone,
  });

  Map<String, dynamic> toJson() => {
        'merchantId': merchantId,
        'products': products.map((p) => p.toJson()).toList(),
        'destinationAddress': destinationAddress.toJson(),
        'promoCode': promoCode,
        if (tipPrice != null) 'tipPrice': tipPrice,
        if (bookingTime != null) 'bookingTime': bookingTime,
        'bookingType': bookingType,
        if (paymentMode != null) 'paymentMode': paymentMode,
        if (timezone != null) 'timezone': timezone,
      };
}

/// POST booking/delivery — place the order.
class CreateOrderRequest {
  final String merchantId;
  final List<CartProductParam> products;
  final DestinationAddress destinationAddress;
  final String customerNote;
  final int paymentMode;
  final double tipPrice;
  final String promoCode;
  final int businessType; // 3
  final int bookingType; // 5 = delivery
  final double? bookingTime;
  final bool isBookForOther;

  const CreateOrderRequest({
    required this.merchantId,
    required this.products,
    required this.destinationAddress,
    this.customerNote = '',
    required this.paymentMode,
    this.tipPrice = 0,
    this.promoCode = '',
    this.businessType = 3,
    this.bookingType = 5,
    this.bookingTime,
    this.isBookForOther = false,
  });

  Map<String, dynamic> toJson() => {
        'merchantId': merchantId,
        // create-order omits the per-line price.
        'products':
            products.map((p) => p.toJson(includePrice: false)).toList(),
        'destinationAddress': destinationAddress.toJson(),
        'customerNote': customerNote,
        'paymentMode': paymentMode,
        'tipPrice': tipPrice,
        'promoCode': promoCode,
        'businessType': businessType,
        'bookingType': bookingType,
        if (bookingTime != null) 'bookingTime': bookingTime,
        'isBookForOther': isBookForOther,
      };
}
