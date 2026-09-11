import '../../models/responses/booking/get_vehicle_type_response.dart';
import '../constants/app_constants.dart';

/// Utility class for schedule-related operations based on ride type
class ScheduleUtil {
  ScheduleUtil._();

  /// Gets max selectable booking days based on ride type
  static int getMaxSelectableDates(RideType? rideType, DriverSettings? driverSetting) {
    return switch (rideType) {
      RideType.normal => driverSetting?.normal?.schedule?.maxBookingDays ?? 0,
      RideType.rental => driverSetting?.rental?.schedule?.maxBookingDays ?? 0,
      RideType.sharing => driverSetting?.share?.schedule?.maxBookingDays ?? 0,
      RideType.fixGroup => driverSetting?.fixGroupBooking?.schedule?.maxBookingDays ?? 0,
      null => driverSetting?.normal?.schedule?.maxBookingDays ?? 0,
    };
  }

  /// Gets schedule time selection type based on ride type
  static int getScheduleTimeSelectionType(RideType? rideType, DriverSettings? driverSetting) {
    return switch (rideType) {
      RideType.normal => driverSetting?.normal?.schedule?.scheduleTimeSelectionType ?? 0,
      RideType.rental => driverSetting?.rental?.schedule?.scheduleTimeSelectionType ?? 0,
      RideType.sharing => driverSetting?.share?.schedule?.scheduleTimeSelectionType ?? 0,
      RideType.fixGroup => driverSetting?.fixGroupBooking?.schedule?.scheduleTimeSelectionType ?? 0,
      null => driverSetting?.normal?.schedule?.scheduleTimeSelectionType ?? 0,
    };
  }

  /// Gets slot interval in minutes based on ride type
  static int getSlotIntervalInMinutes(RideType? rideType, DriverSettings? driverSetting) {
    return switch (rideType) {
      RideType.normal => driverSetting?.normal?.schedule?.slotIntervalInMinutes ?? 0,
      RideType.rental => driverSetting?.rental?.schedule?.slotIntervalInMinutes ?? 0,
      RideType.sharing => driverSetting?.share?.schedule?.slotIntervalInMinutes ?? 0,
      RideType.fixGroup => driverSetting?.fixGroupBooking?.schedule?.slotIntervalInMinutes ?? 0,
      null => driverSetting?.normal?.schedule?.slotIntervalInMinutes ?? 0,
    };
  }

  /// Gets buffer time based on ride type
  static int getBufferTime(RideType? rideType, DriverSettings? driverSetting) {
    return switch (rideType) {
      RideType.normal => driverSetting?.normal?.schedule?.bufferTime ?? 0,
      RideType.rental => driverSetting?.rental?.schedule?.bufferTime ?? 0,
      RideType.sharing => driverSetting?.share?.schedule?.bufferTime ?? 0,
      RideType.fixGroup => driverSetting?.fixGroupBooking?.schedule?.bufferTime ?? 0,
      null => driverSetting?.normal?.schedule?.bufferTime ?? 0,
    };
  }
}
