import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/managers/live_activity_manager.dart';
import '../core/payments/payment_interface.dart';
import '../core/payments/paystack_manager.dart';
import '../core/payments/stripe_payment_manager.dart';
import '../core/payments/webview_payment_manager.dart';
import '../core/preferences/shared_preference_manager.dart';
import '../core/providers/app_providers.dart';
import '../core/utils/common_utils.dart';
import '../core/utils/invoice_util.dart';
import '../data/api/response_state.dart';
import '../data/api/server_config.dart';
import '../data/repository/app_repository.dart';
import '../data/repository/history_repository.dart';
import '../models/requests/add_favourite_driver_request.dart';
import '../models/requests/submit_rating_request.dart';
import '../models/requests/wallet_payment_request.dart';
import '../models/responses/driver/favourite_driver_response.dart';
import '../models/responses/booking/booking_detail_response.dart';
import '../models/responses/payment/payment_intent_response.dart';
import '../models/webview_data_model.dart';

/// Pickup ride type constant (matching Kotlin RideTypeConstant.PICKUP.type)
const int _rideTypePickup = 6;

/// Tip option for predefined tip amounts
class TipOption {
  final double price;
  final String priceStr;
  final bool isSelected;

  const TipOption({
    required this.price,
    required this.priceStr,
    this.isSelected = false,
  });

  TipOption copyWith({bool? isSelected}) {
    return TipOption(
      price: price,
      priceStr: priceStr,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

/// Params for FeedbackViewModel
class FeedbackParams {
  final String bookingId;
  final bool isFromHistory;

  const FeedbackParams({
    required this.bookingId,
    this.isFromHistory = true,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FeedbackParams && other.bookingId == bookingId;
  }

  @override
  int get hashCode => bookingId.hashCode;
}

/// Feedback screen state (matches Kotlin FeedbackState)
class FeedbackState {
  final bool isLoading;
  final String? error;
  final BookingDetails? booking;
  final String driverName;
  final String? driverId;
  final String? driverImageUrl;
  final String? distanceStr;
  final String? timeStr;
  final int selectedRating; // 1-5
  final String comment;
  final bool isSubmitting;

  // Navigation flags (matches Kotlin isNavigateBack / isNavigateToHome)
  final bool isNavigateBack;
  final bool isNavigateToHome;

  // Tip fields
  final List<TipOption> tipOptions;
  final TipOption? selectedTip;
  final String customTipAmount;
  final bool isShowTipOptions;
  final bool showPaymentOption;
  final bool isTipPaymentFailed;
  final bool isNavigateToWebView;
  final WebViewDataModel? navigateURL;
  final bool isNavigateToPayment;

  // Payment
  final int? paymentMethod;
  final String paymentMethodName;

  // Flags
  final bool isCorporateTrip;
  final bool isFavourite;

  const FeedbackState({
    this.isLoading = false,
    this.error,
    this.booking,
    this.driverName = '',
    this.driverId,
    this.driverImageUrl,
    this.distanceStr,
    this.timeStr,
    this.selectedRating = 5,
    this.comment = '',
    this.isSubmitting = false,
    this.isNavigateBack = false,
    this.isNavigateToHome = false,
    this.tipOptions = const [],
    this.selectedTip,
    this.customTipAmount = '',
    this.isShowTipOptions = false,
    this.showPaymentOption = false,
    this.isTipPaymentFailed = false,
    this.isNavigateToWebView = false,
    this.navigateURL,
    this.isNavigateToPayment = false,
    this.paymentMethod,
    this.paymentMethodName = '',
    this.isCorporateTrip = false,
    this.isFavourite = false,
  });

  FeedbackState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    BookingDetails? booking,
    String? driverName,
    String? driverId,
    String? driverImageUrl,
    String? distanceStr,
    String? timeStr,
    int? selectedRating,
    String? comment,
    bool? isSubmitting,
    bool? isNavigateBack,
    bool? isNavigateToHome,
    List<TipOption>? tipOptions,
    TipOption? selectedTip,
    bool clearSelectedTip = false,
    String? customTipAmount,
    bool? isShowTipOptions,
    bool? showPaymentOption,
    bool? isTipPaymentFailed,
    bool? isNavigateToWebView,
    WebViewDataModel? navigateURL,
    bool? isNavigateToPayment,
    int? paymentMethod,
    String? paymentMethodName,
    bool? isCorporateTrip,
    bool? isFavourite,
  }) {
    return FeedbackState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      booking: booking ?? this.booking,
      driverName: driverName ?? this.driverName,
      driverId: driverId ?? this.driverId,
      driverImageUrl: driverImageUrl ?? this.driverImageUrl,
      distanceStr: distanceStr ?? this.distanceStr,
      timeStr: timeStr ?? this.timeStr,
      selectedRating: selectedRating ?? this.selectedRating,
      comment: comment ?? this.comment,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isNavigateBack: isNavigateBack ?? this.isNavigateBack,
      isNavigateToHome: isNavigateToHome ?? this.isNavigateToHome,
      tipOptions: tipOptions ?? this.tipOptions,
      selectedTip:
          clearSelectedTip ? null : (selectedTip ?? this.selectedTip),
      customTipAmount: customTipAmount ?? this.customTipAmount,
      isShowTipOptions: isShowTipOptions ?? this.isShowTipOptions,
      showPaymentOption: showPaymentOption ?? this.showPaymentOption,
      isTipPaymentFailed: isTipPaymentFailed ?? this.isTipPaymentFailed,
      isNavigateToWebView: isNavigateToWebView ?? this.isNavigateToWebView,
      navigateURL: navigateURL ?? this.navigateURL,
      isNavigateToPayment: isNavigateToPayment ?? this.isNavigateToPayment,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentMethodName: paymentMethodName ?? this.paymentMethodName,
      isCorporateTrip: isCorporateTrip ?? this.isCorporateTrip,
      isFavourite: isFavourite ?? this.isFavourite,
    );
  }
}

/// Feedback screen ViewModel (matches Kotlin FeedbackViewModel tip/payment flow)
class FeedbackViewModel extends StateNotifier<FeedbackState> {
  final HistoryRepository _historyRepository;
  final AppRepository _appRepository;
  final SharedPreferenceManager _sharedPref;
  final FeedbackParams _params;

