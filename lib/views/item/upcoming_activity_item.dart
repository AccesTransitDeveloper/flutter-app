import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/localization/app_strings.dart';
import '../../core/localization/string_constants.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme.dart';
import '../../data/api/server_config.dart';
import '../widgets/app_text.dart';

/// Upcoming booking item card for the Activity screen
class UpcomingActivityItem extends StatelessWidget {
  final String vehicleTypeName;
  final String scheduleLabel;
  final String? bookingId;
  final String dateTime;
  final String? vehicleImageUrl;
  final VoidCallback? onTap;

  const UpcomingActivityItem({
    super.key,
    required this.vehicleTypeName,
    required this.scheduleLabel,
    this.bookingId,
    required this.dateTime,
    this.vehicleImageUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colors.colorBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colors.colorText.withValues(alpha: 0.18),
              blurRadius: 4,
              offset: Offset.zero,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimens.padding),
                    child: Row(
                      children: [
                        // Text content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText.caption(
                                vehicleTypeName,
                                color: colors.colorTextHint,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: AppDimens.paddingXS),
                              AppText(
                                scheduleLabel,
                                fontSize: AppTypos.textXXL,
                                fontWeight: FontWeight.w700,
                              ),
                              if (bookingId != null &&
                                  bookingId!.isNotEmpty) ...[
                                const SizedBox(height: AppDimens.paddingXS),
                                AppText.caption(
                                  getString(appStr.descriptionBookingIdWithSeparator, 'description_booking_id_with_separator')
                                      .replacePlaceholders({StringConstant.unitValue: bookingId!}),
                                  color: colors.colorTextHint,
                                ),
                              ],
                              const SizedBox(height: AppDimens.paddingXS),
                              AppText.caption(
                                dateTime,
                                color: colors.colorTextHint,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: AppDimens.paddingM),

                        // Vehicle image
                        _buildVehicleImage(colors),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleImage(AppColorPalette colors) {
    final imageUrl = vehicleImageUrl != null
        ? ServerConfig.getFullImageUrl(vehicleImageUrl)
        : null;

    return SizedBox(
      width: 64,
      height: 64,
      child: imageUrl != null
          ? CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.contain,
              placeholder: (context, url) => Icon(
                Icons.directions_car,
                color: colors.colorTextHint,
                size: 32,
              ),
              errorWidget: (context, url, error) => Icon(
                Icons.directions_car,
                color: colors.colorTextHint,
                size: 32,
              ),
            )
          : Icon(
              Icons.directions_car,
              color: colors.colorTextHint,
              size: 32,
            ),
    );
  }
}
