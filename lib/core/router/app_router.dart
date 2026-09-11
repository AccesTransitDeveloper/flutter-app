import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/ride_type_item.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_constants.dart';
import '../../models/requests/get_vehicle_types_request.dart';
import '../../models/responses/booking/booking_detail_response.dart';
import '../../models/responses/booking/get_vehicle_type_response.dart';
import '../../models/responses/payment/card_response.dart';
import '../../views/bottomsheets/schedule_ride_bottom_sheet.dart';
// Splash
import '../../views/screens/splash/splash_screen.dart';
// Auth
import '../../views/screens/auth/login_screen.dart';
import '../../views/screens/auth/verification_screen.dart';
import '../../views/screens/auth/register_screen.dart';
import '../../views/screens/auth/forgot_password_screen.dart';
import '../../models/responses/auth/country_response.dart';
// Home
import '../../views/screens/main_screen.dart';
// Profile
import '../../views/screens/profile/profile_screen.dart';
import '../../views/screens/profile/edit_profile_screen.dart';
import '../../views/screens/profile/document_screen.dart';
// Legal
import '../../views/screens/legal/legal_screen.dart';
import '../../views/screens/legal/webview_screen.dart';
// Settings
import '../../views/screens/settings/settings_screen.dart';
import '../../views/screens/settings/saved_places_screen.dart';
import '../../views/screens/settings/add_saved_place_screen.dart';
import '../../views/screens/settings/select_location_screen.dart';
// Payment
import '../../views/screens/payment/redeem_screen.dart';
import '../../views/screens/payment/payment_screen.dart';
import '../../views/screens/payment/wallet_history_screen.dart';
// Favourite
import '../../views/screens/favourite/favourite_drivers_screen.dart';
// Referral
import '../../views/screens/referral/referral_screen.dart';
import '../../views/screens/referral/referral_list_screen.dart';
// Support
import '../../views/screens/support/contact_us_screen.dart';
import '../../views/screens/support/ticket_detail_screen.dart';
import '../../views/screens/support/inbox_screen.dart';
// Booking
import '../../views/screens/booking/plan_ride_screen.dart';
import '../../views/screens/booking/add_stops_screen.dart';
import '../../views/screens/booking/choose_ride_screen.dart';
import '../../views/screens/booking/cancellation_policy_screen.dart';
import '../../views/screens/booking/current_ride_screen.dart';
import '../../views/screens/booking/promo_offer_screen.dart';
import '../../viewmodels/promo_offer_viewmodel.dart';
import '../../models/ride_for_other_result.dart';
import '../../models/webview_data_model.dart';
import '../../models/chat/chat_models.dart';
import '../../views/screens/chat/chat_screen.dart';
import '../../views/screens/chat/image_viewer_screen.dart';
import '../../views/screens/delivery/merchant_detail_screen.dart';
import '../../views/screens/delivery/cart_screen.dart';
import '../../models/responses/delivery/delivery_responses.dart';
import '../../views/screens/activity/activity_screen.dart';
import '../../views/screens/activity/trip_detail_screen.dart';
import '../../views/screens/activity/upcoming_trip_detail_screen.dart';
import '../../views/screens/feedback/feedback_screen.dart';
import '../../views/screens/receipt/receipt_screen.dart';
import '../../viewmodels/edit_profile_viewmodel.dart';
import '../../viewmodels/contact_us_viewmodel.dart';
import '../../models/responses/address/address_response.dart';
import '../../views/screens/ai/ai_assistant_screen.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/ai-assistant',
        builder: (context, state) => const AiAssistantScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/verification',
        builder: (context, state) {
          final params = state.extra as Map<String, dynamic>;
          final loginType = params['loginType'] as String;

          if (loginType == 'phone') {
            return VerificationScreen.phone(
              phoneNumber: params['phoneNumber'] as String,
              countryPhoneCode: params['countryPhoneCode'] as String,
              otpLength: params['otpLength'] as int? ?? 6,
              supportsOtp: params['supportsOtp'] as bool? ?? true,
              supportsPassword: params['supportsPassword'] as bool? ?? false,
            );
          } else {
            return VerificationScreen.email(
              otpLength: params['otpLength'] as int? ?? 6,
              supportsOtp: params['supportsOtp'] as bool? ?? true,
              supportsPassword: params['supportsPassword'] as bool? ?? false,
            );
          }
        },
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) {
          final params = state.extra as Map<String, dynamic>;
          final origin = params['origin'] as String;

          if (origin == 'phone') {
            return RegisterScreen.phone(
              phoneNumber: params['phoneNumber'] as String,
              countryPhoneCode: params['countryPhoneCode'] as String,
              countries: params['countries'] as List<Country>,
              selectedCountry: params['selectedCountry'] as Country?,
            );
          } else if (origin == 'social') {
            return RegisterScreen.social(
              socialId: params['socialId'] as String,
              authMethod: params['authMethod'] as int,
              firstName: params['firstName'] as String?,
              lastName: params['lastName'] as String?,
              email: params['email'] as String?,
              countries: params['countries'] as List<Country>,
              selectedCountry: params['selectedCountry'] as Country?,
            );
          } else {
            return RegisterScreen.email(
              email: params['email'] as String,
              countries: params['countries'] as List<Country>,
              selectedCountry: params['selectedCountry'] as Country?,
            );
          }
        },
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) {
          final params = state.extra as Map<String, dynamic>;
          final loginType = params['loginType'] as String;

          if (loginType == 'phone') {
            return ForgotPasswordScreen.phone(
              phoneNumber: params['phoneNumber'] as String,
              countryPhoneCode: params['countryPhoneCode'] as String,
              otpLength: params['otpLength'] as int? ?? 6,
            );
          } else {
            return ForgotPasswordScreen.email(
              email: params['email'] as String,
              otpLength: params['otpLength'] as int? ?? 6,
            );
          }
        },
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const MainScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/edit-profile/:field',
        builder: (context, state) {
          final fieldParam = state.pathParameters['field'] ?? 'name';
          final field = EditProfileField.values.firstWhere(
            (f) => f.name == fieldParam,
            orElse: () => EditProfileField.name,
          );
          return EditProfileScreen(field: field);
        },
      ),
      GoRoute(
        path: '/documents',
        builder: (context, state) => const DocumentScreen(),
      ),
      GoRoute(
        path: '/legal',
        builder: (context, state) => const LegalScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/redeem',
        builder: (context, state) => const RedeemScreen(),
      ),
      GoRoute(
        path: '/wallet-history',
        builder: (context, state) => const WalletHistoryScreen(),
      ),
      GoRoute(
        path: '/favourite-drivers',
        builder: (context, state) => const FavouriteDriversScreen(),
      ),
      GoRoute(
        path: '/referral',
        builder: (context, state) => const ReferralScreen(),
      ),
      GoRoute(
        path: '/referral-list',
        builder: (context, state) => const ReferralListScreen(),
      ),
      GoRoute(
        path: '/contact-us',
        builder: (context, state) => const ContactUsScreen(),
      ),
      GoRoute(
        path: '/ticket-detail',
        builder: (context, state) {
          final ticket = state.extra as SupportTicketItem;
          return TicketDetailScreen(ticket: ticket);
        },
      ),
      GoRoute(
        path: '/inbox',
        builder: (context, state) => const InboxScreen(),
      ),
      GoRoute(
        path: '/payment',
        builder: (context, state) {
          final params = state.extra as Map<String, dynamic>?;
          return PaymentScreen(
            isComeFromBooking: params?['isComeFromBooking'] as bool? ?? false,
            vehicleTypePaymentSetting: params?['vehicleTypePaymentSetting'] as VehicleTypePaymentSetting?,
            myBookingPaymentSetting: params?['myBookingPaymentSetting'] as BookingPaymentSetting?,
            selectedPaymentGateway: params?['selectedPaymentGateway'] as int?,
            selectedCard: params?['selectedCard'] as CardResponse?,
            totalAmount: params?['totalAmount'] as double? ?? 0.0,
            isCorporateBooking: params?['isCorporateBooking'] as bool? ?? false,
            selectedPaymentMethod: params?['selectedPaymentMethod'] as CardResponse?,
            isPreBookingPayment: params?['isPreBookingPayment'] as bool? ?? false,
            isFromCurrentBooking: params?['isFromCurrentBooking'] as bool? ?? false,
            isFromFeedBack: params?['isFromFeedBack'] as bool? ?? false,
            isFromSubscription: params?['isFromSubscription'] as bool? ?? false,
          );
        },
      ),
      GoRoute(
        path: '/plan-ride',
        builder: (context, state) {
          final params = state.extra as Map<String, dynamic>?;
          final pickupAddress = params?['pickupAddress'] as DestinationAddress?;
          final rideType = params?['rideType'] as RideType?;
          final citySetting = params?['citySetting'] as CitySetting?;
          final selectedVehicleTypeId = params?['selectedVehicleTypeId'] as String?;
          final rideTypeItems = params?['rideTypeItems'] as List<RideTypeItem>?;
          return PlanRideScreen(
            initialPickupAddress: pickupAddress,
            rideType: rideType,
            citySetting: citySetting,
            selectedVehicleTypeId: selectedVehicleTypeId,
            rideTypeItems: rideTypeItems ?? const [],
          );
        },
      ),
      GoRoute(
        path: '/add-stops',
        builder: (context, state) {
          final params = state.extra as Map<String, dynamic>;
          return AddStopsScreen(
            pickupAddress: params['pickup'] as DestinationAddress,
            destinationAddress: params['destination'] as DestinationAddress?,
            rideType: params['rideType'] as RideType?,
            citySetting: params['citySetting'] as CitySetting?,
            initialScheduleResult: params['scheduleResult'] as ScheduleRideResult?,
            selectedVehicleTypeId: params['selectedVehicleTypeId'] as String?,
            initialRideForOtherResult: params['rideForOtherResult'] as RideForOtherResult?,
          );
        },
      ),
      GoRoute(
        path: '/saved-places',
        builder: (context, state) {
          final params = state.extra as Map<String, dynamic>?;
          return SavedPlacesScreen(
            isForAddressSelect: params?['isForAddressSelect'] as bool? ?? false,
          );
        },
      ),
      GoRoute(
        path: '/add-saved-place',
        builder: (context, state) {
          final params = state.extra as Map<String, dynamic>?;
          return AddSavedPlaceScreen(
            editingAddress: params?['address'] as SavedAddress?,
            addressType: params?['addressType'] as int?,
            selectedLocation: params?['selectedLocation'] as DestinationAddress?,
          );
        },
      ),
      GoRoute(
        path: '/select-location',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return SelectLocationScreen(
            initialAddress: extra?['initialAddress'] as DestinationAddress?,
            countryCode: extra?['countryCode'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/choose-ride',
        builder: (context, state) {
          final params = state.extra as Map<String, dynamic>;
          return ChooseRideScreen(
            pickupAddress: params['pickup'] as DestinationAddress,
            destinations: params['destinations'] as List<DestinationAddress>,
            rideType: params['rideType'] as RideType?,
            citySetting: params['citySetting'] as CitySetting?,
            scheduleResult: params['scheduleResult'] as ScheduleRideResult?,
            selectedVehicleTypeId: params['selectedVehicleTypeId'] as String?,
            isDestinationLater: params['isDestinationLater'] as bool? ?? false,
            rideForOtherResult: params['rideForOtherResult'] as RideForOtherResult?,
          );
        },
      ),
      GoRoute(
        path: '/cancellation-policy/:vehiclePriceId',
        builder: (context, state) {
          final vehiclePriceId = state.pathParameters['vehiclePriceId'] ?? '';
          return CancellationPolicyScreen(vehiclePriceId: vehiclePriceId);
        },
      ),
      GoRoute(
        path: '/promo-offer',
        builder: (context, state) {
          final params = state.extra as PromoOfferParams;
          return PromoOfferScreen(params: params);
        },
      ),
      GoRoute(
        path: '/webview',
        builder: (context, state) {
          final params = state.extra as Map<String, dynamic>?;
          final webViewData = params?['webViewData'] as WebViewDataModel?;
          final onPaymentData = params?['onPaymentData'] as void Function(String?)?;
          return WebViewScreen(
            webViewData: webViewData,
            onNavigateWithPaymentData: onPaymentData,
          );
        },
      ),
      GoRoute(
        path: '/current-ride/:bookingId',
        builder: (context, state) {
          final bookingId = state.pathParameters['bookingId'] ?? '';
          return CurrentRideScreen(bookingId: bookingId);
        },
      ),
      GoRoute(
        path: '/chat',
        builder: (context, state) {
          final chatConfig = state.extra as ChatConfig;
          return ChatScreen(chatConfig: chatConfig);
        },
      ),
      GoRoute(
        path: '/image-viewer',
        builder: (context, state) {
          final imageUrl = state.extra as String;
          return ImageViewerScreen(imageUrl: imageUrl);
        },
      ),
      GoRoute(
        path: '/merchant-detail',
        builder: (context, state) {
          final params = state.extra as Map<String, dynamic>;
          return MerchantDetailScreen(
            merchant: params['merchant'] as Merchant,
            mainCategoryId: params['mainCategoryId'] as String?,
            cityId: params['cityId'] as String?,
            timezone: params['timezone'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/cart',
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: '/activity',
        builder: (context, state) => const ActivityScreen(),
      ),
      GoRoute(
        path: '/trip-detail/:bookingId',
        builder: (context, state) {
          final bookingId = state.pathParameters['bookingId'] ?? '';
          return TripDetailScreen(bookingId: bookingId);
        },
      ),
      GoRoute(
        path: '/upcoming-trip-detail/:bookingId',
        builder: (context, state) {
          final bookingId = state.pathParameters['bookingId'] ?? '';
          return UpcomingTripDetailScreen(bookingId: bookingId);
        },
      ),
      GoRoute(
        path: '/receipt',
        builder: (context, state) {
          final bookingDetailResponse =
              state.extra as BookingDetailResponse?;
          return ReceiptScreen(
              bookingDetailResponse: bookingDetailResponse);
        },
      ),
      GoRoute(
        path: '/feedback/:bookingId',
        builder: (context, state) {
          final bookingId = state.pathParameters['bookingId'] ?? '';
          final extra = state.extra as Map<String, dynamic>?;
          final isFromHistory = extra?['isFromHistory'] as bool? ?? true;
          return FeedbackScreen(
            bookingId: bookingId,
            isFromHistory: isFromHistory,
          );
        },
      ),
    ],
  );
});
