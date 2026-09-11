import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../core/utils/time_util.dart';
import '../../models/day_setting.dart';
import '../../core/theme/app_theme.dart';
import '../../views/widgets/app_button.dart';
import '../../views/widgets/app_text.dart';

class TimeSlotPickerBottomSheet extends StatefulWidget {
  final DateTime selectedDate;
  final int scheduleTimeSelectionType;
  final int slotIntervalInMinutes;
  final int bufferTime;
  final Map<String, DaySetting>? daySettings;
  final String? title;

  const TimeSlotPickerBottomSheet({
    super.key,
    required this.selectedDate,
    required this.scheduleTimeSelectionType,
    required this.slotIntervalInMinutes,
    required this.bufferTime,
    this.daySettings,
    this.title,
  });

  /// Shows the time slot picker and returns the selected time string
  static Future<String?> show({
    required BuildContext context,
    required DateTime selectedDate,
    required int scheduleTimeSelectionType,
    required int slotIntervalInMinutes,
    required int bufferTime,
    Map<String, DaySetting>? daySettings,
    String? title,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TimeSlotPickerBottomSheet(
        selectedDate: selectedDate,
        scheduleTimeSelectionType: scheduleTimeSelectionType,
        slotIntervalInMinutes: slotIntervalInMinutes,
        bufferTime: bufferTime,
        daySettings: daySettings,
        title: title,
      ),
    );
  }

  @override
  State<TimeSlotPickerBottomSheet> createState() =>
      _TimeSlotPickerBottomSheetState();
}

class _TimeSlotPickerBottomSheetState extends State<TimeSlotPickerBottomSheet> {
  String? _selectedTime;
  List<TimeSlotItem> _timeSlots = [];
  TimeOfDay _pickerTime = TimeOfDay.now();

  /// Minimum selectable time (now + buffer) when the picked date is today.
  /// Null for future dates (no restriction). Times before this are disabled.
  DateTime? _minAllowed;

  // Wheel controllers (stored so past selections can be snapped forward).
  FixedExtentScrollController? _hourController;
  FixedExtentScrollController? _minuteController;
  FixedExtentScrollController? _ampmController;
  bool _snapping = false;

  @override
  void initState() {
    super.initState();
    _buildTimeSlots();
    if (widget.scheduleTimeSelectionType ==
        ScheduleTimeSelectionType.timePicker) {
      _hourController = FixedExtentScrollController(
        initialItem: _pickerTime.hourOfPeriod == 0
            ? 11
            : _pickerTime.hourOfPeriod - 1,
      );
      _minuteController =
          FixedExtentScrollController(initialItem: _pickerTime.minute);
      _ampmController = FixedExtentScrollController(
        initialItem: _pickerTime.period == DayPeriod.am ? 0 : 1,
      );
    }
  }

  @override
  void dispose() {
    _hourController?.dispose();
    _minuteController?.dispose();
    _ampmController?.dispose();
    super.dispose();
  }

  int _to24(int hour12, bool isPM) {
    if (isPM) return hour12 == 12 ? 12 : hour12 + 12;
    return hour12 == 12 ? 0 : hour12;
  }

