import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/constants/socket_constants.dart';
import '../core/localization/app_strings.dart';
import '../core/localization/string_constants.dart';
import '../core/managers/live_activity_manager.dart';
import '../core/managers/socket_manager.dart';
import '../core/preferences/shared_preference_manager.dart';
import '../core/providers/app_providers.dart';
import '../core/map/interface/map_interface.dart';
import '../core/utils/address_validation_util.dart';
import '../core/utils/common_utils.dart';
import '../core/utils/time_util.dart';
import '../core/map/models/map_types.dart';
import '../data/api/response_state.dart';
import '../data/api/server_config.dart';
import '../data/repository/app_repository.dart';
import '../data/repository/socket_repository.dart';
import '../models/responses/booking/accessibility_preference.dart';
import '../models/responses/booking/accessibility_response.dart' as acc;
import '../models/responses/booking/booking_detail_response.dart';
import '../models/responses/booking/get_vehicle_type_response.dart';
import '../models/responses/socket/socket_response.dart';
import '../models/requests/bidding_accept_request.dart';
import '../models/requests/cancel_booking_request.dart';
import '../models/requests/get_vehicle_types_request.dart';
import '../models/requests/submit_invoice_request.dart';
import '../models/requests/wallet_payment_request.dart';
import '../models/webview_data_model.dart';
import '../models/chat/chat_socket_models.dart';
import '../models/responses/payment/card_response.dart';
import '../core/payments/payment_interface.dart';
import '../core/payments/stripe_payment_manager.dart';
import '../core/payments/paystack_manager.dart';
import '../core/payments/webview_payment_manager.dart';

/// State for the Current Ride screen
class CurrentRideState {
  final bool isLoading;
  final String? error;
  final BookingDetailResponse? bookingDetail;
  final Set<CustomerBookingSettings> activeSetting;
  final String? driverTimeEstimation;
  final String? totalDistance;
  final String? etaText;
  final String? trafficTimeStr;
  final bool isNoDriverFound;
  /// Waiting time display string (e.g., "Waiting time: 00:05")
  final String? waitingTimeStr;
  /// Stop waiting time display string (e.g., "Stop Time: 00:05")
  final String? stopWaitingTimeStr;
  /// Total time display string (e.g., "00:05")
  final String? totalTimeStr;
  /// Accessibility list for fare estimation (id → title mapping)
  final List<MapEntry<String, String>> accessibilityList;
  /// Custom prices from accessibility API (for fare estimation title mapping)
  final List<CustomPrice>? customPrices;
  /// Accessibilities from API (for fare estimation title mapping)
  final List<AccessibilityPreference>? accessibilities;
  /// OTP/PIN verification code for the ride
  final String? verificationCode;
  /// Whether to show OTP verification
  final bool showOtpVerification;
  /// Whether to show no provider found bottom sheet
  final bool showNoProviderFoundSheet;
  /// Whether to navigate to home (booking cancelled without no driver found)
  final bool shouldNavigateToHome;
  /// Whether to show invoice bottom sheet content
  final bool showInvoice;
  /// Whether pre-booking payment is required
  final bool isPreBookingPayment;
  /// Whether advance payment limit applies (partial payment scenario)
  final bool isAdvancePaymentLimit;
  /// Whether invoice is already paid
  final bool isInvoicePaid;
  /// Formatted invoice price string for display
  final String? invoicePrice;
  /// Payment mode (e.g., cash, card, wallet)
  final int? paymentMode;
  /// Payment settings for the booking
  final BookingPaymentSetting? myBookingPaymentSetting;
  /// Loading state for submit invoice
  final bool isSubmitInvoiceLoading;
  /// Whether previous payment failed
  final bool isSubmitInvoiceFailed;
  /// Whether to navigate to feedback screen after successful payment
  final bool isNavigateToFeedback;
  /// Whether to show pay by cash button
  final bool showPayByCashButton;
  /// Whether to navigate to WebView for payment
  final bool isNavigateToWebView;
  /// WebView data for payment (URL or HTML content)
  final WebViewDataModel? navigateURL;
  /// Invoice total price (numeric value for API calls)
  final double? invoiceTotalPrice;
  /// Whether payment failed from payment gateway
  final bool isPaymentFailFromPaymentGateway;
  /// Whether to navigate to home after payment
  final bool isNavigateToHome;
  /// Snackbar message to display
  final String? snackBarMessage;
  /// Whether snackbar is showing an error
  final bool isSnackBarError;
  /// Unread message count for chat badge
  final int unreadMessageCount;
  /// Whether to navigate to chat screen
  final bool isNavigateToChat;
  /// Whether to show call options bottom sheet
  final bool showCallOptionsBottomSheet;
  /// Whether driver calling API is loading
  final bool isDriverCallingLoading;
  /// Whether support calling API is loading
  final bool isSupportCallingLoading;
  /// Whether cancel button should be shown (based on cancelUptoStatus and isAllowCancelBooking)
  final bool isShowCancelButton;
  /// Whether to show cancel trip bottom sheet
  final bool showCancelTripBottomSheet;
  /// Whether cancel trip API is loading
  final bool isCancelTripLoading;
  /// List of cancellation reasons from API
  final List<String> cancellationReasonList;
  /// Formatted cancellation charge string
  final String cancellationCharge;
  /// Selected card from payment screen (matching Kotlin selectedCard)
  final CardResponse? selectedCard;
  /// Whether to show bidding request list
  final bool isShowBiddingRequest;
  /// List of driver bids
  final List<Bid> biddingList;
  /// Countdown timer string for bid rejection (e.g., "02:30")
  final String? bidRequestTimeStr;
  /// Customer's bid price for display
  final double? customerBidPrice;
  /// Formatted customer bid price string (with currency)
  final String? formattedCustomerBidPrice;
  /// Whether destination can be changed (DESTINATION_LATER tag or empty destinations)
  final bool isChangeDestinationAvailable;
  /// Loading state for edit address API call
  final bool isEditAddressLoading;

  const CurrentRideState({
    this.isLoading = false,
    this.error,
    this.bookingDetail,
    this.activeSetting = const {},
    this.driverTimeEstimation,
    this.totalDistance,
    this.etaText,
    this.trafficTimeStr,
    this.isNoDriverFound = false,
    this.waitingTimeStr,
    this.stopWaitingTimeStr,
    this.totalTimeStr,
    this.accessibilityList = const [],
    this.customPrices,
    this.accessibilities,
    this.verificationCode,
    this.showOtpVerification = false,
    this.showNoProviderFoundSheet = false,
    this.shouldNavigateToHome = false,
    this.showInvoice = false,
    this.isPreBookingPayment = false,
    this.isAdvancePaymentLimit = false,
    this.isInvoicePaid = false,
    this.invoicePrice,
    this.paymentMode,
    this.myBookingPaymentSetting,
    this.isSubmitInvoiceLoading = false,
    this.isSubmitInvoiceFailed = false,
    this.isNavigateToFeedback = false,
    this.showPayByCashButton = false,
    this.isNavigateToWebView = false,
    this.navigateURL,
    this.invoiceTotalPrice,
    this.isPaymentFailFromPaymentGateway = false,
    this.isNavigateToHome = false,
    this.snackBarMessage,
    this.isSnackBarError = false,
    this.unreadMessageCount = 0,
    this.isNavigateToChat = false,
    this.showCallOptionsBottomSheet = false,
    this.isDriverCallingLoading = false,
    this.isSupportCallingLoading = false,
    this.isShowCancelButton = false,
    this.showCancelTripBottomSheet = false,
    this.isCancelTripLoading = false,
    this.cancellationReasonList = const [],
    this.cancellationCharge = '',
    this.selectedCard,
    this.isShowBiddingRequest = false,
    this.biddingList = const [],
    this.bidRequestTimeStr,
    this.customerBidPrice,
    this.formattedCustomerBidPrice,
    this.isChangeDestinationAvailable = false,
    this.isEditAddressLoading = false,
  });

  /// Get the current booking status
  BookingStatus get bookingStatus =>
      BookingStatus.fromValue(bookingDetail?.booking?.status);

  /// Get trip status text based on current booking status
  String get tripStatusText {
    if (bookingStatus.value < BookingStatus.accepted.value) {
      return getString(
        appStr.headingConnectingNearbyDrivers,
        'heading_connecting_nearby_drivers',
      );
    }
    return switch (bookingStatus) {
      BookingStatus.accepted => getString(
        appStr.descriptionDriverAccepted,
        'description_driver_accepted',
      ),
      BookingStatus.bidding => getString(
        appStr.headingBiddingRequest,
        'heading_bidding_request',
      ),
      BookingStatus.inRoute => getString(
        appStr.bookingStatusInRoute,
        'booking_status_in_route',
      ),
      BookingStatus.arrivedAtPickup => getString(
        appStr.bookingStatusArrivedAtPickup,
        'booking_status_arrived_at_pickup',
      ),
      BookingStatus.started => getString(
        appStr.bookingStatusStarted,
        'booking_status_started',
      ),
      BookingStatus.arrivedAtStop => getString(
        appStr.bookingStatusArrivedAtStop,
        'booking_status_arrived_at_stop',
      ),
      BookingStatus.arrivedAtDestination => getString(
        appStr.descriptionArrivedAtYourDestination,
        'description_arrived_at_your_destination',
      ),
      _ => '',
    };
  }

  /// Whether the drop-off address can be edited
  bool get canEditAddress =>
      activeSetting.contains(CustomerBookingSettings.allowEditAddress) ||
      isChangeDestinationAvailable;

  /// Check if waiting timer should be paused
  /// Timer pauses when trip is started or arrived at stop
  bool get isWaitingTimerPaused =>
      bookingStatus == BookingStatus.started ||
      bookingStatus == BookingStatus.arrivedAtStop;

  /// Check if total timer should be paused
  /// Timer only runs when trip status is STARTED
  bool get isTotalTimerPaused =>
      bookingStatus != BookingStatus.started;

