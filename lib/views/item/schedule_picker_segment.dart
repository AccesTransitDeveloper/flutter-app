import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/schedule_util.dart';
import '../../models/day_setting.dart';
import '../../models/responses/booking/get_vehicle_type_response.dart';
import '../bottomsheets/schedule_date_picker_bottom_sheet.dart';
import '../bottomsheets/time_slot_picker_bottom_sheet.dart';

/// Result from the schedule picker flow
class SchedulePickerResult {
  final DateTime date;
  final String time;
  final DateTime dateTime;

  SchedulePickerResult({
    required this.date,
    required this.time,
    required this.dateTime,
  });

  /// Returns formatted display string like "Today, 2:30 PM" or "Mon, 15 Jan, 2:30 PM"
  String get displayText {
    final now = DateTime.now();
    final isToday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
    final tomorrow = now.add(const Duration(days: 1));
    final isTomorrow = date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day;

    if (isToday) {
      return 'Today, $time';
    } else if (isTomorrow) {
      return 'Tomorrow, $time';
    } else {
      return '${_formatDate(date)}, $time';
    }
  }

  static String _formatDate(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dayName = days[date.weekday - 1];
    final monthName = months[date.month - 1];
    return '$dayName, ${date.day} $monthName';
  }
}

/// Reusable schedule picker that handles the full flow:
/// 1. Show date picker
/// 2. After date selected, show time picker
/// 3. Return the combined result
class SchedulePickerSegment {
  SchedulePickerSegment._();

  /// Check if scheduling is available using BusinessSettings
  /// This is the correct way to check - uses citySetting.businessSettings
  static bool isScheduleAvailableFromBusiness({
    required RideType? rideType,
    required BusinessSettings? businessSettings,
  }) {
    return _checkBusinessAvailability(
      availability: 'SCHEDULE',
      rideType: rideType,
      businessSettings: businessSettings,
    );
  }

  /// Check if "Now" booking is available using BusinessSettings
  /// This is the correct way to check - uses citySetting.businessSettings
  static bool isNowAvailableFromBusiness({
    required RideType? rideType,
    required BusinessSettings? businessSettings,
  }) {
    return _checkBusinessAvailability(
      availability: 'NOW',
      rideType: rideType,
      businessSettings: businessSettings,
    );
  }

  /// Check if multiple locations (adding stops) is available using BusinessSettings.
  /// Mirrors native `businessSetting.contains(.multipleLocation)` (raw 'MULTIPLE_LOCATION').
  static bool isMultipleLocationAvailableFromBusiness({
    required RideType? rideType,
    required BusinessSettings? businessSettings,
  }) {
    return _checkBusinessAvailability(
      availability: 'MULTIPLE_LOCATION',
      rideType: rideType,
      businessSettings: businessSettings,
    );
  }

  /// Helper to check availability from BusinessSettings
  static bool _checkBusinessAvailability({
    required String availability,
    required RideType? rideType,
    required BusinessSettings? businessSettings,
  }) {
    if (businessSettings == null) return false;

    final settingsList = switch (rideType) {
      RideType.normal => businessSettings.normal,
      RideType.rental => businessSettings.rental,
      RideType.sharing => businessSettings.share,
      RideType.fixGroup => businessSettings.fixGroupBooking,
      null => businessSettings.normal,
    };

    return settingsList?.contains(availability) == true;
  }

  /// Check if scheduling is available for the given ride type
  /// @deprecated Use isScheduleAvailableFromBusiness instead
  static bool isScheduleAvailable({
    required RideType? rideType,
    required DriverSettings? driverSettings,
  }) {
    final maxDays = ScheduleUtil.getMaxSelectableDates(rideType, driverSettings);
    return maxDays > 0;
  }

  /// Check if "Now" booking is available for the given ride type
  /// @deprecated Use isNowAvailableFromBusiness instead
  static bool isNowAvailable({
    required RideType? rideType,
    required DriverSettings? driverSettings,
  }) {
    // Check if NOW setting exists for this ride type
    return switch (rideType) {
      RideType.normal => driverSettings?.normal?.now != null,
      RideType.rental => driverSettings?.rental?.now != null,
      RideType.sharing => driverSettings?.share?.now != null,
      RideType.fixGroup => driverSettings?.fixGroupBooking?.now != null,
      null => driverSettings?.normal?.now != null,
    };
  }

  /// Show the complete schedule picker flow
  /// Returns null if user cancels at any point
  static Future<SchedulePickerResult?> show({
    required BuildContext context,
    required RideType? rideType,
    required DriverSettings? driverSettings,
    Map<String, DaySetting>? daySettings,
    DateTime? initialDate,
    String? datePickerTitle,
    String? timePickerTitle,
  }) async {
    if (driverSettings == null) return null;

    // Get schedule settings based on ride type
    final maxBookingDays = ScheduleUtil.getMaxSelectableDates(rideType, driverSettings);
    final scheduleTimeSelectionType = ScheduleUtil.getScheduleTimeSelectionType(rideType, driverSettings);
    final slotIntervalInMinutes = ScheduleUtil.getSlotIntervalInMinutes(rideType, driverSettings);
    final bufferTime = ScheduleUtil.getBufferTime(rideType, driverSettings);

    if (maxBookingDays <= 0) return null;

    // Step 1: Show date picker
    final selectedDate = await ScheduleDatePickerBottomSheet.show(
      context: context,
      maxBookingDays: maxBookingDays,
      scheduleTimeSelectionType: scheduleTimeSelectionType,
      slotIntervalInMinutes: slotIntervalInMinutes,
      bufferTime: bufferTime,
      daySettings: daySettings,
      initialDate: initialDate,
    );

    if (selectedDate == null || !context.mounted) return null;

    // Step 2: Show time picker
    final selectedTime = await TimeSlotPickerBottomSheet.show(
      context: context,
      selectedDate: selectedDate,
      scheduleTimeSelectionType: scheduleTimeSelectionType,
      slotIntervalInMinutes: slotIntervalInMinutes,
      bufferTime: bufferTime,
      daySettings: daySettings,
      title: timePickerTitle,
    );

    if (selectedTime == null) return null;

    // Parse time and combine with date
    final dateTime = _combineDateTime(selectedDate, selectedTime);

    return SchedulePickerResult(
      date: selectedDate,
      time: selectedTime,
      dateTime: dateTime,
    );
  }

  /// Combine date and time string into a single DateTime
  static DateTime _combineDateTime(DateTime date, String timeString) {
    // Try to parse time in format "HH:mm AM/PM" or "HH:mm"
    try {
      final parts = timeString.split(' ');
      final timeParts = parts[0].split(':');
      var hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      // Handle AM/PM
      if (parts.length > 1) {
        final period = parts[1].toUpperCase();
        if (period == 'PM' && hour != 12) {
          hour += 12;
        } else if (period == 'AM' && hour == 12) {
          hour = 0;
        }
      }

      return DateTime(date.year, date.month, date.day, hour, minute);
    } catch (_) {
      // If parsing fails, return date with current time
      final now = DateTime.now();
      return DateTime(date.year, date.month, date.day, now.hour, now.minute);
    }
  }
}
