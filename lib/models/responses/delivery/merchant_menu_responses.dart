import 'delivery_config.dart';

// Response models for the store-delivery MERCHANT MENU (product listing) screen,
// mirroring the the native user app `GET api/group` (groupFor=HOME) response. The
// products arrive as each group's `childs` array (same shape as the home feed,
// but the childs are PRODUCTS carrying price / foodType / variants / modifiers).

double? _toD(dynamic v) => (v as num?)?.toDouble();
int? _toI(dynamic v) => (v as num?)?.toInt();
List<String> _toSList(dynamic v) =>
    (v as List<dynamic>?)?.whereType<String>().toList() ?? const [];

// ── Menu response (groups of products) ────────────────────────────

class MenuResponse {
  final int dataCount;
  final List<MenuGroup> groups;

  const MenuResponse({this.dataCount = 0, this.groups = const []});

  factory MenuResponse.fromJson(Map<String, dynamic> data) {
    final list = (data['groups'] as List<dynamic>?) ?? const [];
    final groups = <MenuGroup>[];
    for (final item in list) {
      if (item is! Map<String, dynamic>) continue;
      // Never let one malformed section drop the whole menu.
      try {
        groups.add(MenuGroup.fromJson(item));
      } catch (_) {}
    }
    return MenuResponse(
      dataCount: _toI(data['dataCount']) ?? 0,
      groups: groups,
    );
  }
}

/// One server-configured menu section (e.g. "Recommended", "Starters"). Layout
/// (columns, scroll, colors) comes from the backend view-config; the items are
/// products.
class MenuGroup {
  final String? id;
  final bool isActive;
  final String? childType;
  final QMainViewConfig? mainView;
  final QHeaderFooter? header;
  final QHeaderFooter? footer;
  final QGridConfig? grid;
  final QGridChildConfig? child;
  final List<DeliveryProduct> products;

  const MenuGroup({
    this.id,
    this.isActive = true,
    this.childType,
    this.mainView,
    this.header,
    this.footer,
    this.grid,
    this.child,
    this.products = const [],
  });

  String? get title => header?.title?.text;
  String? get subtitle => header?.description?.text;

  factory MenuGroup.fromJson(Map<String, dynamic> json) {
    final headerFooter = json['headerFooterViewConfig'] as Map<String, dynamic>?;
    final childs = (json['childs'] as List<dynamic>?) ?? const [];
    return MenuGroup(
      id: (json['_id'] ?? json['id']) as String?,
      isActive: (json['isActive'] as bool?) ?? true,
      childType: json['childType'] as String?,
      mainView: QMainViewConfig.fromJson(
          json['mainViewConfig'] as Map<String, dynamic>?),
      header: QHeaderFooter.fromJson(
          headerFooter?['header'] as Map<String, dynamic>?),
      footer: QHeaderFooter.fromJson(
          headerFooter?['footer'] as Map<String, dynamic>?),
      grid: QGridConfig.fromJson(json['gridViewConfig'] as Map<String, dynamic>?),
      child: QGridChildConfig.fromJson(
          json['gridChildViewConfig'] as Map<String, dynamic>?),
      products: childs
          .whereType<Map<String, dynamic>>()
          .map(DeliveryProduct.fromJson)
          .toList(),
    );
  }
}

// ── Category product list ─────────────────────────────────────────

class ProductListResponse {
  final List<DeliveryProduct> products;

  const ProductListResponse({this.products = const []});