  CurrentRideState copyWith({
    bool? isLoading,
    String? error,
    BookingDetailResponse? bookingDetail,
    Set<CustomerBookingSettings>? activeSetting,
    String? driverTimeEstimation,
    String? totalDistance,
    String? etaText,
    String? trafficTimeStr,
    bool? isNoDriverFound,
    String? waitingTimeStr,
    String? stopWaitingTimeStr,
    String? totalTimeStr,
    List<MapEntry<String, String>>? accessibilityList,
    List<CustomPrice>? customPrices,
    List<AccessibilityPreference>? accessibilities,
    String? verificationCode,
    bool? showOtpVerification,
    bool? showNoProviderFoundSheet,
    bool? shouldNavigateToHome,
    bool? showInvoice,
    bool? isPreBookingPayment,
    bool? isAdvancePaymentLimit,
    bool? isInvoicePaid,
    String? invoicePrice,
    int? paymentMode,
    BookingPaymentSetting? myBookingPaymentSetting,
    bool? isSubmitInvoiceLoading,
    bool? isSubmitInvoiceFailed,
    bool? isNavigateToFeedback,
    bool? showPayByCashButton,
    bool? isNavigateToWebView,
    WebViewDataModel? navigateURL,
    double? invoiceTotalPrice,
    bool? isPaymentFailFromPaymentGateway,
    bool? isNavigateToHome,
    String? snackBarMessage,
    bool? isSnackBarError,
    int? unreadMessageCount,
    bool? isNavigateToChat,
    bool? showCallOptionsBottomSheet,
    bool? isDriverCallingLoading,
    bool? isSupportCallingLoading,
    bool? isShowCancelButton,
    bool? showCancelTripBottomSheet,
    bool? isCancelTripLoading,
    List<String>? cancellationReasonList,
    String? cancellationCharge,
    CardResponse? selectedCard,
    bool? isShowBiddingRequest,
    List<Bid>? biddingList,
    String? bidRequestTimeStr,
    double? customerBidPrice,
    String? formattedCustomerBidPrice,
    bool? isChangeDestinationAvailable,
    bool? isEditAddressLoading,
    bool clearError = false,
    bool clearSnackBar = false,
    bool clearBookingDetail = false,
    bool clearBidding = false,
  }) {
    return CurrentRideState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      bookingDetail: clearBookingDetail
          ? null
          : (bookingDetail ?? this.bookingDetail),
      activeSetting: activeSetting ?? this.activeSetting,
      driverTimeEstimation: driverTimeEstimation ?? this.driverTimeEstimation,
      totalDistance: totalDistance ?? this.totalDistance,
      etaText: etaText ?? this.etaText,
      trafficTimeStr: trafficTimeStr ?? this.trafficTimeStr,
      isNoDriverFound: isNoDriverFound ?? this.isNoDriverFound,
      waitingTimeStr: waitingTimeStr ?? this.waitingTimeStr,
      stopWaitingTimeStr: stopWaitingTimeStr ?? this.stopWaitingTimeStr,
      totalTimeStr: totalTimeStr ?? this.totalTimeStr,
      accessibilityList: accessibilityList ?? this.accessibilityList,
      customPrices: customPrices ?? this.customPrices,
      accessibilities: accessibilities ?? this.accessibilities,
      verificationCode: verificationCode ?? this.verificationCode,
      showOtpVerification: showOtpVerification ?? this.showOtpVerification,
      showNoProviderFoundSheet: showNoProviderFoundSheet ?? this.showNoProviderFoundSheet,
      shouldNavigateToHome: shouldNavigateToHome ?? this.shouldNavigateToHome,
      showInvoice: showInvoice ?? this.showInvoice,
      isPreBookingPayment: isPreBookingPayment ?? this.isPreBookingPayment,
      isAdvancePaymentLimit: isAdvancePaymentLimit ?? this.isAdvancePaymentLimit,
      isInvoicePaid: isInvoicePaid ?? this.isInvoicePaid,
      invoicePrice: invoicePrice ?? this.invoicePrice,
      paymentMode: paymentMode ?? this.paymentMode,
      myBookingPaymentSetting: myBookingPaymentSetting ?? this.myBookingPaymentSetting,
      isSubmitInvoiceLoading: isSubmitInvoiceLoading ?? this.isSubmitInvoiceLoading,
      isSubmitInvoiceFailed: isSubmitInvoiceFailed ?? this.isSubmitInvoiceFailed,
      isNavigateToFeedback: isNavigateToFeedback ?? this.isNavigateToFeedback,
      showPayByCashButton: showPayByCashButton ?? this.showPayByCashButton,
      isNavigateToWebView: isNavigateToWebView ?? this.isNavigateToWebView,
      navigateURL: navigateURL ?? this.navigateURL,
      invoiceTotalPrice: invoiceTotalPrice ?? this.invoiceTotalPrice,
      isPaymentFailFromPaymentGateway: isPaymentFailFromPaymentGateway ?? this.isPaymentFailFromPaymentGateway,
      isNavigateToHome: isNavigateToHome ?? this.isNavigateToHome,
      snackBarMessage: clearSnackBar ? null : (snackBarMessage ?? this.snackBarMessage),
      isSnackBarError: clearSnackBar ? false : (isSnackBarError ?? this.isSnackBarError),
      unreadMessageCount: unreadMessageCount ?? this.unreadMessageCount,
      isNavigateToChat: isNavigateToChat ?? this.isNavigateToChat,
      showCallOptionsBottomSheet: showCallOptionsBottomSheet ?? this.showCallOptionsBottomSheet,
      isDriverCallingLoading: isDriverCallingLoading ?? this.isDriverCallingLoading,
      isSupportCallingLoading: isSupportCallingLoading ?? this.isSupportCallingLoading,
      isShowCancelButton: isShowCancelButton ?? this.isShowCancelButton,
      showCancelTripBottomSheet: showCancelTripBottomSheet ?? this.showCancelTripBottomSheet,
      isCancelTripLoading: isCancelTripLoading ?? this.isCancelTripLoading,
      cancellationReasonList: cancellationReasonList ?? this.cancellationReasonList,
      cancellationCharge: cancellationCharge ?? this.cancellationCharge,
      selectedCard: selectedCard ?? this.selectedCard,
      isShowBiddingRequest: clearBidding ? false : (isShowBiddingRequest ?? this.isShowBiddingRequest),
      biddingList: clearBidding ? const [] : (biddingList ?? this.biddingList),
      bidRequestTimeStr: clearBidding ? null : (bidRequestTimeStr ?? this.bidRequestTimeStr),
      customerBidPrice: clearBidding ? null : (customerBidPrice ?? this.customerBidPrice),
      formattedCustomerBidPrice: clearBidding ? null : (formattedCustomerBidPrice ?? this.formattedCustomerBidPrice),
      isChangeDestinationAvailable: isChangeDestinationAvailable ?? this.isChangeDestinationAvailable,
      isEditAddressLoading: isEditAddressLoading ?? this.isEditAddressLoading,
    );
  }
}

/// Parameters for CurrentRideViewModel
class CurrentRideParams {
  final String bookingId;
  final MapInterface mapManager;
  final int primaryColor;
  final int secondaryColor;

  const CurrentRideParams({
    required this.bookingId,
    required this.mapManager,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CurrentRideParams &&
        other.bookingId == bookingId &&
        other.mapManager == mapManager;
  }

  @override
  int get hashCode => bookingId.hashCode ^ mapManager.hashCode;
}

/// ViewModel for the Current Ride screen
class CurrentRideViewModel extends StateNotifier<CurrentRideState> {
  final AppRepository _appRepository;
  final SocketRepository _socketRepository;
  final CurrentRideParams _params;
  final MapInterface _mapManager;
  final SocketManager _socketManager;
  final SharedPreferenceManager _sharedPref;

  /// Global booking detail response
  BookingDetailResponse? _bookingDetailResponse;

  /// Flag to track if directions are drawn on map
  bool _isDirectionsSet = false;
  double? _driverBearing;
  double? _cameraBearing;
  List<LatLng> _routePoints = const [];
  bool isNoDriverFound = false;

  /// Base markers (pickup, stops, destination) - stored to combine with driver marker
  List<MapMarker> _baseMarkers = [];

  /// Current driver location
  LatLng? _driverLocation;

  /// List of driver location points for polyline
  List<LatLng> _driverLocationList = [];

  /// Map pin URL for driver marker (from vehicle type)
  String? _mapPinUrl;

  /// Waiting time timer
  Timer? _waitingTimer;

  /// Current waiting time in seconds (can be negative for free waiting time)
  int _waitingTimeSeconds = 0;

  /// Total time timer
  Timer? _totalTimer;

  /// Current total time in seconds
  int _totalTimeSeconds = 0;

  /// Stop waiting time timer
  Timer? _stopWaitingTimeTimer;

  /// Current stop waiting time in seconds (can be negative for free stop time)
  int _stopWaitingTimeSeconds = 0;

  /// Chat ID obtained from JOIN_CHAT ack
  String _chatId = '';

  CurrentRideViewModel(
    this._appRepository,
    this._socketRepository,
    this._params,
    this._socketManager,
    this._sharedPref,
  ) : _mapManager = _params.mapManager,
      super(const CurrentRideState()) {
    _init();
  }

  void _init() {
    debugPrint(
      '🚗 CurrentRideViewModel - Initialized with bookingId: ${_params.bookingId}',
    );
    _connectSocket();
    _getBookingDetails();
    _emitChatSocketEvent();
    _listenChatSocketEvent();
  }

  /// Connect to socket and emit SIGN_UP event
  void _connectSocket() {
    _socketManager.connect(
      onConnected: () {
        debugPrint(
          '🚗 CurrentRideViewModel - Socket connected, emitting SIGN_UP',
        );
        _socketManager.emitEvent(
          SocketConstants.eventSignUp,
          ackCallback: (ackData) {
            debugPrint(
              '🚗 CurrentRideViewModel - SIGN_UP ack received: $ackData',
            );
          },
        );
      },
    );

    // Listen for booking status updates
    _socketManager.listenEvent(SocketConstants.bookingStatus, (data) {
      debugPrint('🚗 CurrentRideViewModel - BOOKING_STATUS received: $data');
      if (data is Map<String, dynamic>) {
        final bookingStatus = BookingStatusData.fromJson(data);
        state = state.copyWith(
          isNoDriverFound: bookingStatus.isNoDriverFound ?? false,
        );

        // The moment the driver marks arrival the ride is over for the
        // customer, so drop the live surface right away rather than waiting on
        // the booking-detail round trip (invoice may still be pending).
        if ((bookingStatus.status ?? 0) >=
            BookingStatus.arrivedAtDestination.value) {
          _stopLiveActivity();
          // Drop the ride's tilted camera back to flat, so the invoice and
          // rating view isn't left looking down a street at 60 degrees.
          final lastKnown = _driverLocation;
          if (lastKnown != null) {
            _mapManager.animateCamera(lastKnown, pitch: 0, bearing: 0);
          }
        }

        // Refresh booking details if status >= ACCEPTED (20) or if bidding booking
        final isBiddingBooking =
            _bookingDetailResponse?.booking?.biddingDetail?.isBidding == true;
        if ((bookingStatus.status ?? 0) >= BookingStatus.accepted.value ||
            isBiddingBooking) {
          _getBookingDetails();
        }

        // Update driver estimation if available
        if (bookingStatus.currentRouteEstimation != null) {
          setDriverEstimation(
            remainingTimeInSeconds: bookingStatus.currentRouteEstimation?.time ?? 0,
            totalDistanceValue: (bookingStatus.currentRouteEstimation?.distance ?? 0).toDouble(),
          );
        }
      }
    });
  }

  /// Get current booking ID
  String get bookingId => _params.bookingId;

  /// Refresh booking details (called on resume)
  Future<void> refreshBookingDetails() async {
    debugPrint('🚗 CurrentRideViewModel - Refreshing booking details');
    await _getBookingDetails();
  }

  /// Compact ETA for the live surface, e.g. "2 min" or "1 hr 5 min". The shared
  /// TimeUtil string spells the unit out ("2 Minutes") because the label comes
  /// from the server, which is too long for the notification / Live Activity.
  String _shortEta(int seconds) {
    final totalMinutes = (seconds / 60).ceil().clamp(1, 24 * 60);
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    final minLabel = getString(null, 'live_time_min');
    final hourLabel = getString(null, 'live_time_hr');
    if (hours > 0) {
      return minutes > 0
          ? '$hours $hourLabel $minutes $minLabel'
          : '$hours $hourLabel';
    }
    return '$totalMinutes $minLabel';
  }

  /// Tear down the live booking surface for this ride.
  Future<void> _stopLiveActivity() =>
      LiveActivityManager.instance.stopActivity(_params.bookingId);

