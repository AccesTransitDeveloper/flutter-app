import '../../models/invoice.dart';
import '../../models/responses/booking/booking_detail_response.dart';
import '../../models/responses/booking/get_vehicle_type_response.dart';
import 'common_utils.dart';

/// Charge type enum for categorizing price data
enum ChargeType {
  charges,
  additionalPrices,
  accessibilityPrices,
  taxPrices,
}

/// Price type constants matching backend values
class PriceType {
  static const String bookingFee = 'bookingFee';
  static const String distancePrice = 'distancePrice';
  static const String timePrice = 'timePrice';
  static const String minimumFee = 'minimumFee';
  static const String waitingTimePrice = 'waitingTimePrice';
  static const String airportWaitingTimePrice = 'airportWaitingTimePrice';
  static const String stopWaitingTimePrice = 'stopWaitingTimePrice';
  static const String trafficTimePrice = 'trafficTimePrice';
  static const String surgePrice = 'surgePrice';
  static const String cancellationPrice = 'cancellationPrice';
  static const String promoBonus = 'promoBonus';
  static const String airportPrice = 'airportPrice';
  static const String zoneToZonePrice = 'zoneToZonePrice';
  static const String cityToCityPrice = 'cityToCityPrice';
  static const String bidPrice = 'bidPrice';
  static const String tipPrice = 'tipPrice';
  static const String cartPrice = 'cartPrice';
  static const String offerBonus = 'offerBonus';
  static const String deliveryPrice = 'deliveryPrice';
  static const String platformProfit = 'platformProfit';
  static const String extraCharge = 'extraCharge';
  static const String nowBookingCharge = 'nowBookingCharge';

  /// Get display title for price type
  static String getTitle(String value) {
    switch (value) {
      case bookingFee:
        return 'Booking Fee';
      case distancePrice:
        return 'Distance Price';
      case timePrice:
        return 'Time Price';
      case minimumFee:
        return 'Minimum Fee';
      case waitingTimePrice:
        return 'Waiting Time Price';
      case airportWaitingTimePrice:
        return 'Airport Waiting Time Price';
      case stopWaitingTimePrice:
        return 'Stop Waiting Time Price';
      case trafficTimePrice:
        return 'Traffic Time Price';
      case surgePrice:
        return 'Surge Price';
      case cancellationPrice:
        return 'Cancellation Price';
      case promoBonus:
        return 'Promo Bonus';
      case airportPrice:
        return 'Airport Price';
      case zoneToZonePrice:
        return 'Zone to Zone Price';
      case cityToCityPrice:
        return 'City to City Price';
      case bidPrice:
        return 'Bid Price';
      case tipPrice:
        return 'Tip Price';
      case cartPrice:
        return 'Item Total';
      case offerBonus:
        return 'Discounts and Offers';
      case deliveryPrice:
        return 'Delivery Charge';
      case platformProfit:
        return 'Platform Profit';
      case extraCharge:
        return 'Extra Charge';
      case nowBookingCharge:
        return 'Now Booking Charge';
      default:
        return value;
    }
  }
}

/// Distance unit constants
class DistanceUnit {
  static const int km = 1;
  static const int miles = 2;

  static String getUnit(int? distanceUnit) {
    switch (distanceUnit) {
      case miles:
        return 'miles';
      case km:
      default:
        return 'km';
    }
  }
}

/// Utility class for converting InvoiceDetail to list of Invoice items
class InvoiceUtil {
  final int currencyDirection;
  final String currencySign;
  final int decimalPointValue;
  final int? distanceUnit;

  InvoiceUtil({
    required this.currencyDirection,
    required this.currencySign,
    required this.decimalPointValue,
    this.distanceUnit,
  });

