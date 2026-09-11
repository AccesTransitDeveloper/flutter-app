import '../localization/app_strings.dart';

class AppConstants {
  // Production URLs
  static const String apiBaseUrl = 'https://api.accessibletransit.com/api/';
  static const String imageBaseUrl =
      'https://accessibletransit.s3.us-east-1.amazonaws.com/';
  static const String historyBaseUrl =
      'https://history.accessibletransit.com/api/';
  static const String socketBaseUrl = 'https://socket.accessibletransit.com/';

  // Payment
  static String stripePublishableKey = '';

  // Demo URLs
  static const String demoApiBaseUrl = 'https://api.accessibletransit.com/api/';
  static const String demoImageBaseUrl = 'https://api.accessibletransit.com/';
  static const String demoHistoryBaseUrl =
      'https://demohistory.accessibletransit.com/api/';
  static const String demoSocketBaseUrl =
      'https://demosocket.accessibletransit.com/';

  // Local development ports
  static const int apiPort = 4000;
  static const int historyPort = 4001;
  static const int socketPort = 4002;
}

class BusinessType {
  static const int taxi = 1;
  static const int quickDelivery = 2;
  static const int delivery = 3;
  static const int service = 4;
  static const int courier = 5;
}

/// Entity type constants (matches Kotlin Entity object)
class EntityType {
  static const int admin = 1;
  static const int customer = 2;
  static const int driver = 3;
  static const int partner = 4;
  static const int dispatcher = 5;
  static const int corporate = 6;
  static const int merchant = 7;
  static const int picker = 17;
}

enum ChatType {
  SUPPORT_CHAT,
  CUSTOMER_DRIVER_CHAT,
  CUSTOMER_MERCHANT_CHAT,
  DRIVER_MERCHANT_CHAT,
}

/// Transfer using constants (matches Kotlin TransferUsing)
class TransferUsing {
  static const int qrCode = 1;
  static const int phoneNumber = 2;
}

class LoginBy {
  static const int email = 1;
  static const int phone = 2;
  static const int otp = 4;
  static const int password = 5;
  static const int google = 6;
  static const int apple = 7;
}

class OtpSendMode {
  static const int sms = 1;
  static const int email = 2;
  static const int smsEmail = 3;
}

/// Ride type enum with localized strings
enum RideType {
  normal(1, 'description_normal'),
  sharing(2, 'description_share'),
  rental(3, 'description_rental'),
  fixGroup(7, 'description_fix_group_booking');

  final int value;
  final String stringKey;

  const RideType(this.value, this.stringKey);

  /// Get localized name for display
  String getName() {
    final appStrValue = switch (this) {
      RideType.normal => appStr.descriptionNormal,
      RideType.sharing => appStr.descriptionShare,
      RideType.rental => appStr.descriptionRental,
      RideType.fixGroup => appStr.descriptionFixGroupBooking,
    };
    return getString(appStrValue, stringKey);
  }

  /// Get RideType from int value, returns null if not found
  static RideType? fromValue(int? value) {
    if (value == null) return null;
    return RideType.values.where((t) => t.value == value).firstOrNull;
  }
}

enum Gender {
  none(''),
  male('MALE'),
  female('FEMALE');

  final String value;
  const Gender(this.value);

  static Gender fromValue(String? value) {
    if (value == null || value.isEmpty) return Gender.none;
    return Gender.values.firstWhere(
      (g) => g.value.toUpperCase() == value.toUpperCase(),
      orElse: () => Gender.none,
    );
  }
}

/// Date format patterns used throughout the app
enum DateFormat {
  apiFormat("yyyy-MM-dd'T'HH:mm:ss.SSSZ"),
  apiDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"),
  dateOnlyFormat('dd-MM-yyyy'),
  dateFormatWithSpace('dd MMM yyyy'),
  dateMonthWithSpace('dd MMM'),
  dateTimeFormat('dd-MM-yyyy hh:mm a'),
  dayMonthTimeYearFormat('d MMM yyyy, hh:mm a'),
  hourMinuteFormat('hh:mm a'),
  dateMonthHourMinuteFormat('dd MMMM, hh:mm a'),
  weekdayAndTime('EEE hh:mm a');

