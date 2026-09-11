import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/localization/app_strings.dart';
import '../../core/localization/string_constants.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme.dart';
import '../../data/api/server_config.dart';
import '../../models/responses/booking/booking_history_response.dart';
import '../widgets/app_text.dart';

/// Reusable list item for past booking history in the Activity screen
class PastActivityItem extends StatelessWidget {
  final Bookings booking;
  final bool isRebookLoading;
  final VoidCallback? onTap;
  final VoidCallback? onRebook;

  const PastActivityItem({
    super.key,
    required this.booking,
    this.isRebookLoading = false,
    this.onTap,
    this.onRebook,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isCancelled = booking.status == BookingStatus.cancelled.value;
    final shouldShowCancelledAmount =
        !isCancelled || _hasPositiveDisplayedAmount();

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimens.paddingM),
        child: Row(
          children: [
            // Vehicle thumbnail
            _buildVehicleImage(colors),

            const SizedBox(width: AppDimens.paddingS),

            // Booking details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.body(
                    booking.vehicleType?.name ?? '',
                    fontWeight: FontWeight.w600,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (booking.uniqueId != null &&
                      booking.uniqueId!.isNotEmpty) ...[
                    const SizedBox(height: AppDimens.paddingXS),
                    AppText.caption(
                      getString(appStr.descriptionBookingIdWithSeparator, 'description_booking_id_with_separator')
                        .replacePlaceholders({StringConstant.unitValue: booking.uniqueId!}),
                      color: colors.colorTextHint,
                    ),
                  ],
                  const SizedBox(height: AppDimens.paddingXS),
                  AppText.caption(
                    booking.completedTimeValue ?? '',
                    color: colors.colorTextHint,
                  ),
                  if (booking.bookingPrice != null &&
                      booking.bookingPrice!.isNotEmpty &&
                      shouldShowCancelledAmount) ...[
                    const SizedBox(height: AppDimens.paddingXS),
                    AppText.caption(
                      isCancelled
                          ? '${booking.bookingPrice} · ${getString(appStr.descriptionCancelled, 'description_cancelled')}'
                          : booking.bookingPrice!,
                      color: isCancelled
                          ? colors.colorWarning
                          : colors.colorTextHint,
                    ),
                  ] else if (isCancelled) ...[
                    const SizedBox(height: AppDimens.paddingXS),
                    AppText.caption(
                      getString(appStr.descriptionCancelled, 'description_cancelled'),
                      color: colors.colorWarning,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: AppDimens.paddingS),

            // Rebook chip
            _buildRebookChip(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleImage(AppColorPalette colors) {
    final imageUrl = booking.vehicleType?.imageUrl != null
        ? ServerConfig.getFullImageUrl(booking.vehicleType!.imageUrl)
        : null;

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: colors.colorBackgroundGray,
        borderRadius: BorderRadius.circular(AppDimens.paddingS),
      ),
      child: imageUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(AppDimens.paddingS),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => Icon(
                  Icons.directions_car,
                  color: colors.colorTextHint,
                  size: 28,
                ),
                errorWidget: (context, url, error) => Icon(
                  Icons.directions_car,
                  color: colors.colorTextHint,
                  size: 28,
                ),
              ),
            )
          : Icon(
              Icons.directions_car,
              color: colors.colorTextHint,
              size: 28,
            ),
    );
  }

  Widget _buildRebookChip(AppColorPalette colors) {
    return GestureDetector(
      onTap: isRebookLoading ? null : onRebook,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingM,
          vertical: AppDimens.paddingS,
        ),
        decoration: BoxDecoration(
          color: colors.colorBackgroundGray,
          borderRadius: BorderRadius.circular(AppDimens.paddingXL),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isRebookLoading)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.colorText,
                ),
              )
            else
              Icon(
                Icons.refresh,
                size: 16,
                color: colors.colorText,
              ),
            const SizedBox(width: AppDimens.paddingXS),
            AppText.caption(
              getString(appStr.buttonReBook, 'button_re_book'),
              fontWeight: FontWeight.w500,
              color: colors.colorText,
            ),
          ],
        ),
      ),
    );
  }

  bool _hasPositiveDisplayedAmount() {
    final total = booking.total;
    if (total != null) return total > 0;

    final price = booking.bookingPrice;
    if (price == null || price.isEmpty) return false;

    final normalized = price.replaceAll(RegExp(r'[^0-9.\-]'), '');
    final parsed = double.tryParse(normalized);
    return (parsed ?? 0) > 0;
  }
}

