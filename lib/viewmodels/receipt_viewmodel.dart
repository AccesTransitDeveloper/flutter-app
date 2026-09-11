import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/common_utils.dart';
import '../core/utils/invoice_util.dart';
import '../core/utils/time_util.dart';
import '../data/api/response_state.dart';
import '../data/repository/app_repository.dart';
import '../models/invoice.dart';
import '../models/responses/booking/accessibility_response.dart';
import '../models/responses/booking/booking_detail_response.dart';

/// State for the Receipt screen
class ReceiptState {
  final bool isLoading;
  final String bookingId;
  final String bookingPrice;
  final String customerName;
  final String rideDate;
  final String paymentDate;
  final int paymentMode;
  final List<Invoice> invoiceList;
  final bool isMinFareApplied;
  final String distance;
  final String time;
  final String payment;
  final String waitingTime;
  final String stopWaitingTime;
  final String trafficTime;
  final Set<CustomerBookingSettings> activeSetting;
  final String snackBarMessage;
  final String? error;

  const ReceiptState({
    this.isLoading = false,
    this.bookingId = '',
    this.bookingPrice = '',
    this.customerName = '',
    this.rideDate = '',
    this.paymentDate = '',
    this.paymentMode = 0,
    this.invoiceList = const [],
    this.isMinFareApplied = false,
    this.distance = '',
    this.time = '',
    this.payment = '',
    this.waitingTime = '',
    this.stopWaitingTime = '',
    this.trafficTime = '',
    this.activeSetting = const {},
    this.snackBarMessage = '',
    this.error,
  });

