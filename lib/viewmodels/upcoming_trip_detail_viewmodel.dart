import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/localization/app_strings.dart';
import '../core/managers/live_activity_manager.dart';
import '../core/constants/app_constants.dart';
import '../core/map/interface/map_interface.dart';
import '../core/map/models/map_types.dart';
import '../core/preferences/shared_preference_manager.dart';
import '../core/providers/app_providers.dart';
import '../core/utils/common_utils.dart';
import '../core/utils/date_utils.dart';
import '../core/utils/invoice_util.dart';
import '../data/api/response_state.dart';
import '../data/repository/app_repository.dart';
import '../models/requests/cancel_booking_request.dart';
import '../models/requests/get_vehicle_types_request.dart';
import '../models/responses/booking/booking_detail_response.dart';
import '../models/responses/booking/cancellation_charge_response.dart';
import '../models/responses/setting/cancellation_reason_response.dart';

/// Params for UpcomingTripDetailViewModel
class UpcomingTripDetailParams {
  final String bookingId;
  final MapInterface mapManager;
  final int primaryColor;

  const UpcomingTripDetailParams({
    required this.bookingId,
    required this.mapManager,
    required this.primaryColor,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UpcomingTripDetailParams && other.bookingId == bookingId;
  }

  @override
  int get hashCode => bookingId.hashCode;
}

/// Upcoming trip detail screen state
class UpcomingTripDetailState {
  final bool isLoading;
  final String? error;
  final BookingDetailResponse? response;
  final BookingDetails? booking;

  // Formatted display fields
  final String? priceStr;
  final String? distanceStr;
  final String? dateTimeStr;
  final String? estimatedTimeStr;
  final String statusLabel;

  // Address list
  final List<DestinationAddress> addressList;

  // Flags
  final bool isDriveDetailVisible;
  final bool isAllowCancelBooking;
  final bool isAllowCall;
  final Set<CustomerBookingSettings> activeSetting;

  // Cancel flow
  final List<CancellationReason> cancellationReasons;
  final bool isCancelLoading;
  final CancellationChargeResponse? cancellationCharge;
  final String? cancelError;
  final bool isCancelled;

  const UpcomingTripDetailState({
    this.isLoading = false,
    this.error,
    this.response,
    this.booking,
    this.priceStr,
    this.distanceStr,
    this.dateTimeStr,
    this.estimatedTimeStr,
    this.statusLabel = '',
    this.addressList = const [],
    this.isDriveDetailVisible = false,
    this.isAllowCancelBooking = false,
    this.isAllowCall = false,
    this.activeSetting = const {},
    this.cancellationReasons = const [],
    this.isCancelLoading = false,
    this.cancellationCharge,
    this.cancelError,
    this.isCancelled = false,
  });

  UpcomingTripDetailState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    BookingDetailResponse? response,
    BookingDetails? booking,
    String? priceStr,
    String? distanceStr,
    String? dateTimeStr,
    String? estimatedTimeStr,
    String? statusLabel,
    List<DestinationAddress>? addressList,
    bool? isDriveDetailVisible,
    bool? isAllowCancelBooking,
    bool? isAllowCall,
    Set<CustomerBookingSettings>? activeSetting,
    List<CancellationReason>? cancellationReasons,
    bool? isCancelLoading,
    CancellationChargeResponse? cancellationCharge,
    String? cancelError,
    bool clearCancelError = false,
    bool? isCancelled,
  }) {
    return UpcomingTripDetailState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      response: response ?? this.response,
      booking: booking ?? this.booking,
      priceStr: priceStr ?? this.priceStr,
      distanceStr: distanceStr ?? this.distanceStr,
      dateTimeStr: dateTimeStr ?? this.dateTimeStr,
      estimatedTimeStr: estimatedTimeStr ?? this.estimatedTimeStr,
      statusLabel: statusLabel ?? this.statusLabel,
      addressList: addressList ?? this.addressList,
      isDriveDetailVisible:
          isDriveDetailVisible ?? this.isDriveDetailVisible,
      isAllowCancelBooking:
          isAllowCancelBooking ?? this.isAllowCancelBooking,
      isAllowCall: isAllowCall ?? this.isAllowCall,
      activeSetting: activeSetting ?? this.activeSetting,
      cancellationReasons:
          cancellationReasons ?? this.cancellationReasons,
      isCancelLoading: isCancelLoading ?? this.isCancelLoading,
      cancellationCharge: cancellationCharge ?? this.cancellationCharge,
      cancelError:
          clearCancelError ? null : (cancelError ?? this.cancelError),
      isCancelled: isCancelled ?? this.isCancelled,
    );
  }
}