  String get _bookingId => _params.bookingId;

  // City setting from response (for tip data)
  BookingCitySetting? _citySetting;
  // Payment manager for card gateway tips
  PaymentInterface? _paymentManager;

  FeedbackViewModel(
    this._historyRepository,
    this._appRepository,
    this._sharedPref,
    this._params,
  ) : super(const FeedbackState()) {
    // Reaching feedback means the ride is over, so the live booking surface
    // must be gone — a catch-all for any completion path that skipped teardown.
    LiveActivityManager.instance.stopActivity(_params.bookingId);
    _getBookingDetails();
  }

  // ─── Booking Details ───

  Future<void> _getBookingDetails() async {
    state = state.copyWith(isLoading: true);

    if (_params.isFromHistory) {
      final response =
          await _historyRepository.getHistoryBookingDetails(_bookingId);

      switch (response) {
        case Success<BookingDetailResponse>():
          final booking = response.data?.booking;
          if (booking == null) {
            state =
                state.copyWith(isLoading: false, error: '');
            return;
          }
          _citySetting = booking.historyCitySetting;
          _processBookingDetails(booking, response.data);

        case Error<BookingDetailResponse>():
          state = state.copyWith(
            isLoading: false,
            error: response.error?.message,
          );

        case Loading<BookingDetailResponse>():
          break;
      }
    } else {
      final response = await _appRepository.getBookingDetails(_bookingId);

      switch (response) {
        case Success<BookingDetailResponse>():
          final booking = response.data?.booking;
          if (booking == null) {
            state =
                state.copyWith(isLoading: false, error: '');
            return;
          }
          _citySetting =
              response.data?.citySetting ?? booking.historyCitySetting;
          _processBookingDetails(booking, response.data);

        case Error<BookingDetailResponse>():
          state = state.copyWith(
            isLoading: false,
            error: response.error?.message,
          );

        case Loading<BookingDetailResponse>():
          break;
      }
    }
  }