  final String value;
  const DateFormat(this.value);
}

/// Support ticket status constants
class SupportTicketStatus {
  static const String open = 'OPEN';
  static const String closed = 'CLOSED';
  static const String reopen = 'REOPEN';
  static const String cancelled = 'CANCELLED';
}

/// Device type constants
class DeviceType {
  static const String android = 'ANDROID';
  static const String ios = 'IOS';
}

/// User type constants
class UserType {
  static const int customer = 2;
}

/// Notification type constants
class NotificationType {
  static const int push = 3;
}

/// Address type constants
class AddressType {
  static const int home = 1;
  static const int work = 2;
  static const int other = 3;
}

/// Schedule time selection type constants
class ScheduleTimeSelectionType {
  static const int timePicker = 1;
  static const int slot = 2;
  static const int slotRange = 3;
}

/// Payment purpose type constants
class PaymentPurposeType {
  static const int addWallet = 1;
  static const int bookingPayment = 2;
  static const int tipPayment = 3;
  static const int splitPayment = 4;
  static const int cancelBookingPayment = 5;
  static const int addCard = 6;
  static const int preBookingPayment = 8;
  static const int fixedGroupRidePayment = 11;
}

/// Payment transaction status constants
class PaymentTransactionStatus {
  static const int pending = 1;
  static const int initiated = 2;
  static const int paid = 3;
  static const int failed = 4;
  static const int cancelled = 5;
  static const int refunded = 6;
  static const int captureRequired = 7;
}

/// Entity type status constants (matches Kotlin EntityTypeStatus)
class EntityTypeStatus {
  static const int pending = 1;
  static const int decline = 2;
  static const int approve = 3;
  static const int block = 4;
  static const int available = 6;
  static const int inBooking = 7;
  static const int availableForShare = 8;
  static const int nearAvailable = 9;
}

/// Booking setting constants
class BookingSettingConstant {
  static const String allowPromoCode = 'AllowPromocode';
  static const String showNearestDriver = 'ShowNearestDriver';
  static const String showFareEstimation = 'ShowFareEstimation';
  static const String showFareEstimationInDetail = 'ShowFareEstimationInDetail';
  static const String showDriverEstimation = 'ShowDriverEstimation';
  static const String allowCorporateBooking = 'AllowCorporateBooking';
  static const String allowRideForOther = 'AllowRideForOther';
  static const String tip = 'Tip';
  static const String showPassengerCapacity = 'ShowPassengerCapacity';
  static const String showLuggageCapacity = 'ShowLuggageCapacity';
  static const String allowProductWiseRating = 'AllowProductWiseRating';
  static const String showProductWiseRating = 'ShowProductWiseRating';
}

/// Payment gateway type constants
enum PaymentGatewayType {
  cash(1, 'description_cash'),
  wallet(2, 'description_wallet'),
  stripe(3, 'description_stripe'),
  paystack(4, 'description_paystack'),
  razorpay(5, 'description_razorpay'),
  mercado(7, 'description_mercado_pago'),
  payu(8, 'description_payu'),
  pago(9, 'description_pago'),
  pagoC2p(10, 'description_pago'),
  zaincash(11, 'description_zaincash'),
  hyperpay(12, 'description_hyperpay'),
  nestpay(13, 'description_nestpay'),
  qicard(14, 'description_qicard'),
  mpesa(15, 'description_mpesa');

  final int value;
  final String stringKey;

  const PaymentGatewayType(this.value, this.stringKey);

