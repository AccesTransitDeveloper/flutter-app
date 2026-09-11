import '../get_vehicle_types_request.dart';

/// Request bodies for the store-delivery business, mirroring the native
/// the native user app SDelivery module.

/// POST booking/delivery/check_business
/// Validates delivery availability at the address and returns the city setting
/// (cityId, timezone) used by the merchant list call.
class CheckDeliveryBusinessRequest {
  final DestinationAddress destinationAddress;
  final String? mainCategoryId;
  final String? merchantId;

  const CheckDeliveryBusinessRequest({
    required this.destinationAddress,
    this.mainCategoryId,
    this.merchantId,
  });

  Map<String, dynamic> toJson() => {
        'destinationAddress': destinationAddress.toJson(),
        if (mainCategoryId != null) 'mainCategoryId': mainCategoryId,
        if (merchantId != null) 'merchantId': merchantId,
      };
}

/// GET main_category
/// Returns the delivery main categories for the city/business.
///
/// NOTE: This is a GET with query-string params (not a POST body), mirroring
/// the native app. For store delivery only businessType is sent (bookingType is
/// nil — it's only sent for the `service` business).
class DeliveryCategoryRequest {
  final String? countryId;
  final String? cityId;
  final int businessType; // delivery = 3
  final int? bookingType; // null for delivery; only set for service business

  const DeliveryCategoryRequest({
    this.countryId,
    this.cityId,
    this.businessType = 3,
    this.bookingType,
  });

  Map<String, String> toQueryParameters() => {
        if (countryId != null) 'countryId': countryId!,
        if (cityId != null) 'cityId': cityId!,
        'businessType': businessType.toString(),
        if (bookingType != null) 'bookingType': bookingType!.toString(),
      };
}

/// POST dynamic_group/get
/// Returns the server-configured dynamic groups (curated rails + all-merchant
/// list) for a main category — the native "dynamic group" home design.
class DynamicGroupRequest {
  final DestinationAddress destinationAddress;
  final String mainCategoryId;
  final String cityId;
  final String countryId;
  final String timezone;
  final int page;
  final int limit;
  final int businessType; // delivery = 3
  final String? searchText;

  const DynamicGroupRequest({
    required this.destinationAddress,
    required this.mainCategoryId,
    required this.cityId,
    required this.countryId,
    required this.timezone,
    this.page = 1,
    this.limit = 5,
    this.businessType = 3,
    this.searchText,
  });

  Map<String, dynamic> toJson() => {
        'destinationAddress': destinationAddress.toJson(),
        'mainCategoryId': mainCategoryId,
        'cityId': cityId,
        'countryId': countryId,
        'timezone': timezone,
        'page': page,
        'limit': limit,
        'businessType': businessType,
        if (searchText != null && searchText!.isNotEmpty) 'searchText': searchText,
      };
}

/// GET group
/// Returns the server-configured product sections for a MERCHANT (the store
/// menu / product-listing screen). Mirrors native `GET api/group` with
/// groupFor=HOME. GET with query-string params.
class MerchantMenuRequest {
  final String merchantId;
  final String? mainCategoryId;
  final String groupFor; // HOME
  final int page;
  final int limit;
  final int businessType; // delivery = 3

  const MerchantMenuRequest({
    required this.merchantId,
    this.mainCategoryId,
    this.groupFor = 'HOME',
    this.page = 1,
    this.limit = 20,
    this.businessType = 3,
  });

  Map<String, String> toQueryParameters() => {
        'groupFor': groupFor,
        'merchantId': merchantId,
        if (mainCategoryId != null && mainCategoryId!.isNotEmpty)
          'mainCategoryId': mainCategoryId!,
        'page': page.toString(),
        'limit': limit.toString(),
        'businessType': businessType.toString(),
      };
}

/// GET product/list
/// Products belonging to one category of a merchant (the SECTIONED menu).
class CategoryProductsRequest {
  final String merchantId;
  final String categoryId;
  final int businessType; // delivery = 3
  final int page;
  final int limit;
  final String? timezone;

  const CategoryProductsRequest({
    required this.merchantId,
    required this.categoryId,
    this.businessType = 3,
    this.page = 1,
    this.limit = 30,
    this.timezone,
  });

  Map<String, String> toQueryParameters() => {
        'merchantId': merchantId,
        'categoryId': categoryId,
        'businessType': businessType.toString(),
        'page': page.toString(),
        'limit': limit.toString(),
        if (timezone != null && timezone!.isNotEmpty) 'timezone': timezone!,
      };
}

/// GET product/{productId}
/// Full product detail (variants + modifiers) for the customize sheet.
class ProductDetailRequest {
  final String merchantId;
  final int businessType; // delivery = 3
  final bool isForCreateOrder;
  final String? timezone;

  const ProductDetailRequest({
    required this.merchantId,
    this.businessType = 3,
    this.isForCreateOrder = true,
    this.timezone,
  });

  Map<String, String> toQueryParameters() => {
        'merchantId': merchantId,
        'businessType': businessType.toString(),
        'isForCreateOrder': isForCreateOrder.toString(),
        if (timezone != null && timezone!.isNotEmpty) 'timezone': timezone!,
      };
}

/// POST booking/delivery/merchants
/// Returns the list of stores/restaurants for a main category.
class DeliveryMerchantListRequest {
  final DestinationAddress destinationAddress;
  final String mainCategoryId;
  final String cityId;
  final String timezone;
  final String? searchText;
  final int page;
  final int limit;
  final int bookingType; // store delivery = 5
  final double? bookingTime;

  const DeliveryMerchantListRequest({
    required this.destinationAddress,
    required this.mainCategoryId,
    required this.cityId,
    required this.timezone,
    this.searchText,
    this.page = 1,
    this.limit = 20,
    this.bookingType = 5,
    this.bookingTime,
  });

  Map<String, dynamic> toJson() => {
        'destinationAddress': destinationAddress.toJson(),
        'mainCategoryId': mainCategoryId,
        'cityId': cityId,
        'timezone': timezone,
        if (searchText != null && searchText!.isNotEmpty) 'searchText': searchText,
        'page': page,
        'limit': limit,
        'bookingType': bookingType,
        if (bookingTime != null) 'bookingTime': bookingTime,
      };
}
