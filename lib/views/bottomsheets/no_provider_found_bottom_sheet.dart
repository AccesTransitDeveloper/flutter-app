import 'package:flutter/material.dart';

import '../../core/localization/app_strings.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text.dart';

class NoProviderFoundBottomSheet extends StatelessWidget {
  final VoidCallback onClose;

  const NoProviderFoundBottomSheet({
    super.key,
    required this.onClose,
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
            AppText.title(
              getString(appStr.headingNoProviderFound, 'heading_no_provider_found'),
            ),
            const SizedBox(height: AppDimens.paddingM),
            AppText.body(
              getString(appStr.descriptionNoProviderFound, 'description_no_provider_found'),
              color: colors.colorText,
            ),
            const SizedBox(height: AppDimens.paddingXL),
            SizedBox(
              width: double.infinity,
              child: AppFilledButton(
                text: getString(appStr.buttonClose, 'button_close'),
                onPressed: onClose,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Show no provider found bottom sheet
Future<void> showNoProviderFoundBottomSheet({
  required BuildContext context,
  required VoidCallback onClose,
}) {
  return showModalBottomSheet(
    context: context,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: context.colors.colorBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(16),
      ),
    ),
    builder: (context) => NoProviderFoundBottomSheet(
      onClose: () {
        Navigator.pop(context);
        onClose();
      },
    ),
  );
}
