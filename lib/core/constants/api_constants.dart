/// API Parameters used in headers and request bodies
class ApiParams {
  static const String authorization = 'Authorization';
  static const String language = 'language';
  static const String type = 'type';
  static const String page = 'page';
  static const String limit = 'limit';
  static const String sortOrder = 'sortOrder';
  static const String deviceType = 'deviceType';
  static const String userType = 'userType';
  static const String notificationType = 'notificationType';
  static const String expiryDate = 'expiryDate';
  static const String uniqueCode = 'uniqueCode';
  static const String startDate = 'startDate';
  static const String endDate = 'endDate';
}

/// Main API Endpoints
class ApiEndpoint {
  static const String getToken = 'auth/get_token';
  static const String getEntityDetail = 'auth/get_entity_detail';
  static const String getLanguageStrings = 'language/strings';
  static const String getCountries = 'country/all';
  static const String checkRegistered = 'auth/check_registered';
  static const String generateOtp = 'auth/generate_otp';
  static const String verifyOtp = 'auth/verify_otp';
  static const String stringIn = 'auth/signin';
  static const String signOut = 'auth/signout';
  static const String signUp = 'auth/customer/signup';
  static const String googleGeocode = 'gmaps/maps/api/geocode/json';
  static const String googleDirections = 'gmaps/maps/api/directions/json';
  static const String changePassword = 'auth/change_password';
  static const String getBusinessType = 'booking/businessType';
  static const String getVehicleTypes = 'booking/taxi/get_vehicle_types';
  static const String deviceToken = 'auth/device_token';
  static const String uploadActivityToken = 'booking/notification_token';
  static const String updateProfile = 'auth/update_profile';
  static const String profilePicture = 'auth/profile_picture';
  static const String getDocuments = 'uploaded_document';
  static const String uploadDocument = 'uploaded_document/{documentId}';
  static const String transactionCredit = 'transaction/credit';
  static const String getRewardPoints = 'transaction/reward_point';
  static const String withdrawRewardPoints = 'transaction/reward_point/withdraw';
  static const String getLanguage = 'language';
  static const String setLanguage = 'auth/language';
  static const String getEmergencyContact = 'emergency_contact';
  static const String modifyEmergencyContact = 'emergency_contact/{contactId}';
  static const String deleteAccount = 'auth/delete_account';
  static const String referralHistory = 'referral';
  static const String getSupportTicketHistory = 'support/ticket';
  static const String addSupportTicketIkmage = 'support/ticket/image/{ticketId}';
  static const String updateTicketStatus = 'support/ticket/{ticketId}/status';
  static const String getSupportTicketCategories = 'support/ticket/categories';
  static const String getNotifications = 'notifiations';
  static const String address = 'address';
  static const String modifyAddress = 'address/{addressId}';
  static const String accessibility = 'accessibility';
  static const String getCards = 'card';
  static const String getFareEstimate = 'booking/taxi/get_fare_estimate';
  static const String createBooking = 'booking/taxi';
  static const String findNearestDrivers = 'booking/taxi/find_nearest_driver';
  static const String googleDistanceMatrix = 'gmaps/maps/api/distancematrix/json';
  static const String googleRouteDistanceMatrix = 'gmaps/routes/distanceMatrix/v2:computeRouteMatrix';
  static const String cancellationPolicy = 'booking/cancellation_policy';
  static const String getPaymentGateways = 'payment_gateway/user';
  static const String getCorporatePaymentGateways = 'payment_gateway/corporate';
  static const String addCardIntent = 'card/intent/add/{gateway}';
  static const String addCard = 'card/{gateway}';
  static const String modifyCard = 'card/{cardId}';
  static const String paymentIntentCreate = 'payment/intent/create/{paymentGateway}';
  static const String transferCredits = 'transaction/credit/transfer';
  static const String searchUser = 'transaction/credit/transfer/search_user';
  static const String getPromoCodes = "booking/promocode_list";
  static const String validatePromo = 'booking/validate_promo';
  static const String getBookingDetails = 'booking/{id}';
  static const String cancelBooking = 'booking/cancel/{bookingId}';
  static const String getCancellationCharges = 'booking/cancellation_charge/{id}';
  static const String cancellationReason = 'cancellation_reason';
  static const String submitInvoice = 'booking/submit_invoice/{bookingId}';
  static const String calling = 'calling/{bookingId}';
  static const String supportCalling = 'calling/support_call';
  static const String acceptBidding = 'booking/taxi/customer_accept_bidding/{bookingId}';
  static const String rejectBidding = 'booking/taxi/customer_reject_bidding/{bookingId}';
  static const String fixGroupBookingDetails = 'booking/fixed_group_ride/{id}';
  static const String cancelFixBookingDetails = 'booking/fixed_group_ride/cancel/{id}';
  static const String sosCall = 'sms_template/sos/{bookingId}';
  static const String partialPaymentByCash = 'payment/cash/booking/{bookingId}';
  static const String walletBookingPayment = 'payment/wallet/booking/{bookingId}';
  static const String fixGroupWalletBookingPayment = 'payment/wallet/fixed_group_ride/{bookingId}';
  static const String submitRating = 'booking/submit_rating';
  static const String favouriteDriver = 'booking/favourite_driver';
  static const String walletTipPayment = 'payment/wallet/tip/{bookingId}';
  static const String bookingList = 'booking';
  static const String updateBookingAddress = 'booking/taxi/update_address/{id}';
  static const String informationStatus = 'auth/customer/information_status';

  // ── Delivery (store) business ──────────────────────────────────
  static const String checkDeliveryBusiness = 'booking/delivery/check_business';
  static const String getDeliveryMerchants = 'booking/delivery/merchants';
  static const String getMainCategories = 'main_category';
  static const String getDynamicGroups = 'dynamic_group/get';
  static const String getMerchantMenu = 'group';
  static const String getProductList = 'product/list';
  static const String getProductDetail = 'product/{productId}';
  static const String getDeliveryCart = 'booking/delivery/cart';
  static const String createDeliveryOrder = 'booking/delivery';
}

/// History API Endpoints
class HistoryApiEndpoint {
  static const String bookingHistory = 'booking_history';
}

/// Socket API Endpoints
class SocketApiEndpoint {
  static const String location = 'api/location/{bookingId}';
  static const String shareLink = 'api/location/share/{bookingId}';
  static const String chatAttachment = 'api/chat/attachment';
}