  /// Whether a given hour/minute on the picked date is before the minimum
  /// allowed time (i.e. in the past). Always false for future dates.
  bool _isPast(int hour24, int minute) {
    if (_minAllowed == null) return false;
    final dt = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      hour24,
      minute,
    );
    return dt.isBefore(_minAllowed!);
  }

  /// If the current selection is in the past, snap the wheels forward to the
  /// minimum allowed time. Guarantees a past time can never stay selected.
  void _enforceMinTime() {
    if (_minAllowed == null || _snapping) return;
    if (!_isPast(_pickerTime.hour, _pickerTime.minute)) return;

    final minTod =
        TimeOfDay(hour: _minAllowed!.hour, minute: _minAllowed!.minute);
    _snapping = true;
    setState(() => _pickerTime = minTod);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _hourController?.jumpToItem(
          minTod.hourOfPeriod == 0 ? 11 : minTod.hourOfPeriod - 1);
      _minuteController?.jumpToItem(minTod.minute);
      _ampmController?.jumpToItem(minTod.period == DayPeriod.am ? 0 : 1);
      _snapping = false;
    });
  }

  void _buildTimeSlots() {
    if (widget.scheduleTimeSelectionType == ScheduleTimeSelectionType.timePicker) {
      // For time picker mode, set initial time with buffer
      final now = DateTime.now();
      final withBuffer = now.add(Duration(minutes: widget.bufferTime));

      // Only restrict past times when the picked date is today. Times before
      // (now + buffer) are disabled so the user can't pick a past slot.
      final isToday = widget.selectedDate.year == now.year &&
          widget.selectedDate.month == now.month &&
          widget.selectedDate.day == now.day;
      _minAllowed = isToday
          ? DateTime(withBuffer.year, withBuffer.month, withBuffer.day,
              withBuffer.hour, withBuffer.minute)
          : null;

      _pickerTime = TimeOfDay(hour: withBuffer.hour, minute: withBuffer.minute);
      return;
    }

    // For slot modes, build the time slots
    final startDateTime = TimeUtil.createStartDateTime(
      widget.selectedDate,
      widget.slotIntervalInMinutes,
      widget.bufferTime,
    );

    final endOfDay = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      23,
      59,
      59,
      999,
    );

    final daySetting = TimeUtil.getDaySettingsForDate(
      widget.selectedDate,
      widget.daySettings,
    );

    final showRange =
        widget.scheduleTimeSelectionType == ScheduleTimeSelectionType.slotRange;

    _timeSlots = TimeUtil.buildTimeSlots(
      startDateTime: startDateTime,
      endOfDay: endOfDay,
      selectedScheduleDate: widget.selectedDate,
      slotDiffInMinutes: widget.slotIntervalInMinutes,
      bufferMinutes: widget.bufferTime,
      showRange: showRange,
      daySetting: daySetting,
    );

    // Auto-select first slot if available
    if (_timeSlots.isNotEmpty && _selectedTime == null) {
      _selectedTime = _timeSlots.first.value;
    }
  }

  /// Check if the selected time is in the past for today's date.
  /// Uses the same minute-precision [_minAllowed] as the wheel greying/snapping
  /// so the exact minimum minute (now + buffer) is selectable — comparing
  /// against a fresh, second-precision "now" would falsely reject it.
  bool _isSelectedTimePast() => _isPast(_pickerTime.hour, _pickerTime.minute);

  void _onSelectPressed() {
    if (widget.scheduleTimeSelectionType == ScheduleTimeSelectionType.timePicker) {
      // Validate that selected time is not in the past
      if (_isSelectedTimePast()) {
        context.showErrorSnackBar(
          getString(appStr.errorPleaseSelectFutureTime, 'error_please_select_future_time'),
        );
        return;
      }

      // Format the time picker value
      final hour = _pickerTime.hour;
      final minute = _pickerTime.minute;
      final period = hour >= 12 ? 'PM' : 'AM';
      final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      final formattedTime =
          '${hour12.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
      Navigator.pop(context, formattedTime);
    } else if (_selectedTime != null) {
      Navigator.pop(context, _selectedTime);
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppDimens.padding),

            // Title
            if (widget.title != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppDimens.paddingM),
                child: AppText.title(
                  widget.title!,
                  fontWeight: FontWeight.w600,
                ),
              ),

            // Content based on selection type
            if (widget.scheduleTimeSelectionType ==
                ScheduleTimeSelectionType.timePicker)
              _buildTimePicker(colors)
            else
              _buildTimeSlotList(colors),

            // Buttons
            Padding(
              padding: const EdgeInsets.all(AppDimens.padding),
              child: Row(
                children: [
                  Expanded(
                    child: AppFilledButton(
                      text: getString(appStr.buttonDone, 'button_done'),
                      onPressed: _onSelectPressed,
                    ),
                  ),
                  const SizedBox(width: AppDimens.paddingM),
                  Expanded(
                    child: AppOutlinedButton(
                      text: getString(appStr.buttonCancel, 'button_cancel'),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker(dynamic colors) {
    final isPM = _pickerTime.period == DayPeriod.pm;

    return SizedBox(
      height: 200,
      child: Row(
        children: [
          // Hour picker
          Expanded(
            child: ListWheelScrollView.useDelegate(
              itemExtent: 40,
              perspective: 0.005,
              diameterRatio: 1.5,
              physics: const FixedExtentScrollPhysics(),
              controller: _hourController,
              onSelectedItemChanged: (index) {
                setState(() {
                  final hour12 = index + 1;
                  _pickerTime = TimeOfDay(
                    hour: _to24(hour12, _pickerTime.period == DayPeriod.pm),
                    minute: _pickerTime.minute,
                  );
                });
                _enforceMinTime();
              },
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: 12,
                builder: (context, index) {
                  final hour = index + 1;
                  final isSelected = (_pickerTime.hourOfPeriod == 0 ? 12 : _pickerTime.hourOfPeriod) == hour;
                  // Hour is disabled only if even its last minute (:59) is past.
                  final isDisabled = _isPast(_to24(hour, isPM), 59);
                  return Center(
                    child: AppText.body(
                      hour.toString().padLeft(2, '0'),
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isDisabled
                          ? colors.colorText.withValues(alpha: 0.3)
                          : colors.colorText,
                    ),
                  );
                },
              ),
            ),
          ),
          // Minute picker
          Expanded(
            child: ListWheelScrollView.useDelegate(
              itemExtent: 40,
              perspective: 0.005,
              diameterRatio: 1.5,
              physics: const FixedExtentScrollPhysics(),
              controller: _minuteController,
              onSelectedItemChanged: (index) {
                setState(() {
                  _pickerTime =
                      TimeOfDay(hour: _pickerTime.hour, minute: index);
                });
                _enforceMinTime();
              },
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: 60,
                builder: (context, index) {
                  final isSelected = _pickerTime.minute == index;
                  // Minute is disabled if it's past for the current hour.
                  final isDisabled = _isPast(_pickerTime.hour, index);
                  return Center(
                    child: AppText.body(
                      index.toString().padLeft(2, '0'),
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isDisabled
                          ? colors.colorText.withValues(alpha: 0.3)
                          : colors.colorText,
                    ),
                  );
                },
              ),
            ),
          ),
          // AM/PM picker
          Expanded(
            child: ListWheelScrollView.useDelegate(
              itemExtent: 40,
              perspective: 0.005,
              diameterRatio: 1.5,
              physics: const FixedExtentScrollPhysics(),
              controller: _ampmController,
              onSelectedItemChanged: (index) {
                setState(() {
                  final isPM = index == 1;
                  int newHour;
                  if (isPM && _pickerTime.hour < 12) {
                    newHour = _pickerTime.hour + 12;
                  } else if (!isPM && _pickerTime.hour >= 12) {
                    newHour = _pickerTime.hour - 12;
                  } else {
                    newHour = _pickerTime.hour;
                  }
                  _pickerTime =
                      TimeOfDay(hour: newHour, minute: _pickerTime.minute);
                });
                _enforceMinTime();
              },
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: 2,
                builder: (context, index) {
                  final text = index == 0 ? 'AM' : 'PM';
                  final isSelected = (index == 0 &&
                          _pickerTime.period == DayPeriod.am) ||
                      (index == 1 && _pickerTime.period == DayPeriod.pm);
                  // A period is disabled if even its latest time (best hour :59)
                  // is past — e.g. AM greyed out once now+buffer is in the PM.
                  final isDisabled = _isPast(index == 0 ? 11 : 23, 59);
                  return Center(
                    child: AppText.body(
                      text,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isDisabled
                          ? colors.colorText.withValues(alpha: 0.3)
                          : colors.colorText,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlotList(dynamic colors) {
    if (_timeSlots.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppDimens.paddingXL),
        child: AppText.body(
          'No time slots available',
          color: colors.colorText,
          textAlign: TextAlign.center,
        ),
      );
    }

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.4,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.padding),
        itemCount: _timeSlots.length,
        itemBuilder: (context, index) {
          final slot = _timeSlots[index];
          final isSelected = _selectedTime == slot.value;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedTime = slot.value;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: AppDimens.paddingM,
              ),
              alignment: Alignment.center,
              child: AppText.title(
                slot.display,
                fontSize: isSelected ? 20 : 16,
                color: isSelected ? colors.colorPrimary : colors.colorText,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }
}
