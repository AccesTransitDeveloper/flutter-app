/// Singleton class to hold booking related data
class BookingData {
  static String? createdBookingId;

  BookingData._();

  static void clear() {
    createdBookingId = null;
  }
}
