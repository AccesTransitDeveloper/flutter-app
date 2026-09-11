import 'package:flutter/material.dart';

import '../../core/localization/app_strings.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/common_utils.dart';
import '../../models/ride_for_other_result.dart';
import '../screens/booking/choose_rider_screen.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text.dart';

/// "Switch rider" bottom sheet.
/// Shows "Me" option and previously selected other rider with radio buttons.
/// "Add new contact" opens the contact picker screen.
class SwitchRiderBottomSheet extends StatefulWidget {
  final RideForOtherResult? initialResult;
  final List<RideForOtherResult> recentRiders;
  final String defaultCountryCode;

  const SwitchRiderBottomSheet({
    super.key,
    this.initialResult,
    this.recentRiders = const [],
    required this.defaultCountryCode,
  });

  /// Shows the switch rider bottom sheet and returns the result
  static Future<RideForOtherResult?> show({
    required BuildContext context,
    RideForOtherResult? initialResult,
    List<RideForOtherResult> recentRiders = const [],
    String defaultCountryCode = '+91',
  }) {
    return showModalBottomSheet<RideForOtherResult>(
      context: context,
      backgroundColor: context.colors.colorBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SwitchRiderBottomSheet(
        initialResult: initialResult,
        recentRiders: recentRiders,
        defaultCountryCode: defaultCountryCode,
      ),
    );
  }

  @override
  State<SwitchRiderBottomSheet> createState() => _SwitchRiderBottomSheetState();
}

class _SwitchRiderBottomSheetState extends State<SwitchRiderBottomSheet> {
  late bool _isForMe;
  RideForOtherResult? _selectedOther;

  @override
  void initState() {
    super.initState();
    _isForMe = widget.initialResult?.isForMe ?? true;
    _selectedOther =
        (widget.initialResult != null && !widget.initialResult!.isForMe)
            ? widget.initialResult
            : null;
  }

  void _onDonePressed() {
    if (_isForMe) {
      Navigator.pop(context, const RideForOtherResult.forMe());
    } else if (_selectedOther != null) {
      Navigator.pop(context, _selectedOther);
    }
  }

  Future<void> _openChooseRider() async {
    final result = await Navigator.push<RideForOtherResult>(
      context,
      MaterialPageRoute(
        builder: (_) => ChooseRiderScreen(
          recentRiders: widget.recentRiders,
          defaultCountryCode: widget.defaultCountryCode,
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _isForMe = false;
        _selectedOther = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.padding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(bottom: AppDimens.padding),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.colorText.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title
            AppText.title(
              getString(appStr.headingSwitchRider, 'heading_switch_rider'),
              fontSize: 20,
            ),
            const SizedBox(height: AppDimens.padding),

            // Divider
            Divider(
              color: colors.colorText.withValues(alpha: 0.1),
              height: 1,
            ),

            // "Me" option
            _RiderOption(
              colors: colors,
              avatar: CircleAvatar(
                radius: 22,
                backgroundColor: colors.colorBackgroundGray,
                child: Icon(Icons.person, color: colors.colorText, size: 24),
              ),
              title: getString(appStr.descriptionMe, 'description_me'),
              isSelected: _isForMe,
              onTap: () => setState(() {
                _isForMe = true;
              }),
            ),

            // Previously selected other rider
            if (_selectedOther != null) ...[
              Divider(
                color: colors.colorText.withValues(alpha: 0.1),
                height: 1,
              ),
              _RiderOption(
                colors: colors,
                avatar: CircleAvatar(
                  radius: 22,
                  backgroundColor: colors.colorPrimary,
                  child: AppText.body(
                    getInitials(_selectedOther!.displayName),
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                title: _selectedOther!.displayName,
                subtitle:
                    '${_selectedOther!.countryPhoneCode ?? ''}${_selectedOther!.phone ?? ''}',
                isSelected: !_isForMe,
                onTap: () => setState(() {
                  _isForMe = false;
                }),
              ),
            ],

            // Divider
            Divider(
              color: colors.colorText.withValues(alpha: 0.1),
              height: 1,
            ),

            // "Add new contact" option
            InkWell(
              onTap: _openChooseRider,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: AppDimens.paddingM),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: colors.colorBackgroundGray,
                      child: Icon(Icons.person_add_outlined,
                          color: colors.colorText, size: 22),
                    ),
                    const SizedBox(width: AppDimens.paddingM),
                    Expanded(
                      child: AppText.body(
                        getString(appStr.buttonAddNewContact, 'button_add_new_contact'),
                        fontWeight: FontWeight.w500,
                        color: colors.colorText,
                      ),
                    ),
                    Icon(Icons.chevron_right,
                        color: colors.colorText.withValues(alpha: 0.5)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppDimens.padding),

            // Done button
            AppFilledButton(
              text: getString(appStr.buttonDone, 'button_done'),
              onPressed:
                  (_isForMe || _selectedOther != null) ? _onDonePressed : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _RiderOption extends StatelessWidget {
  final AppColorPalette colors;
  final Widget avatar;
  final String title;
  final String? subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _RiderOption({
    required this.colors,
    required this.avatar,
    required this.title,
    this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimens.paddingM),
        child: Row(
          children: [
            avatar,
            const SizedBox(width: AppDimens.paddingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.body(
                    title,
                    fontWeight: FontWeight.w500,
                    color: colors.colorText,
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    AppText.caption(
                      subtitle!,
                      color: colors.colorText.withValues(alpha: 0.6),
                    ),
                  ],
                ],
              ),
            ),
            // Radio indicator
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? colors.colorPrimary
                      : colors.colorText.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.colorPrimary,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
