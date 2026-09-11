import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text.dart';
import '../../widgets/app_text_field.dart';

/// Confirm Pickup segment for Choose Ride screen
/// Shows pickup location for user confirmation
class ChooseRideConfirmPickup extends StatelessWidget {
  final TextEditingController driverMessageController;
  final ValueChanged<String> onDriverMessageChanged;
  final bool isLoading;
  final VoidCallback onConfirm;

  const ChooseRideConfirmPickup({
    super.key,
    required this.driverMessageController,
    required this.onDriverMessageChanged,
    this.isLoading = false,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.colorBackground,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with drag handle
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

            // Title
            Padding(
              padding: const EdgeInsets.all(AppDimens.padding),
              child: Center(
                child: AppText.title(
                  getString(appStr.headingConfirmPickupSpot, 'heading_confirm_pickup_spot'),
                  fontSize: 18,
                ),
              ),
            ),

            Divider(color: colors.colorBackgroundGray, height: 1),

            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimens.padding,
                AppDimens.padding,
                AppDimens.padding,
                AppDimens.paddingM,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.body(
                    getString(
                      appStr.headingMessageToYourDriver,
                      'heading_message_to_your_driver',
                    ),
                    fontWeight: FontWeight.w600,
                  ),
                  const SizedBox(height: AppDimens.paddingM),
                  AppTextField(
                    controller: driverMessageController,
                    hintText: getString(
                      appStr.hintWriteNotes,
                      'hint_write_notes',
                    ),
                    onChanged: onDriverMessageChanged,
                    textInputAction: TextInputAction.done,
                    maxLines: 3,
                    maxLength: 150,
                    fillColor: colors.colorBackgroundGray,
                    borderColor: colors.colorBackgroundGray,
                  ),
                ],
              ),
            ),

            // Confirm button
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimens.padding,
                0,
                AppDimens.padding,
                AppDimens.padding,
              ),
              child: AppFilledButton(
                text: getString(appStr.buttonConfirmPickup, 'button_confirm_pickup'),
                isLoading: isLoading,
                onPressed: onConfirm,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
