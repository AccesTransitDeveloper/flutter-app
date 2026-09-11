import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/utils/time_util.dart';
import '../../models/day_setting.dart';
import '../../core/theme/app_theme.dart';
import '../../views/widgets/app_text.dart';

class ScheduleDatePickerBottomSheet extends StatefulWidget {
  final int maxBookingDays;
  final int scheduleTimeSelectionType;
  final int slotIntervalInMinutes;
  final int bufferTime;
  final Map<String, DaySetting>? daySettings;
  final DateTime? initialDate;

  const ScheduleDatePickerBottomSheet({
    super.key,
    required this.maxBookingDays,
    required this.scheduleTimeSelectionType,
    required this.slotIntervalInMinutes,
    required this.bufferTime,
    this.daySettings,
    this.initialDate,
  });

  /// Shows the schedule date picker and returns the selected date
  static Future<DateTime?> show({
    required BuildContext context,
    required int maxBookingDays,
    required int scheduleTimeSelectionType,
    required int slotIntervalInMinutes,
    required int bufferTime,
    Map<String, DaySetting>? daySettings,
    DateTime? initialDate,
  }) {
    return showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ScheduleDatePickerBottomSheet(
        maxBookingDays: maxBookingDays,
        scheduleTimeSelectionType: scheduleTimeSelectionType,
        slotIntervalInMinutes: slotIntervalInMinutes,
        bufferTime: bufferTime,
        daySettings: daySettings,
        initialDate: initialDate,
      ),
    );
  }

  @override
  State<ScheduleDatePickerBottomSheet> createState() =>
      _ScheduleDatePickerBottomSheetState();
}

class _ScheduleDatePickerBottomSheetState
    extends State<ScheduleDatePickerBottomSheet> {
  late DateTime _selectedDate;
  late List<DateTime> _selectableDates;

  @override
  void initState() {
    super.initState();
    _buildSelectableDates();
    _selectedDate = widget.initialDate ?? _selectableDates.firstOrNull ?? DateTime.now();
  }

  void _buildSelectableDates() {
    _selectableDates = [];
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    for (int i = 0; i <= widget.maxBookingDays; i++) {
      final date = startOfToday.add(Duration(days: i));

      // For slot-based selection, check if there are available slots
      if (widget.scheduleTimeSelectionType != ScheduleTimeSelectionType.timePicker) {
        final hasSlot = TimeUtil.hasAvailableSlot(
          date: date,
          bufferMinutes: widget.bufferTime,
          slotDiffMinutes: widget.slotIntervalInMinutes,
          daySetting: TimeUtil.getDaySettingsForDate(date, widget.daySettings),
        );
        if (hasSlot) {
          _selectableDates.add(date);
        }
      } else {
        // For time picker mode, all days within range are valid
        _selectableDates.add(date);
      }
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(AppDimens.padding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: AppText.body(
                      getString(appStr.buttonCancel, 'button_cancel'),
                      color: colors.colorText,
                    ),
                  ),
                  AppText.title(
                    getString(appStr.headingSelectDate, 'heading_select_date'),
                    fontWeight: FontWeight.w600,
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, _selectedDate),
                    child: AppText.body(
                      getString(appStr.buttonDone, 'button_done'),
                      color: colors.colorPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: colors.colorBackgroundGray),

            if (_selectableDates.isEmpty)
              Padding(
                padding: const EdgeInsets.all(AppDimens.paddingXL),
                child: AppText.body(
                  'No dates available for scheduling',
                  color: colors.colorText,
                  textAlign: TextAlign.center,
                ),
              )
            else
              SizedBox(
                height: 200,
                child: ListWheelScrollView.useDelegate(
                  itemExtent: 50,
                  perspective: 0.005,
                  diameterRatio: 1.5,
                  physics: const FixedExtentScrollPhysics(),
                  controller: FixedExtentScrollController(
                    initialItem: _selectableDates.indexWhere((d) =>
                        d.year == _selectedDate.year &&
                        d.month == _selectedDate.month &&
                        d.day == _selectedDate.day),
                  ),
                  onSelectedItemChanged: (index) {
                    setState(() {
                      _selectedDate = _selectableDates[index];
                    });
                  },
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: _selectableDates.length,
                    builder: (context, index) {
                      final date = _selectableDates[index];
                      final isSelected = date.year == _selectedDate.year &&
                          date.month == _selectedDate.month &&
                          date.day == _selectedDate.day;

                      final isToday = _isToday(date);
                      final isTomorrow = _isTomorrow(date);

                      String displayText;
                      if (isToday) {
                        displayText = 'Today, ${_getDayName(date.weekday)} ${date.day} ${_getMonthName(date.month)}';
                      } else if (isTomorrow) {
                        displayText = 'Tomorrow, ${_getDayName(date.weekday)} ${date.day} ${_getMonthName(date.month)}';
                      } else {
                        displayText = '${_getDayName(date.weekday)}, ${date.day} ${_getMonthName(date.month)} ${date.year}';
                      }

                      return Center(
                        child: AppText.body(
                          displayText,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected
                              ? colors.colorText
                              : colors.colorText,
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day;
  }
}