  /// Build invoice description list from rental PackageDetail
  /// Matches Kotlin setPackageDetails() logic
  List<Invoice> getPackageInvoiceList(PackageDetail? packageDetail) {
    if (packageDetail == null) return [];

    final packageInvoiceList = <Invoice>[];
    final distanceUnitStr = DistanceUnit.getUnit(distanceUnit);

    String? strMin;
    String? strDistance;
    String? strSlotMin;
    String? strSlotDistance;
    String? strTimePrice;
    String? strDistancePrice;
    String? strExtraMin;
    String? strExtraDistance;

    // Process timePrice
    final time = packageDetail.timePrice;
    if (time != null && time.isActive == true) {
      if (time.isApplySlotPrice == true &&
          time.slots != null &&
          time.slots!.isNotEmpty) {
        strSlotMin = _getSubStringSlots(
          priceData: time,
          isApplied: false,
          isDistance: false,
        );
      } else {
        // Base unit: "X min"
        if ((time.basePriceUnit ?? 0) > 0) {
          strMin =
              '${time.basePriceUnit!.toStringAsFixed(decimalPointValue)} min';
        }

        // Time charge: "Time Charge: $X"
        if ((time.basePrice ?? 0) > 0) {
          strTimePrice = 'Time Charge: ${_formatPrice(time.basePrice)}';
        }

        // Extra time charge: "Extra time charge $X / min"
        if ((time.unitPrice ?? 0) > 0) {
          final unitValue = '${_formatPrice(time.unitPrice)} / min';
          strExtraMin = 'Extra time charge $unitValue';
        }
      }
    }

    // Process distancePrice
    final distance = packageDetail.distancePrice;
    if (distance != null && distance.isActive == true) {
      if (distance.isApplySlotPrice == true &&
          distance.slots != null &&
          distance.slots!.isNotEmpty) {
        strSlotDistance = _getSubStringSlots(
          priceData: distance,
          isApplied: false,
          isDistance: true,
        );
      } else {
        // Base unit: "X km"
        if ((distance.basePriceUnit ?? 0) > 0) {
          strDistance =
              '${distance.basePriceUnit!.toStringAsFixed(decimalPointValue)} $distanceUnitStr';
        }

        // Distance charge: "Distance Charge: $X"
        if ((distance.basePrice ?? 0) > 0) {
          strDistancePrice =
              'Distance Charge: ${_formatPrice(distance.basePrice)}';
        }

        // Extra distance charge: "Extra distance charge $X / km"
        if ((distance.unitPrice ?? 0) > 0) {
          final unitValue =
              '${_formatPrice(distance.unitPrice)} / $distanceUnitStr';
          strExtraDistance = 'Extra distance charge $unitValue';
        }
      }
    }

    // Build invoice list (matches Kotlin order)

    // 1. Combined distance & time summary: "X km & Y min"
    final strTimeDistance =
        [strDistance, strMin].where((s) => s != null).join(' & ');
    if (strTimeDistance.isNotEmpty) {
      packageInvoiceList.add(Invoice(title: strTimeDistance));
    }

    // 2. Distance charge with optional extra
    if (strDistancePrice != null) {
      packageInvoiceList.add(
          Invoice(title: strDistancePrice, subTitle: strExtraDistance));
    } else if (strExtraDistance != null) {
      packageInvoiceList.add(Invoice(title: strExtraDistance));
    }

    // 3. Slot distance
    if (strSlotDistance != null) {
      packageInvoiceList
          .add(Invoice(title: 'Distance Charge', subTitle: strSlotDistance));
    }

    // 4. Time charge with optional extra
    if (strTimePrice != null) {
      packageInvoiceList
          .add(Invoice(title: strTimePrice, subTitle: strExtraMin));
    } else if (strExtraMin != null) {
      packageInvoiceList.add(Invoice(title: strExtraMin));
    }

    // 5. Slot time
    if (strSlotMin != null) {
      packageInvoiceList
          .add(Invoice(title: 'Time Charge', subTitle: strSlotMin));
    }

    return packageInvoiceList;
  }

