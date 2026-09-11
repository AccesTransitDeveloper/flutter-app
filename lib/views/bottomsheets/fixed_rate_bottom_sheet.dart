import 'package:flutter/material.dart';

import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text.dart';

/// Bottom sheet to ask user if they want fixed rate pricing
class FixedRateBottomSheet extends StatelessWidget {
  final VoidCallback onYes;
  final VoidCallback onNo;

  const FixedRateBottomSheet({
    super.key,
    required this.onYes,
    required this.onNo,
  });

  /// Shows the fixed rate bottom sheet
  /// Returns true if user wants fixed rate, false otherwise
  static Future<bool?> show({
    required BuildContext context,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => FixedRateBottomSheet(
        onYes: () => Navigator.pop(context, true),
        onNo: () => Navigator.pop(context, false),
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

              // Title
              Padding(
                padding: const EdgeInsets.only(top: AppDimens.paddingS),
                child: AppText.title(
                  'Fixed Rate Available',
                  fontSize: 18,
                ),
              ),

              const SizedBox(height: AppDimens.paddingS),

              // Description
              AppText.body(
                'Do you want to go with a fixed price for this trip?',
                fontSize: 12,
              ),

              const SizedBox(height: AppDimens.padding),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: AppFilledButton(
                      text: 'Yes',
                      onPressed: onYes,
                    ),
                  ),
                  const SizedBox(width: AppDimens.paddingM),
                  Expanded(
                    child: AppOutlinedButton(
                      text: 'No',
                      onPressed: onNo,
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
