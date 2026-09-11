import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_dimens.dart';
import '../../models/day_setting.dart';
import '../../models/responses/booking/get_vehicle_type_response.dart';
import '../../core/theme/app_theme.dart';
import '../../views/widgets/app_button.dart';
import '../../views/widgets/app_text.dart';
import '../../views/item/schedule_picker_segment.dart';

/// Schedule option for ride booking
enum ScheduleOption { now, later }

/// Result from the schedule ride bottom sheet
class ScheduleRideResult {
  final ScheduleOption option;
  final SchedulePickerResult? scheduleResult;

  ScheduleRideResult({
    required this.option,
    this.scheduleResult,
  });

  bool get isNow => option == ScheduleOption.now;
  bool get isScheduled => option == ScheduleOption.later && scheduleResult != null;

  /// Returns display text for the chip
  String get chipLabel {
    if (isNow) return 'Pickup now';
    if (scheduleResult != null) return scheduleResult!.displayText;
    return 'Schedule';
  }
}

class ScheduleRideBottomSheet extends StatefulWidget {
  final ScheduleOption initialOption;
  final RideType? rideType;
  final DriverSettings? driverSettings;
  final BusinessSettings? businessSettings;
  final Map<String, DaySetting>? daySettings;
  final SchedulePickerResult? initialScheduleResult;

  const ScheduleRideBottomSheet({
    super.key,
    this.initialOption = ScheduleOption.now,
    this.rideType,
    this.driverSettings,
    this.businessSettings,
    this.daySettings,
    this.initialScheduleResult,
  });

  /// Shows the schedule ride bottom sheet and returns the result
  /// Uses businessSettings to check NOW/SCHEDULE availability
  static Future<ScheduleRideResult?> show({
    required BuildContext context,
    ScheduleOption initialOption = ScheduleOption.now,
    RideType? rideType,
    DriverSettings? driverSettings,
    BusinessSettings? businessSettings,
    Map<String, DaySetting>? daySettings,
    SchedulePickerResult? initialScheduleResult,
  }) {
    return showModalBottomSheet<ScheduleRideResult>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ScheduleRideBottomSheet(
        initialOption: initialOption,
        rideType: rideType,
        driverSettings: driverSettings,
        businessSettings: businessSettings,
        daySettings: daySettings,
        initialScheduleResult: initialScheduleResult,
      ),
    );
  }

  @override
  State<ScheduleRideBottomSheet> createState() => _ScheduleRideBottomSheetState();
}

class _ScheduleRideBottomSheetState extends State<ScheduleRideBottomSheet> {
  late ScheduleOption _selectedOption;
  SchedulePickerResult? _scheduleResult;

  /// Check if SCHEDULE is available using BusinessSettings
  bool get _isScheduleAvailable => SchedulePickerSegment.isScheduleAvailableFromBusiness(
        rideType: widget.rideType,
        businessSettings: widget.businessSettings,
      );

  /// Check if NOW is available using BusinessSettings
  bool get _isNowAvailable => SchedulePickerSegment.isNowAvailableFromBusiness(
        rideType: widget.rideType,
        businessSettings: widget.businessSettings,
      );

  @override
  void initState() {
    super.initState();
    _selectedOption = widget.initialOption;
    _scheduleResult = widget.initialScheduleResult;

    // If "Now" is not available, default to "Later"
    if (!_isNowAvailable && _isScheduleAvailable) {
      _selectedOption = ScheduleOption.later;
    }
  }

  Future<void> _onDonePressed() async {
    if (_selectedOption == ScheduleOption.now) {
      Navigator.pop(context, ScheduleRideResult(option: ScheduleOption.now));
      return;
    }

    // For "Later" option, show the schedule picker flow
    if (!mounted) return;

    final result = await SchedulePickerSegment.show(
      context: context,
      rideType: widget.rideType,
      driverSettings: widget.driverSettings,
      daySettings: widget.daySettings,
      initialDate: _scheduleResult?.date,
    );

    if (result != null && mounted) {
      Navigator.pop(
        context,
        ScheduleRideResult(
          option: ScheduleOption.later,
          scheduleResult: result,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.colorBackground,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppDimens.paddingL),
          topRight: Radius.circular(AppDimens.paddingL),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.padding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              AppText.title(
                'When do you need a ride?',
                fontWeight: FontWeight.w600,
              ),
              const SizedBox(height: AppDimens.paddingL),

              Divider(color: colors.colorText.withValues(alpha: 0.2)),

              // Now option
              _buildOption(
                context: context,
                icon: Icons.access_time,
                title: 'Now',
                subtitle: 'Request a ride, hop-in, and go',
                option: ScheduleOption.now,
                isEnabled: _isNowAvailable,
              ),

              Divider(color: colors.colorText.withValues(alpha: 0.2)),

              // Later option
              _buildOption(
                context: context,
                icon: Icons.calendar_today_outlined,
                title: 'Later',
                subtitle: _scheduleResult != null
                    ? _scheduleResult!.displayText
                    : 'Reserve for extra peace of mind',
                option: ScheduleOption.later,
                isEnabled: _isScheduleAvailable,
              ),

              const SizedBox(height: AppDimens.paddingL),

              // Done button
              AppFilledButton(
                text: 'Done',
                onPressed: _onDonePressed,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required ScheduleOption option,
    bool isEnabled = true,
  }) {
    final colors = context.colors;
    final isSelected = _selectedOption == option;
    final opacity = isEnabled ? 1.0 : 0.4;

    return InkWell(
      onTap: isEnabled ? () => setState(() => _selectedOption = option) : null,
      child: Opacity(
        opacity: opacity,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppDimens.paddingM),
          child: Row(
            children: [
              // Icon
              Icon(
                icon,
                color: colors.colorText,
                size: AppDimens.iconSize,
              ),
              const SizedBox(width: AppDimens.padding),

              // Title and subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.body(
                      title,
                      fontWeight: FontWeight.w500,
                    ),
                    const SizedBox(height: 2),
                    AppText.caption(
                      subtitle,
                      color: colors.colorText,
                    ),
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
                    color: isSelected ? colors.colorText : colors.colorText,
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
                            color: colors.colorText,
                          ),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
