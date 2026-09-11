import 'package:flutter/material.dart';

import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme.dart';
import '../../views/widgets/app_button.dart';
import '../../views/widgets/app_text.dart';

class LogoutBottomSheet extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onLogout;

  const LogoutBottomSheet({
    super.key,
    required this.isLoading,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.padding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppText.title('Log out'),
            const SizedBox(height: AppDimens.paddingS),
            AppText.body(
              'Are you sure you want to log out?',
              color: colors.colorText,
            ),
            const SizedBox(height: AppDimens.paddingXL),
            Row(
              children: [
                Expanded(
                  child: AppOutlinedButton(
                    text: 'Cancel',
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: AppDimens.paddingM),
                Expanded(
                  child: AppFilledButton(
                    text: 'Log out',
                    isLoading: isLoading,
                    onPressed: () {
                      onLogout();
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
