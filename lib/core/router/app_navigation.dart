import 'package:flutter/material.dart';
import '../../models/ride_type_item.dart';
import 'package:go_router/go_router.dart';

import '../../models/responses/auth/country_response.dart';
import '../../models/requests/get_vehicle_types_request.dart';
import '../../models/requests/promo_code_list_request.dart';
import '../../models/responses/address/address_response.dart';
import '../../models/responses/booking/booking_detail_response.dart';
import '../../models/responses/booking/get_vehicle_type_response.dart';
import '../../models/responses/payment/card_response.dart';
import '../../models/webview_data_model.dart';
import '../../models/chat/chat_models.dart';
import '../../viewmodels/contact_us_viewmodel.dart';
import '../../viewmodels/edit_profile_viewmodel.dart';
import '../../viewmodels/promo_offer_viewmodel.dart';
import '../../models/ride_for_other_result.dart';
import '../../features/ai/ai_models.dart';
import '../../views/bottomsheets/schedule_ride_bottom_sheet.dart';
import '../constants/app_constants.dart';

extension AppNavigation on BuildContext {
  Future<OrderSuggestion?> navigateToAiAssistant() async =>
      await push<OrderSuggestion?>('/ai-assistant');
  // Common
  void goBack<T>([T? result]) => pop(result);

  // Auth & Main
  void navigateToLogin() => go('/login');

  void navigateToHome() => go('/home');

  // Auth Flow - Verification
  void navigateToVerificationPhone({
    required String phoneNumber,
    required String countryPhoneCode,
    int otpLength = 6,
    bool supportsOtp = true,
    bool supportsPassword = false,
  }) {
    push('/verification', extra: {
      'loginType': 'phone',
      'phoneNumber': phoneNumber,
      'countryPhoneCode': countryPhoneCode,
      'otpLength': otpLength,
      'supportsOtp': supportsOtp,
      'supportsPassword': supportsPassword,
    });
  }

  void navigateToVerificationEmail({
    int otpLength = 6,
    bool supportsOtp = true,
    bool supportsPassword = false,
  }) {
    push('/verification', extra: {
      'loginType': 'email',
      'otpLength': otpLength,
      'supportsOtp': supportsOtp,
      'supportsPassword': supportsPassword,
    });
  }

  // Auth Flow - Register
  void navigateToRegisterPhone({
    required String phoneNumber,
    required String countryPhoneCode,
    required List<Country> countries,
    Country? selectedCountry,
  }) {
    push('/register', extra: {
      'origin': 'phone',
      'phoneNumber': phoneNumber,
      'countryPhoneCode': countryPhoneCode,
      'countries': countries,
      'selectedCountry': selectedCountry,
    });
  }

  void navigateToRegisterEmail({
    required String email,
    required List<Country> countries,
    Country? selectedCountry,
  }) {
    push('/register', extra: {
      'origin': 'email',
      'email': email,
      'countries': countries,
      'selectedCountry': selectedCountry,
    });
  }

  void navigateToRegisterSocial({
    required String socialId,
    required int authMethod,
    String? firstName,
    String? lastName,
    String? email,
    required List<Country> countries,
    Country? selectedCountry,
  }) {
    push('/register', extra: {
      'origin': 'social',
      'socialId': socialId,
      'authMethod': authMethod,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'countries': countries,
      'selectedCountry': selectedCountry,
    });
  }

  // Auth Flow - Forgot Password
  void navigateToForgotPasswordPhone({
    required String phoneNumber,
    required String countryPhoneCode,
    int otpLength = 6,
  }) {
    push('/forgot-password', extra: {
      'loginType': 'phone',
      'phoneNumber': phoneNumber,
      'countryPhoneCode': countryPhoneCode,
      'otpLength': otpLength,
    });
  }

  void navigateToForgotPasswordEmail({
    required String email,
    int otpLength = 6,
  }) {
    push('/forgot-password', extra: {
      'loginType': 'email',
      'email': email,
      'otpLength': otpLength,
    });
  }

  // Profile
  Future<T?> navigateToProfile<T>() => push<T>('/profile');