  /// Get list of invoice elements from InvoiceDetail
  List<Invoice> getInvoiceElements({
    required InvoiceDetail? invoiceData,
    bool isFareEstimate = false,
    List<MapEntry<String, String>> accessibilityList = const [],
  }) {
    if (invoiceData == null) return [];

    final invoiceList = <Invoice>[];

    // Process charges
    invoiceData.charges?.forEach((charge) {
      final invoice = _getElementFromPriceType(
        priceData: charge,
        chargeType: ChargeType.charges,
      );
      if (invoice != null) {
        final appliedOnStr = _getAppliedOnStr(
          applyOn: charge.applyOn,
          dataToFilter: invoiceData.charges ?? [],
          accessibilityList: accessibilityList,
        );
        invoiceList.add(invoice.copyWith(
          subTitle: _combineSubtitle(invoice.subTitle, appliedOnStr),
        ));
      }
    });

    // Process additional prices
    invoiceData.additionalPrices?.forEach((additionalPrice) {
      // Find display name from custom prices in accessibility list
      final customName = accessibilityList
          .where((item) => item.key == additionalPrice.chargeId)
          .map((item) => item.value)
          .firstOrNull;

      final priceData = customName != null
          ? PriceData(
              title: customName,
              chargeId: additionalPrice.chargeId,
              price: additionalPrice.price,
              unit: additionalPrice.unit,
              unitPrice: additionalPrice.unitPrice,
              basePrice: additionalPrice.basePrice,
              basePriceUnit: additionalPrice.basePriceUnit,
              discountedPrice: additionalPrice.discountedPrice,
              driverProfit: additionalPrice.driverProfit,
              driverProfitType: additionalPrice.driverProfitType,
              driverProfitPercentage: additionalPrice.driverProfitPercentage,
              isApplySlotPrice: additionalPrice.isApplySlotPrice,
              appliedSlots: additionalPrice.appliedSlots,
              slots: additionalPrice.slots,
              applyOn: additionalPrice.applyOn,
              childs: additionalPrice.childs,
              isSlotInPriceWithUnitCalculation:
                  additionalPrice.isSlotInPriceWithUnitCalculation,
              isSlotInPriceWithSum: additionalPrice.isSlotInPriceWithSum,
            )
          : additionalPrice;

      final invoice = _getElementFromPriceType(
        priceData: priceData,
        chargeType: ChargeType.additionalPrices,
      );
      if (invoice != null) {
        invoiceList.add(invoice);
      }
    });

    // Process accessibility prices (skip for fare estimate)
    if (!isFareEstimate) {
      invoiceData.accessibilityPrices?.forEach((accessibilityPrice) {
        // Find display name from accessibility list
        final accessibilityName = accessibilityList
            .where((item) => item.key == accessibilityPrice.chargeId)
            .map((item) => item.value)
            .firstOrNull;

        final invoice = _getElementFromPriceType(
          priceData: PriceData(
            title: accessibilityName ?? accessibilityPrice.title,
            chargeId: accessibilityPrice.chargeId,
            price: accessibilityPrice.price,
            unit: accessibilityPrice.unit,
            unitPrice: accessibilityPrice.unitPrice,
            basePrice: accessibilityPrice.basePrice,
            basePriceUnit: accessibilityPrice.basePriceUnit,
            discountedPrice: accessibilityPrice.discountedPrice,
            driverProfit: accessibilityPrice.driverProfit,
            driverProfitType: accessibilityPrice.driverProfitType,
            driverProfitPercentage: accessibilityPrice.driverProfitPercentage,
            isApplySlotPrice: accessibilityPrice.isApplySlotPrice,
            appliedSlots: accessibilityPrice.appliedSlots,
            slots: accessibilityPrice.slots,
            applyOn: accessibilityPrice.applyOn,
            childs: accessibilityPrice.childs,
            isSlotInPriceWithUnitCalculation:
                accessibilityPrice.isSlotInPriceWithUnitCalculation,
            isSlotInPriceWithSum: accessibilityPrice.isSlotInPriceWithSum,
          ),
          chargeType: ChargeType.accessibilityPrices,
        );
        if (invoice != null) {
          invoiceList.add(invoice);
        }
      });
    }

    // Process modifier prices
    invoiceData.modifierPrice?.forEach((modifierPrice) {
      final priceData = _modifierPriceToPriceData(modifierPrice);
      final invoice = _getElementFromPriceType(
        priceData: priceData,
        chargeType: ChargeType.additionalPrices,
      );
      if (invoice != null) {
        invoiceList.add(invoice);
      }
    });

    // Process tax prices
    invoiceData.taxPrices?.forEach((taxPrice) {
      final invoice = _getElementFromPriceType(
        priceData: taxPrice,
        chargeType: ChargeType.taxPrices,
      );
      if (invoice != null) {
        final appliedOnStr = _getAppliedOnStr(
          applyOn: taxPrice.applyOn,
          dataToFilter: invoiceData.charges ?? [],
          accessibilityList: accessibilityList,
        );
        invoiceList.add(invoice.copyWith(
          subTitle: _combineSubtitle(invoice.subTitle, appliedOnStr),
        ));
      }
    });

    return invoiceList;
  }