  factory ProductListResponse.fromJson(Map<String, dynamic> data) {
    final list = ((data['products'] as List<dynamic>?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(DeliveryProduct.fromJson)
        .toList();
    return ProductListResponse(products: list);
  }
}

// ── Product detail ────────────────────────────────────────────────

class ProductDetailResponse {
  final DeliveryProduct? product;

  const ProductDetailResponse({this.product});

  factory ProductDetailResponse.fromJson(Map<String, dynamic> data) {
    final productJson = data['product'] as Map<String, dynamic>?;
    return ProductDetailResponse(
      product:
          productJson != null ? DeliveryProduct.fromJson(productJson) : null,
    );
  }
}

// ── Product ───────────────────────────────────────────────────────

class DeliveryProduct {
  final String? id;
  final String? name;
  final String? description;
  final String? imageUrl; // assets[0].url
  final String? foodType; // VEG / NON_VEG / EGG / VEGAN
  final String? status; // ACTIVE / INACTIVE / OUT_OF_STOCK
  final double? price; // default variant price
  final double? discountedPrice; // default variant discounted price
  final double? rate;
  final int? rateCount;
  final List<ProductVariant> variants;
  final List<ProductModifier> modifiers;
  final List<String> tagIds;

  const DeliveryProduct({
    this.id,
    this.name,
    this.description,
    this.imageUrl,
    this.foodType,
    this.status,
    this.price,
    this.discountedPrice,
    this.rate,
    this.rateCount,
    this.variants = const [],
    this.modifiers = const [],
    this.tagIds = const [],
  });

  bool get isOutOfStock => (status ?? '').toUpperCase() == 'OUT_OF_STOCK';
  bool get isVeg => (foodType ?? '').toUpperCase() == 'VEG' ||
      (foodType ?? '').toUpperCase() == 'VEGAN';
  bool get isEgg => (foodType ?? '').toUpperCase() == 'EGG';
  bool get isNonVeg => (foodType ?? '').toUpperCase() == 'NON_VEG';
  bool get hasFoodType => (foodType ?? '').isNotEmpty;

  /// More than one variant → the user must choose (e.g. size/unit options).
  bool get hasVariants => variants.length > 1;
  bool get hasModifiers => modifiers.isNotEmpty;

  bool get hasDiscount =>
      discountedPrice != null &&
      price != null &&
      discountedPrice! > 0 &&
      discountedPrice! < price!;

  /// The price the user actually pays for the default variant.
  double? get effectivePrice => hasDiscount ? discountedPrice : price;

  int? get discountPercent => hasDiscount
      ? (((price! - discountedPrice!) / price!) * 100).round()
      : null;

  /// The variant used as the default when adding without opening detail.
  ProductVariant? get defaultVariant {
    for (final v in variants) {
      if (v.isDefaultSelected) return v;
    }
    return variants.isNotEmpty ? variants.first : null;
  }

  factory DeliveryProduct.fromJson(Map<String, dynamic> json) {
    final variants = ((json['variants'] as List<dynamic>?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(ProductVariant.fromJson)
        .toList();
    final modifiers = ((json['modifiers'] as List<dynamic>?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(ProductModifier.fromJson)
        .toList();

    ProductVariant? def;
    for (final v in variants) {
      if (v.isDefaultSelected) {
        def = v;
        break;
      }
    }
    def ??= variants.isNotEmpty ? variants.first : null;

    return DeliveryProduct(
      id: (json['_id'] ?? json['id']) as String?,
      name: json['name'] as String?,
      description: json['description'] as String?,
      imageUrl: _firstAssetUrl(json) ?? json['imageUrl'] as String?,
      foodType: json['foodType'] as String?,
      status: json['status'] as String?,
      price: def?.price,
      discountedPrice: def?.discountedPrice,
      rate: _toD(json['rate']),
      rateCount: _toI(json['rateCount']),
      variants: variants,
      modifiers: modifiers,
      tagIds: _toSList(json['tagIds']),
    );
  }

  static String? _firstAssetUrl(Map<String, dynamic> json) {
    final assets = json['assets'] as List<dynamic>?;
    if (assets == null || assets.isEmpty) return null;
    final first = assets.first;
    return first is Map<String, dynamic> ? first['url'] as String? : null;
  }
}

// ── Variant (size / unit option) ──────────────────────────────────

class ProductVariant {
  final String? id;
  final String? name;
  final double? price;
  final double? discountedPrice;
  final String? status;
  final bool isDefaultSelected;
  final int? maxQtyAddInCart;
  final String? unitLabel; // e.g. "500 g", "Large"

  const ProductVariant({
    this.id,
    this.name,
    this.price,
    this.discountedPrice,
    this.status,
    this.isDefaultSelected = false,
    this.maxQtyAddInCart,
    this.unitLabel,
  });

  bool get hasDiscount =>
      discountedPrice != null &&
      price != null &&
      discountedPrice! > 0 &&
      discountedPrice! < price!;

  double? get effectivePrice => hasDiscount ? discountedPrice : price;

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    final unit = json['unit'] as Map<String, dynamic>?;
    return ProductVariant(
      id: (json['_id'] ?? json['id']) as String?,
      name: json['name'] as String?,
      price: _toD(json['price']),
      discountedPrice: _toD(json['discountedPrice']),
      status: json['status'] as String?,
      isDefaultSelected: (json['isDefaultSelected'] as bool?) ?? false,
      maxQtyAddInCart: _toI(json['maxQtyAddInCart']),
      unitLabel: _unitLabel(unit),
    );
  }

  static String? _unitLabel(Map<String, dynamic>? unit) {
    if (unit == null) return null;
    final desc = unit['unitDescription'] as String?;
    if (desc != null && desc.isNotEmpty) return desc;
    final value = unit['unitValue'];
    final type = unit['unitType'] as String?;
    if (value != null && type != null) return '$value $type';
    return null;
  }
}

// ── Modifier (add-on group) + option ──────────────────────────────

class ProductModifier {
  final String? id;
  final String? name;
  final bool isAllowAddQuantity;
  final int minRange;
  final int maxRange;
  final List<ProductModifierOption> options;

  const ProductModifier({
    this.id,
    this.name,
    this.isAllowAddQuantity = false,
    this.minRange = 0,
    this.maxRange = 0,
    this.options = const [],
  });

  bool get isRequired => minRange > 0;
  bool get isSingleChoice => maxRange == 1;

  factory ProductModifier.fromJson(Map<String, dynamic> json) {
    return ProductModifier(
      id: (json['_id'] ?? json['id']) as String?,
      name: json['name'] as String?,
      isAllowAddQuantity: (json['isAllowAddQuantity'] as bool?) ?? false,
      minRange: _toI(json['minRange']) ?? 0,
      maxRange: _toI(json['maxRange']) ?? 0,
      options: ((json['options'] as List<dynamic>?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ProductModifierOption.fromJson)
          .toList(),
    );
  }
}

class ProductModifierOption {
  final String? id;
  final String? name;
  final String? image;
  final double? price;
  final bool isDefaultSelected;

  const ProductModifierOption({
    this.id,
    this.name,
    this.image,
    this.price,
    this.isDefaultSelected = false,
  });

  factory ProductModifierOption.fromJson(Map<String, dynamic> json) {
    return ProductModifierOption(
      id: (json['_id'] ?? json['id']) as String?,
      name: json['name'] as String?,
      image: json['image'] as String?,
      price: _toD(json['price']),
      isDefaultSelected: (json['isDefaultSelected'] as bool?) ?? false,
    );
  }
}
