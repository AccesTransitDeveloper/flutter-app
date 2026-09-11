import 'package:flutter/material.dart';

import '../../core/theme/app_dimens.dart';
import '../../models/requests/get_vehicle_types_request.dart';
import '../../core/theme/app_theme.dart';
import 'app_text.dart';

/// Reusable address input card with pickup/dropoff fields and optional plus button
class AppAddressInputCard extends StatelessWidget {
  final TextEditingController pickupController;
  final TextEditingController destinationController;
  final FocusNode pickupFocusNode;
  final FocusNode destinationFocusNode;
  final String pickupHint;
  final String destinationHint;
  final bool isPickupFocused;
  final bool isDestinationFocused;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onClearPickup;
  final VoidCallback? onClearDestination;
  final VoidCallback? onAddStopTap;
  final bool showAddButton;
  final bool isAddButtonEnabled;

  const AppAddressInputCard({
    super.key,
    required this.pickupController,
    required this.destinationController,
    required this.pickupFocusNode,
    required this.destinationFocusNode,
    this.pickupHint = 'Enter pickup location',
    this.destinationHint = 'Where to?',
    this.isPickupFocused = false,
    this.isDestinationFocused = false,
    this.onSearchChanged,
    this.onClearPickup,
    this.onClearDestination,
    this.onAddStopTap,
    this.showAddButton = true,
    this.isAddButtonEnabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Bordered container
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppDimens.paddingM),
            decoration: BoxDecoration(
              border: Border.all(color: colors.colorPrimary),
              borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
            ),
            child: Row(
              children: [
                // Pickup/Drop icons with line
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/ic_pickup.png',
                      width: 20,
                      height: 20,
                      color: colors.colorPrimary,
                      colorBlendMode: BlendMode.srcIn,
                    ),
                    Container(
                      width: 1.5,
                      height: 20,
                      color: colors.colorPrimary.withValues(alpha: 0.3),
                    ),
                    Image.asset(
                      'assets/images/ic_drop_off.png',
                      width: 20,
                      height: 20,
                      color: colors.colorPrimary,
                      colorBlendMode: BlendMode.srcIn,
                    ),
                  ],
                ),
                const SizedBox(width: AppDimens.paddingM),
                // Text fields
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _AddressTextField(
                        controller: pickupController,
                        focusNode: pickupFocusNode,
                        hint: pickupHint,
                        isFocused: isPickupFocused,
                        onChanged: onSearchChanged,
                        onClear: onClearPickup,
                      ),
                      Divider(
                        color: colors.colorText.withValues(alpha: 0.3),
                        height: 1,
                      ),
                      _AddressTextField(
                        controller: destinationController,
                        focusNode: destinationFocusNode,
                        hint: destinationHint,
                        isFocused: isDestinationFocused,
                        onChanged: onSearchChanged,
                        onClear: onClearDestination,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showAddButton) ...[
          const SizedBox(width: AppDimens.paddingM),
          // Plus button - outside the box
          GestureDetector(
            onTap: isAddButtonEnabled ? onAddStopTap : null,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isAddButtonEnabled
                    ? colors.colorBackgroundGray
                    : colors.colorBackgroundGray.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add,
                color: isAddButtonEnabled
                    ? colors.colorText
                    : colors.colorText.withValues(alpha: 0.3),
                size: 20,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Internal text field widget for address input
class _AddressTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final bool isFocused;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  const _AddressTextField({
    required this.controller,
    required this.focusNode,
    required this.hint,
    this.isFocused = false,
    this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: () => focusNode.requestFocus(),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppDimens.paddingXS),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                style: TextStyle(fontSize: 14, color: colors.colorText),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyle(fontSize: 14, color: colors.colorText),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.paddingXS,
                    vertical: AppDimens.paddingXS,
                  ),
                ),
                onChanged: onChanged,
              ),
            ),
            if (controller.text.isNotEmpty && isFocused)
              GestureDetector(
                onTap: onClear,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: colors.colorPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    size: 14,
                    color: colors.colorBackground,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Reusable stops list card for displaying pickup and stops with connecting line
class AppStopsListCard extends StatelessWidget {
  final DestinationAddress pickupAddress;
  final List<DestinationAddress> stops;
  final bool noMoreStopsAllowed;
  final VoidCallback? onAddStopTap;
  final ValueChanged<int>? onStopTap;
  final ValueChanged<int>? onRemoveStop;

  const AppStopsListCard({
    super.key,
    required this.pickupAddress,
    required this.stops,
    this.noMoreStopsAllowed = false,
    this.onAddStopTap,
    this.onStopTap,
    this.onRemoveStop,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Gray container with stops
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.paddingM,
              vertical: AppDimens.paddingS,
            ),
            decoration: BoxDecoration(
              color: colors.colorBackgroundGray,
              borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column: icons with connecting lines
                _buildIconsColumn(context),
                const SizedBox(width: AppDimens.paddingM),
                // Right column: address texts with drag handles
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Pickup row content
                      _buildStopRowContent(
                        context,
                        address: pickupAddress,
                        index: -1,
                        isPickup: true,
                      ),
                      // Stop rows content
                      for (int i = 0; i < stops.length; i++)
                        _buildStopRowContent(
                          context,
                          address: stops[i],
                          index: i,
                          isPickup: false,
                        ),
                      // Add stop row content (hidden when max stop limit reached)
                      if (!noMoreStopsAllowed)
                        _buildAddStopRowContent(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // X buttons column (outside the gray container)
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Placeholder for pickup row (no X button)
            const SizedBox(height: 48),

            // X buttons for each stop
            for (int i = 0; i < stops.length; i++)
              SizedBox(
                height: 48,
                width: 40,
                child: Center(
                  child: GestureDetector(
                    onTap: () => onRemoveStop?.call(i),
                    child: Icon(
                      Icons.close,
                      color: colors.colorText,
                      size: 20,
                    ),
                  ),
                ),
              ),

            // Placeholder for add stop row (no X button)
            const SizedBox(height: 48),
          ],
        ),
      ],
    );
  }

  /// Builds the left column with icons and connecting lines
  Widget _buildIconsColumn(BuildContext context) {
    final colors = context.colors;
    final totalRows = 1 + stops.length + (noMoreStopsAllowed ? 0 : 1); // pickup + stops + add stop (if allowed)
    final totalHeight = totalRows * 48.0;

    return SizedBox(
      width: 24,
      height: totalHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Continuous vertical line from first icon to last icon
          Positioned(
            top: 24, // Center of first row (pickup)
            bottom: 24, // Center of last row (add stop)
            child: Container(
              width: 1.5,
              color: colors.colorPrimary.withValues(alpha: 0.3),
            ),
          ),

          // Pickup icon - centered in first 48px row
          Positioned(
            top: 24 - 8, // 48/2 - 16/2 = center the 16px icon
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: colors.colorBackgroundGray,
                shape: BoxShape.circle,
                border: Border.all(
                  color: colors.colorPrimary,
                  width: 2,
                ),
              ),
            ),
          ),

          // Stop icons - centered in their respective rows
          for (int i = 0; i < stops.length; i++)
            Positioned(
              top: 48 + (i * 48) + 24 - 10, // row offset + center - half icon height
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: colors.colorPrimary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      color: colors.colorBackground,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

          // Add stop icon - centered in last 48px row (hidden when max stop limit reached)
          if (!noMoreStopsAllowed)
            Positioned(
              top: totalHeight - 48 + 24 - 10, // last row offset + center - half icon
              child: Container(
                width: 20,
                height: 20,
                color: colors.colorBackgroundGray,
                child: Icon(
                  Icons.add,
                  color: colors.colorText,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Row content without the icon column
  Widget _buildStopRowContent(
    BuildContext context, {
    required DestinationAddress address,
    required int index,
    required bool isPickup,
  }) {
    final colors = context.colors;

    return GestureDetector(
      onTap: () {
        if (!isPickup && index >= 0) {
          onStopTap?.call(index);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            // Address text
            Expanded(
              child: AppText.body(
                address.title ?? address.address ?? 'Unknown location',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Drag handle
            Icon(
              Icons.menu,
              color: colors.colorText,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  /// Add stop row content without the icon column
  Widget _buildAddStopRowContent(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onAddStopTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            // Text
            Expanded(
              child: AppText.body(
                'Add stop',
                color: colors.colorText,
              ),
            ),

            // Drag handle
            Icon(
              Icons.menu,
              color: colors.colorText,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