  /// Keep the live booking surface (iOS Live Activity / Android ongoing
  /// notification) in sync with the current ride — mirrors native
  /// `OngoingRideViewModel.setUIData()`, which (re)starts the activity on every
  /// booking-detail refresh rather than waiting for a push to arrive.
  Future<void> _syncLiveActivity(BookingDetailResponse? data) async {
    final booking = data?.booking;
    if (booking == null) return;
    final bookingId = _params.bookingId;
    if (bookingId.isEmpty) return;
    final status = booking.status ?? 0;

    // Once the ride reaches the destination / completes / is cancelled the
    // surface is torn down (matches native's `status >= 70` guard).
    if (status >= BookingStatus.arrivedAtDestination.value) {
      await LiveActivityManager.instance.stopActivity(bookingId);
      return;
    }

    // Live tracking only becomes meaningful once a driver is engaged.
    if (status < BookingStatus.accepted.value) return;

    // On iOS a fresh `request(pushType:.token)` each refresh would stack
    // duplicate activities; updates there arrive via push, so start only once.
    if (Platform.isIOS &&
        await LiveActivityManager.instance.isActivityActive(bookingId)) {
      return;
    }

    final driver = booking.confirmedDriver;
    final vehicle = driver?.vehicleDetail;
    final pickup = booking.pickupAddress;
    final destinations = booking.destinationAddresses;
    final destination = (destinations != null && destinations.isNotEmpty)
        ? destinations.last
        : null;

    // The driver photo can only be embedded from a local file. Android reads it
    // straight into the notification bitmap; iOS needs it in a shared App Group
    // container, so skip the download there until that capability is enabled.
    final photoPath =
        Platform.isAndroid ? await _downloadDriverPhoto(driver?.imageUrl) : '';

    // Live driver ETA (from the socket route estimation). Before the ride
    // starts it's the time to the pickup; once started, the time to the drop.
    final eta = state.etaText ?? '';
    final headingToDrop = status >= BookingStatus.started.value;

    final liveActivity = data?.liveActivity;
    await LiveActivityManager.instance.startActivity(
      bookingId: bookingId,
      uniqueId: booking.uniqueId ?? '',
      statusText: state.tripStatusText,
      status: status,
      progress: liveActivity?.progress ?? 0,
      pickupPoints: liveActivity?.pickupPoint ?? const <int>[],
      destinationPoint: liveActivity?.destinationPoint ?? 100,
      driverName: driver?.name ?? '',
      rating: driver?.rate != null ? driver!.rate!.toStringAsFixed(1) : '',
      vehicleName: _vehicleLabel(vehicle, booking.vehicleType?.name),
      // The live surface shows the same badge the ride screen does, so it
      // follows the licence too.
      plateNo: vehicle?.vehicleLicense ?? '',
      pickupAddress: pickup?.address ?? pickup?.title ?? '',
      destinationAddress:
          destination?.address ?? destination?.title ?? '',
      pickupTime: headingToDrop ? '' : eta,
      destinationTime: headingToDrop ? eta : '',
      photoPath: photoPath,
    );
  }

  /// Human-readable vehicle label, e.g. "White Astor". Falls back to the
  /// vehicle's own name and then the booked vehicle-type name.
  String _vehicleLabel(DriverVehicleDetail? vehicle, String? vehicleTypeName) {
    final parts = [vehicle?.color, vehicle?.model]
        .where((e) => e != null && e.trim().isNotEmpty)
        .map((e) => e!.trim())
        .toList();
    if (parts.isNotEmpty) return parts.join(' ');
    final name = vehicle?.name?.trim();
    if (name != null && name.isNotEmpty) return name;
    return vehicleTypeName?.trim() ?? '';
  }