/// Upcoming trip detail screen ViewModel (active bookings via main API)
class UpcomingTripDetailViewModel
    extends StateNotifier<UpcomingTripDetailState> {
  final AppRepository _appRepository;
  final SharedPreferenceManager _sharedPref;
  final UpcomingTripDetailParams _params;

  String get bookingId => _params.bookingId;

  UpcomingTripDetailViewModel(
    this._appRepository,
    this._sharedPref,
    this._params,
  ) : super(const UpcomingTripDetailState()) {
    _getBookingDetails();
  }

  Future<void> _getBookingDetails() async {
    state = state.copyWith(isLoading: true);

    final response = await _appRepository.getBookingDetails(bookingId);

    switch (response) {
      case Success<BookingDetailResponse>():
        final data = response.data;
        final booking = data?.booking;
        if (booking == null) {
          state =
              state.copyWith(isLoading: false, error: '');
          return;
        }
        _processBookingDetails(data!, booking);

      case Error<BookingDetailResponse>():
        state = state.copyWith(
          isLoading: false,
          error: response.error?.message,
        );

      case Loading<BookingDetailResponse>():
        break;
    }
  }

  void _processBookingDetails(
      BookingDetailResponse data, BookingDetails booking) {
    final invoice = booking.bookingInvoice;
    final currencyDirection = invoice?.setCurrencySign ?? 1;
    final currencySign = invoice?.currencySign ?? '';
    final decimalPointValue = invoice?.decimalPointValue ?? 2;

    // Price — use bid price if bidding, otherwise estimated total
    String? priceStr;
    if (booking.biddingDetail?.isBidding == true) {
      final bidPrice = (booking.biddingDetail?.finalBidPrice ?? 0) > 0
          ? booking.biddingDetail?.finalBidPrice
          : booking.biddingDetail?.customerBidPrice;
      priceStr = (bidPrice ?? 0).toDouble().applyPriceSetting(
        currencyDirection: currencyDirection,
        currencySign: currencySign,
        decimalPointValue: decimalPointValue,
      );
    } else {
      final total = invoice?.estimated?.total;
      priceStr = total.applyPriceSetting(
        currencyDirection: currencyDirection,
        currencySign: currencySign,
        decimalPointValue: decimalPointValue,
      );
    }

    // Distance (value is in meters, convert to km or miles)
    String? distanceStr;
    final distanceInMeters = invoice?.estimated?.distance;
    if (distanceInMeters != null) {
      final distanceUnit = invoice?.distanceUnit ?? 0;
      final isMiles = distanceUnit == DistanceUnit.miles;
      final convertedDistance = isMiles
          ? distanceInMeters / 1609.344
          : distanceInMeters / 1000.0;
      final unit = isMiles ? 'mi' : 'km';
      distanceStr = '${convertedDistance.toStringAsFixed(2)} $unit';
    }

    // Estimated time (seconds → minutes)
    String? estimatedTimeStr;
    final timeInSeconds = invoice?.estimated?.time;
    if (timeInSeconds != null && timeInSeconds > 0) {
      final minutes = (timeInSeconds / 60).ceil();
      estimatedTimeStr = '$minutes min';
    }

    // DateTime (booking time)
    String? dateTimeStr;
    if (booking.bookingTime != null) {
      final date = DateTime.fromMillisecondsSinceEpoch(booking.bookingTime!);
      dateTimeStr =
          AppDateUtils.format(date, DateFormat.dayMonthTimeYearFormat);
    }

    // Status label
    final statusLabel =
        BookingStatus.fromValue(booking.status).name;

    // Address list
    final addressList = <DestinationAddress>[];
    if (booking.pickupAddress != null) {
      addressList.add(booking.pickupAddress!);
    }
    if (booking.destinationAddresses != null) {
      addressList.addAll(booking.destinationAddresses!);
    }

    // Resolve settings by booking status (same pattern as current_ride_viewmodel)
    final customerBookingSetting = data.citySetting?.customerBookingSetting;
    final bookingStatus = BookingStatus.fromValue(booking.status);

    final List<String>? settingList = switch (bookingStatus) {
      BookingStatus.requested => customerBookingSetting?.requested,
      BookingStatus.assigned => customerBookingSetting?.assigned,
      BookingStatus.accepted => customerBookingSetting?.accepted,
      BookingStatus.inRoute => customerBookingSetting?.inRoute,
      BookingStatus.arrivedAtPickup => customerBookingSetting?.arrivedAtPickup,
      BookingStatus.started => customerBookingSetting?.started,
      BookingStatus.arrivedAtStop => customerBookingSetting?.arrivedAtStop,
      BookingStatus.arrivedAtDestination =>
        customerBookingSetting?.arrivedAtDestination,
      BookingStatus.arrivedNearDestination =>
        customerBookingSetting?.arrivedNearDestination,
      BookingStatus.serviceCompleted =>
        customerBookingSetting?.serviceCompleted,
      BookingStatus.merchantAccepted =>
        customerBookingSetting?.merchantAccepted,
      BookingStatus.merchantPreparing =>
        customerBookingSetting?.merchantPreparing,
      BookingStatus.merchantCompleted =>
        customerBookingSetting?.merchantCompleted,
      _ => null,
    };

    final activeSetting = (settingList ?? [])
        .map((value) => CustomerBookingSettings.fromSetting(value))
        .toSet();

    state = state.copyWith(
      isLoading: false,
      response: data,
      booking: booking,
      priceStr: priceStr,
      distanceStr: distanceStr,
      dateTimeStr: dateTimeStr,
      estimatedTimeStr: estimatedTimeStr,
      statusLabel: statusLabel,
      addressList: addressList,
      isDriveDetailVisible: booking.confirmedDriver != null,
      isAllowCancelBooking: data.isAllowCancelBooking ?? false,
      isAllowCall: data.isAllowCall ?? false,
      activeSetting: activeSetting,
    );

    // Show route on map
    _showRouteOnMap(booking);
  }

  // TODO: Extract shared map route logic (duplicated in TripDetailViewModel and ActivityScreen)
  void _showRouteOnMap(BookingDetails booking) {
    final mapManager = _params.mapManager;
    final primaryColor = _params.primaryColor;

    // Markers
    final markers = <MapMarker>[];
    final boundsPoints = <LatLng>[];

    // Pickup marker
    final pickup = booking.pickupAddress;
    if (pickup != null && pickup.latitude != null && pickup.longitude != null) {
      final pos = LatLng(pickup.latitude!, pickup.longitude!);
      markers.add(MapMarker(
        id: 'pickup',
        position: pos,
        title: '',
        snippet: pickup.address,
        iconAsset: 'assets/images/ic_pickup.png',
        iconWidth: 32,
        iconHeight: 32,
        iconColor: primaryColor,
      ));
      boundsPoints.add(pos);
    }

    // Destination markers
    final destinations = booking.destinationAddresses ?? [];
    for (int i = 0; i < destinations.length; i++) {
      final dest = destinations[i];
      if (dest.latitude != null && dest.longitude != null) {
        final pos = LatLng(dest.latitude!, dest.longitude!);
        final isLast = i == destinations.length - 1;
        markers.add(MapMarker(
          id: 'destination_$i',
          position: pos,
          title: '',
          snippet: dest.address,
          iconAsset: isLast ? 'assets/images/ic_drop_off.png' : null,
          iconWidth: isLast ? 32 : 20,
          iconHeight: isLast ? 32 : 20,
          iconColor: primaryColor,
          stopNumber: isLast ? null : i + 1,
        ));
        boundsPoints.add(pos);
      }
    }

    mapManager.setMarkers(markers);

    // Polyline from direction path
    final directionPath = booking.bookingInvoice?.estimated?.directionPath;
    if (directionPath != null && directionPath.isNotEmpty) {
      mapManager.setPolyline(MapPolyline.fromEncoded(
        encoded: directionPath,
        color: primaryColor,
      ));
    }

    // Fit camera to show all points
    if (boundsPoints.isNotEmpty) {
      mapManager.fitBounds(boundsPoints, padding: 80);
    }
  }

  /// Fetch cancellation reasons
  Future<void> getCancellationReasons() async {
    state = state.copyWith(isCancelLoading: true, clearCancelError: true);

    final businessType =
        state.booking?.businessType ?? BusinessType.taxi;
    // Native sends businessType only (MyBookingDetailsViewModel), no `type`.
    final response = await _appRepository.getCancellationReasons({
      'businessType': businessType.toString(),
    });

    switch (response) {
      case Success<CancellationReasonResponse>():
        // Always offer "Others" with a free-text box, exactly like the running
        // trip's cancel sheet and native. Without it an empty server list left
        // the sheet with no options at all and the booking uncancellable.
        final reasons = [
          ...?response.data?.cancellationReasons,
          CancellationReason(
            reasons: getString(appStr.descriptionOthers, 'description_others'),
          ),
        ];

        state = state.copyWith(
          isCancelLoading: false,
          cancellationReasons: reasons,
        );

      case Error<CancellationReasonResponse>():
        state = state.copyWith(
          isCancelLoading: false,
          cancelError: response.error?.message,
        );

      case Loading<CancellationReasonResponse>():
        break;
    }
  }

  /// Get cancellation charges
  Future<void> getCancellationCharges() async {
    state = state.copyWith(isCancelLoading: true, clearCancelError: true);

    final response =
        await _appRepository.getCancellationCharges(bookingId);

    switch (response) {
      case Success<CancellationChargeResponse>():
        state = state.copyWith(
          isCancelLoading: false,
          cancellationCharge: response.data,
        );

      case Error<CancellationChargeResponse>():
        state = state.copyWith(
          isCancelLoading: false,
          cancelError: response.error?.message,
        );

      case Loading<CancellationChargeResponse>():
        break;
    }
  }

  /// Cancel booking with a reason
  Future<bool> cancelBooking(String reason) async {
    state = state.copyWith(isCancelLoading: true, clearCancelError: true);

    final request = CancelBookingRequest(
      bookingId: bookingId,
      cancellationReason: reason,
    );
    final response =
        await _appRepository.cancelBooking(bookingId, request);

    switch (response) {
      case Success<dynamic>():
        // Cancelling from trip detail leaves no running-ride screen to do this,
        // so the live surface for this booking has to be dropped here too.
        await LiveActivityManager.instance.stopActivity(bookingId);
        state = state.copyWith(
          isCancelLoading: false,
          isCancelled: true,
        );
        return true;

      case Error<dynamic>():
        state = state.copyWith(
          isCancelLoading: false,
          cancelError: response.error?.message,
        );
        return false;

      case Loading<dynamic>():
        return false;
    }
  }

  /// Check if server-side calling is allowed
  bool get _isAllowCall => state.isAllowCall;

  /// Dial a phone number using system dialer
  Future<void> _dialPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  /// Call driver via API (masked) or direct dial
  Future<void> callDriver() async {
    if (!_isAllowCall) {
      final phone = state.booking?.confirmedDriver?.phone ?? '';
      if (phone.isNotEmpty) {
        _dialPhone(phone);
      }
      return;
    }

    final response = await _appRepository.calling(bookingId);

    switch (response) {
      case Success<dynamic>():
        break;

      case Error<dynamic>():
        state = state.copyWith(
          cancelError: response.error?.message,
        );

      case Loading<dynamic>():
        break;
    }
  }

  /// Call support via API (masked) or direct dial
  Future<void> callSupport() async {
    if (!_isAllowCall) {
      final phone =
          _sharedPref.getSetting()?.contactDetail?.phone ?? '';
      if (phone.isNotEmpty) {
        _dialPhone(phone);
      }
      return;
    }

    await _appRepository.supportCalling();
  }
}

/// Provider for UpcomingTripDetailViewModel
final upcomingTripDetailViewModelProvider = StateNotifierProvider.autoDispose
    .family<UpcomingTripDetailViewModel, UpcomingTripDetailState,
        UpcomingTripDetailParams>((ref, params) {
  final appRepository = ref.watch(appRepositoryProvider);
  final sharedPref = ref.watch(sharedPreferenceManagerProvider).maybeWhen(
        data: (data) => data,
        orElse: () => throw Exception('SharedPreferences not initialized'),
      );
  return UpcomingTripDetailViewModel(appRepository, sharedPref, params);
});
