import 'package:intl/intl.dart';

import '../../models/day_setting.dart';
import '../localization/app_strings.dart';
import '../localization/string_constants.dart';
import 'validator/validator.dart';

/// Utility class for time-related operations
class TimeUtil {
  TimeUtil._();

  /// Format seconds to localized time string (e.g., "5 min")
  static String formattedTime(int seconds) {
    var mins = (seconds / 60).ceil();
    if (mins == 0) {
      mins = 1;
    }

    final finalTime = getString(
      appStr.descriptionUnitValue,
      'description_unit_value',
    ).replacePlaceholders({
      StringConstant.unitValue: mins,
      StringConstant.unit: getString(
        appStr.descriptionMinutesUnit,
        'description_minutes_unit',
      ),
    });

    return finalTime;
  }

  /// Convert seconds to "X Hr Y Min Z Sec" format
  static String convertSecondsToHMS(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;

    if (hours > 0) {
      return '$hours Hr ${minutes.toString().padLeft(2, '0')} Min ${remainingSeconds.toString().padLeft(2, '0')} Sec';
    } else if (minutes > 0) {
      return '${minutes.toString().padLeft(2, '0')} Min ${remainingSeconds.toString().padLeft(2, '0')} Sec';
    } else {
      return '${remainingSeconds.toString().padLeft(2, '0')} Sec';
    }
  }

  /// Create start DateTime for time slot generation
  static DateTime createStartDateTime(
    DateTime selectedDate,
    int slotDiffInMinutes,
    int bufferMinutes,
  ) {
    final now = DateTime.now();
    var nowPlusBuffer = now.add(Duration(minutes: bufferMinutes));

    // Round up to nearest slotDiff
    final roundedMinute =
        ((nowPlusBuffer.minute + slotDiffInMinutes - 1) ~/ slotDiffInMinutes) *
        slotDiffInMinutes;

    nowPlusBuffer = DateTime(
      nowPlusBuffer.year,
      nowPlusBuffer.month,
      nowPlusBuffer.day,
      nowPlusBuffer.hour,
      roundedMinute,
    );

    // Start of selected date
    final selectedDateStart = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );

    return selectedDateStart.isAfter(nowPlusBuffer)
        ? selectedDateStart
        : nowPlusBuffer;
  }

  /// Check if there are available time slots for a given date
  static bool hasAvailableSlot({
    required DateTime date,
    required int bufferMinutes,
    required int slotDiffMinutes,
    DaySetting? daySetting,
  }) {
    final startDateTime = createStartDateTime(
      date,
      slotDiffMinutes,
      bufferMinutes,
    );

    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

    final slots = buildTimeSlots(
      startDateTime: startDateTime,
      endOfDay: endOfDay,
      selectedScheduleDate: date,
      slotDiffInMinutes: slotDiffMinutes,
      bufferMinutes: bufferMinutes,
      showRange: false,
      daySetting: daySetting,
    );

    return slots.isNotEmpty;
  }

  /// Build list of time slots
  /// Returns list of (displayText, rawValue) pairs
  static List<TimeSlotItem> buildTimeSlots({
    required DateTime startDateTime,
    required DateTime endOfDay,
    required DateTime selectedScheduleDate,
    required int slotDiffInMinutes,
    required int bufferMinutes,
    required bool showRange,
    DaySetting? daySetting,
  }) {
    final slots = <TimeSlotItem>[];
    final timeFormat = ValidatorConfig.timeFormat;
    final displayFormat = DateFormat(timeFormat);
    final outputFormat = DateFormat(timeFormat);

    if (startDateTime.day != selectedScheduleDate.day) {
      return slots;
    }

    if (daySetting?.isAllowFullDay == false && daySetting?.time != null) {
      // Sort time slots by start time
      final sortedTimeSlots = List<TimeSlot>.from(daySetting!.time!)
        ..sort((a, b) => (a.startTime ?? 0).compareTo(b.startTime ?? 0));

      for (final timeSlot in sortedTimeSlots) {
        final currentMinuteOfDay =
            startDateTime.hour * 60 + startDateTime.minute;
        final startTime = timeSlot.startTime ?? 0;
        final endTime = timeSlot.endTime ?? 0;

        if (currentMinuteOfDay > endTime) {
          continue;
        }

        final actualStartMinute = _calculateActualStartMinute(
          currentMinuteOfDay,
          startTime,
          slotDiffInMinutes,
        );

        var cal = _createDateTimeForMinuteOfDay(
          selectedScheduleDate,
          actualStartMinute,
        );
        final endCal = _createDateTimeForMinuteOfDay(
          selectedScheduleDate,
          endTime,
        );

        while (cal.isBefore(endCal)) {
          final nowPlusBuffer = DateTime.now().add(
            Duration(minutes: bufferMinutes),
          );

          if (cal.isAfter(nowPlusBuffer)) {
            slots.add(
              _createSlot(
                cal,
                slotDiffInMinutes,
                displayFormat,
                outputFormat,
                showRange,
              ),
            );
          }
          cal = cal.add(Duration(minutes: slotDiffInMinutes));
        }
      }
    } else {
      // Full day allowed
      var cal = startDateTime;
      while (cal.isBefore(endOfDay)) {
        slots.add(
          _createSlot(
            cal,
            slotDiffInMinutes,
            displayFormat,
            outputFormat,
            showRange,
          ),
        );
        cal = cal.add(Duration(minutes: slotDiffInMinutes));
      }
    }

    return slots;
  }

  static int _calculateActualStartMinute(
    int currentMinuteOfDay,
    int startTime,
    int slotDiffInMinutes,
  ) {
    final maxStart =
        currentMinuteOfDay > startTime ? currentMinuteOfDay : startTime;
    final roundedUp =
        ((maxStart + slotDiffInMinutes - 1) ~/ slotDiffInMinutes) *
        slotDiffInMinutes;
    return roundedUp > startTime ? roundedUp : startTime;
  }

  static DateTime _createDateTimeForMinuteOfDay(
    DateTime date,
    int minuteOfDay,
  ) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      minuteOfDay ~/ 60,
      minuteOfDay % 60,
    );
  }

  static TimeSlotItem _createSlot(
    DateTime cal,
    int slotDiffInMinutes,
    DateFormat displayFormat,
    DateFormat outputFormat,
    bool showRange,
  ) {
    final rawStart = outputFormat.format(cal);
    final displayStart = displayFormat.format(cal);

    final endCal = cal.add(Duration(minutes: slotDiffInMinutes));
    final displayEnd = displayFormat.format(endCal);

    final display = showRange ? '$displayStart - $displayEnd' : displayStart;

    return TimeSlotItem(display: display, value: rawStart);
  }

  /// Get day settings for a specific date from a map
  /// Key is day of week (0 = Sunday, 1 = Monday, etc.)
  static DaySetting? getDaySettingsForDate(
    DateTime date,
    Map<String, DaySetting>? daySettings,
  ) {
    if (daySettings == null || daySettings.isEmpty) return null;

    // DateTime.weekday: Monday = 1, Sunday = 7
    // Convert to: Sunday = 0, Monday = 1, etc.
    final key = (date.weekday % 7).toString();

    return daySettings[key];
  }

  /// Format duration in minutes to "X hr Y min" format
  static String formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;

    if (hours > 0 && mins > 0) {
      return '$hours hr $mins min';
    } else if (hours > 0) {
      return '$hours hr';
    } else {
      return '$mins min';
    }
  }
}

/// Time slot item with display text and raw value
class TimeSlotItem {
  final String display;
  final String value;

  const TimeSlotItem({
    required this.display,
    required this.value,
  });
}
