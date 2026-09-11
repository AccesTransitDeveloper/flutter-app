import 'package:flutter/material.dart';

import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme.dart';
import 'app_text.dart';

/// Reusable chip widget with icon, label and dropdown arrow
class AppChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const AppChip({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingM,
          vertical: AppDimens.paddingS,
        ),
        decoration: BoxDecoration(
          color: colors.colorBackgroundGray,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: AppDimens.paddingS),
              child: Icon(icon, size: 18, color: colors.colorText),
            ),
            Padding(
              padding: const EdgeInsets.only(right: AppDimens.paddingXS),
              child: AppText.body(label, color: colors.colorText),
            ),
            Icon(Icons.keyboard_arrow_down, size: 18, color: colors.colorText),
          ],
        ),
      ),
    );
  }
}
