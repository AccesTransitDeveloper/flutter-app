import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/localization/app_strings.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme.dart';
import '../../data/api/server_config.dart';
import '../../models/ride_type_item.dart';
import '../widgets/app_text.dart';

/// Picker for the booking type (Normal / Rental / Share ...).
///
/// This choice used to be made from the home screen's suggestions grid; it now
/// lives on "Plan your ride" as a dropdown next to the ride-for and schedule
/// chips.
class RideTypeBottomSheet extends StatelessWidget {
  final List<RideTypeItem> items;
  final RideType? selectedType;

  const RideTypeBottomSheet({
    super.key,
    required this.items,
    this.selectedType,
  });

  static Future<RideTypeItem?> show({
    required BuildContext context,
    required List<RideTypeItem> items,
    RideType? selectedType,
  }) {
    return showModalBottomSheet<RideTypeItem>(
      context: context,
      backgroundColor: context.colors.colorBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => RideTypeBottomSheet(
        items: items,
        selectedType: selectedType,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.padding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.title(
              getString(null, 'heading_suggestions'),
              fontWeight: FontWeight.w600,
            ),
            const SizedBox(height: AppDimens.padding),
            for (final item in items)
              _RideTypeTile(
                item: item,
                isSelected: item.type == selectedType,
                onTap: () => Navigator.of(context).pop(item),
              ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }
}

class _RideTypeTile extends StatelessWidget {
  final RideTypeItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _RideTypeTile({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final imageUrl = item.imgUrl != null && item.imgUrl!.isNotEmpty
        ? ServerConfig.getFullImageUrl(item.imgUrl)
        : null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimens.paddingM),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimens.paddingM),
        child: Row(
          children: [
            if (imageUrl != null)
              CachedNetworkImage(
                imageUrl: imageUrl,
                width: 32,
                height: 32,
                errorWidget: (_, _, _) =>
                    Icon(_iconFor(item.type), color: colors.colorText, size: 28),
              )
            else
              Icon(_iconFor(item.type), color: colors.colorText, size: 28),
            const SizedBox(width: AppDimens.padding),
            Expanded(
              child: AppText.body(
                item.typeName,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelected)
              Icon(Icons.check, color: colors.colorPrimary, size: 20),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(RideType type) => switch (type) {
        RideType.normal => Icons.directions_car,
        RideType.sharing => Icons.people,
        RideType.rental => Icons.schedule,
        RideType.fixGroup => Icons.group,
      };
}