  void _processBookingDetails(
    BookingDetails booking,
    BookingDetailResponse? detailResponse,
  ) {
    final driver = booking.confirmedDriver;
    final invoice = booking.bookingInvoice;

    // Driver image
    String? driverImageUrl;
    if (driver?.imageUrl != null && driver!.imageUrl!.isNotEmpty) {
      driverImageUrl = ServerConfig.getFullImageUrl(driver.imageUrl);
    }

    // Distance from actual (matching Kotlin: bookingInvoice.actual.distance)
    String? distanceStr;
    final actualDistanceInMeters = invoice?.actual?.distance;
    if (actualDistanceInMeters != null && actualDistanceInMeters > 0) {
      final distanceUnit = invoice?.distanceUnit ?? 0;
      final isMiles = distanceUnit == DistanceUnit.miles;
      final convertedDistance = isMiles
          ? actualDistanceInMeters / 1609.344
          : actualDistanceInMeters / 1000.0;
      final unit = isMiles ? 'mi' : 'km';
      distanceStr = '${convertedDistance.toStringAsFixed(2)} $unit';
    }

    // Time from actual (matching Kotlin: bookingInvoice.actual.time)
    String? timeStr;
    final actualTime = invoice?.actual?.time;
    if (actualTime != null && actualTime > 0) {
      final minutes = (actualTime / 60).ceil();
      timeStr = '$minutes min';
    }

    // Payment method from booking invoice (matching Kotlin SetBookingData)
    final paymentMode = invoice?.paymentMode;
    final paymentGateways =
        _citySetting?.paymentSetting?.paymentGateways ?? [];
    final isPickup = booking.bookingType == _rideTypePickup;

    // Payment method name (matching Kotlin PaymentMode.getValue)
    String paymentMethodName = '';
    if (paymentMode == PaymentGatewayType.cash.value) {
      paymentMethodName = 'Select Payment Gateway';
    } else if (paymentMode != null) {
      final gateway = PaymentGatewayType.fromValue(paymentMode);
      paymentMethodName = gateway?.getName() ?? '';
    }

    state = state.copyWith(
      isLoading: false,
      booking: booking,
      driverId: driver?.id,
      driverName: driver?.name ?? '',
      driverImageUrl: driverImageUrl,
      distanceStr: distanceStr,
      timeStr: timeStr,
      paymentMethod: paymentMode,
      paymentMethodName: paymentMethodName,
      isCorporateTrip: booking.corporateId != null,
      isShowTipOptions: paymentGateways.isNotEmpty && !isPickup,
    );

    // Build tip price list
    _createTipPriceList(booking);

    // Check if driver is already a favourite
    _checkIfFavourite();
  }

  void _createTipPriceList(BookingDetails booking) {
    final tipPrices = _citySetting?.tipPrices ?? [];
    if (tipPrices.isEmpty) return;

    final invoice = booking.bookingInvoice;
    final currencyDirection = invoice?.setCurrencySign ?? 1;
    final currencySign = invoice?.currencySign ?? '';

    final options = tipPrices.map((price) {
      return TipOption(
        price: price,
        priceStr: price.applyPriceSetting(
          currencyDirection: currencyDirection,
          currencySign: currencySign,
          decimalPointValue: 0,
        ),
      );
    }).toList();

    state = state.copyWith(tipOptions: options);
  }

  // ─── Rating ───

  void selectRating(int rating) {
    state = state.copyWith(selectedRating: rating);
  }

  void updateComment(String comment) {
    state = state.copyWith(comment: comment);
  }

  // ─── Tip (matching Kotlin TipSelection / TipAmountChange events) ───

  /// Select a predefined tip option
  void selectTip(int index) {
    final tipOption = state.tipOptions[index];
    final updated = state.tipOptions.asMap().entries.map((entry) {
      return entry.value.copyWith(isSelected: entry.key == index);
    }).toList();

    state = state.copyWith(
      selectedTip: tipOption,
      tipOptions: updated,
      customTipAmount: '',
      showPaymentOption: true,
    );
  }

  /// Update custom tip amount (matching Kotlin TipAmountChange)
  void updateTipAmount(String amount) {
    final deselected =
        state.tipOptions.map((t) => t.copyWith(isSelected: false)).toList();

    state = state.copyWith(
      customTipAmount: amount,
      clearSelectedTip: true,
      tipOptions: deselected,
      showPaymentOption: amount.isNotEmpty,
    );
  }

  /// Update payment method (matching Kotlin CardSelection event)
  void updatePaymentMethod(int paymentGateway, String name) {
    state = state.copyWith(
      paymentMethod: paymentGateway,
      paymentMethodName: name,
    );
  }

  /// Get current tip amount (from selectedTip or custom input)
  double _getTipAmount() {
    if (state.selectedTip != null) return state.selectedTip!.price;
    if (state.customTipAmount.isNotEmpty) {
      return double.tryParse(state.customTipAmount) ?? 0;
    }
    return 0;
  }

