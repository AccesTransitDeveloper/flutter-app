import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/localization/string_constants.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/api/server_config.dart';
import '../../../models/responses/booking/accessibility_preference.dart';
import '../../../models/responses/booking/booking_detail_response.dart';
import '../../../models/responses/booking/get_vehicle_type_response.dart';
import '../../../models/ride_for_other_result.dart';
import '../../bottomsheets/fare_estimation_bottom_sheet.dart';
import '../../widgets/app_text.dart';

/// Confirm Details segment for Choose Ride screen
/// Shows selected vehicle summary before booking
class ChooseRideConfirmDetails extends StatelessWidget {
  final NormalVehicles? selectedVehicle;
  final String? currencySign;
  final CountrySettings? countrySetting;
  final double totalPrice;
  final int? tripDuration;
  final VoidCallback onBack;
  final List<CustomPrice>? customPrices;
  final List<AccessibilityPreference>? accessibilities;
  final List<String>? selectedAccessibilityIds;
  /// Updated price detail from getFareEstimate API (includes promo discount)
  final InvoiceDetail? updatedPriceDetail;
  /// Selected promo code
  final PromoDetail? selectedPromo;
  /// Callback when user taps to apply promo
  final VoidCallback? onApplyPromo;
  /// Callback when user taps to remove promo
  final VoidCallback? onRemovePromo;
  /// Selected rental package (when rental vehicle)
  final RentalPack? selectedRentalPackage;
  /// Whether this is a rental booking with package
  final bool isRental;
  /// Callback when user taps "Change" to go back to package selection
  final VoidCallback? onChangePackage;
  /// Whether bidding is available
  final bool isBiddingAvailable;
  /// Whether bidding is currently active
  final bool isBidding;
  /// The bid price entered by the user
  final double? bidPrice;
  /// Callback when user taps "Wish to Bid?"
  final VoidCallback? onBiddingToggle;
  /// Callback when user taps remove bid
  final VoidCallback? onRemoveBid;
  /// Whether this is a destination-later booking (hides prices/bidding)
  final bool isDestinationLater;
  /// Ride for other result (shows "For me" or "For John")
  final RideForOtherResult? rideForOtherResult;