  String getName() {
    final appStrValue = switch (this) {
      PaymentGatewayType.cash => appStr.descriptionCash,
      PaymentGatewayType.wallet => appStr.descriptionWallet,
      PaymentGatewayType.stripe => appStr.descriptionStripe,
      PaymentGatewayType.paystack => appStr.descriptionPaystack,
      PaymentGatewayType.razorpay => appStr.descriptionRazorpay,
      PaymentGatewayType.mercado => appStr.descriptionMercadoPago,
      PaymentGatewayType.payu => appStr.descriptionPayu,
      PaymentGatewayType.pago => appStr.descriptionPago,
      PaymentGatewayType.pagoC2p => appStr.descriptionPago,
      PaymentGatewayType.zaincash => appStr.descriptionZaincash,
      PaymentGatewayType.hyperpay => appStr.descriptionHyperpay,
      PaymentGatewayType.nestpay => appStr.descriptionNestpay,
      PaymentGatewayType.qicard => appStr.descriptionQicard,
      PaymentGatewayType.mpesa => appStr.descriptionMpesa,
    };
    return getString(appStrValue, stringKey);
  }

  static PaymentGatewayType? fromValue(int? value) {
    if (value == null) return null;
    return PaymentGatewayType.values.cast<PaymentGatewayType?>().firstWhere(
          (type) => type?.value == value,
          orElse: () => null,
        );
  }
}

/// Booking status enum
enum BookingStatus {
  requested(1),
  assigned(10),
  noDriverFound(11),
  notAnswered(12),
  rejected(13),
  merchantAccepted(14),
  noPickerFound(16),
  merchantPreparing(141),
  merchantCompleted(142),
  accepted(20),
  bidding(21),
  pickerCompleted(24),
  inRoute(30),
  arrivedAtPickup(40),
  picked(41),
  dropped(42),
  started(50),
  serviceCompleted(55),
  arrivedAtStop(60),
  arrivedNearDestination(65),
  arrivedAtDestination(70),
  cancelled(90),
  merchantRejected(91),
  unknown(-1);

  final int value;

  const BookingStatus(this.value);

  /// Get BookingStatus from int value, returns unknown if not found
  static BookingStatus fromValue(int? value) {
    if (value == null) return BookingStatus.unknown;
    return BookingStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => BookingStatus.unknown,
    );
  }
}

/// History filter type constants
class HistoryFilterType {
  static const int last7Days = 0;
  static const int currentMonth = 1;
  static const int previousMonth = 2;
  static const int previous6Months = 3;
  static const int specificDates = 4;
}

/// Customer booking settings enum
enum CustomerBookingSettings {
  showShareRide('ShowShareRide'),
  allowCallToDriver('AllowCallToDriver'),
  allowCallToSupport('AllowCallToSupport'),
  allowChatWithDriver('AllowChatWithDriver'),
  allowCallToMerchant('AllowCallToMerchant'),
  allowChatWithMerchant('AllowChatWithMerchant'),
  allowSos('AllowSos'),
  showRating('ShowRating'),
  showMerchantRating('ShowMerchantRating'),
  showDriverArrivedEstimation('ShowDriverArrivedEstimation'),
  showWaitingTime('ShowWaitingTime'),
  showTotalTimeAndDistance('ShowTotalTimeandDistance'),
  otpVerification('OtpVerification'),
  showNewDriverTag('ShowNewDriverTag'),
  showCarPhotos('ShowCarPhotos'),
  showTotalFare('ShowTotalFare'),
  showStopWaitingTime('ShowStopWaitingTime'),
  showTrafficTime('ShowTrafficTime'),
  allowEditAddress('AllowEditAddress'),
  unknown('');

  final String setting;

  const CustomerBookingSettings(this.setting);

  static CustomerBookingSettings fromSetting(String? setting) {
    if (setting == null || setting.isEmpty) return CustomerBookingSettings.unknown;
    return CustomerBookingSettings.values.firstWhere(
      (s) => s.setting == setting,
      orElse: () => CustomerBookingSettings.unknown,
    );
  }
}

/// Credit status constants (wallet transactions)
class CreditStatus {
  static const int added = 1;
  static const int deducted = 2;
}