  ReceiptState copyWith({
    bool? isLoading,
    String? bookingId,
    String? bookingPrice,
    String? customerName,
    String? rideDate,
    String? paymentDate,
    int? paymentMode,
    List<Invoice>? invoiceList,
    bool? isMinFareApplied,
    String? distance,
    String? time,
    String? payment,
    String? waitingTime,
    String? stopWaitingTime,
    String? trafficTime,
    Set<CustomerBookingSettings>? activeSetting,
    String? snackBarMessage,
    String? error,
    bool clearError = false,
  }) {
    return ReceiptState(
      isLoading: isLoading ?? this.isLoading,
      bookingId: bookingId ?? this.bookingId,
      bookingPrice: bookingPrice ?? this.bookingPrice,
      customerName: customerName ?? this.customerName,
      rideDate: rideDate ?? this.rideDate,
      paymentDate: paymentDate ?? this.paymentDate,
      paymentMode: paymentMode ?? this.paymentMode,
      invoiceList: invoiceList ?? this.invoiceList,
      isMinFareApplied: isMinFareApplied ?? this.isMinFareApplied,
      distance: distance ?? this.distance,
      time: time ?? this.time,
      payment: payment ?? this.payment,
      waitingTime: waitingTime ?? this.waitingTime,
      stopWaitingTime: stopWaitingTime ?? this.stopWaitingTime,
      trafficTime: trafficTime ?? this.trafficTime,
      activeSetting: activeSetting ?? this.activeSetting,
      snackBarMessage: snackBarMessage ?? this.snackBarMessage,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// ViewModel for the Receipt screen
/// Matches Kotlin InvoiceViewModel logic
class ReceiptViewModel extends StateNotifier<ReceiptState> {
  final AppRepository _appRepository;
  final BookingDetailResponse _bookingDetailResponse;

  late final BookingInvoice? _bookingInvoice;
  late final InvoiceDetail? _actual;
  late final InvoiceUtil _invoiceUtil;

  ReceiptViewModel(
    this._appRepository,
    this._bookingDetailResponse,
  ) : super(const ReceiptState()) {
    _loadInvoice();
  }

  void _loadInvoice() {
    final booking = _bookingDetailResponse.booking;
    _bookingInvoice = booking?.bookingInvoice;
    final actual = _bookingInvoice?.actual;
    _actual = actual;

    if (actual == null) return;

    final setCurrencySign = _bookingInvoice?.setCurrencySign ?? SetCurrencySign.left;
    final currencySign = _bookingInvoice?.currencySign ?? '';
    final decimalPointValue = _bookingInvoice?.decimalPointValue ?? 0;

    _invoiceUtil = InvoiceUtil(
      currencyDirection: setCurrencySign,
      currencySign: currencySign,
      decimalPointValue: decimalPointValue,
      distanceUnit: _bookingInvoice?.distanceUnit,
    );

    // Booking ID
    final bookingId = booking?.uniqueId ?? '';

    // Customer name
    final customerName = booking?.customerDetail?.name ?? '';

    // Ride date & payment date
    final rideDate = _formatRideDate(booking?.completedAt ?? booking?.bookingTime);
    final paymentDate = _formatPaymentDate(booking?.completedAt ?? booking?.bookingTime);

    // Payment mode raw value
    final paymentModeValue = _bookingInvoice?.paymentMode ?? 0;

    // Total price
    final bookingPrice = actual.total?.applyPriceSetting(
          currencyDirection: setCurrencySign,
          currencySign: currencySign,
          decimalPointValue: decimalPointValue,
        ) ??
        '';

    // Distance
    final distance = actual.distance != null
        ? '${actual.distance!.toStringAsFixed(1)} ${DistanceUnit.getUnit(_bookingInvoice?.distanceUnit)}'
        : '';

    // Time
    final time = TimeUtil.formattedTime(actual.time ?? 0);

    // Payment mode name
    final payment =
        PaymentGatewayType.fromValue(_bookingInvoice?.paymentMode)?.getName() ??
            '';

    // Waiting times
    final waitingTime =
        TimeUtil.formattedTime((actual.waitingTime ?? 0).toInt());
    final stopWaitingTime =
        TimeUtil.formattedTime((actual.stopWaitingTime ?? 0).toInt());
    final trafficTime =
        TimeUtil.formattedTime((actual.trafficTime ?? 0).toInt());

    // Invoice line items
    final invoiceList =
        _invoiceUtil.getInvoiceElements(invoiceData: actual);

    // Min fare applied
    final isMinFareApplied = actual.isMinFareApplied ?? false;

    // Active customer booking settings
    final activeSetting = _resolveActiveSettings();

    state = state.copyWith(
      bookingId: bookingId,
      bookingPrice: bookingPrice,
      customerName: customerName,
      rideDate: rideDate,
      paymentDate: paymentDate,
      paymentMode: paymentModeValue,
      distance: distance,
      time: time,
      payment: payment,
      waitingTime: waitingTime,
      stopWaitingTime: stopWaitingTime,
      trafficTime: trafficTime,
      invoiceList: invoiceList,
      isMinFareApplied: isMinFareApplied,
      activeSetting: activeSetting,
    );

    // Fetch accessibility names if needed
    if ((actual.accessibilityPrices?.isNotEmpty == true) ||
        (actual.additionalPrices?.isNotEmpty == true)) {
      _getAccessibility();
    }
  }

  /// Resolve active customer booking settings based on booking status
  /// Matches Kotlin setCustomerBookingSetting()
  Set<CustomerBookingSettings> _resolveActiveSettings() {
    final booking = _bookingDetailResponse.booking;
    final customerBookingSetting =
        _bookingDetailResponse.citySetting?.customerBookingSetting;

    if (customerBookingSetting != null) {
      final bookingStatus = BookingStatus.fromValue(booking?.status);
      final settingList = switch (bookingStatus) {
        BookingStatus.requested => customerBookingSetting.requested,
        BookingStatus.assigned => customerBookingSetting.assigned,
        BookingStatus.accepted => customerBookingSetting.accepted,
        BookingStatus.inRoute => customerBookingSetting.inRoute,
        BookingStatus.arrivedAtPickup => customerBookingSetting.arrivedAtPickup,
        BookingStatus.started => customerBookingSetting.started,
        BookingStatus.arrivedAtStop => customerBookingSetting.arrivedAtStop,
        BookingStatus.arrivedAtDestination =>
          customerBookingSetting.arrivedAtDestination,
        _ => null,
      };

      if (settingList != null) {
        return settingList
            .map((value) => CustomerBookingSettings.fromSetting(value))
            .toSet();
      }
    }

    // Fallback: for taxi business type show all relevant settings
    if (booking?.businessType == BusinessType.taxi) {
      return {
        CustomerBookingSettings.showTotalTimeAndDistance,
        CustomerBookingSettings.showWaitingTime,
        CustomerBookingSettings.showStopWaitingTime,
        CustomerBookingSettings.showTrafficTime,
      };
    }

    return {
      CustomerBookingSettings.showTotalTimeAndDistance,
    };
  }

  /// Fetch accessibility names to update invoice line item titles
  /// Matches Kotlin getAccessibility()
  Future<void> _getAccessibility() async {
    state = state.copyWith(isLoading: true);

    final response = await _appRepository.getAccessibility();

    if (!mounted) return;

    switch (response) {
      case Success<AccessibilityResponse>():
        state = state.copyWith(isLoading: false);

        final accessibilities = response.data?.accessibilities ?? [];
        final customPrices = response.data?.customPrices ?? [];

        // Build accessibility list (id → name mapping)
        final accessibilityList = accessibilities
            .map((a) => MapEntry(a.id ?? '', a.accessibility ?? ''))
            .toList()
          ..addAll(
            customPrices.map((c) => MapEntry(c.id ?? '', c.title ?? '')),
          );

        // Re-run invoice elements with accessibility names
        final invoiceList = _invoiceUtil.getInvoiceElements(
          invoiceData: _actual,
          accessibilityList: accessibilityList,
        );

        state = state.copyWith(invoiceList: invoiceList);

      case Error<AccessibilityResponse>():
        state = state.copyWith(isLoading: false);
        _showSnackBar(response.error?.message ?? '');

      case Loading<AccessibilityResponse>():
        break;
    }
  }

  static const List<String> _monthsFull = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  /// Format timestamp to "MMMM dd, yyyy" (e.g., "June 14, 2025")
  static String _formatRideDate(int? millis) {
    if (millis == null || millis == 0) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(millis);
    return '${_monthsFull[date.month - 1]} ${date.day.toString().padLeft(2, '0')}, ${date.year}';
  }

  /// Format timestamp to "M/dd/yy hh:mm a" (e.g., "6/14/25 10:04 PM")
  static String _formatPaymentDate(int? millis) {
    if (millis == null || millis == 0) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(millis);
    final hour = date.hour == 0 ? 12 : (date.hour > 12 ? date.hour - 12 : date.hour);
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${date.month}/${date.day.toString().padLeft(2, '0')}/${date.year.toString().substring(2)} ${hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} $period';
  }

  void _showSnackBar(String message) {
    state = state.copyWith(snackBarMessage: message);
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        state = state.copyWith(snackBarMessage: '');
      }
    });
  }
}

/// Provider for ReceiptViewModel
final receiptViewModelProvider = StateNotifierProvider.autoDispose
    .family<ReceiptViewModel, ReceiptState, BookingDetailResponse>(
        (ref, bookingDetailResponse) {
  final appRepository = ref.watch(appRepositoryProvider);
  return ReceiptViewModel(appRepository, bookingDetailResponse);
});