  /// Download the driver photo to a cached local file and return its path
  /// (empty string on any failure). Cached by URL so it downloads at most once.
  Future<String> _downloadDriverPhoto(String? path) async {
    if (path == null || path.isEmpty) return '';
    // The API returns a relative path (e.g. "driver_profile/abc.jpeg"), so it
    // has to be resolved against the image base URL before fetching.
    final url = ServerConfig.getFullImageUrl(path);
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/la_driver_${url.hashCode}.jpg');
      if (await file.exists()) return file.path;
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        return file.path;
      }
    } catch (e) {
      debugPrint('🔔 [LiveActivity] Driver photo download failed: $e');
    }
    return '';
  }

  /// Fetch booking details from API
  Future<void> _getBookingDetails() async {
    if (_params.bookingId.isEmpty) {
      debugPrint('🚗 CurrentRideViewModel - bookingId is empty');
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    final response = await _appRepository.getBookingDetails(_params.bookingId);

    switch (response) {
      case Success():
        debugPrint(
          '🚗 CurrentRideViewModel - Booking details fetched successfully',
        );
        _bookingDetailResponse = response.data;
        _mapPinUrl = response.data?.booking?.vehicleType?.mapPinUrl;
        _setCustomerBookingSetting();
        if (!_isDirectionsSet) {
          _showDirectionsOnMap();
        }

        final booking = response.data?.booking;

        // Set OTP verification code
        final verificationCode = (booking?.isShowOtp == true) ? booking?.otp : null;

        final isInvoicePaid = booking?.bookingInvoice?.paymentStatus == PaymentTransactionStatus.paid;
        final isCapturePaymentPending = booking?.bookingInvoice?.isCapturePaymentPending ?? false;

        // Compute cancel button visibility (like Kotlin)
        final bookingStatusValue = booking?.status ?? 0;
        final cancelUptoStatus = response.data?.cancelUptoStatus ?? 0;
        final isAllowCancel = response.data?.isAllowCancelBooking ?? false;
        final isShowCancel = bookingStatusValue <= cancelUptoStatus && isAllowCancel;

        // Check if destination can be changed (DESTINATION_LATER tag or empty destinations)
        final isChangeDestAvailable =
            booking?.bookingTags?.contains('DESTINATION_LATER') == true ||
            (booking?.destinationAddresses?.isEmpty ?? true);

        state = state.copyWith(
          isLoading: false,
          bookingDetail: response.data,
          isChangeDestinationAvailable: isChangeDestAvailable,
          verificationCode: verificationCode,
          showOtpVerification: booking?.isShowOtp == true,
          isPreBookingPayment: isCapturePaymentPending,
          isAdvancePaymentLimit: booking?.bookingInvoice?.isAdvancePaymentLimit ?? false,
          isInvoicePaid: isInvoicePaid,
          isShowCancelButton: isShowCancel,
        );

        // Keep the live booking surface (Live Activity / ongoing notification)
        // in sync on every refresh, mirroring native setUIData().
        _syncLiveActivity(response.data);

        // Re-place the driver pin and ride camera on every refresh. Previously
        // this only happened when the socket pushed a fix, so a driver that
        // reports rarely (a car waiting at the kerb) left the camera stuck on
        // whatever it was set to when the screen first opened.
        _updateMarkersWithDriver();

        // Check if pre-booking payment is required and show invoice bottom sheet
        if (!isInvoicePaid &&
            isCapturePaymentPending &&
            booking?.bookingType != RideType.fixGroup.value) {
          final isAdvancePay = booking?.bookingInvoice?.isAdvancePaymentLimit ?? false;
          final advancePayPercentage = booking?.bookingInvoice?.advancePaymentLimit ?? 0.0;
          final estimatedTotal = booking?.bookingInvoice?.estimated?.total ?? 0.0;

          final total = (isAdvancePay && advancePayPercentage > 0)
              ? (estimatedTotal * advancePayPercentage) / 100
              : estimatedTotal;

          final invoicePrice = total.applyPriceSetting(
            currencyDirection: booking?.setCurrencySign ?? 1,
            currencySign: booking?.bookingInvoice?.currencySign ?? '',
            decimalPointValue: booking?.decimalPointValue ?? 2,
          );

          state = state.copyWith(
            showInvoice: true,
            paymentMode: (isAdvancePay && state.paymentMode != null)
                ? state.paymentMode
                : booking?.bookingInvoice?.paymentMode,
            isPreBookingPayment: true,
            isInvoicePaid: false,
            invoicePrice: invoicePrice,
            invoiceTotalPrice: total,
            myBookingPaymentSetting: response.data?.citySetting?.paymentSetting,
            showPayByCashButton: booking?.bookingInvoice?.paymentMode == PaymentGatewayType.cash.value,
          );
          return;
        }

        // Fetch accessibility data for fare estimation titles
        _getAccessibility();

        // Handle booking status logic (mirrors Kotlin getBookingDetails branching)
        final status = booking?.status ?? 0;
        final bids = booking?.biddingDetail?.bids;
        final hasBids = bids != null && bids.isNotEmpty;

        if (status >= BookingStatus.accepted.value &&
            status != BookingStatus.bidding.value) {
          // ── Branch 1: status >= ACCEPTED (but NOT bidding) ──
          // Normal ride flow: driver assigned, show trip details / invoice
          _clearBiddingState();

          final remaining = booking?.bookingInvoice?.paymentDetail?.remaining ?? 0.0;
          final actualTotal = booking?.bookingInvoice?.actual?.total ?? 0.0;
          final totalPrice = remaining > 0 ? remaining : actualTotal;

          final invoicePrice = totalPrice.applyPriceSetting(
            currencyDirection: booking?.setCurrencySign ?? 1,
            currencySign: booking?.bookingInvoice?.currencySign ?? '',
            decimalPointValue: booking?.decimalPointValue ?? 2,
          );

          if (status != BookingStatus.cancelled.value) {
            final isArrivedAtDest = status == BookingStatus.arrivedAtDestination.value;
            if (isArrivedAtDest || (booking?.isPaymentRequired ?? false)) {
              state = state.copyWith(
                showInvoice: true,
                invoicePrice: invoicePrice,
                invoiceTotalPrice: totalPrice,
                paymentMode: booking?.bookingInvoice?.paymentMode,
                myBookingPaymentSetting: response.data?.citySetting?.paymentSetting,
                showPayByCashButton: booking?.bookingInvoice?.paymentMode == PaymentGatewayType.cash.value,
              );
            } else {
              _updateSettings();
            }
          }
        } else if (hasBids) {
          // ── Branch 2: bids exist (status < ACCEPTED or status == BIDDING) ──
          // Kotlin: isShowBiddingRequest = true, expandBottomSheet, fixBottomSheetToFullScreen
          _setBiddingData();
        } else {
          // ── Branch 3: no bids, status < ACCEPTED (connecting to drivers) ──
          // Kotlin: showConnectingToNearbyDriver = true, isShowBiddingRequest = false
          _clearBiddingState();
        }

        // Check if booking is cancelled
        if (booking?.status == BookingStatus.cancelled.value) {
          debugPrint(
            '🚗 CurrentRideViewModel - Booking CANCELLED, isNoDriverFound: ${state.isNoDriverFound}',
          );
          _stopLiveActivity();
          if (state.isNoDriverFound) {
            state = state.copyWith(showNoProviderFoundSheet: true);
          } else {
            state = state.copyWith(shouldNavigateToHome: true);
          }
        }

      case Error():
        debugPrint('🚗 CurrentRideViewModel - Error: ${response.message}');
        state = state.copyWith(isLoading: false, error: response.message);

      case Loading():
        break;
    }
  }

  /// Update settings based on booking status
  void _updateSettings() {
    // Start timers based on active settings
    if (state.activeSetting.contains(CustomerBookingSettings.showWaitingTime)) {
      _startWaitingTimer();
    }
    if (state.activeSetting.contains(CustomerBookingSettings.showTotalTimeAndDistance)) {
      _startTotalTimer();
    }
    if (state.activeSetting.contains(CustomerBookingSettings.showStopWaitingTime)) {
      _startStopWaitingTimer();
    }

    _getDriverLocationApi();
    _getDriverLiveLocation();
  }

  /// Start waiting timer using Timer.periodic
  ///
  /// The timer counts up from the initial waiting time value.
  /// - If time < 0: Shows "Free waiting time" (counting up to 0)
  /// - If time >= 0: Shows "Waiting time" (counting up from 0)
  /// - Timer pauses when trip is started or arrived at stop
  void _startWaitingTimer() {
    _stopWaitingTimer();

    // Get initial waiting time from booking invoice (in seconds)
    final waitingTime = _bookingDetailResponse?.booking?.bookingInvoice?.actual?.waitingTime;
    _waitingTimeSeconds = waitingTime?.toInt() ?? 0;

    // Set initial display
    _updateWaitingTimeStr();

    // Start timer that ticks every second
    _waitingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      // Only increment when not paused
      if (!state.isWaitingTimerPaused) {
        _waitingTimeSeconds++;
        _updateWaitingTimeStr();
      }
    });
  }

  /// Update waiting time string in state
  void _updateWaitingTimeStr() {
    final isFreeWaitingTime = _waitingTimeSeconds < 0;
    final timeToDisplay = isFreeWaitingTime
        ? -_waitingTimeSeconds
        : _waitingTimeSeconds;

    final hours = timeToDisplay ~/ 3600;
    final minutes = (timeToDisplay % 3600) ~/ 60;
    final seconds = timeToDisplay % 60;

    final timeString = hours > 0
        ? '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}'
        : '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    final label = isFreeWaitingTime
        ? getString(appStr.descriptionFreeWaitingTime, 'description_free_waiting_time')
        : getString(appStr.descriptionWaitingTime, 'description_waiting_time');

    state = state.copyWith(waitingTimeStr: '$label: $timeString');
  }

  /// Stop waiting timer
  void _stopWaitingTimer() {
    _waitingTimer?.cancel();
    _waitingTimer = null;
  }

  /// Start total timer using Timer.periodic
  ///
  /// Timer only runs when trip status is STARTED (isTotalTimerPaused = false)
  /// When paused, timer still ticks but doesn't increment time
  void _startTotalTimer() {
    _stopTotalTimer();

    // Get initial total time from booking invoice (in seconds)
    final totalTime = _bookingDetailResponse?.booking?.bookingInvoice?.actual?.time;
    _totalTimeSeconds = totalTime?.toInt() ?? 0;

    // Set initial display
    _updateTotalTimeStr();

    // Start timer that ticks every second
    _totalTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      // Only increment when not paused (status is STARTED)
      if (!state.isTotalTimerPaused) {
        _totalTimeSeconds++;
        _updateTotalTimeStr();
      }
    });
  }

  /// Update total time string in state
  void _updateTotalTimeStr() {
    final hours = _totalTimeSeconds ~/ 3600;
    final minutes = (_totalTimeSeconds % 3600) ~/ 60;
    final seconds = _totalTimeSeconds % 60;

    final timeString = hours > 0
        ? '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}'
        : '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    state = state.copyWith(totalTimeStr: timeString);
  }

  /// Stop total timer
  void _stopTotalTimer() {
    _totalTimer?.cancel();
    _totalTimer = null;
  }

  /// Start stop waiting timer using Timer.periodic
  ///
  /// Similar to waiting timer but for stop waiting time.
  /// - If time < 0: Shows "Free Stop Time" (counting up to 0)
  /// - If time >= 0: Shows "Stop Time" (counting up from 0)
  /// - Timer is paused when trip status is STARTED (runs when ARRIVED_AT_STOP)
  void _startStopWaitingTimer() {
    _stopStopWaitingTimer();

    // Get initial stop waiting time from booking invoice (in seconds)
    final stopWaitingTime = _bookingDetailResponse?.booking?.bookingInvoice?.actual?.stopWaitingTime;
    _stopWaitingTimeSeconds = stopWaitingTime?.toInt() ?? 0;

    // Set initial display
    _updateStopWaitingTimeStr();

    // Start timer that ticks every second
    _stopWaitingTimeTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      // Only increment when not paused (status is ARRIVED_AT_STOP, not STARTED)
      if (!_isStopWaitingTimerPaused) {
        _stopWaitingTimeSeconds++;
        _updateStopWaitingTimeStr();
      }
    });
  }

  /// Check if stop waiting timer should be paused
  /// Paused when trip status is STARTED, runs when ARRIVED_AT_STOP
  bool get _isStopWaitingTimerPaused =>
      state.bookingStatus == BookingStatus.started;

  /// Update stop waiting time string in state
  void _updateStopWaitingTimeStr() {
    final isFreeStopTime = _stopWaitingTimeSeconds < 0;
    final timeToDisplay = isFreeStopTime
        ? -_stopWaitingTimeSeconds
        : _stopWaitingTimeSeconds;

    final hours = timeToDisplay ~/ 3600;
    final minutes = (timeToDisplay % 3600) ~/ 60;
    final seconds = timeToDisplay % 60;

    final timeString = hours > 0
        ? '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}'
        : '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    final label = isFreeStopTime
        ? getString(appStr.descriptionFreeStopTime, 'description_free_stop_time')
        : getString(appStr.descriptionStopTime, 'description_stop_time');

    state = state.copyWith(stopWaitingTimeStr: '$label: $timeString');
  }

  /// Stop stop waiting timer
  void _stopStopWaitingTimer() {
    _stopWaitingTimeTimer?.cancel();
    _stopWaitingTimeTimer = null;
  }

  /// Format traffic time in seconds to HH:MM:SS or MM:SS string
  String _formatTrafficTime(int trafficTimeSeconds) {
    final hours = trafficTimeSeconds ~/ 3600;
    final minutes = (trafficTimeSeconds % 3600) ~/ 60;
    final seconds = trafficTimeSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  /// Get accessibility data for fare estimation title mapping
  ///
  /// This fetches accessibilities and customPrices from the API.
  /// The data is converted to types expected by fare estimation bottom sheet
  /// which uses it to map charge IDs to readable titles via InvoiceUtil.
  Future<void> _getAccessibility() async {
    final response = await _appRepository.getAccessibility();

    switch (response) {
      case Success<acc.AccessibilityResponse>():
        debugPrint('🚗 CurrentRideViewModel - Accessibility fetched successfully');

        final apiAccessibilities = response.data?.accessibilities ?? [];
        final apiCustomPrices = response.data?.customPrices ?? [];

        // Convert API accessibilities to AccessibilityPreference (used by fare estimation)
        final accessibilities = apiAccessibilities.map((a) => AccessibilityPreference(
          id: a.id,
          accessibility: a.accessibility,
        )).toList();

        // Convert API customPrices to CustomPrice from get_vehicle_type_response (used by fare estimation)
        final customPrices = apiCustomPrices.map((cp) => CustomPrice(
          id: cp.id,
          title: cp.title,
        )).toList();

        // Create accessibilityList: combines accessibilities and customPrices as (id, title) pairs
        // This is passed to InvoiceUtil.getInvoiceElements for title mapping
        final accessibilityList = <MapEntry<String, String>>[
          ...apiAccessibilities.map((a) => MapEntry(a.id ?? '', a.accessibility ?? '')),
          ...apiCustomPrices.map((cp) => MapEntry(cp.id ?? '', cp.title ?? '')),
        ];

        state = state.copyWith(
          accessibilityList: accessibilityList,
          customPrices: customPrices,
          accessibilities: accessibilities,
        );

      case Error():
        debugPrint('🚗 CurrentRideViewModel - Accessibility error: ${response.message}');

      case Loading():
        break;
    }
  }

  /// Get driver location from API
  Future<void> _getDriverLocationApi() async {
    if (_params.bookingId.isEmpty) return;

    final response = await _socketRepository.getLocation(_params.bookingId);

    switch (response) {
      case Success():
        debugPrint('🚗 CurrentRideViewModel - Driver location fetched');

        // Extract location list
        final locations = response.data?.location;
        if (locations != null && locations.isNotEmpty) {
          final locationPoints = locations
              .where((loc) => loc?.latitude != null && loc?.longitude != null)
              .map((loc) => LatLng(loc!.latitude!, loc.longitude!))
              .toList();

          if (locationPoints.isNotEmpty) {
            // Update driver location
            _driverLocation = locationPoints.last;
            _driverLocationList = locationPoints;

            // Update markers with driver position
            _updateMarkersWithDriver();
          }
        }

        // Update driver estimation from currentRouteEstimation
        final estimation = response.data?.currentRouteEstimation;
        if (estimation != null) {
          setDriverEstimation(
            remainingTimeInSeconds: estimation.time,
            totalDistanceValue: estimation.distance ?? 0.0,
          );
        }

        // Update total distance if available (convert meters to km)
        // Update total distance (always update like Kotlin - no > 0 check)
        final distance = response.data?.distance ?? 0.0;
        final distanceInKm = distance / 1000.0;
        state = state.copyWith(
          totalDistance: '${distanceInKm.toStringAsFixed(2)} ${getString(appStr.descriptionDistanceUnitKm, 'description_distance_unit_km')}',
        );

        // Update traffic time (always update like Kotlin - no > 0 check)
        final trafficTime = response.data?.trafficTime ?? 0;
        state = state.copyWith(trafficTimeStr: _formatTrafficTime(trafficTime));

      case Error():
        debugPrint(
          '🚗 CurrentRideViewModel - Driver location error: ${response.message}',
        );

      case Loading():
        break;
    }
  }

  /// Listen for driver live location updates
  void _getDriverLiveLocation() {
    _socketManager.listenEvent(SocketConstants.driverLiveLocation, (data) {
      debugPrint('🚗 CurrentRideViewModel - DRIVER_LIVE_LOCATION received: $data');

      if (data is Map<String, dynamic>) {
        final liveLocationResponse = DriverLiveLocationResponse.fromJson(data);
        final locations = liveLocationResponse.locations;

        debugPrint('🚗 CurrentRideViewModel - distanceList: ${liveLocationResponse.distanceList}');
        debugPrint('🚗 CurrentRideViewModel - looking for bookingId: ${_params.bookingId}');

        // Find distance for current booking
        final distanceData = liveLocationResponse.distanceList?.firstWhere(
          (d) => d?.bookingId == _params.bookingId,
          orElse: () => null,
        );

        debugPrint('🚗 CurrentRideViewModel - distanceData found: $distanceData');
        debugPrint('🚗 CurrentRideViewModel - distance value: ${distanceData?.distance}');

        // Update total distance and traffic time (always update like Kotlin - no > 0 check)
        // Convert meters to kilometers
        final distanceInKm = (distanceData?.distance ?? 0.0) / 1000.0;
        debugPrint('🚗 CurrentRideViewModel - distanceInKm: $distanceInKm');
        state = state.copyWith(
          totalDistance: '${distanceInKm.toStringAsFixed(2)} ${getString(appStr.descriptionDistanceUnitKm, 'description_distance_unit_km')}',
        );
        debugPrint('🚗 CurrentRideViewModel - totalDistance set to: ${state.totalDistance}');

        // Update traffic time (always set like Kotlin - no > 0 check)
        final trafficTime = distanceData?.trafficTime ?? 0;
        final trafficTimeStr = _formatTrafficTime(trafficTime);
        state = state.copyWith(trafficTimeStr: trafficTimeStr);

        // Update driver location if available
        if (locations != null && locations.isNotEmpty) {
          final lastLocation = locations.last;
          if (lastLocation?.latitude != null && lastLocation?.longitude != null) {
            final newLocation = LatLng(
              lastLocation!.latitude!,
              lastLocation.longitude!,
            );

            // Update driver location
            _driverLocation = newLocation;
            _driverLocationList.add(newLocation);

            // The driver's device already reports its heading, which beats
            // deriving one from two fixes. A parked car reports 0, so hold the
            // last real heading rather than snapping the camera back to north.
            final reportedBearing = lastLocation.bearing;
            if (reportedBearing != null && reportedBearing != 0) {
              _driverBearing = reportedBearing;
            }

            // Update markers with driver position
            _updateMarkersWithDriver();
          }
        }
      }
    });
  }

  /// Update map markers including driver marker
  /// Returns true when the ride's 3D follow camera took control.
  bool _updateMarkersWithDriver() {
    // Same fallback as the camera: the socket may not push a fix for another
    // half-minute, and until it did the car pin was simply absent even though
    // the booking detail already carried the driver's last known point.
    final driverLocation = _driverLocation ?? _driverLocationFromBooking();
    if (driverLocation == null) return false;

    final allMarkers = List<MapMarker>.from(_baseMarkers);

    // Once the ride is under way the camera sits on the car looking down the
    // road, so the map *is* the driver's viewpoint — a pin planted on top of
    // that viewpoint just blocks the road ahead. Before the trip starts the pin
    // is still how the customer sees the car approaching, so keep it there.
    if (!_isRideUnderWay) {
      // Get driver marker icon URL from mapPinUrl
      final driverIconUrl = _mapPinUrl != null && _mapPinUrl!.isNotEmpty
          ? ServerConfig.getFullImageUrl(_mapPinUrl)
          : null;

      // Add driver marker (iconAsset is fallback if iconUrl fails)
      allMarkers.add(
        MapMarker(
          id: 'driver',
          position: driverLocation,
          title: '',
          iconUrl: driverIconUrl,
          iconAsset: 'assets/images/ic_car_pin.png',
          iconWidth: 40,
          iconHeight: 40,
        ),
      );
    }

    _mapManager.setMarkers(allMarkers);

    // Draw driver's traveled path polyline
    _updateDriverPathPolyline();

    return _followDriverInThreeD();
  }

  /// True once the driver has started the trip.
  ///
  /// Read off the response rather than `state`: _showDirectionsOnMap runs
  /// before the fetched booking has been copied into state, so `state` would
  /// still be carrying the previous status at that point.
  bool get _isRideUnderWay =>
      BookingStatus.fromValue(_bookingDetailResponse?.booking?.status) ==
          BookingStatus.started;

  /// Camera used while the ride is in progress. The tilt is the whole point:
  /// the map styles only render their 3D building geometry once the camera is
  /// pitched off vertical — at 0 it stays the usual flat top-down map.
  static const double _ridingPitch = 85;
  static const double _ridingZoom = 19.5;

  /// Follow the car in a tilted, street-level camera once the driver starts the
  /// trip, instead of leaving the map on the flat overview that was fitted to
  /// pickup and destination back when the ride was booked.
  /// Returns true when it took control of the camera.
  bool _followDriverInThreeD() {
    if (!_isRideUnderWay) return false;

    // Opening the screen mid-ride, the socket may not push a fix for another
    // half-minute (a stopped car reports rarely), and until then there was no
    // driver position to aim at — the map just sat on the flat route overview.
    // The booking detail carries the driver's last known point, so start there.
    final target = _driverLocation ?? _driverLocationFromBooking();
    if (target == null) return false;

    // Which way the camera looks. Where the car has actually been over the last
    // few fixes is ground truth and comes first: the drawn route is only ~45
    // points for the whole trip, so its local direction can disagree with the
    // road the car is really on (it read 71 degrees east while the car drove
    // 351 degrees north). Route and destination stay as fallbacks for a car
    // that hasn't moved yet.
    final bearing = _smoothedBearing(
      _bearingFromRecentFixes(target) ??
          _driverBearing ??
          _bearingAlongRoute(target) ??
          _bearingTowardsDestination(target),
    );

    debugPrint(
      '🗺️ ride camera → target=$target bearing=$bearing '
      '(route=${_bearingAlongRoute(target)} reported=$_driverBearing '
      'fixes=${_bearingFromRecentFixes(target)} '
      'dest=${_bearingTowardsDestination(target)}) '
      'routePoints=${_routePoints.length}',
    );
    _mapManager.animateCamera(
      target,
      zoom: _ridingZoom,
      pitch: _ridingPitch,
      bearing: bearing,
      duration: _ridingCameraDurationMs,
      ease: true,
    );
    return true;
  }

  /// How far along the route to look when deciding which way is "forward".
  /// Short enough to track the road the car is actually on, long enough that a
  /// single kink in the geometry doesn't swing the camera around.
  static const double _routeLookAheadMetres = 80;

  /// Heading along the route itself, from the point nearest the driver towards
  /// a point a little further on.
  ///
  /// This is what keeps the drawn route running up the screen. Aiming straight
  /// at the destination isn't the same thing: a route that leaves eastwards
  /// before turning north put the destination at the top of the screen while
  /// the line itself still ran sideways past the car.
  double? _bearingAlongRoute(LatLng target) {
    if (_routePoints.length < 2) return null;

    var nearestIndex = 0;
    var nearestDistance = double.infinity;
    for (var i = 0; i < _routePoints.length; i++) {
      final distance = _distanceBetween(target, _routePoints[i]);
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearestIndex = i;
      }
    }

    // Walk forward until we're far enough along to have a stable heading.
    var travelled = 0.0;
    var aheadIndex = nearestIndex;
    while (aheadIndex < _routePoints.length - 1 &&
        travelled < _routeLookAheadMetres) {
      travelled +=
          _distanceBetween(_routePoints[aheadIndex], _routePoints[aheadIndex + 1]);
      aheadIndex++;
    }
    if (aheadIndex == nearestIndex) return null;

    return _bearingBetween(target, _routePoints[aheadIndex]);
  }

  /// Great-circle distance in metres.
  double _distanceBetween(LatLng from, LatLng to) {
    const earthRadius = 6371000.0;
    const toRadians = math.pi / 180;

    final lat1 = from.latitude * toRadians;
    final lat2 = to.latitude * toRadians;
    final deltaLat = (to.latitude - from.latitude) * toRadians;
    final deltaLon = (to.longitude - from.longitude) * toRadians;

    final a = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(deltaLon / 2) *
            math.sin(deltaLon / 2);
    return earthRadius * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  /// How far back along the driver's trail to look for a heading. Consecutive
  /// fixes can be a couple of metres apart, where GPS scatter alone swings the
  /// computed bearing wildly; over this distance the noise averages out.
  static const double _headingBaselineMetres = 15;

  /// Fraction of the remaining turn applied per update. The camera eases into
  /// a new heading over a handful of fixes instead of snapping, which is what
  /// keeps a U-turn from whipping around.
  static const double _bearingSmoothing = 0.25;

  /// Animation length for the follow camera. Fixes arrive roughly every 200ms,
  /// and an animation longer than the gap is cut off by the next one — that
  /// half-finished movement is what made the follow look jerky.
  static const int _ridingCameraDurationMs = 220;

  /// Whether to draw the driver's travelled path behind the car. Off for now.
  static const bool _showDriverTrail = false;

  /// Heading from where the driver actually came from, measured far enough back
  /// down the trail to be stable. Null until the car has covered that distance.
  double? _bearingFromRecentFixes(LatLng target) {
    for (var i = _driverLocationList.length - 1; i >= 0; i--) {
      final candidate = _driverLocationList[i];
      if (_distanceBetween(candidate, target) >= _headingBaselineMetres) {
        return _bearingBetween(candidate, target);
      }
    }
    return null;
  }

  /// Eases the camera towards [next] and always turns the short way round.
  ///
  /// Bearings wrap at 360, so stepping from 350 to 10 degrees is a 20 degree
  /// turn right, not a 340 degree spin left — taking the raw difference is what
  /// made the map wheel around on a U-turn.
  double? _smoothedBearing(double? next) {
    if (next == null) return _cameraBearing;

    final current = _cameraBearing;
    if (current == null) {
      _cameraBearing = next;
      return next;
    }

    final delta = (next - current + 540) % 360 - 180;
    _cameraBearing = (current + delta * _bearingSmoothing + 360) % 360;
    return _cameraBearing;
  }

  /// Heading from the driver towards where the ride is going — the last
  /// destination, falling back to the pickup for the leg before the trip
  /// starts. Keeps the route pointing up the screen while the car is stopped.
  double? _bearingTowardsDestination(LatLng target) {
    final booking = _bookingDetailResponse?.booking;
    if (booking == null) return null;

    final destinations = booking.destinationAddresses;
    final destination = (destinations != null && destinations.isNotEmpty)
        ? destinations.last
        : null;

    final latitude = destination?.latitude ?? booking.pickupAddress?.latitude;
    final longitude = destination?.longitude ?? booking.pickupAddress?.longitude;
    if (latitude == null || longitude == null) return null;

    final towards = LatLng(latitude, longitude);
    if (towards.latitude == target.latitude &&
        towards.longitude == target.longitude) {
      return null;
    }
    return _bearingBetween(target, towards);
  }

  /// The driver's last known point as carried by the booking detail, stored
  /// GeoJSON-style as [lng, lat].
  LatLng? _driverLocationFromBooking() {
    final coordinates =
        _bookingDetailResponse?.booking?.confirmedDriver?.location?.coordinates;
    if (coordinates == null || coordinates.length < 2) return null;
    return LatLng(coordinates[1], coordinates[0]);
  }

  /// Initial bearing from [from] to [to], in degrees clockwise from north.
  double _bearingBetween(LatLng from, LatLng to) {
    const toRadians = math.pi / 180;
    final lat1 = from.latitude * toRadians;
    final lat2 = to.latitude * toRadians;
    final deltaLon = (to.longitude - from.longitude) * toRadians;

    final y = math.sin(deltaLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(deltaLon);

    return (math.atan2(y, x) / toRadians + 360) % 360;
  }

  /// Draw polyline showing driver's traveled path
  /// Draw the trail the driver has already covered.
  ///
  /// Switched off for now via [_showDriverTrail] — the drawing code is left in
  /// place so it can be turned back on by flipping that one flag.
  void _updateDriverPathPolyline() {
    if (!_showDriverTrail) {
      // Also clears a trail drawn before the flag was turned off.
      _mapManager.setDriverPathPolyline(null);
      return;
    }

    if (_driverLocationList.length < 2) {
      // Need at least 2 points to draw a polyline
      _mapManager.setDriverPathPolyline(null);
      return;
    }

    _mapManager.setDriverPathPolyline(
      MapPolyline(
        id: 'driver_path',
        points: _driverLocationList,
        color: _params.secondaryColor,
        width: 5.0,
      ),
    );
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Edit destination address during active ride
  Future<void> editDestinationAddress(DestinationAddress newDestination) async {
    // Validate new destination against pickup
    final pickup = state.bookingDetail?.booking?.pickupAddress;
    if (pickup != null) {
      final countryError = AddressValidationUtil.checkSameCountry(
        pickupAddress: pickup,
        stops: const [],
        dropoffAddress: newDestination,
      );
      if (countryError != null) {
        state = state.copyWith(
          snackBarMessage: countryError,
          isSnackBarError: true,
        );
        return;
      }

      final duplicateError = AddressValidationUtil.checkDuplicateAddresses(
        pickupAddress: pickup,
        stops: const [],
        dropoffAddress: newDestination,
      );
      if (duplicateError != null) {
        state = state.copyWith(
          snackBarMessage: duplicateError,
          isSnackBarError: true,
        );
        return;
      }
    }

    state = state.copyWith(isEditAddressLoading: true);

    final request = GetVehicleTypesRequest(
      destinationAddresses: [newDestination],
    );

    final response = await _appRepository.updateDestinationAddress(
      _params.bookingId,
      request,
    );

    switch (response) {
      case Success():
        debugPrint('🚗 CurrentRideViewModel - Destination address updated');

        state = state.copyWith(
          isEditAddressLoading: false,
          isChangeDestinationAvailable: false,
        );

        // Redraw map immediately with new destination and polyline
        _redrawMapAfterAddressUpdate(
          newDestination,
          response.data?.directionPath,
        );

        // Re-fetch booking details to get canonical server state
        _isDirectionsSet = true; // prevent _showDirectionsOnMap from overwriting
        await _getBookingDetails();

      case Error():
        debugPrint(
          '🚗 CurrentRideViewModel - Edit address error: ${response.message}',
        );
        state = state.copyWith(
          isEditAddressLoading: false,
          snackBarMessage: response.message,
          isSnackBarError: true,
        );

      case Loading():
        break;
    }
  }

  /// Redraw map markers and polyline after destination address is updated
  void _redrawMapAfterAddressUpdate(
    DestinationAddress newDestination,
    String? directionPath,
  ) {
    final booking = _bookingDetailResponse?.booking;
    if (booking == null) return;

    final markers = <MapMarker>[];
    final boundsPoints = <LatLng>[];
    final primaryColor = _params.primaryColor;

    // Pickup marker
    final pickup = booking.pickupAddress;
    if (pickup?.latitude != null && pickup?.longitude != null) {
      final pickupLatLng = LatLng(pickup!.latitude!, pickup.longitude!);
      markers.add(
        MapMarker(
          id: 'pickup',
          position: pickupLatLng,
          title: '',
          snippet: pickup.address,
          iconAsset: 'assets/images/ic_pickup.png',
          iconWidth: 32,
          iconHeight: 32,
          iconColor: primaryColor,
        ),
      );
      boundsPoints.add(pickupLatLng);
    }

    // New destination marker
    if (newDestination.latitude != null && newDestination.longitude != null) {
      final destLatLng = LatLng(
        newDestination.latitude!,
        newDestination.longitude!,
      );
      markers.add(
        MapMarker(
          id: 'destination_0',
          position: destLatLng,
          title: '',
          snippet: newDestination.address,
          iconAsset: 'assets/images/ic_drop_off.png',
          iconWidth: 32,
          iconHeight: 32,
          iconColor: primaryColor,
        ),
      );
      boundsPoints.add(destLatLng);
    }

    // Update markers
    _baseMarkers = markers;
    _mapManager.setMarkers(markers);

    // Draw new polyline
    if (directionPath != null && directionPath.isNotEmpty) {
      final route =
          MapPolyline.fromEncoded(encoded: directionPath, color: primaryColor);
      _routePoints = route.points;
      _mapManager.setPolyline(route);
    }

    // Fit camera to show all points
    if (boundsPoints.isNotEmpty) {
      _mapManager.fitBounds(boundsPoints, padding: 100);
    }

    _isDirectionsSet = true;
  }

  /// Show directions on map with pickup, stops, destination markers and polyline
  void _showDirectionsOnMap() {
    final booking = _bookingDetailResponse?.booking;
    if (booking == null) return;

    final markers = <MapMarker>[];
    final boundsPoints = <LatLng>[];
    final primaryColor = _params.primaryColor;

    // Pickup marker
    final pickup = booking.pickupAddress;
    if (pickup?.latitude != null && pickup?.longitude != null) {
      final pickupLatLng = LatLng(pickup!.latitude!, pickup.longitude!);
      markers.add(
        MapMarker(
          id: 'pickup',
          position: pickupLatLng,
          title: '',
          snippet: pickup.address,
          iconAsset: 'assets/images/ic_pickup.png',
          iconWidth: 32,
          iconHeight: 32,
          iconColor: primaryColor,
        ),
      );
      boundsPoints.add(pickupLatLng);
    }

    // Destination markers
    final destinations = booking.destinationAddresses;
    if (destinations != null && destinations.isNotEmpty) {
      final lastIndex = destinations.length - 1;

      for (int i = 0; i < destinations.length; i++) {
        final dest = destinations[i];
        if (dest.latitude == null || dest.longitude == null) continue;

        final destLatLng = LatLng(dest.latitude!, dest.longitude!);
        boundsPoints.add(destLatLng);

        if (i == lastIndex) {
          // Final destination
          markers.add(
            MapMarker(
              id: 'destination_$i',
              position: destLatLng,
              title: '',
              snippet: dest.address,
              iconAsset: 'assets/images/ic_drop_off.png',
              iconWidth: 32,
              iconHeight: 32,
              iconColor: primaryColor,
            ),
          );
        } else {
          // Intermediate stop
          markers.add(
            MapMarker(
              id: 'stop_$i',
              position: destLatLng,
              title: '',
              snippet: dest.address,
              stopNumber: i + 1,
              iconColor: primaryColor,
            ),
          );
        }
      }
    }

    // Store base markers and set on map
    _baseMarkers = markers;
    _mapManager.setMarkers(markers);

    // Draw polyline from encoded direction path
    final directionPath = booking.bookingInvoice?.estimated?.directionPath;
    if (directionPath != null && directionPath.isNotEmpty) {
      final route =
          MapPolyline.fromEncoded(encoded: directionPath, color: primaryColor);
      _routePoints = route.points;
      _mapManager.setPolyline(route);
    }

    // Fit camera to show all points — unless the ride is already under way, in
    // which case the whole-route overview would immediately undo the tilted
    // follow camera (fitBounds derives a flat, north-up camera).
    if (_updateMarkersWithDriver()) {
      // Driver pin drawn and the camera is already placed on it.
    } else if (boundsPoints.isNotEmpty) {
      _mapManager.fitBounds(boundsPoints, padding: 100);
    }

    _isDirectionsSet = true;
  }

  /// Set customer booking settings based on current booking status
  void _setCustomerBookingSetting() {
    final customerBookingSetting =
        _bookingDetailResponse?.citySetting?.customerBookingSetting;
    if (customerBookingSetting == null) return;

    final bookingStatus = BookingStatus.fromValue(
      _bookingDetailResponse?.booking?.status,
    );

    final List<String>? settingList = switch (bookingStatus) {
      BookingStatus.requested => customerBookingSetting.requested,
      BookingStatus.assigned => customerBookingSetting.assigned,
      BookingStatus.accepted => customerBookingSetting.accepted,
      BookingStatus.inRoute => customerBookingSetting.inRoute,
      BookingStatus.arrivedAtPickup => customerBookingSetting.arrivedAtPickup,
      BookingStatus.started => customerBookingSetting.started,
      BookingStatus.arrivedAtStop => customerBookingSetting.arrivedAtStop,
      BookingStatus.arrivedAtDestination =>
        customerBookingSetting.arrivedAtDestination,
      BookingStatus.arrivedNearDestination =>
        customerBookingSetting.arrivedNearDestination,
      BookingStatus.serviceCompleted => customerBookingSetting.serviceCompleted,
      BookingStatus.merchantAccepted => customerBookingSetting.merchantAccepted,
      BookingStatus.merchantPreparing =>
        customerBookingSetting.merchantPreparing,
      BookingStatus.merchantCompleted =>
        customerBookingSetting.merchantCompleted,
      _ => null,
    };

    if (settingList != null) {
      _updateActiveSetting(settingList);
    }
  }

  /// Update active settings in state
  void _updateActiveSetting(List<String> settingList) {
    final activeSetting = settingList
        .map((value) => CustomerBookingSettings.fromSetting(value))
        .toSet();

    state = state.copyWith(activeSetting: activeSetting);
  }

  /// Set driver estimation from current route estimation
  void setDriverEstimation({
    required int? remainingTimeInSeconds,
    double totalDistanceValue = 0.0,
  }) {
    if (remainingTimeInSeconds == null) return;

    final formattedTime = TimeUtil.formattedTime(remainingTimeInSeconds);
    final driverTimeEstimation = getString(
      appStr.descriptionDriverTimeEstimate,
      'description_driver_time_estimate',
    ).replacePlaceholders({StringConstant.driverTimeEstimate: formattedTime});

    // Convert meters to kilometers (always set like Kotlin - no > 0 check)
    final distanceInKm = totalDistanceValue / 1000.0;
    state = state.copyWith(
      driverTimeEstimation: driverTimeEstimation,
      etaText: _shortEta(remainingTimeInSeconds),
      totalDistance: '${distanceInKm.toStringAsFixed(2)} ${getString(appStr.descriptionDistanceUnitKm, 'description_distance_unit_km')}',
    );
  }

  /// Reset navigation flags after handling them
  void resetNavigationFlags() {
    state = state.copyWith(
      showNoProviderFoundSheet: false,
      shouldNavigateToHome: false,
      isNavigateToHome: false,
      isNavigateToWebView: false,
      isNavigateToFeedback: false,
    );
  }

  /// Clear snackbar message
  void clearSnackBar() {
    state = state.copyWith(clearSnackBar: true);
  }

  // ============= Chat Methods =============

  /// Emit JOIN_CHAT socket event to get chatId and unread count
  void _emitChatSocketEvent() {
    final request = SocketJoinChatRequest(
      referenceId: _params.bookingId,
      chatType: ChatType.CUSTOMER_DRIVER_CHAT.name,
    );

    _socketManager.emitEvent(
      SocketConstants.eventJoinChat,
      data: request.toJson(),
      ackCallback: (ackData) {
        debugPrint('🚗 CurrentRideViewModel - JOIN_CHAT ack: $ackData');
        try {
          final json = ackData is Map<String, dynamic>
              ? ackData
              : jsonDecode(ackData.toString()) as Map<String, dynamic>;
          final response = SocketJoinChatResponse.fromJson(json);
          _chatId = response.chatId ?? _chatId;
          state = state.copyWith(
            unreadMessageCount: response.unreadMessageCount ?? 0,
          );
        } catch (e) {
          debugPrint('🚗 CurrentRideViewModel - Error parsing join chat: $e');
        }
      },
    );
  }

  /// Listen for incoming chat messages to update unread count
  void _listenChatSocketEvent() {
    _socketManager.listenEvent(SocketConstants.eventChatMessage, (data) {
      debugPrint('🚗 CurrentRideViewModel - CHAT_MESSAGE received');
      try {
        final json = data is Map<String, dynamic>
            ? data
            : jsonDecode(data.toString()) as Map<String, dynamic>;
        final response = SocketChatMessageResponse.fromJson(json);

        if (response.referenceId != _params.bookingId) {
          return;
        }

        _chatId = response.chatId ?? _chatId;

        int unreadCount = 0;
        final customerUnread = response.unreadCounts?.firstWhere(
          (uc) => uc.type == EntityType.customer,
          orElse: () => const UnreadCount(),
        );
        unreadCount = customerUnread?.unreadCount ?? 0;

        state = state.copyWith(unreadMessageCount: unreadCount);
      } catch (e) {
        debugPrint('🚗 CurrentRideViewModel - Error parsing chat message: $e');
      }
    });
  }

  /// Handle chat button click - navigate to chat screen
  void onChatClick() {
    state = state.copyWith(
      unreadMessageCount: 0,
      isNavigateToChat: true,
    );
  }

  /// Reset chat navigation flag after handling
  void onRedirectToChat() {
    state = state.copyWith(isNavigateToChat: false);
  }

  // ============= Call Methods =============

  /// Handle call button click - smart routing based on available options
  void onCallClick() {
    final activeSetting = state.activeSetting;
    final showDriverCall =
        activeSetting.contains(CustomerBookingSettings.allowCallToDriver) &&
        (_bookingDetailResponse?.booking?.confirmedDriver?.phone ?? '').length > 5;
    final showSupportCall =
        activeSetting.contains(CustomerBookingSettings.allowCallToSupport);

    if (showDriverCall && showSupportCall) {
      state = state.copyWith(showCallOptionsBottomSheet: true);
    } else if (showSupportCall) {
      _supportCalling();
    } else if (showDriverCall) {
      _calling();
    }
  }

  /// Dismiss call options bottom sheet
  void dismissCallOptionsBottomSheet() {
    state = state.copyWith(showCallOptionsBottomSheet: false);
  }

  /// Call driver - either direct dial or API call
  Future<void> onCallDriverClick() async {
    state = state.copyWith(showCallOptionsBottomSheet: false);
    await _calling();
  }

  /// Call support - either direct dial or API call
  Future<void> onCallSupportClick() async {
    state = state.copyWith(showCallOptionsBottomSheet: false);
    await _supportCalling();
  }

  /// Check if server-side calling is allowed
  bool get _isAllowCall =>
      _bookingDetailResponse?.isAllowCall == true;

  /// Dial a phone number using system dialer
  Future<void> _dialPhone(String phone) async {
    try {
      final uri = Uri.parse('tel:$phone');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      debugPrint('🚗 CurrentRideViewModel - Error dialing: $e');
    }
  }

  /// Call driver via API or direct dial
  Future<void> _calling() async {
    if (!_isAllowCall) {
      final phone = _bookingDetailResponse?.booking?.confirmedDriver?.phone ?? '';
      if (phone.isNotEmpty) {
        _dialPhone(phone);
      }
      return;
    }

    state = state.copyWith(isLoading: true, isDriverCallingLoading: true);

    final response = await _appRepository.calling(_params.bookingId);

    switch (response) {
      case Success():
        state = state.copyWith(
          isLoading: false,
          isDriverCallingLoading: false,
          snackBarMessage: response.message ?? '',
        );
        break;
      case Error():
        state = state.copyWith(
          isLoading: false,
          isDriverCallingLoading: false,
          snackBarMessage: response.error?.message ?? '',
          isSnackBarError: true,
        );
        break;
      case Loading():
        break;
    }
  }

  /// Call support via API or direct dial
  Future<void> _supportCalling() async {
    if (!_isAllowCall) {
      final phone = _sharedPref.getSetting()?.contactDetail?.phone ?? '';
      if (phone.isNotEmpty) {
        _dialPhone(phone);
      }
      return;
    }

    state = state.copyWith(isLoading: true, isSupportCallingLoading: true);

    final response = await _appRepository.supportCalling();

    switch (response) {
      case Success():
        state = state.copyWith(
          isLoading: false,
          isSupportCallingLoading: false,
          snackBarMessage: response.message ?? '',
        );
        break;
      case Error():
        state = state.copyWith(
          isLoading: false,
          isSupportCallingLoading: false,
          snackBarMessage: response.error?.message ?? '',
          isSnackBarError: true,
        );
        break;
      case Loading():
        break;
    }
  }

  // ============= Cancel Trip Methods =============

  /// Called when user taps "Cancel trip" from popup menu
  /// Shows bottom sheet immediately, data streams in reactively
  void onCancelTripClick() {
    state = state.copyWith(showCancelTripBottomSheet: true);
    _getCancellationReasons();
    _getCancellationCharges();
  }

  /// Dismiss cancel trip bottom sheet
  void dismissCancelTripBottomSheet() {
    state = state.copyWith(showCancelTripBottomSheet: false);
  }

  /// Fetch cancellation reasons from API
  Future<void> _getCancellationReasons() async {
    final response = await _appRepository.getCancellationReasons({
      'businessType': BusinessType.taxi.toString(),
    });

    switch (response) {
      case Success():
        final reasons = response.data?.cancellationReasons
                ?.map((r) => r.reasons ?? '')
                .where((r) => r.isNotEmpty)
                .toList() ??
            [];
        reasons.add(getString(appStr.descriptionOthers, 'description_others'));
        state = state.copyWith(cancellationReasonList: reasons);
      case Error():
        break;
      case Loading():
        break;
    }
  }

  /// Fetch cancellation charges from API
  Future<void> _getCancellationCharges() async {
    final response = await _appRepository.getCancellationCharges(_params.bookingId);

    switch (response) {
      case Success():
        if ((response.data?.total ?? 0) > 0) {
          final booking = _bookingDetailResponse?.booking;
          final charge = (response.data?.total ?? 0.0).applyPriceSetting(
            currencyDirection: booking?.setCurrencySign ?? 1,
            currencySign: booking?.bookingInvoice?.currencySign ?? '',
            decimalPointValue: booking?.decimalPointValue ?? 2,
          );
          state = state.copyWith(cancellationCharge: charge);
        }
      case Error():
        break;
      case Loading():
        break;
    }
  }

  /// Cancel the trip with a given reason
  Future<void> cancelTrip(String reason) async {
    state = state.copyWith(isCancelTripLoading: true);

    final request = CancelBookingRequest(
      bookingId: _params.bookingId,
      cancellationReason: reason,
    );

    final response = await _appRepository.cancelBooking(
      _params.bookingId,
      request,
    );

    switch (response) {
      case Success():
        // The customer's own cancellation has to tear the live surface down
        // here: this screen is about to pop, and once its autoDispose provider
        // is gone nothing else in the app would ever stop the notification.
        await _stopLiveActivity();
        state = state.copyWith(
          isCancelTripLoading: false,
          showCancelTripBottomSheet: false,
          snackBarMessage: response.message ?? '',
          shouldNavigateToHome: true,
        );
      case Error():
        state = state.copyWith(
          isCancelTripLoading: false,
          snackBarMessage: response.error?.message ?? '',
          isSnackBarError: true,
        );
      case Loading():
        break;
    }
  }

  // ============= Bidding Methods =============

  /// Timer for bid rejection countdown
  Timer? _bidRejectTimer;

  /// Target time (epoch ms) when bids auto-reject
  int _targetBidRejectTime = 0;

  /// Clear bidding state and stop timer
  void _clearBiddingState() {
    state = state.copyWith(clearBidding: true);
    _stopBidRejectTimer();
  }

  /// Populate bidding data from booking details
  /// Called from Branch 2 of _getBookingDetails when bids exist
  void _setBiddingData() {
    final booking = _bookingDetailResponse?.booking;
    final biddingDetail = booking?.biddingDetail;
    final bids = biddingDetail?.bids;

    if (bids != null && bids.isNotEmpty) {
      final rejectTime = biddingDetail?.customerBidRejectTime;

      // Format customer bid price (like Kotlin applyPriceSetting)
      final currencyDirection = booking?.setCurrencySign ?? 1;
      final currencySign = booking?.bookingInvoice?.currencySign ?? '';
      final decimalPointValue = booking?.decimalPointValue ?? 2;

      final customerBidPrice = biddingDetail?.customerBidPrice;
      final formattedCustomerBidPrice = customerBidPrice.applyPriceSetting(
        currencyDirection: currencyDirection,
        currencySign: currencySign,
        decimalPointValue: decimalPointValue,
      );

      state = state.copyWith(
        isShowBiddingRequest: true,
        biddingList: bids,
        customerBidPrice: customerBidPrice,
        formattedCustomerBidPrice: formattedCustomerBidPrice,
      );

      // Start countdown timer if reject time is available
      if (rejectTime != null && rejectTime > 0) {
        _targetBidRejectTime = rejectTime;
        _startBidRejectTimer();
      }
    } else {
      _clearBiddingState();
    }
  }

  /// Start countdown timer for bid rejection
  void _startBidRejectTimer() {
    _stopBidRejectTimer();
    _updateBidRejectTimeStr();

    _bidRejectTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateBidRejectTimeStr();
    });
  }

  /// Update bid rejection countdown string
  void _updateBidRejectTimeStr() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final remainingMs = _targetBidRejectTime - now;

    if (remainingMs <= 0) {
      _stopBidRejectTimer();
      state = state.copyWith(bidRequestTimeStr: '00:00');
      // Refresh booking details when timer expires
      _getBookingDetails();
      return;
    }

    final remainingSeconds = (remainingMs / 1000).ceil();
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    final timeStr =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    state = state.copyWith(bidRequestTimeStr: timeStr);
  }

  /// Stop bid rejection timer
  void _stopBidRejectTimer() {
    _bidRejectTimer?.cancel();
    _bidRejectTimer = null;
  }

  /// Accept a driver's bid
  Future<void> acceptBid(String driverId) async {
    state = state.copyWith(isLoading: true);

    final request = BiddingAcceptRequest(
      bookingId: _params.bookingId,
      driverId: driverId,
    );

    final response = await _appRepository.acceptBidding(
      _params.bookingId,
      request,
    );

    switch (response) {
      case Success():
        state = state.copyWith(
          isLoading: false,
          clearBidding: true,
          snackBarMessage: response.message ?? '',
        );
        _stopBidRejectTimer();
        _getBookingDetails();
      case Error():
        state = state.copyWith(
          isLoading: false,
          snackBarMessage: response.error?.message ?? '',
          isSnackBarError: true,
        );
      case Loading():
        break;
    }
  }

  /// Reject a driver's bid
  Future<void> rejectBid(String driverId, int index) async {
    final request = BiddingAcceptRequest(
      bookingId: _params.bookingId,
      driverId: driverId,
    );

    final response = await _appRepository.rejectBidding(
      _params.bookingId,
      request,
    );

    switch (response) {
      case Success():
        // Remove bid from list
        final updatedList = List<Bid>.from(state.biddingList);
        if (index >= 0 && index < updatedList.length) {
          updatedList.removeAt(index);
        }
        state = state.copyWith(
          biddingList: updatedList,
          isShowBiddingRequest: updatedList.isNotEmpty,
        );
        if (updatedList.isEmpty) {
          _stopBidRejectTimer();
          _getBookingDetails();
        }
      case Error():
        state = state.copyWith(
          snackBarMessage: response.error?.message ?? '',
          isSnackBarError: true,
        );
      case Loading():
        break;
    }
  }

  // ============= Payment Methods =============

  /// Current payment manager instance
  PaymentInterface? _paymentManager;

  /// Cached intent payment for retry scenarios
  IntentPayment? _intentPayment;

  /// Check if this is a corporate trip
  bool get _isCorporateTrip =>
      _bookingDetailResponse?.booking?.corporateId?.isNotEmpty == true;

  /// Submit invoice after payment is complete
  Future<void> submitInvoice() async {
    final bookingId = _params.bookingId;
    final request = SubmitInvoiceRequest(bookingId: bookingId);

    state = state.copyWith(
      isLoading: true,
      isSubmitInvoiceLoading: true,
    );

    final response = await _appRepository.submitInvoice(bookingId, request);

    switch (response) {
      case Success():
        state = state.copyWith(
          isLoading: false,
          showInvoice: false,
          isNavigateToFeedback: !state.isNavigateToFeedback,
          isSubmitInvoiceFailed: false,
          isSubmitInvoiceLoading: false,
        );
        // The ride is over and we navigate away to feedback, so no further
        // booking refresh happens — tear the live surface down here.
        _stopLiveActivity();
        // Clear cached intent payment
        _intentPayment = null;
      case Error():
        state = state.copyWith(
          isLoading: false,
          isSubmitInvoiceFailed: true,
          isSubmitInvoiceLoading: false,
        );
      case Loading():
        break;
    }
  }

  /// Pay for booking using wallet
  Future<void> _walletBookingPayment() async {
    final bookingId = _params.bookingId;

    state = state.copyWith(
      isLoading: true,
      isSubmitInvoiceLoading: true,
    );

    final response = await _appRepository.walletBookingPayment(bookingId);

    switch (response) {
      case Success():
        state = state.copyWith(isLoading: false);
        if (_bookingDetailResponse?.booking?.isPaymentRequired == true) {
          state = state.copyWith(isNavigateToHome: true);
        } else {
          submitInvoice();
        }
      case Error():
        state = state.copyWith(isLoading: false);
        // Show error via state if needed
      case Loading():
        break;
    }
  }

  /// Pay by cash for partial payment scenario
  Future<void> _payByCashForPartialPayment() async {
    final bookingId = _params.bookingId;

    state = state.copyWith(isLoading: true);

    final response = await _appRepository.partialPaymentByCash(bookingId);

    switch (response) {
      case Success():
        state = state.copyWith(isLoading: false);
        submitInvoice();
      case Error():
        state = state.copyWith(isLoading: false);
        // Show error via state if needed
      case Loading():
        break;
    }
  }

  /// Create payment intent for card/gateway payments
  Future<void> _paymentIntentCreate() async {
    final paymentGateway = state.paymentMode;
    final booking = _bookingDetailResponse?.booking;

    // Determine payment purpose
    final paymentPurpose = (state.isPreBookingPayment &&
            booking?.isPaymentRequired != true)
        ? PaymentPurposeType.preBookingPayment
        : PaymentPurposeType.bookingPayment;

    final request = WalletPaymentRequest(
      amount: state.invoiceTotalPrice,
      countryId: booking?.countryId,
      currency: booking?.bookingInvoice?.currencySign,
      paymentPurpose: paymentPurpose,
      bookingId: _params.bookingId,
    );

    state = state.copyWith(
      isLoading: true,
      isSubmitInvoiceLoading: true,
    );

    final response = await _appRepository.paymentIntentCreate(
      paymentGateway: paymentGateway.toString(),
      request: request,
    );

    switch (response) {
      case Success():
        debugPrint('💳 paymentIntentCreate: status=${response.data?.paymentTransactionStatus}');

        switch (response.data?.paymentTransactionStatus) {
          case PaymentTransactionStatus.initiated:
            _handlePaymentIntentResponse(response.data?.intent);
          case PaymentTransactionStatus.paid:
            if (booking?.isPaymentRequired == true) {
              state = state.copyWith(isNavigateToHome: true);
            } else {
              submitInvoice();
            }
            state = state.copyWith(
              isLoading: false,
              showInvoice: false,
              isSubmitInvoiceFailed: false,
            );
          default:
            state = state.copyWith(
              isLoading: false,
              showInvoice: true,
              isNavigateToFeedback: false,
              isSubmitInvoiceFailed: true,
            );
        }
      case Error():
        state = state.copyWith(
          isLoading: false,
          isSubmitInvoiceFailed: true,
          isPaymentFailFromPaymentGateway: true,
          isSubmitInvoiceLoading: false,
          snackBarMessage: response.error?.message ?? '',
          isSnackBarError: true,
        );
      case Loading():
        break;
    }
  }

  /// Handle payment intent response from payment gateway
  void _handlePaymentIntentResponse(IntentPayment? intent) {
    if (intent == null) return;

    // Cache intent for retry scenarios
    _intentPayment = intent;

    // Initialize payment SDK
    _paymentManager?.initPaymentSdk(intent.publicKey ?? '');

    // Create payment intent with callback
    _paymentManager?.createPaymentIntent(
      intent: intent,
      callback: PaymentCallbackImpl(
        onSuccess: (paymentMethodId, intentResponse) {
          if (paymentMethodId != null) {
            // Payment successful via SDK
            if (state.isPreBookingPayment) {
              // Hide invoice and continue with booking flow
              state = state.copyWith(
                showInvoice: false,
                isSubmitInvoiceLoading: false,
              );
              // Refresh booking details
              _getBookingDetails();
            } else {
              if (_bookingDetailResponse?.booking?.isPaymentRequired == true) {
                state = state.copyWith(isNavigateToHome: true);
              } else {
                submitInvoice();
              }
            }
          } else {
            // Need to open WebView for payment
            WebViewDataModel? webViewData;

            if (intentResponse?.url != null && intentResponse!.url!.isNotEmpty) {
              webViewData = WebViewDataModel(
                webURL: intent.url,
                name: 'Payment',
              );
            } else if (intentResponse?.html != null && intentResponse!.html!.isNotEmpty) {
              webViewData = WebViewDataModel(
                webContent: intent.html,
                name: 'Payment',
              );
            }

            if (webViewData != null) {
              state = state.copyWith(
                isNavigateToWebView: true,
                navigateURL: webViewData,
                isSubmitInvoiceLoading: false,
              );
            }
          }
        },
        onCapture: () {
          // Handle capture if needed
        },
        onCardCreated: (paymentMethodId, intent) {
          // Handle card created if needed
        },
        onError: (error) {
          state = state.copyWith(
            isSubmitInvoiceFailed: true,
            isPaymentFailFromPaymentGateway: true,
            snackBarMessage: error.toString(),
            isSnackBarError: true,
          );
          debugPrint('💳 Payment error: ${error.toString()}');
        },
      ),
    );
  }

  /// Main entry point for booking payment
  /// Called when user taps Pay button
  void payBookingPayment() {
    final paymentGateway = state.paymentMode;
    final bookingId = _params.bookingId;

    // Set payment manager based on payment gateway type
    if (paymentGateway == PaymentGatewayType.stripe.value) {
      _paymentManager = StripePaymentManager();
    } else if (paymentGateway == PaymentGatewayType.paystack.value) {
      _paymentManager = PayStackManager();
    } else {
      // WebView based payment gateways (razorpay, mercado, payu, etc.)
      _paymentManager = WebViewPaymentManager();
    }

    // Corporate trip - just submit invoice
    if (_isCorporateTrip) {
      submitInvoice();
      return;
    }

    // Handle based on payment gateway type
    if (paymentGateway == PaymentGatewayType.wallet.value) {
      // Wallet payment
      if (state.isSubmitInvoiceFailed || state.isAdvancePaymentLimit) {
        _walletBookingPayment();
      } else {
        submitInvoice();
      }
    } else if (paymentGateway == PaymentGatewayType.cash.value) {
      // Cash payment
      if (state.isAdvancePaymentLimit) {
        _payByCashForPartialPayment();
      } else {
        submitInvoice();
      }
    } else {
      // Card/Gateway payment
      if (_intentPayment != null && _intentPayment?.id == bookingId) {
        // Reuse cached intent
        _handlePaymentIntentResponse(_intentPayment);
      } else {
        _paymentIntentCreate();
      }
    }
  }

  /// Handle payment result from WebView
  /// Called when user returns from payment WebView
  void handlePaymentWebViewResponse(bool success, String? message) {
    // Update failure flags first (like Kotlin)
    state = state.copyWith(
      isSubmitInvoiceFailed: !success,
      isPaymentFailFromPaymentGateway: !success,
      isNavigateToWebView: false,
    );

    if (success) {
      if (_bookingDetailResponse?.booking?.isPaymentRequired == true) {
        state = state.copyWith(isNavigateToHome: true);
         _hideInvoiceAndShowConnectingDriverSheet();
         _getBookingDetails();
      } else if (state.isPreBookingPayment) {
        // Hide invoice and show connecting driver sheet
        _hideInvoiceAndShowConnectingDriverSheet();
        _getBookingDetails();
      } else {
        submitInvoice();
        _getBookingDetails();
      }
    }

    // Show snackbar with message
    if (message != null && message.isNotEmpty) {
      state = state.copyWith(
        snackBarMessage: message,
        isSnackBarError: !success,
      );
    }
  }

  /// Update payment from card selection (matching Kotlin SetCardData event)
  void setCardData(CardResponse? card) {
    state = state.copyWith(
      paymentMode: card?.paymentGatewayType,
      selectedCard: card,
    );
  }

  /// Hide invoice and show connecting driver sheet (pre-booking payment flow)
  void _hideInvoiceAndShowConnectingDriverSheet() {
    state = state.copyWith(
      showInvoice: false,
      isSubmitInvoiceLoading: false,
    );
  }

  @override
  void dispose() {
    debugPrint(
      '🚗 CurrentRideViewModel - DISPOSED bookingId: ${_params.bookingId}',
    );
    // Remove socket listeners to prevent "used after dispose" errors
    _socketManager.offEvent(SocketConstants.bookingStatus);
    _socketManager.offEvent(SocketConstants.driverLiveLocation);
    _socketManager.offEvent(SocketConstants.eventChatMessage);
    _stopWaitingTimer();
    _stopTotalTimer();
    _stopStopWaitingTimer();
    _stopBidRejectTimer();
    // Safety net: if this screen goes away with the ride already finished,
    // make sure the live surface doesn't linger. (An ongoing ride keeps its
    // notification alive on purpose, so only tear down terminal bookings.)
    final lastStatus = _bookingDetailResponse?.booking?.status ?? 0;
    if (lastStatus >= BookingStatus.arrivedAtDestination.value) {
      _stopLiveActivity();
    }
    super.dispose();
  }
}

/// Provider for CurrentRideViewModel
final currentRideViewModelProvider = StateNotifierProvider.autoDispose
    .family<CurrentRideViewModel, CurrentRideState, CurrentRideParams>((
      ref,
      params,
    ) {
      final appRepository = ref.watch(appRepositoryProvider);
      final socketRepository = ref.watch(socketRepositoryProvider);
      final socketManager = ref.watch(socketManagerProvider);
      final sharedPref = ref.watch(sharedPreferenceManagerProvider).maybeWhen(
            data: (data) => data,
            orElse: () => throw Exception('SharedPreferences not initialized'),
          );
      return CurrentRideViewModel(
        appRepository,
        socketRepository,
        params,
        socketManager,
        sharedPref,
      );
    });
