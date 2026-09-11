import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme.dart';
import '../../data/api/server_config.dart';
import '../../models/responses/booking/accessibility_preference.dart';
import '../../models/responses/booking/booking_detail_response.dart';
import '../../models/responses/booking/get_vehicle_type_response.dart';
import '../bottomsheets/fare_estimation_bottom_sheet.dart';

/// Individual vehicle item widget for displaying vehicle options
/// Used in Choose Ride screen for vehicle selection
class VehicleItem extends StatelessWidget {
  final int index;
  final NormalVehicles vehicle;
  final bool isSelected;
  final String? currencySign;
  final CountrySettings? countrySetting;
  final List<CustomPrice>? customPrices;
  final List<AccessibilityPreference>? accessibilities;
  final List<String>? selectedAccessibilityIds;
  final bool isDestinationLater;
  final bool isRental;
  /// Estimated driver arrival time in seconds from distance matrix (null = not loaded)
  final int? durationSeconds;
  final VoidCallback onTap;

  const VehicleItem({
    super.key,
    required this.index,
    required this.vehicle,
    required this.isSelected,
    required this.currencySign,
    required this.countrySetting,
    this.customPrices,
    this.accessibilities,
    this.selectedAccessibilityIds,
    this.isDestinationLater = false,
    this.isRental = false,
    this.durationSeconds,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final vehicleDetail = vehicle.vehicleTypeDetail;
    final priceDetail = vehicle.priceDetail;

    final name = vehicleDetail?.name ?? 'Vehicle';
    final imageUrl = vehicleDetail?.imageUrl != null
        ? ServerConfig.getFullImageUrl(vehicleDetail!.imageUrl)
        : null;
    final passengerCapacity = vehicleDetail?.passengerCapacity ?? 4;
    final luggageCapacity = vehicleDetail?.luggageCapacity;
    final basePrice = priceDetail?.total ?? 0;
    final accessibilityAmount = _calculateAccessibilityAmount(
      priceDetail?.accessibilityPrices,
      selectedAccessibilityIds,
    );
    final totalPrice = basePrice + accessibilityAmount;
    final decimalPointValue = countrySetting?.decimalPointValue ?? 2;
    final formattedPrice =
        '${currencySign ?? '₹'}${totalPrice.toStringAsFixed(decimalPointValue)}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimens.paddingM),
        padding: const EdgeInsets.all(AppDimens.paddingM),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
          border: isSelected
              ? Border.all(color: colors.colorPrimary, width: 2)
              : null,
        ),
        child: Row(
          children: [
            // Vehicle image
            _buildVehicleImage(colors, imageUrl),

            const SizedBox(width: AppDimens.paddingM),

            // Vehicle info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colors.colorText,
                    ),
                  ),
                  if (durationSeconds != null && durationSeconds! > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${(durationSeconds! / 60).ceil()} min',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.colorPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 16,
                        color: colors.colorText.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$passengerCapacity',
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.colorText,
                        ),
                      ),
                      if (luggageCapacity != null && luggageCapacity > 0) ...[
                        const SizedBox(width: AppDimens.paddingM),
                        Icon(
                          Icons.luggage_outlined,
                          size: 16,
                          color: colors.colorText.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$luggageCapacity',
                          style: TextStyle(
                            fontSize: 14,
                            color: colors.colorText,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Price section with info icon (hidden for destination-later or rental)
            if (!isDestinationLater && !isRental)
              _buildPriceSection(context, colors, formattedPrice, priceDetail),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleImage(AppColorPalette colors, String? imageUrl) {
    return Container(
      width: 80,
      height: 50,
      decoration: BoxDecoration(
        color: colors.colorBackground,
        borderRadius: BorderRadius.circular(AppDimens.buttonRadiusSmall),
      ),
      child: imageUrl != null
          ? CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.contain,
              placeholder: (context, url) => Icon(
                Icons.directions_car,
                color: colors.colorText,
                size: 32,
              ),
              errorWidget: (context, url, error) => Icon(
                Icons.directions_car,
                color: colors.colorText,
                size: 32,
              ),
            )
          : Icon(
              Icons.directions_car,
              color: colors.colorText,
              size: 32,
            ),
    );
  }

  Widget _buildPriceSection(
    BuildContext context,
    AppColorPalette colors,
    String formattedPrice,
    InvoiceDetail? priceDetail,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          formattedPrice,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colors.colorText,
          ),
        ),
        const SizedBox(width: AppDimens.paddingS),
        GestureDetector(
          onTap: () => _showFareEstimation(context, priceDetail),
          child: Icon(
            Icons.info_outline,
            color: colors.colorText,
            size: 20,
          ),
        ),
      ],
    );
  }

  /// Calculate total accessibility amount from selected accessibility prices
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

  void _showFareEstimation(BuildContext context, InvoiceDetail? priceDetail) {
    showFareEstimationBottomSheet(
      context: context,
      invoiceDetail: priceDetail,
      currencySign: currencySign ?? '₹',
      currencyDirection: countrySetting?.setCurrencySign ?? 0,
      decimalPointValue: countrySetting?.decimalPointValue ?? 2,
      distanceUnit: countrySetting?.distanceUnit,
      vehiclePriceId: vehicle.id,
      customPrices: customPrices,
      accessibilities: accessibilities,
      selectedAccessibilityIds: selectedAccessibilityIds,
    );
  }
}
