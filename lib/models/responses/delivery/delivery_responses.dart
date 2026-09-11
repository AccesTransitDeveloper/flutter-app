import 'delivery_config.dart';

// Response models for the store-delivery business, mirroring the native
// the native user app SDelivery module. Hand-written fromJson (no build_runner needed).
//
// NOTE: The API client's BaseResponse already unwraps the top-level `data`
// object, so each fromJson below receives the INNER data object directly
// (not the full `{ "data": { ... } }` envelope).

// ── check_business ────────────────────────────────────────────────

class CheckDeliveryBusinessResponse {
  final DeliveryCitySetting? citySetting;
  final String? countryId;

  const CheckDeliveryBusinessResponse({this.citySetting, this.countryId});

  factory CheckDeliveryBusinessResponse.fromJson(Map<String, dynamic> data) {
    final citySettingJson = data['citySetting'] as Map<String, dynamic>?;
    final countrySettingJson = data['countrySetting'] as Map<String, dynamic>?;
    return CheckDeliveryBusinessResponse(
      citySetting: citySettingJson != null
          ? DeliveryCitySetting.fromJson(citySettingJson)
          : null,
      countryId: (countrySettingJson?['_id'] ?? countrySettingJson?['countryId'])
          as String?,
    );
  }
}

class DeliveryCitySetting {
  final String? cityId;
  final String? timezone;

  const DeliveryCitySetting({this.cityId, this.timezone});

  factory DeliveryCitySetting.fromJson(Map<String, dynamic> json) =>
      DeliveryCitySetting(
        cityId: json['cityId'] as String?,
        timezone: json['timezone'] as String?,
      );
}

// ── main_category ─────────────────────────────────────────────────

class DeliveryCategoryResponse {
  final List<DeliveryCategory> mainCategories;

  const DeliveryCategoryResponse({this.mainCategories = const []});

  factory DeliveryCategoryResponse.fromJson(Map<String, dynamic> data) {
    final list = (data['mainCategories'] as List<dynamic>?) ?? const [];
    return DeliveryCategoryResponse(
      mainCategories: list
          .whereType<Map<String, dynamic>>()
          .map(DeliveryCategory.fromJson)
          .toList(),
    );
  }
}

class DeliveryCategory {
  final String? id;
  final String? name;

  /// Server-driven display config (mirrors native `viewConfig`):
  /// [imageUrl] = viewConfig.item.image, [textColor] = viewConfig.item.color,
  /// [bgColor] = viewConfig.bgColor. Colors are hex strings (e.g. "#FF5722").
  final String? imageUrl;
  final String? textColor;
  final String? bgColor;

  final List<String> tagIds;

  const DeliveryCategory({
    this.id,
    this.name,
    this.imageUrl,
    this.textColor,
    this.bgColor,
    this.tagIds = const [],
  });

  factory DeliveryCategory.fromJson(Map<String, dynamic> json) {
    final viewConfig = json['viewConfig'] as Map<String, dynamic>?;
    final item = viewConfig?['item'] as Map<String, dynamic>?;
    return DeliveryCategory(
      id: (json['_id'] ?? json['id']) as String?,
      name: json['name'] as String?,
      imageUrl: (item?['image'] ?? json['imageUrl']) as String?,
      textColor: item?['color'] as String?,
      bgColor: viewConfig?['bgColor'] as String?,
      tagIds: ((json['tagIds'] as List<dynamic>?) ?? const [])
          .whereType<String>()
          .toList(),
    );
  }
}

// ── dynamic groups ────────────────────────────────────────────────

class GroupListResponse {
  final int dataCount;
  final List<DeliveryGroup> groups;

  const GroupListResponse({this.dataCount = 0, this.groups = const []});

  factory GroupListResponse.fromJson(Map<String, dynamic> data) {
    final list = (data['groups'] as List<dynamic>?) ?? const [];
    final groups = <DeliveryGroup>[];
    for (final item in list) {
      if (item is! Map<String, dynamic>) continue;
      // Never let one malformed group drop the whole feed.
      try {
        groups.add(DeliveryGroup.fromJson(item));
      } catch (_) {}
    }
    return GroupListResponse(
      dataCount: (data['dataCount'] as num?)?.toInt() ?? 0,
      groups: groups,
    );
  }
}