/// Credit transaction type constants (wallet transactions)
class CreditTransactionType {
  static const int referralBonus = 1;
  static const int referrerBonus = 2;
  static const int digitalPayment = 3;
  static const int fromAdmin = 4;
  static const int tipPayment = 5;
  static const int toFriend = 6;
  static const int fromFriend = 7;
  static const int rewardPointWithdraw = 8;
  static const int penalty = 9;
  static const int bookingPayment = 10;
  static const int cancelBookingPayment = 11;
  static const int bookingProfit = 12;
  static const int incentive = 13;
  static const int bankTransfer = 14;
  static const int refund = 15;
  static const int subscription = 16;
  static const int fixGroupBooking = 18;
}

/// Penalty type constants
class PenaltyType {
  static const String rideCancellation = 'RIDE_CANCELLATION';
  static const String lowRating = 'LOW_RATING';
  static const String missedRides = 'MISSED_RIDES';
}

/// Booking tags enum
enum BookingTags {
  normal('NORMAL', 'description_normal'),
  share('SHARE', 'description_share'),
  rental('RENTAL', 'description_rental'),
  openBooking('OPEN_BOOKING', 'description_open_booking'),
  now('NOW', 'description_now'),
  schedule('SCHEDULE', 'description_schedule'),
  bidding('BIDDING', 'description_bidding'),
  multipleLocation('MULTIPLE_LOCATION', 'description_multiple_location'),
  fixFare('FIX_FARE', 'description_fix_fare'),
  cityToCity('CITY_TO_CITY', 'description_city_to_city'),
  zone('ZONE', 'description_zone'),
  airport('AIRPORT', 'description_airport'),
  destinationLater('DESTINATION_LATER', 'description_destination_later'),
  splitPayment('SPLIT_PAYMENT', 'description_split_payment'),
  returnTag('RETURN', 'description_return'),
  redZone('RED_ZONE', 'description_red_zone'),
  guestToken('GUEST_TOKEN', 'description_guest_token'),
  outsideBoundary('OUTSIDE_BOUNDARY', 'description_outside_boundary'),
  fixGroupBooking('FIX_GROUP_BOOKING', 'description_fix_group_booking'),
  weekly('WEEKLY', 'description_weekly'),
  unknown('', '');

  final String tag;
  final String stringKey;

  const BookingTags(this.tag, this.stringKey);

  /// Get localized name for display
  String getName() {
    final appStrValue = switch (this) {
      BookingTags.normal => appStr.descriptionNormal,
      BookingTags.share => appStr.descriptionShare,
      BookingTags.rental => appStr.descriptionRental,
      BookingTags.openBooking => appStr.descriptionOpenBooking,
      BookingTags.now => appStr.descriptionNow,
      BookingTags.schedule => appStr.descriptionSchedule,
      BookingTags.bidding => appStr.descriptionBidding,
      BookingTags.multipleLocation => appStr.descriptionMultipleLocation,
      BookingTags.fixFare => appStr.descriptionFixFare,
      BookingTags.cityToCity => appStr.descriptionCityToCity,
      BookingTags.zone => appStr.descriptionZone,
      BookingTags.airport => appStr.descriptionAirport,
      BookingTags.destinationLater => appStr.descriptionDestinationLater,
      BookingTags.splitPayment => appStr.descriptionSplitPayment,
      BookingTags.returnTag => appStr.descriptionReturn,
      BookingTags.redZone => appStr.descriptionRedZone,
      BookingTags.guestToken => appStr.descriptionGuestToken,
      BookingTags.outsideBoundary => appStr.descriptionOutsideBoundary,
      BookingTags.fixGroupBooking => appStr.descriptionFixGroupBooking,
      BookingTags.weekly => appStr.descriptionWeekly,
      BookingTags.unknown => null,
    };
    return getString(appStrValue, stringKey);
  }

  static BookingTags fromValue(String? tag) {
    if (tag == null || tag.isEmpty) return BookingTags.unknown;
    return BookingTags.values.firstWhere(
      (t) => t.tag == tag,
      orElse: () => BookingTags.unknown,
    );
  }
}