  Future<T?> navigateToEditProfile<T>(EditProfileField field) =>
      push<T>('/edit-profile/${field.name}');

  Future<void> navigateToDocuments() => push('/documents');

  void navigateToLegal() => push('/legal');

  void navigateToSettings() => push('/settings');

  // Wallet, Referral & Redeem
  void navigateToWalletHistory() => push('/wallet-history');

  void navigateToRedeem() => push('/redeem');

  void navigateToReferral() => push('/referral');

  void navigateToReferralList() => push('/referral-list');

  // Favourite
  void navigateToFavouriteDrivers() => push('/favourite-drivers');

  // Support
  void navigateToContactUs() => push('/contact-us');

  Future<bool?> navigateToTicketDetail(SupportTicketItem ticket) =>
      push<bool>('/ticket-detail', extra: ticket);

  void navigateToInbox() => push('/inbox');

  void navigateToActivity() => push('/activity');

  /// Open a store's menu / product-listing screen.
  void navigateToMerchantDetail({
    required Object merchant,
    String? mainCategoryId,
    String? cityId,
    String? timezone,
  }) =>
      push('/merchant-detail', extra: {
        'merchant': merchant,
        'mainCategoryId': mainCategoryId,
        'cityId': cityId,
        'timezone': timezone,
      });

  /// Open the delivery cart / checkout screen.
  void navigateToCart() => push('/cart');

  /// Navigate to payment screen
  /// Matches Kotlin navigation arguments:
  /// - IS_NAVIGATE_TO_BOOKING
  /// - VEHICLE_TYPE_PAYMENT_GATEWAYS
  /// - PAYMENT_SETTINGS
  /// - SELECTED_PAYMENT_GATEWAYS
  /// - SELECTED_CARD
  /// - TOTAL_AMOUNT
  /// - CORPORATE_BOOKING
  /// - SELECTED_PAYMENT_METHOD
  /// - IS_PRE_BOOKING_PAYMENT
  /// - IS_CURRENT_BOOKING
  /// - IS_FROM_SUBSCRIPTION
  Future<CardResponse?> navigateToPayment({
    bool isComeFromBooking = false,
    VehicleTypePaymentSetting? vehicleTypePaymentSetting,
    BookingPaymentSetting? myBookingPaymentSetting,
    int? selectedPaymentGateway,
    CardResponse? selectedCard,
    double totalAmount = 0.0,
    bool isCorporateBooking = false,
    CardResponse? selectedPaymentMethod,
    bool isPreBookingPayment = false,
    bool isFromCurrentBooking = false,
    bool isFromFeedBack = false,
    bool isFromSubscription = false,
  }) async {
    return await push<CardResponse>('/payment', extra: {
      'isComeFromBooking': isComeFromBooking,
      'vehicleTypePaymentSetting': vehicleTypePaymentSetting,
      'myBookingPaymentSetting': myBookingPaymentSetting,
      'selectedPaymentGateway': selectedPaymentGateway,
      'selectedCard': selectedCard,
      'totalAmount': totalAmount,
      'isCorporateBooking': isCorporateBooking,
      'selectedPaymentMethod': selectedPaymentMethod,
      'isPreBookingPayment': isPreBookingPayment,
      'isFromCurrentBooking': isFromCurrentBooking,
      'isFromFeedBack': isFromFeedBack,
      'isFromSubscription': isFromSubscription,
    });
  }

  void navigateToWebView({
    WebViewDataModel? webViewData,
    void Function(String?)? onPaymentData,
  }) {
    push('/webview', extra: {
      'webViewData': webViewData,
      'onPaymentData': onPaymentData,
    });
  }

