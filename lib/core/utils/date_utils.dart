import 'package:intl/intl.dart' as intl;
import 'package:timezone/timezone.dart' as tz;

import '../constants/app_constants.dart';

/// Stores selected date/time for fixed group booking
class FixedGroupDateTime {
  static int? selectedDateMillis;
  static int? selectedDepartureTimeHour;
  static int? selectedDepartureTimeMinute;
  static int? selectedReturnTimeHour;
  static int? selectedReturnTimeMinute;

  static void clear() {
    selectedDateMillis = null;
    selectedDepartureTimeHour = null;
    selectedDepartureTimeMinute = null;
    selectedReturnTimeHour = null;
    selectedReturnTimeMinute = null;
  }
}

/// Utility class for date formatting throughout the app
class AppDateUtils {
  static const List<String> _monthsShort = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  static const List<String> _monthsFull = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  static const List<String> _weekdaysShort = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
  ];

  /// Parse date string from API
  static DateTime? parse(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  /// Format date using specified DateFormat enum
  static String format(DateTime? date, DateFormat format) {
    if (date == null) return '';

    switch (format) {
      case DateFormat.dateOnlyFormat:
        return _formatDateOnly(date);
      case DateFormat.dateFormatWithSpace:
        return _formatDateWithSpace(date);
      case DateFormat.dateMonthWithSpace:
        return _formatDateMonthWithSpace(date);
      case DateFormat.dateTimeFormat:
        return _formatDateTime(date);
      case DateFormat.dayMonthTimeYearFormat:
        return _formatDayMonthTimeYear(date);
      case DateFormat.hourMinuteFormat:
        return _formatHourMinute(date);
      case DateFormat.dateMonthHourMinuteFormat:
        return _formatDateMonthHourMinute(date);
      case DateFormat.weekdayAndTime:
        return _formatWeekdayAndTime(date);
      case DateFormat.apiFormat:
      case DateFormat.apiDateFormat:
        return date.toIso8601String();
    }
  }

  /// Format date string from API using specified DateFormat enum
  /// Converts UTC to local time before formatting
  static String formatString(String? dateString, DateFormat format) {
    final date = convertUtcToLocal(dateString ?? '');
    return AppDateUtils.format(date, format);
  }

  /// Get 12-hour format hour
  static int _get12Hour(int hour) {
    if (hour == 0) return 12;
    if (hour > 12) return hour - 12;
    return hour;
  }

  /// Get AM/PM period
  static String _getPeriod(int hour) {
    return hour >= 12 ? 'PM' : 'AM';
  }

  /// dd-MM-yyyy
  static String _formatDateOnly(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    return '$day-$month-$year';
  }

  /// dd MMM yyyy
  static String _formatDateWithSpace(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = _monthsShort[date.month - 1];
    final year = date.year;
    return '$day $month $year';
  }

  /// dd MMM
  static String _formatDateMonthWithSpace(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = _monthsShort[date.month - 1];
    return '$day $month';
  }

  /// dd-MM-yyyy hh:mm a
  static String _formatDateTime(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    final hour = _get12Hour(date.hour).toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final period = _getPeriod(date.hour);
    return '$day-$month-$year $hour:$minute $period';
  }

  /// d MMM yyyy, hh:mm a
  static String _formatDayMonthTimeYear(DateTime date) {
    final day = date.day;
    final month = _monthsShort[date.month - 1];
    final year = date.year;
    final hour = _get12Hour(date.hour).toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final period = _getPeriod(date.hour);
    return '$day $month $year, $hour:$minute $period';
  }

  /// hh:mm a
  static String _formatHourMinute(DateTime date) {
    final hour = _get12Hour(date.hour).toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final period = _getPeriod(date.hour);
    return '$hour:$minute $period';
  }

  /// dd MMMM, hh:mm a
  static String _formatDateMonthHourMinute(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = _monthsFull[date.month - 1];
    final hour = _get12Hour(date.hour).toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final period = _getPeriod(date.hour);
    return '$day $month, $hour:$minute $period';
  }

  /// EEE hh:mm a
  static String _formatWeekdayAndTime(DateTime date) {
    final weekday = _weekdaysShort[date.weekday - 1];
    final hour = _get12Hour(date.hour).toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final period = _getPeriod(date.hour);
    return '$weekday $hour:$minute $period';
  }

  /// Get month year string (e.g., "January 2024")
  static String getMonthYear(DateTime date) {
    return '${_monthsFull[date.month - 1]} ${date.year}';
  }

  /// Get month year from date string
  static String getMonthYearFromString(String? dateString) {
    final date = parse(dateString);
    if (date == null) return '';
    return getMonthYear(date);
  }

  /// Format date to yyyy-MM-dd (for API submission)
  static String toApiDateString(DateTime? date) {
    if (date == null) return '';
    final year = date.year;
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  // ============= NEW METHODS FROM KOTLIN DateUtils =============

  static const String _mmmDdYyyy = 'MMM dd yyyy';

  /// Format date for API submission with time set to 23:59:59 UTC
  static String? dateFormationForSubmit(String? dateString) {
    if (dateString == null) return null;
    try {
      final inputFormat = intl.DateFormat(_mmmDdYyyy);
      var date = inputFormat.parse(dateString);
      date = addTimeToDate(date, 23, 59, 59);
      return convertLocalToUtc(date);
    } catch (e) {
      return null;
    }
  }

  /// Convert UTC date string to local date string (MMM dd yyyy format)
  static String? utcToShowLocalDate(String? dateString) {
    if (dateString == null) return null;
    try {
      final localDate = convertUtcToLocal(dateString);
      if (localDate == null) return null;
      final newDateFormat = intl.DateFormat(_mmmDdYyyy);
      return newDateFormat.format(localDate);
    } catch (e) {
      return '';
    }
  }

  /// Convert UTC date string to local milliseconds
  static int? utcToShowLocalDateMilliseconds(String? dateString) {
    if (dateString == null) return null;
    try {
      final localDate = convertUtcToLocal(dateString);
      return localDate?.millisecondsSinceEpoch;
    } catch (e) {
      return 0;
    }
  }

  /// Convert milliseconds to formatted date string (MMM dd yyyy)
  static String millisecondsToFormattedDateOnlyString(int milliseconds) {
    final sdf = intl.DateFormat(_mmmDdYyyy);
    final date = DateTime.fromMillisecondsSinceEpoch(milliseconds);
    return sdf.format(date);
  }

  /// Convert UTC date string to local formatted string (dd MMM, hh:mm a)
  static String dateConvertToLocalFormattedString(String? dateString) {
    if (dateString == null) return '';
    try {
      final localDate = convertUtcToLocal(dateString);
      if (localDate == null) return '';
      return _formatDateMonthTime(localDate);
    } catch (e) {
      return '';
    }
  }

  /// Format as "dd MMM, hh:mm a" using dynamic time format
  static String _formatDateMonthTime(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = _monthsShort[date.month - 1];
    final hour = _get12Hour(date.hour).toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final period = _getPeriod(date.hour);
    return '$day $month, $hour:$minute $period';
  }

  /// Convert UTC date string to local month year format (MMMM yyyy)
  static String dateConvertToLocalMonthYear(String? dateString) {
    if (dateString == null) return '';
    try {
      final localDate = convertUtcToLocal(dateString);
      if (localDate == null) return '';
      return getMonthYear(localDate);
    } catch (e) {
      return '';
    }
  }

  /// Convert UTC datetime string to local DateTime
  static DateTime? convertUtcToLocal(String utcDateTime) {
    try {
      final utcDate = DateTime.parse(utcDateTime).toUtc();
      return utcDate.toLocal();
    } catch (e) {
      return null;
    }
  }

  /// Convert local DateTime to UTC string
  static String convertLocalToUtc(DateTime localDateTime) {
    try {
      final utcDate = localDateTime.toUtc();
      return utcDate.toIso8601String();
    } catch (e) {
      return '';
    }
  }

  /// Change date format between two DateFormat enums
  static String changeDateFormat(
    DateFormat inputDateFormat,
    DateFormat outputFormat,
    String dateString,
  ) {
    try {
      final date = DateTime.parse(dateString).toUtc();
      return format(date.toLocal(), outputFormat);
    } catch (e) {
      return '';
    }
  }

  /// Check if date is valid (today or future)
  static bool isValidDate(int selectedDateMillis) {
    const millisPerDay = 24 * 60 * 60 * 1000;
    return selectedDateMillis >
        DateTime.now().millisecondsSinceEpoch - millisPerDay;
  }

  /// Add time to a date
  static DateTime addTimeToDate(
    DateTime date,
    int hours,
    int minutes,
    int seconds,
  ) {
    return date.add(Duration(hours: hours, minutes: minutes, seconds: seconds));
  }

  /// Format expiry date for card input (MM/YY)
  static String formatExpiryDateForCard(String input) {
    var formatted = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (formatted.length > 2) {
      formatted = '${formatted.substring(0, 2)}/${formatted.substring(2)}';
    }
    return formatted;
  }

  /// Get start of day timestamp (00:00:00.000)
  static int getStartOfDay(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final startOfDay = DateTime(date.year, date.month, date.day);
    return startOfDay.millisecondsSinceEpoch;
  }

  /// Get end of day timestamp (23:59:59.999)
  static int getEndOfDay(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
    return endOfDay.millisecondsSinceEpoch;
  }

  /// Convert a wall-clock [dateTime] (the time the user picked on screen) into
  /// epoch milliseconds, interpreting the clock components in [ianaTimeZone]
  /// (the selected city's timezone). Matches the native user app `currentTimeMillis(in:)`.
  ///
  /// Example: user picks 9:30 AM and [ianaTimeZone] is "America/New_York" — the
  /// returned epoch is for 9:30 AM New York time, regardless of the device's own
  /// timezone. Falls back to the device-local epoch when the zone is
  /// null/empty/unknown.
  static int wallClockToEpochMillis(DateTime dateTime, String? ianaTimeZone) {
    if (ianaTimeZone == null || ianaTimeZone.isEmpty) {
      return dateTime.millisecondsSinceEpoch;
    }
    try {
      final location = tz.getLocation(ianaTimeZone);
      final zoned = tz.TZDateTime(
        location,
        dateTime.year,
        dateTime.month,
        dateTime.day,
        dateTime.hour,
        dateTime.minute,
        dateTime.second,
      );
      return zoned.millisecondsSinceEpoch;
    } catch (_) {
      // Unknown timezone identifier — fall back to device-local epoch.
      return dateTime.millisecondsSinceEpoch;
    }
  }

  /// Get start of day DateTime
  static DateTime getStartOfDayDateTime(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Get end of day DateTime
  static DateTime getEndOfDayDateTime(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }
}