  /// Convert ModifierPrice to PriceData
  PriceData _modifierPriceToPriceData(ModifierPrice modifier) {
    return PriceData(
      title: modifier.name,
      price: modifier.price,
      driverProfit: modifier.driverProfit,
      discountedPrice: modifier.discountedPrice,
      driverProfitPercentage: modifier.driverProfitPercentage,
      driverProfitType: modifier.driverProfitType,
      childs: modifier.options
          ?.map((opt) => PriceData(
                title: opt.name,
                price: opt.price,
                driverProfitType: opt.driverProfitType,
                driverProfit: opt.driverProfit,
                discountedPrice: opt.discountedPrice,
                driverProfitPercentage: opt.driverProfitPercentage,
              ))
          .toList(),
    );
  }

  /// Get invoice element from price data
  Invoice? _getElementFromPriceType({
    required PriceData priceData,
    required ChargeType chargeType,
  }) {
    final price = priceData.price ?? 0;
    if (price <= 0) return null;

    // Match Kotlin: title.toValue().ifEmpty { chargeId.toValue() }
    // Empty string must fall through to chargeId (not just null)
    final rawTitle = priceData.title;
    final title = (rawTitle != null && rawTitle.isNotEmpty)
        ? rawTitle
        : (priceData.chargeId ?? '');
    final titleValue = PriceType.getTitle(title);

    final discountValue = (priceData.discountedPrice ?? 0) > 0 &&
            (priceData.discountedPrice ?? 0) < price
        ? _formatPrice(priceData.discountedPrice)
        : null;

    final priceValue = _formatPrice(price);

    final isFree = chargeType == ChargeType.charges &&
        priceData.discountedPrice != null &&
        (priceData.discountedPrice ?? 0) <= 0;

    String subTitle = '';

    switch (title) {
      case PriceType.bookingFee:
      case PriceType.minimumFee:
      case PriceType.cancellationPrice:
      case PriceType.promoBonus:
        return Invoice(
          title: titleValue,
          subTitle: '',
          isFree: isFree,
          discount: discountValue,
          amount: priceValue,
          invoiceChild: _getChildInvoices(priceData.childs),
        );

      case PriceType.distancePrice:
        return _getTimeDistancePriceElement(
          title: titleValue,
          amount: priceValue,
          priceData: priceData,
          isDistance: true,
        );

      case PriceType.timePrice:
      case PriceType.waitingTimePrice:
      case PriceType.airportWaitingTimePrice:
      case PriceType.stopWaitingTimePrice:
      case PriceType.trafficTimePrice:
        return _getTimeDistancePriceElement(
          title: titleValue,
          amount: priceValue,
          priceData: priceData,
          isDistance: false,
        );

      case PriceType.surgePrice:
        if ((priceData.unit ?? 0) > 0) {
          subTitle = '${priceData.unit} X';
        }
        return Invoice(
          title: titleValue,
          subTitle: subTitle,
          isFree: isFree,
          discount: discountValue,
          amount: priceValue,
          invoiceChild: _getChildInvoices(priceData.childs),
        );

      default:
        if (chargeType == ChargeType.taxPrices && (priceData.unit ?? 0) > 0) {
          subTitle = '${(priceData.unit ?? 0).toStringAsFixed(decimalPointValue)} %';
        }
        if (title.isNotEmpty) {
          return Invoice(
            title: titleValue,
            subTitle: subTitle,
            isFree: isFree,
            discount: discountValue,
            amount: priceValue,
            invoiceChild: _getChildInvoices(priceData.childs),
          );
        }
        return null;
    }
  }