/// One server-configured group: a section whose entire layout — header text,
/// grid columns, scroll type, cell image shape, colors, padding — is driven by
/// the backend view-config (native CategoryGridMetaDataModel).
class DeliveryGroup {
  final String? id;
  final bool isActive;
  final String? childType; // ALL_MERCHANT, TOP_RATED_MERCHANT, CATEGORY, ...
  final QMainViewConfig? mainView;
  final QHeaderFooter? header;
  final QHeaderFooter? footer;
  final QGridConfig? grid;
  final QGridChildConfig? child;
  final List<Merchant> products; // childs (stores)

  const DeliveryGroup({
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

  bool get isAllMerchant => childType == 'ALL_MERCHANT';

  /// A section of restaurants (not the all-merchant list, not a promo group).
  bool get isMerchantSection =>
      (childType ?? '').contains('MERCHANT') &&
      !isAllMerchant &&
      products.isNotEmpty;

  String? get title => header?.title?.text;
  String? get subtitle => header?.description?.text;

  factory DeliveryGroup.fromJson(Map<String, dynamic> json) {
    final headerFooter =
        json['headerFooterViewConfig'] as Map<String, dynamic>?;
    final childs = (json['childs'] as List<dynamic>?) ?? const [];

    return DeliveryGroup(
      id: (json['_id'] ?? json['id']) as String?,
      isActive: (json['isActive'] as bool?) ?? true,
      childType: json['childType'] as String?,
      mainView:
          QMainViewConfig.fromJson(json['mainViewConfig'] as Map<String, dynamic>?),
      header:
          QHeaderFooter.fromJson(headerFooter?['header'] as Map<String, dynamic>?),
      footer:
          QHeaderFooter.fromJson(headerFooter?['footer'] as Map<String, dynamic>?),
      grid: QGridConfig.fromJson(json['gridViewConfig'] as Map<String, dynamic>?),
      child: QGridChildConfig.fromJson(
          json['gridChildViewConfig'] as Map<String, dynamic>?),
      products: childs
          .whereType<Map<String, dynamic>>()
          .map(Merchant.fromJson)
          .toList(),
    );
  }
}

// ── merchants ─────────────────────────────────────────────────────

class MerchantListResponse {
  final int dataCount;
  final List<Merchant> merchants;

  const MerchantListResponse({this.dataCount = 0, this.merchants = const []});

  factory MerchantListResponse.fromJson(Map<String, dynamic> data) {
    final list = (data['merchants'] as List<dynamic>?) ?? const [];
    return MerchantListResponse(
      dataCount: (data['dataCount'] as num?)?.toInt() ?? 0,
      merchants: list
          .whereType<Map<String, dynamic>>()
          .map(Merchant.fromJson)
          .toList(),
    );
  }
}

class Merchant {
  final String? id;
  final String? name;
  final String? address;
  final String? imageUrl;
  final double? customerRate;
  final int? customerRateCount;
  final double? distance;
  final bool? isOpen;
  final String? description;
  final double? minPreparationTime;
  final double? maxPreparationTime;
  final int? priceRating;

  const Merchant({
    this.id,
    this.name,
    this.address,
    this.imageUrl,
    this.customerRate,
    this.customerRateCount,
    this.distance,
    this.isOpen,
    this.description,
    this.minPreparationTime,
    this.maxPreparationTime,
    this.priceRating,
  });

  factory Merchant.fromJson(Map<String, dynamic> json) => Merchant(
        id: (json['_id'] ?? json['id']) as String?,
        name: json['name'] as String?,
        address: json['address'] as String?,
        // Merchants carry `imageUrl`; dynamic-group child items instead carry the
        // image in `assets[0].url`, so fall back to that.
        imageUrl: (json['imageUrl'] ?? _firstAssetUrl(json)) as String?,
        customerRate: (json['customerRate'] as num?)?.toDouble(),
        customerRateCount:
            ((json['customerRateCount'] ?? json['rateCount']) as num?)?.toInt(),
        distance: (json['distance'] as num?)?.toDouble(),
        isOpen: json['isOpen'] as bool?,
        description: json['description'] as String?,
        minPreparationTime: (json['minPreparationTime'] as num?)?.toDouble(),
        maxPreparationTime: (json['maxPreparationTime'] as num?)?.toDouble(),
        priceRating: (json['priceRating'] as num?)?.toInt(),
      );

  /// First image url from a dynamic-group child item's `assets` array.
  static String? _firstAssetUrl(Map<String, dynamic> json) {
    final assets = json['assets'] as List<dynamic>?;
    if (assets == null || assets.isEmpty) return null;
    final first = assets.first;
    return first is Map<String, dynamic> ? first['url'] as String? : null;
  }
}
