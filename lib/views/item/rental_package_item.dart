import 'package:flutter/material.dart';

import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/invoice_util.dart';
import '../../models/invoice.dart';
import '../../models/responses/booking/accessibility_preference.dart';
import '../../models/responses/booking/booking_detail_response.dart';
import '../../models/responses/booking/get_vehicle_type_response.dart';
import '../bottomsheets/fare_estimation_bottom_sheet.dart';

/// Individual rental package item widget
/// Used in Choose Ride screen when a rental vehicle is selected
/// Matches Kotlin RentalPackageItem: shows package name, price, info icon,
/// and full invoice breakdown (distance/time charges, slots, extra charges)
class RentalPackageItem extends StatelessWidget {
  final int index;
  final RentalPack package;
  final bool isSelected;
  final String? currencySign;
  final CountrySettings? countrySetting;
  final List<CustomPrice>? customPrices;
  final List<AccessibilityPreference>? accessibilities;
  final List<String>? selectedAccessibilityIds;
  final VoidCallback onTap;

  const RentalPackageItem({
    super.key,
    required this.index,
    required this.package,
    required this.isSelected,
    required this.currencySign,
    required this.countrySetting,
    this.customPrices,
    this.accessibilities,
    this.selectedAccessibilityIds,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final decimalPointValue = countrySetting?.decimalPointValue ?? 2;
    final currencyDirection = countrySetting?.setCurrencySign ?? 0;
    final sign = currencySign ?? '₹';
    final priceDetail = package.priceDetail;
    final basePrice = priceDetail?.total ?? 0;
    final accessibilityAmount = _calculateAccessibilityAmount(
      priceDetail?.accessibilityPrices,
      selectedAccessibilityIds,
    );
    final totalPrice = basePrice + accessibilityAmount;
    final formattedPrice =
        '$sign${totalPrice.toStringAsFixed(decimalPointValue)}';

    // Build invoice list from packageDetail
    final invoiceUtil = InvoiceUtil(
      currencyDirection: currencyDirection,
      currencySign: sign,
      decimalPointValue: decimalPointValue,
      distanceUnit: countrySetting?.distanceUnit,
    );
    final packageInvoiceList =
        invoiceUtil.getPackageInvoiceList(package.packageDetail);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimens.paddingM),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.colorPrimary
              : colors.colorPrimary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: package name + price with info icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    package.packageName ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : colors.colorText,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected)
                      GestureDetector(
                        onTap: () => _showFareEstimation(context),
                        child: Icon(
                          Icons.info_outline,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    if (isSelected) const SizedBox(width: 5),
                    Text(
                      formattedPrice,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : colors.colorText,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Invoice detail items
            if (packageInvoiceList.isNotEmpty) ...[
              const SizedBox(height: 10),
              ...packageInvoiceList.asMap().entries.map((entry) {
                final invoice = entry.value;
                return _buildInvoiceItem(colors, invoice);
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceItem(AppColorPalette colors, Invoice invoice) {
    final titleColor = isSelected
        ? Colors.white.withValues(alpha: 0.85)
        : colors.colorText.withValues(alpha: 0.6);
    final subtitleColor = isSelected
        ? Colors.white.withValues(alpha: 0.7)
        : colors.colorText.withValues(alpha: 0.5);

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (invoice.title != null && invoice.title!.isNotEmpty)
            Text(
              invoice.title!,
              style: TextStyle(
                fontSize: 12,
                color: titleColor,
              ),
            ),
          if (invoice.subTitle != null && invoice.subTitle!.isNotEmpty)
            Text(
              invoice.subTitle!,
              style: TextStyle(
                fontSize: 11,
                color: subtitleColor,
              ),
            ),
        ],
      ),
    );
  }

  double _calculateAccessibilityAmount(
    List<PriceData>? accessibilityPrices,
    List<String>? selectedIds,
  ) {
    if (accessibilityPrices == null || accessibilityPrices.isEmpty) return 0;
    if (selectedIds == null || selectedIds.isEmpty) return 0;

    double total = 0;
    for (final price in accessibilityPrices) {
      if (selectedIds.contains(price.chargeId)) {
        total += price.price ?? 0;
      }
    }
    return total;
  }

  void _showFareEstimation(BuildContext context) {
    showFareEstimationBottomSheet(
      context: context,
      invoiceDetail: package.priceDetail,
      currencySign: currencySign ?? '₹',
      currencyDirection: countrySetting?.setCurrencySign ?? 0,
      decimalPointValue: countrySetting?.decimalPointValue ?? 2,
      distanceUnit: countrySetting?.distanceUnit,
      vehiclePriceId: package.id,
      customPrices: customPrices,
      accessibilities: accessibilities,
      selectedAccessibilityIds: selectedAccessibilityIds,
    );
  }
}