  // ─── Navigation resets (matching Kotlin ChangeNavigate* events) ───

  void resetNavigateToPayment() {
    state = state.copyWith(isNavigateToPayment: false);
  }

  void resetNavigateToWebView() {
    state = state.copyWith(isNavigateToWebView: false);
  }

  // ─── Submit (matching Kotlin SubmitClick flow exactly) ───

  Future<void> submitRating() async {
    // Guard against multiple submissions
    if (state.isLoading) return;

    // Check if tip is present (matching Kotlin: tipAmount.isNotEmpty || selectedTip != null)
    if (state.customTipAmount.isNotEmpty || state.selectedTip != null) {
      // If payment method is CASH → navigate to payment selection screen
      if (state.paymentMethod == PaymentGatewayType.cash.value) {
        state = state.copyWith(isNavigateToPayment: true);
      } else {
        await _paymentIntentCreate();
      }
    } else {
      await _submitRatingApi();
    }
  }

  /// Payment intent creation (matching Kotlin paymentIntentCreate exactly)
  Future<void> _paymentIntentCreate() async {
    final paymentGateway = state.paymentMethod;
    if (paymentGateway == null) return;

    final tipAmount = _getTipAmount();
    if (tipAmount <= 0) return;

    state = state.copyWith(isLoading: true);

    if (paymentGateway == PaymentGatewayType.wallet.value) {
      // Wallet payment (matching Kotlin wallet branch)
      await _walletTipPayment(tipAmount);
    } else {
      // Card/gateway payment (matching Kotlin card branch)
      await _cardTipPayment(tipAmount, paymentGateway);
    }
  }

  /// Wallet tip payment (matching Kotlin walletTipPayment)
  Future<void> _walletTipPayment(double tipAmount) async {
    final request = WalletPaymentRequest(amount: tipAmount);
    final response =
        await _appRepository.walletTipPayment(_bookingId, request);

    switch (response) {
      case Success<dynamic>():
        // Matching Kotlin: set isLoading false, then call submitRating
        state = state.copyWith(isLoading: false);
        await _submitRatingApi();

      case Error<dynamic>():
        state = state.copyWith(
          isLoading: false,
          isTipPaymentFailed: true,
          error: response.error?.message,
        );

      case Loading<dynamic>():
        break;
    }
  }

  /// Card gateway tip payment (matching Kotlin card payment flow)
  Future<void> _cardTipPayment(double tipAmount, int paymentGateway) async {
    // Initialize payment manager (Stripe native, everything else WebView)
    _paymentManager = switch (paymentGateway) {
      int g when g == PaymentGatewayType.stripe.value => StripePaymentManager(),
      int g when g == PaymentGatewayType.paystack.value => PayStackManager(),
      _ => WebViewPaymentManager(),
    };

    final entity = _sharedPref.getEntity();
    final request = WalletPaymentRequest(
      amount: tipAmount,
      countryId: entity?.countryId,
      currency: entity?.creditCurrencyCode,
      paymentPurpose: PaymentPurposeType.tipPayment,
      bookingId: _bookingId,
    );

    final response = await _appRepository.paymentIntentCreate(
      paymentGateway: paymentGateway.toString(),
      request: request,
    );

    switch (response) {
      case Success<PaymentIntentResponse>():
        _handlePaymentIntentResponse(response.data, response.message);

      case Error<PaymentIntentResponse>():
        state = state.copyWith(
          isLoading: false,
          isTipPaymentFailed: true,
          error: response.error?.message,
        );

      case Loading<PaymentIntentResponse>():
        break;
    }
  }