  /// Get time/distance price element with slot support
  Invoice _getTimeDistancePriceElement({
    required String title,
    required String amount,
    required PriceData priceData,
    required bool isDistance,
  }) {
    final unit = isDistance
        ? DistanceUnit.getUnit(distanceUnit)
        : 'min';

    // Handle slot pricing
    if (priceData.isApplySlotPrice == true) {
      final subTitle = _getSubStringSlots(
        priceData: priceData,
        isApplied: true,
        isDistance: isDistance,
      );
      return Invoice(title: title, subTitle: subTitle, amount: amount);
    }

    final subTitleList = <String>[];

    // Base price
    if ((priceData.basePrice ?? 0) > 0) {
      var baseSubTitle = 'Price: ${_formatPrice(priceData.basePrice)}';
      if ((priceData.basePriceUnit ?? 0) > 0) {
        final baseUnit =
            '${(priceData.basePriceUnit ?? 0).toStringAsFixed(decimalPointValue)} $unit';
        baseSubTitle += ' ($baseUnit)';
      }
      subTitleList.add(baseSubTitle);
    }

    // Unit price
    final unitValue = _formatPrice(priceData.unitPrice);
    final subTitle = '$unitValue / $unit';
    subTitleList.add(subTitle);

    return Invoice(
      title: title,
      subTitle: subTitleList.join('\n'),
      amount: amount,
    );
  }

  /// Get subtitle for slot pricing
  String _getSubStringSlots({
    required PriceData priceData,
    required bool isApplied,
    required bool isDistance,
  }) {
    final unit = isDistance
        ? DistanceUnit.getUnit(distanceUnit)
        : 'min';

    final slotsList = isApplied
        ? (priceData.appliedSlots ?? [])
        : (priceData.slots ?? []);

    final lines = <String>[];

    for (var i = 0; i < slotsList.length; i++) {
      final slot = slotsList[i];
      final min = slot.min ?? 0;
      final max = slot.max ?? 0;
      final isLast = i == slotsList.length - 1;

      final price = isApplied ? slot.unitPrice : slot.price;
      final unitValue = _formatPrice(price);

      final maxDisplay = max >= 999999 ? '∞' : '$max';
      final slotRange = '$min $unit - $maxDisplay $unit';

      var strSub = '$unitValue / $unit';
      if (priceData.isSlotInPriceWithUnitCalculation != true) {
        strSub = unitValue;
      }

      if (priceData.isSlotInPriceWithSum == true || !isApplied) {
        lines.add('$slotRange: $strSub');
      } else {
        final currentUnit = priceData.unit ?? 0;
        if (currentUnit >= min && currentUnit <= max && !isLast) {
          lines.add('$slotRange: $strSub');
          break;
        } else if (isLast) {
          lines.add('$slotRange: $strSub');
        }
      }
    }

    return lines.join('\n');
  }

  /// Get child invoice items
  List<InvoiceChild>? _getChildInvoices(List<PriceData>? childs) {
    if (childs == null || childs.isEmpty) return null;

    return childs
        .where((child) => (child.price ?? 0) > 0)
        .map((child) => InvoiceChild(
              title: PriceType.getTitle(child.title ?? ''),
              amount: _formatPrice(child.price),
            ))
        .toList();
  }

  /// Get "Applied on" string for taxes
  String _getAppliedOnStr({
    List<String>? applyOn,
    required List<PriceData> dataToFilter,
    List<MapEntry<String, String>> accessibilityList = const [],
  }) {
    if (applyOn == null || applyOn.isEmpty) return '';

    final applicableCharges = applyOn.where((charge) {
      // Check if charge exists in dataToFilter
      final existsInData = dataToFilter.any((data) =>
          data.title == charge ||
          (data.childs?.any((child) => child.title == charge) ?? false));

      // Check if charge exists in accessibility list
      final existsInAccessibility =
          accessibilityList.any((item) => item.key == charge);

      return existsInData || existsInAccessibility;
    }).map((charge) {
      // Try to find in accessibility list first
      final accessibilityItem = accessibilityList
          .where((item) => item.key == charge)
          .map((item) => item.value)
          .firstOrNull;

      return accessibilityItem ?? PriceType.getTitle(charge);
    }).join(', ');

    if (applicableCharges.isEmpty) return '';

    return 'Applied On ($applicableCharges)';
  }

  /// Combine subtitle with applied on string
  String _combineSubtitle(String? subTitle, String appliedOnStr) {
    if (subTitle?.isNotEmpty == true && appliedOnStr.isNotEmpty) {
      return '$subTitle\n$appliedOnStr';
    }
    return '${subTitle ?? ''}$appliedOnStr';
  }

  /// Format price with currency settings
  String _formatPrice(double? price) {
    if (price == null) return '';
    return price.applyPriceSetting(
      currencyDirection: currencyDirection,
      currencySign: currencySign,
      decimalPointValue: decimalPointValue,
    );
  }
}
