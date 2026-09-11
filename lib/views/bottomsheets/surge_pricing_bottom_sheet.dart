import 'package:flutter/material.dart';

import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text.dart';

/// Bottom sheet to show surge pricing confirmation
class SurgePricingBottomSheet extends StatelessWidget {
  final String surgeUnit;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const SurgePricingBottomSheet({
    super.key,
    required this.surgeUnit,
    required this.onConfirm,
    required this.onCancel,
  });

  /// Shows the surge pricing bottom sheet
  /// Returns true if confirmed, false if cancelled, null if dismissed
  static Future<bool?> show({
    required BuildContext context,
    required String surgeUnit,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => SurgePricingBottomSheet(
        surgeUnit: surgeUnit,
        onConfirm: () => Navigator.pop(context, true),
        onCancel: () => Navigator.pop(context, false),
      ),
    );
  }

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
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.padding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: AppDimens.paddingM),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.colorText.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title with surge multiplier
              Padding(
                padding: const EdgeInsets.only(top: AppDimens.paddingS),
                child: AppText.title(
                  'Surge Pricing ${surgeUnit}x',
                  fontSize: 18,
                ),
              ),

              const SizedBox(height: AppDimens.paddingS),

              // Description
              AppText.body(
                'At times of intense demand, prices increase to help ensure that those who need a ride can get one.',
                fontSize: 12,
              ),

              const SizedBox(height: AppDimens.padding),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: AppFilledButton(
                      text: 'Confirm',
                      onPressed: onConfirm,
                    ),
                  ),
                  const SizedBox(width: AppDimens.paddingM),
                  Expanded(
                    child: AppOutlinedButton(
                      text: 'Cancel',
                      onPressed: onCancel,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
