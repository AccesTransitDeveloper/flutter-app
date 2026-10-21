import 'package:flutter/material.dart';

import '../../core/localization/app_strings.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text.dart';
import '../widgets/app_text_field.dart';

/// Cancels a trip with an optional "Other" choice and optional written reason.
class CancelTripBottomSheet extends StatefulWidget {
  final List<String> reasons;
  final String cancellationCharge;
  final bool isCancelTripLoading;
  final ValueChanged<String> onReasonSelected;
  final VoidCallback onDismiss;

  const CancelTripBottomSheet({
    super.key,
    required this.reasons,
    required this.cancellationCharge,
    required this.isCancelTripLoading,
    required this.onReasonSelected,
    required this.onDismiss,
  });

  static Future<void> show(
    BuildContext context, {
    required List<String> reasons,
    required String cancellationCharge,
    required bool isCancelTripLoading,
    required ValueChanged<String> onReasonSelected,
    required VoidCallback onDismiss,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.colorBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      builder: (context) => CancelTripBottomSheet(
        reasons: reasons,
        cancellationCharge: cancellationCharge,
        isCancelTripLoading: isCancelTripLoading,
        onReasonSelected: (reason) {
          Navigator.pop(context);
          onReasonSelected(reason);
        },
        onDismiss: () {
          Navigator.pop(context);
          onDismiss();
        },
      ),
    );
  }

  @override
  State<CancelTripBottomSheet> createState() => _CancelTripBottomSheetState();
}

class _CancelTripBottomSheetState extends State<CancelTripBottomSheet> {
  int _selectedIndex = -1;
  String? _otherReason;

  /// Both a selection and a written reason are optional. Never invent a reason.
  String get _selectedReason {
    if (_selectedIndex < 0) return '';
    final written = (_otherReason ?? '').trim();
    if (written.isNotEmpty) return written;
    return widget.reasons[_selectedIndex];
  }

  bool get _canSubmit => !widget.isCancelTripLoading;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // Lift the whole sheet above the keyboard, then let the reason list scroll
    // inside whatever height is left. As bottom padding *inside* the scroll
    // view this only grew the scroll extent, leaving the content behind the
    // keyboard whenever it was taller than the viewport.
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimens.padding),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with back arrow and title
            Row(
              children: [
                InkWell(
                  onTap: widget.isCancelTripLoading ? null : widget.onDismiss,
                  borderRadius: BorderRadius.circular(20),
                  child: Icon(
                    Icons.arrow_back,
                    color: colors.colorText,
                  ),
                ),
                const SizedBox(width: AppDimens.paddingM),
                Expanded(
                  child: Center(
                    child: AppText.title(
                      getString(
                        appStr.headingCancelTrip,
                        'heading_cancel_trip',
                      ),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // Spacer to balance the back arrow
                const SizedBox(width: 24 + AppDimens.paddingM),
              ],
            ),

            const SizedBox(height: AppDimens.paddingXL),

            // "Why do you want to cancel?" heading
            AppText.title(
              getString(
                appStr.headingWhyDoYouWantToCancel,
                'heading_why_do_you_want_to_cancel',
              ),
              fontWeight: FontWeight.w600,
            ),

            const SizedBox(height: AppDimens.paddingM),
            const Text('Reason is optional. You can cancel without selecting or writing one.'),

            // Cancellation charge notice (if applicable)
            if (widget.cancellationCharge.isNotEmpty) ...[
              AppText.body(
                getString(
                  appStr.descriptionCancellationChargeWillBeApplied,
                  'description_cancellation_charge_will_be_applied',
                ).replaceAll('{{_AMOUNT}}', widget.cancellationCharge),
                color: colors.colorWarning,
              ),
              const SizedBox(height: AppDimens.paddingM),
            ],

            // Only "Other" is offered; tapping again clears the selection.
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry in widget.reasons.asMap().entries)
                  ChoiceChip(
                    label: Text(entry.value),
                    selected: _selectedIndex == entry.key,
                    onSelected: widget.isCancelTripLoading ? null : (selected) {
                      setState(() => _selectedIndex = selected ? entry.key : -1);
                    },
                  ),
              ],
            ),

            // A written explanation is optional, even after selecting Other.
            if (_selectedIndex >= 0) ...[
              const SizedBox(height: AppDimens.paddingM),
              AppTextField(
                onChanged: (value) => setState(() => _otherReason = value),
                maxLines: 2,
                hintText: getString(
                  appStr.hintWriteSpecificReason,
                  'hint_write_specific_reason',
                ),
                borderRadius: 12,
                borderColor: colors.colorText.withValues(alpha: 0.2),
              ),
            ],

            const SizedBox(height: AppDimens.paddingXL),

            // Cancel Trip button
            SizedBox(
              width: double.infinity,
              child: AppFilledButton(
                text: getString(
                  appStr.descriptionCancelTrip,
                  'description_cancel_trip',
                ),
                enabled: _canSubmit,
                isLoading: widget.isCancelTripLoading,
                onPressed: () {
                  if (_canSubmit) {
                    widget.onReasonSelected(_selectedReason);
                  }
                },
              ),
            ),

            const SizedBox(height: AppDimens.paddingM),

            // Keep my trip button
            SizedBox(
              width: double.infinity,
              child: AppOutlinedButton(
                text: getString(
                  appStr.buttonKeepMyTrip,
                  'button_keep_my_trip',
                ),
                onPressed: widget.isCancelTripLoading ? null : widget.onDismiss,
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }

}