/// Featured card with map for the most recent booking
class PastActivityFeaturedCard extends StatelessWidget {
  final Bookings booking;
  final bool isRebookLoading;
  final Widget? mapWidget;
  final VoidCallback? onTap;
  final VoidCallback? onRebook;

  const PastActivityFeaturedCard({
    super.key,
    required this.booking,
    this.isRebookLoading = false,
    this.mapWidget,
    this.onTap,
    this.onRebook,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isCancelled = booking.status == BookingStatus.cancelled.value;
    final shouldShowCancelledAmount =
        !isCancelled || _hasPositiveDisplayedAmount();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: colors.colorText.withValues(alpha: 0.1),
          ),
          borderRadius: BorderRadius.circular(AppDimens.paddingM),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Map
            Container(
              height: 180,
              width: double.infinity,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: colors.colorBackgroundGray,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppDimens.paddingM),
                ),
              ),
              child: mapWidget ??
                  Icon(
                    Icons.map_outlined,
                    size: 48,
                    color: colors.colorText.withValues(alpha: 0.2),
                  ),
            ),

            // Booking info
            Padding(
              padding: const EdgeInsets.all(AppDimens.padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.title(
                    booking.vehicleType?.name ?? '',
                    fontWeight: FontWeight.w600,
                  ),
                  if (booking.uniqueId != null &&
                      booking.uniqueId!.isNotEmpty) ...[
                    const SizedBox(height: AppDimens.paddingXS),
                    AppText.body(
                      getString(appStr.descriptionBookingIdWithSeparator, 'description_booking_id_with_separator')
                        .replacePlaceholders({StringConstant.unitValue: booking.uniqueId!}),
                      color: colors.colorTextHint,
                    ),
                  ],
                  const SizedBox(height: AppDimens.paddingXS),
                  AppText.body(
                    booking.completedTimeValue ?? '',
                    color: colors.colorTextHint,
                  ),
                  if (booking.bookingPrice != null &&
                      booking.bookingPrice!.isNotEmpty &&
                      shouldShowCancelledAmount) ...[
                    const SizedBox(height: AppDimens.paddingXS),
                    AppText.body(
                      isCancelled
                          ? '${booking.bookingPrice} · ${getString(appStr.descriptionCancelled, 'description_cancelled')}'
                          : booking.bookingPrice!,
                      color: isCancelled
                          ? colors.colorWarning
                          : colors.colorTextHint,
                    ),
                  ] else if (isCancelled) ...[
                    const SizedBox(height: AppDimens.paddingXS),
                    AppText.body(
                      getString(appStr.descriptionCancelled, 'description_cancelled'),
                      color: colors.colorWarning,
                    ),
                  ],
                  const SizedBox(height: AppDimens.paddingM),

                  // Rebook button
                  _buildRebookChip(colors),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRebookChip(AppColorPalette colors) {
    return GestureDetector(
      onTap: isRebookLoading ? null : onRebook,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingM,
          vertical: AppDimens.paddingS,
        ),
        decoration: BoxDecoration(
          color: colors.colorBackgroundGray,
          borderRadius: BorderRadius.circular(AppDimens.paddingXL),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isRebookLoading)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.colorText,
                ),
              )
            else
              Icon(
                Icons.refresh,
                size: 16,
                color: colors.colorText,
              ),
            const SizedBox(width: AppDimens.paddingXS),
            AppText.caption(
              getString(appStr.buttonReBook, 'button_re_book'),
              fontWeight: FontWeight.w500,
              color: colors.colorText,
            ),
          ],
        ),
      ),
    );
  }

  bool _hasPositiveDisplayedAmount() {
    final total = booking.total;
    if (total != null) return total > 0;

    final price = booking.bookingPrice;
    if (price == null || price.isEmpty) return false;

    final normalized = price.replaceAll(RegExp(r'[^0-9.\-]'), '');
    final parsed = double.tryParse(normalized);
    return (parsed ?? 0) > 0;
  }
}