  // Booking Flow
  /// Navigate to plan ride screen
  /// [rideType] - null means show all types, specific type filters to that type
  void navigateToPlanRide({
    DestinationAddress? pickupAddress,
    RideType? rideType,
    CitySetting? citySetting,
    String? selectedVehicleTypeId,
    List<RideTypeItem>? rideTypeItems,
  }) {
    push('/plan-ride', extra: {
      'pickupAddress': pickupAddress,
      'rideType': rideType,
      'citySetting': citySetting,
      'selectedVehicleTypeId': selectedVehicleTypeId,
      // Handed over from home rather than re-read from a provider: the home
      // view model is autoDispose, so reading it here would spin up a second
      // instance and refetch the whole vehicle-type call.
      'rideTypeItems': rideTypeItems,
    });
  }

  void navigateToAddStops({
    required DestinationAddress pickup,
    DestinationAddress? destination,
    RideType? rideType,
    CitySetting? citySetting,
    ScheduleRideResult? scheduleResult,
    String? selectedVehicleTypeId,
    RideForOtherResult? rideForOtherResult,
  }) {
    push('/add-stops', extra: {
      'pickup': pickup,
      'destination': destination,
      'rideType': rideType,
      'citySetting': citySetting,
      'scheduleResult': scheduleResult,
      'selectedVehicleTypeId': selectedVehicleTypeId,
      'rideForOtherResult': rideForOtherResult,
    });
  }

  void navigateToChooseRide({
    required DestinationAddress pickup,
    required List<DestinationAddress> destinations,
    RideType? rideType,
    CitySetting? citySetting,
    ScheduleRideResult? scheduleResult,
    String? selectedVehicleTypeId,
    bool isDestinationLater = false,
    RideForOtherResult? rideForOtherResult,
  }) {
    push('/choose-ride', extra: {
      'pickup': pickup,
      'destinations': destinations,
      'rideType': rideType,
      'citySetting': citySetting,
      'scheduleResult': scheduleResult,
      'selectedVehicleTypeId': selectedVehicleTypeId,
      'isDestinationLater': isDestinationLater,
      'rideForOtherResult': rideForOtherResult,
    });
  }

  // Saved Places
  void navigateToSavedPlaces({bool isForAddressSelect = false}) {
    push('/saved-places', extra: {
      'isForAddressSelect': isForAddressSelect,
    });
  }

  Future<DestinationAddress?> navigateToSavedPlacesForResult() async {
    return await push<DestinationAddress>('/saved-places', extra: {
      'isForAddressSelect': true,
    });
  }

  void navigateToAddSavedPlace({
    SavedAddress? address,
    int? addressType,
    DestinationAddress? selectedLocation,
  }) {
    push('/add-saved-place', extra: {
      'address': address,
      'addressType': addressType,
      'selectedLocation': selectedLocation,
    });
  }

  Future<DestinationAddress?> navigateToSelectLocation({
    DestinationAddress? initialAddress,
    String? countryCode,
  }) async {
    return await push<DestinationAddress>(
      '/select-location',
      extra: {
        'initialAddress': initialAddress,
        'countryCode': countryCode,
      },
    );
  }

  /// Navigate to promo offer screen and return selected promo
  Future<PromoDetail?> navigateToPromoOffer({
    required PromoCodeListRequest promoCodeListRequest,
    int bookingTime = 0,
    int priceMode = 0,
    int paymentMode = 0,
    double? latitude,
    double? longitude,
  }) async {
    return await push<PromoDetail>(
      '/promo-offer',
      extra: PromoOfferParams(
        promoCodeListRequest: promoCodeListRequest,
        bookingTime: bookingTime,
        priceMode: priceMode,
        paymentMode: paymentMode,
        latitude: latitude,
        longitude: longitude,
      ),
    );
  }

  /// Navigate to current ride screen
  void navigateToCurrentRide({required String bookingId}) {
    push('/current-ride/$bookingId');
  }

  /// Navigate to chat screen
  void navigateToChat({required ChatConfig chatConfig}) {
    push('/chat', extra: chatConfig);
  }

  /// Navigate to image viewer screen
  void navigateToImageViewer({required String imageUrl}) {
    push('/image-viewer', extra: imageUrl);
  }

  /// Navigate to receipt/invoice screen
  void navigateToReceipt(
      {required BookingDetailResponse bookingDetailResponse}) {
    push('/receipt', extra: bookingDetailResponse);
  }
}