  const ChooseRideConfirmDetails({
    super.key,
    required this.selectedVehicle,
    required this.currencySign,
    required this.countrySetting,
    required this.totalPrice,
    this.tripDuration,
    required this.onBack,
    this.customPrices,
    this.accessibilities,
    this.selectedAccessibilityIds,
    this.updatedPriceDetail,
    this.selectedPromo,
    this.onApplyPromo,
    this.onRemovePromo,
    this.selectedRentalPackage,
    this.isRental = false,
    this.onChangePackage,
    this.isBiddingAvailable = false,
    this.isBidding = false,
    this.bidPrice,
    this.onBiddingToggle,
    this.onRemoveBid,
    this.isDestinationLater = false,
    this.rideForOtherResult,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final vehicleDetail = selectedVehicle?.vehicleTypeDetail;

    final name = vehicleDetail?.name ?? 'Vehicle';
    final imageUrl = vehicleDetail?.imageUrl != null
        ? ServerConfig.getFullImageUrl(vehicleDetail!.imageUrl)
        : null;
    final passengerCapacity = vehicleDetail?.passengerCapacity ?? 4;
    final luggageCapacity = vehicleDetail?.luggageCapacity;
    final description = vehicleDetail?.description ?? '';
    final decimalPointValue = countrySetting?.decimalPointValue ?? 2;
    final formattedPrice =
        '${currencySign ?? '\u20B9'}${totalPrice.toStringAsFixed(decimalPointValue)}';

    // Format trip duration
    final durationText = tripDuration != null
        ? '${(tripDuration! / 60).ceil()} min'
        : '';

    return Container(
      decoration: BoxDecoration(
        color: colors.colorBackground,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: AppDimens.paddingM),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.colorText.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            const SizedBox(height: AppDimens.paddingM),

            // Title
            AppText.title(
              getString(appStr.headingConfirmDetails, 'heading_confirm_details'),
              fontWeight: FontWeight.w600,
            ),

            const SizedBox(height: AppDimens.paddingM),

            Divider(color: colors.colorText.withValues(alpha: 0.1)),

            const SizedBox(height: AppDimens.paddingM),

            // Vehicle image (centered, larger for normal, smaller for rental)
            _buildVehicleImage(colors, imageUrl, isSmall: isRental),

            const SizedBox(height: AppDimens.paddingM),

            if (isRental && selectedRentalPackage != null) ...[
              // Rental: vehicle name (secondary) + package name (primary) + Change button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimens.padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Vehicle name (secondary text)
                    AppText.body(
                      name,
                      color: colors.colorText.withValues(alpha: 0.7),
                    ),
                    const SizedBox(height: AppDimens.paddingS),
                    // Package name + price + info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: AppText.title(
                            selectedRentalPackage!.packageName ?? '',
                            fontWeight: FontWeight.w600,
                            color: colors.colorText,
                          ),
                        ),
                        if (!isDestinationLater)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppText.title(
                                formattedPrice,
                                fontWeight: FontWeight.w600,
                                color: colors.colorText,
                              ),
                              const SizedBox(width: AppDimens.paddingS),
                              GestureDetector(
                                onTap: () => _showFareEstimation(context),
                                child: Icon(
                                  Icons.info_outline,
                                  color: colors.colorText,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    // Change package link
                    GestureDetector(
                      onTap: onChangePackage,
                      child: AppText.body(
                        'Change',
                        color: colors.colorPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    // Package description (distance & time)
                    _buildPackageDescription(colors),
                  ],
                ),
              ),
            ] else ...[
              // Normal: vehicle info row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimens.padding),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Name and capacity
                    Row(
                      children: [
                        AppText.title(
                          name,
                          fontWeight: FontWeight.w600,
                          color: colors.colorText,
                        ),
                        const SizedBox(width: AppDimens.paddingM),
                        Icon(
                          Icons.person_outline,
                          size: 18,
                          color: colors.colorText.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 4),
                        AppText.body(
                          '$passengerCapacity',
                          color: colors.colorText,
                        ),
                        if (luggageCapacity != null && luggageCapacity > 0) ...[
                          const SizedBox(width: AppDimens.paddingM),
                          Icon(
                            Icons.luggage_outlined,
                            size: 18,
                            color: colors.colorText.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 4),
                          AppText.body(
                            '$luggageCapacity',
                            color: colors.colorText,
                          ),
                        ],
                      ],
                    ),

                    // Price with info button (hidden for destination-later)
                    if (!isDestinationLater)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppText.title(
                            formattedPrice,
                            fontWeight: FontWeight.w600,
                            color: colors.colorText,
                          ),
                          const SizedBox(width: AppDimens.paddingS),
                          GestureDetector(
                            onTap: () => _showFareEstimation(context),
                            child: Icon(
                              Icons.info_outline,
                              color: colors.colorText,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              // Duration and description
              if (durationText.isNotEmpty || description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.padding,
                    vertical: AppDimens.paddingS,
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        if (durationText.isNotEmpty) ...[
                          AppText.body(
                            durationText,
                            color: colors.colorText.withValues(alpha: 0.7),
                          ),
                          if (description.isNotEmpty)
                            AppText.body(
                              ' \u2022 ',
                              color: colors.colorText.withValues(alpha: 0.7),
                            ),
                        ],
                        if (description.isNotEmpty)
                          AppText.body(
                            description,
                            color: colors.colorText.withValues(alpha: 0.7),
                          ),
                      ],
                    ),
                  ),
                ),
            ],

            // Promo row
            _buildPromoRow(colors),

            // Ride for other row
            _buildRideForOtherRow(colors),

            // Bidding row
            if (isBiddingAvailable)
              _buildBiddingRow(colors),

          ],
        ),
    );
  }

  void _showFareEstimation(BuildContext context) {
    // Use updated price detail from fare estimate API if available,
    // then fall back to rental package or vehicle priceDetail
    final priceDetail = updatedPriceDetail ??
        (isRental ? selectedRentalPackage?.priceDetail : null) ??
        selectedVehicle?.priceDetail;
    showFareEstimationBottomSheet(
      context: context,
      invoiceDetail: priceDetail,
      currencySign: currencySign ?? '\u20B9',
      currencyDirection: countrySetting?.setCurrencySign ?? 0,
      decimalPointValue: countrySetting?.decimalPointValue ?? 2,
      distanceUnit: countrySetting?.distanceUnit,
      vehiclePriceId: isRental ? selectedRentalPackage?.id : selectedVehicle?.id,
      customPrices: customPrices,
      accessibilities: accessibilities,
      selectedAccessibilityIds: selectedAccessibilityIds,
    );
  }

  Widget _buildVehicleImage(AppColorPalette colors, String? imageUrl, {bool isSmall = false}) {
    final width = isSmall ? 100.0 : 160.0;
    final height = isSmall ? 60.0 : 100.0;
    final iconSize = isSmall ? 40.0 : 64.0;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colors.colorBackground,
        borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
      ),
      child: imageUrl != null
          ? CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.contain,
              placeholder: (context, url) => Icon(
                Icons.directions_car,
                color: colors.colorText,
                size: iconSize,
              ),
              errorWidget: (context, url, error) => Icon(
                Icons.directions_car,
                color: colors.colorText,
                size: iconSize,
              ),
            )
          : Icon(
              Icons.directions_car,
              color: colors.colorText,
              size: iconSize,
            ),
    );
  }

  Widget _buildPackageDescription(AppColorPalette colors) {
    final packageDetail = selectedRentalPackage?.packageDetail;
    if (packageDetail == null) return const SizedBox.shrink();

    final descriptions = <String>[];

    final distancePrice = packageDetail.distancePrice;
    if (distancePrice != null && distancePrice.isActive == true) {
      final unit = distancePrice.basePriceUnit;
      if (unit != null && unit > 0) {
        final unitStr = unit.toStringAsFixed(unit.truncateToDouble() == unit ? 0 : 1);
        descriptions.add('$unitStr km');
      }
    }

    final timePrice = packageDetail.timePrice;
    if (timePrice != null && timePrice.isActive == true) {
      final unit = timePrice.basePriceUnit;
      if (unit != null && unit > 0) {
        final unitStr = unit.toStringAsFixed(unit.truncateToDouble() == unit ? 0 : 1);
        descriptions.add('$unitStr min');
      }
    }

    if (descriptions.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppDimens.paddingS),
      child: AppText.body(
        descriptions.join(' & '),
        color: colors.colorText.withValues(alpha: 0.7),
      ),
    );
  }

  Widget _buildPromoRow(AppColorPalette colors) {
    final hasPromo = selectedPromo != null;

    return GestureDetector(
      onTap: hasPromo ? onRemovePromo : onApplyPromo,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.padding,
          vertical: AppDimens.paddingM,
        ),
        child: Row(
          children: [
            Icon(
              Icons.local_offer_outlined,
              color: hasPromo ? colors.colorPrimary : colors.colorText,
              size: 24,
            ),
            const SizedBox(width: AppDimens.paddingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.body(
                    hasPromo
                        ? selectedPromo!.code ?? getString(appStr.descriptionPromoApplied, 'description_promo_applied')
                        : getString(appStr.descriptionApplyPromoCode, 'description_apply_promo_code'),
                    fontWeight: FontWeight.w500,
                    color: hasPromo ? colors.colorPrimary : colors.colorText,
                  ),
                  if (hasPromo && selectedPromo!.promoAppliedStr != null)
                    AppText.caption(
                      selectedPromo!.promoAppliedStr!,
                      color: colors.colorPrimary,
                    ),
                ],
              ),
            ),
            Icon(
              hasPromo ? Icons.close : Icons.chevron_right,
              color: hasPromo ? colors.colorPrimary : colors.colorText,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRideForOtherRow(AppColorPalette colors) {
    final label = rideForOtherResult == null || rideForOtherResult!.isForMe
        ? getString(appStr.descriptionForMe, 'description_for_me')
        : getString(appStr.descriptionRideFor, 'description_ride_for')
            .replacePlaceholders({StringConstant.userName: rideForOtherResult!.displayName});

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.padding,
        vertical: AppDimens.paddingM,
      ),
      child: Row(
        children: [
          Icon(
            Icons.person_outline,
            color: colors.colorText,
            size: 24,
          ),
          const SizedBox(width: AppDimens.paddingM),
          Expanded(
            child: AppText.body(
              label,
              fontWeight: FontWeight.w500,
              color: colors.colorText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBiddingRow(AppColorPalette colors) {
    final decimalPointValue = countrySetting?.decimalPointValue ?? 2;
    final currency = currencySign ?? '';

    if (isBidding && bidPrice != null) {
      // Bidding is active — show bid amount with remove option
      final formattedBid =
          '$currency${bidPrice!.toStringAsFixed(decimalPointValue)}';

      return GestureDetector(
        onTap: onRemoveBid,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.padding,
            vertical: AppDimens.paddingM,
          ),
          child: Row(
            children: [
              Icon(
                Icons.gavel,
                color: colors.colorPrimary,
                size: 24,
              ),
              const SizedBox(width: AppDimens.paddingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.body(
                      getString(
                          appStr.descriptionYourBid, 'description_your_bid'),
                      fontWeight: FontWeight.w500,
                      color: colors.colorPrimary,
                    ),
                    AppText.caption(
                      formattedBid,
                      color: colors.colorPrimary,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.close,
                color: colors.colorPrimary,
              ),
            ],
          ),
        ),
      );
    }

    // Bidding not active — show toggle
    return GestureDetector(
      onTap: onBiddingToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.padding,
          vertical: AppDimens.paddingM,
        ),
        child: Row(
          children: [
            Icon(
              Icons.gavel_outlined,
              color: colors.colorText,
              size: 24,
            ),
            const SizedBox(width: AppDimens.paddingM),
            Expanded(
              child: AppText.body(
                getString(
                    appStr.descriptionWishToBid, 'description_wish_to_bid'),
                fontWeight: FontWeight.w500,
                color: colors.colorText,
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: colors.colorText,
            ),
          ],
        ),
      ),
    );
  }
}