  /// Handle payment intent response (matching Kotlin INITIATED/PAID/else flow)
  void _handlePaymentIntentResponse(
      PaymentIntentResponse? data, String? message) {
    if (data?.paymentTransactionStatus ==
        PaymentTransactionStatus.initiated) {
      _paymentManager?.initPaymentSdk(data?.intent?.publicKey ?? '');
      _paymentManager?.createPaymentIntent(
        intent: data?.intent,
        callback: PaymentCallbackImpl(
          onSuccess: (paymentMethodId, intentResponse) {
            if (paymentMethodId != null) {
              _submitRatingApi();
            } else {
              WebViewDataModel? webViewData;
              if (intentResponse?.url != null &&
                  intentResponse!.url!.isNotEmpty) {
                webViewData = WebViewDataModel(
                  webURL: Uri.encodeFull(intentResponse.url!),
                );
              } else if (intentResponse?.html != null &&
                  intentResponse!.html!.isNotEmpty) {
                webViewData = WebViewDataModel(
                  webContent: Uri.encodeFull(intentResponse.html!),
                );
              }
              if (webViewData != null) {
                state = state.copyWith(
                  isNavigateToWebView: !state.isNavigateToWebView,
                  navigateURL: webViewData,
                );
              }
            }
          },
          onCapture: () {},
          onCardCreated: (_, _) {},
          onError: (error) {
            debugPrint('Tip payment error: $error');
            state = state.copyWith(isLoading: false, isTipPaymentFailed: true);
          },
        ),
      );
    } else if (data?.paymentTransactionStatus ==
        PaymentTransactionStatus.paid) {
      _submitRatingApi();
    } else {
      state = state.copyWith(
        isLoading: false,
        error: message,
      );
      _submitRatingApi();
    }
  }

  /// Handle WebView payment result (matching Kotlin PaymentResponse event)
  void handleWebViewPaymentResult(bool success) {
    state = state.copyWith(isNavigateToWebView: false);
    if (success) {
      _submitRatingApi();
    } else {
      state = state.copyWith(isLoading: false, isTipPaymentFailed: true);
    }
  }

  /// Submit rating to API (matching Kotlin submitRating — taxi/driver only)
  Future<void> _submitRatingApi() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final request = SubmitRatingRequest(
      bookingId: _bookingId,
      rate: state.selectedRating.toDouble(),
      review: state.comment.isNotEmpty ? state.comment : null,
      rateTo: EntityType.driver,
    );

    final response = await _appRepository.submitRating(_bookingId, request);

    switch (response) {
      case Success<dynamic>():
        // Matching Kotlin: isFromHistory → isNavigateBack, else → isNavigateToHome
        if (_params.isFromHistory) {
          state = state.copyWith(isLoading: false, isNavigateBack: true);
        } else {
          state = state.copyWith(isLoading: false, isNavigateToHome: true);
        }

      case Error<dynamic>():
        state = state.copyWith(
          isLoading: false,
          error: response.error?.message,
        );

      case Loading<dynamic>():
        break;
    }
  }

  /// Skip rating / Maybe Later (matching Kotlin MaybeLaterClick)
  void skipRating() {
    state = state.copyWith(isNavigateToHome: true);
  }

  // ─── Favourite Driver ───

  /// Check if current driver is already a favourite
  Future<void> _checkIfFavourite() async {
    final driverId = state.driverId;
    if (driverId == null) return;

    final response = await _appRepository.getFavouriteDrivers();

    switch (response) {
      case Success<FavouriteDriverResponse>():
        final isFav = response.data?.favouriteDrivers
                ?.any((d) => d.id == driverId) ??
            false;
        state = state.copyWith(isFavourite: isFav);
      case Error<FavouriteDriverResponse>():
        break;
      case Loading<FavouriteDriverResponse>():
        break;
    }
  }

  /// Add current driver as favourite
  Future<void> addFavourite() async {
    final driverId = state.driverId;
    if (driverId == null) return;

    final request = AddFavouriteDriverRequest(driverId: driverId);
    final response = await _appRepository.addFavouriteDriver(request);

    switch (response) {
      case Success():
        state = state.copyWith(isFavourite: true);
      case Error():
        break;
      case Loading():
        break;
    }
  }

  /// Remove current driver from favourites
  Future<void> removeFavourite() async {
    final driverId = state.driverId;
    if (driverId == null) return;

    final response = await _appRepository.deleteFavouriteDriver(driverId);

    switch (response) {
      case Success():
        state = state.copyWith(isFavourite: false);
      case Error():
        break;
      case Loading():
        break;
    }
  }

  /// Get city setting payment setting (for payment screen navigation)
  BookingPaymentSetting? get paymentSetting => _citySetting?.paymentSetting;
}

/// Provider for FeedbackViewModel
final feedbackViewModelProvider = StateNotifierProvider.autoDispose
    .family<FeedbackViewModel, FeedbackState, FeedbackParams>(
        (ref, params) {
  final historyRepository = ref.watch(historyRepositoryProvider);
  final appRepository = ref.watch(appRepositoryProvider);
  final sharedPref = ref.watch(sharedPreferenceManagerProvider).valueOrNull;
  return FeedbackViewModel(
    historyRepository,
    appRepository,
    sharedPref!,
    params,
  );
});
