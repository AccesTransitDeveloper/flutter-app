import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../../core/providers/app_providers.dart';
import '../../core/constants/api_constants.dart';
import '../../models/requests/device_token_request.dart';
import '../../models/requests/entity_detail_request.dart';
import '../../models/requests/firebase_device_token_request.dart';
import '../../models/requests/check_registered_request.dart';
import '../../models/requests/generate_otp_request.dart';
import '../../models/requests/verify_otp_request.dart';
import '../../models/requests/sign_in_request.dart';
import '../../models/requests/sign_up_request.dart';
import '../../models/requests/change_password_request.dart';
import '../../models/requests/business_type_request.dart';
import '../../models/requests/get_vehicle_types_request.dart';
import '../../models/requests/find_nearest_drivers_request.dart';
import '../../models/responses/booking/nearest_drivers_response.dart';
import '../../models/requests/update_profile_request.dart';
import '../../models/responses/auth/entity_detail_response.dart';
import '../../models/responses/booking/check_business_response.dart';
import '../../models/responses/booking/get_vehicle_type_response.dart';
import '../../models/responses/auth/country_response.dart';
import '../../models/responses/auth/verify_otp_response.dart';
import '../../models/responses/location/geocode_response.dart';
import '../../models/responses/document/document_response.dart';
import '../../models/responses/redeem/redeem_point_response.dart';
import '../../models/responses/payment/transaction_credit_response.dart';
import '../../models/requests/redeem_withdraw_request.dart';
import '../../models/requests/set_language_request.dart';
import '../../models/requests/emergency_contact_request.dart';
import '../../models/responses/setting/language_response.dart';
import '../../models/responses/setting/emergency_contact_response.dart';
import '../../models/responses/referral/referral_history_response.dart';
import '../../models/responses/support/support_ticket_response.dart';
import '../../models/requests/support_ticket_request.dart';
import '../../models/responses/notification/notification_response.dart';
import '../../models/responses/address/address_response.dart';
import '../../models/responses/booking/cancellation_policy_response.dart';
import '../../models/responses/payment/payment_gateway_response.dart';
import '../../models/responses/payment/corporate_payment_response.dart';
import '../../models/responses/payment/add_card_intent_response.dart';
import '../../models/requests/add_card_request.dart';
import '../../models/requests/wallet_payment_request.dart';
import '../../models/responses/payment/payment_intent_response.dart';
import '../../models/responses/payment/card_response.dart';
import '../../models/requests/transfer_credit_request.dart';
import '../../models/requests/promo_code_list_request.dart';
import '../../models/requests/validate_promo_code_request.dart';
import '../../models/requests/fare_estimate_request.dart';
import '../../models/responses/payment/search_user_response.dart';
import '../../models/responses/booking/promo_code_response.dart';
import '../../models/responses/booking/fare_estimate_response.dart';
import '../../models/responses/booking/my_bookings_response.dart';
import '../../models/requests/create_booking_request.dart';
import '../../models/requests/cancel_booking_request.dart';
import '../../models/requests/submit_invoice_request.dart';
import '../../models/requests/bidding_accept_request.dart';
import '../../models/requests/submit_rating_request.dart';
import '../../models/requests/add_favourite_driver_request.dart';
import '../../models/responses/driver/favourite_driver_response.dart';
import '../../models/responses/booking/create_booking_response.dart';
import '../../models/responses/booking/booking_detail_response.dart';
import '../../models/responses/booking/cancellation_charge_response.dart';
import '../../models/responses/setting/cancellation_reason_response.dart';
import '../../models/responses/booking/accessibility_response.dart';
import '../../models/responses/booking/fix_group_detail_response.dart';
import '../../models/responses/setting/missing_information_response.dart';
import '../../models/requests/distance_matrix_request.dart';
import '../../models/responses/location/distance_matrix_response.dart';
import '../../models/requests/delivery/delivery_requests.dart';
import '../../models/requests/delivery/cart_requests.dart';
import '../../models/responses/delivery/delivery_responses.dart';
import '../../models/responses/delivery/merchant_menu_responses.dart';
import '../../models/responses/delivery/cart_responses.dart';
import '../api/response_state.dart';

class AppRepository {
  final ApiClient apiClient;

  AppRepository(this.apiClient);

  Future<ResponseState<dynamic>> getToken(
      DeviceTokenRequest deviceTokenRequest) async {
    return apiClient.post<dynamic>(
      ApiEndpoint.getToken,
      headers: {
        ApiParams.type: '2',
      },
      body: deviceTokenRequest.toJson(),
    );
  }

  // ── Delivery (store) business ──────────────────────────────────

  Future<ResponseState<CheckDeliveryBusinessResponse>> checkDeliveryBusiness(
      CheckDeliveryBusinessRequest request) async {
    return apiClient.post<CheckDeliveryBusinessResponse>(
      ApiEndpoint.checkDeliveryBusiness,
      body: request.toJson(),
      fromJsonT: (json) => CheckDeliveryBusinessResponse.fromJson(json),
    );
  }

  Future<ResponseState<DeliveryCategoryResponse>> getDeliveryCategories(
      DeliveryCategoryRequest request) async {
    // main_category is a GET with query-string params (mirrors native).
    return apiClient.get<DeliveryCategoryResponse>(
      ApiEndpoint.getMainCategories,
      queryParameters: request.toQueryParameters(),
      fromJsonT: (json) => DeliveryCategoryResponse.fromJson(json),
    );
  }

  Future<ResponseState<MerchantListResponse>> getDeliveryMerchants(
      DeliveryMerchantListRequest request) async {
    return apiClient.post<MerchantListResponse>(
      ApiEndpoint.getDeliveryMerchants,
      body: request.toJson(),
      fromJsonT: (json) => MerchantListResponse.fromJson(json),
    );
  }

  Future<ResponseState<GroupListResponse>> getDeliveryGroups(
      DynamicGroupRequest request) async {
    return apiClient.post<GroupListResponse>(
      ApiEndpoint.getDynamicGroups,
      body: request.toJson(),
      fromJsonT: (json) => GroupListResponse.fromJson(json),
    );
  }

  /// Store menu / product listing for one merchant (GET group, groupFor=HOME).
  Future<ResponseState<MenuResponse>> getMerchantMenu(
      MerchantMenuRequest request) async {
    return apiClient.get<MenuResponse>(
      ApiEndpoint.getMerchantMenu,
      queryParameters: request.toQueryParameters(),
      fromJsonT: (json) => MenuResponse.fromJson(json),
    );
  }

  /// Products of one category within a merchant (the sectioned menu).
  Future<ResponseState<ProductListResponse>> getCategoryProducts(
      CategoryProductsRequest request) async {
    return apiClient.get<ProductListResponse>(
      ApiEndpoint.getProductList,
      queryParameters: request.toQueryParameters(),
      fromJsonT: (json) => ProductListResponse.fromJson(json),
    );
  }

  /// Full product detail (variants + modifiers) for the customize sheet.
  Future<ResponseState<ProductDetailResponse>> getProductDetail(
      String productId, ProductDetailRequest request) async {
    final path =
        ApiEndpoint.getProductDetail.replaceAll('{productId}', productId);
    return apiClient.get<ProductDetailResponse>(
      path,
      queryParameters: request.toQueryParameters(),
      fromJsonT: (json) => ProductDetailResponse.fromJson(json),
    );
  }

  /// Recalculate the delivery cart — availability + itemised price breakdown.
  Future<ResponseState<CartSummaryResponse>> getDeliveryCartSummary(
      CartSummaryRequest request) async {
    return apiClient.post<CartSummaryResponse>(
      ApiEndpoint.getDeliveryCart,
      body: request.toJson(),
      fromJsonT: (json) => CartSummaryResponse.fromJson(json),
    );
  }

  /// Place the delivery order.
  Future<ResponseState<PlaceOrderResponse>> placeDeliveryOrder(
      CreateOrderRequest request) async {
    return apiClient.post<PlaceOrderResponse>(
      ApiEndpoint.createDeliveryOrder,
      body: request.toJson(),
      fromJsonT: (json) => PlaceOrderResponse.fromJson(json),
    );
  }

  Future<ResponseState<EntityDetailResponse>> getEntityDetail(
      EntityDetailRequest entityDetailRequest) async {
    return apiClient.post<EntityDetailResponse>(
      ApiEndpoint.getEntityDetail,
      body: entityDetailRequest.toJson(),
      fromJsonT: (json) => EntityDetailResponse.fromJson(json),
    );
  }

  Future<ResponseState<Map<String, dynamic>>> getLanguageStrings(
      String language) async {
    return apiClient.get<Map<String, dynamic>>(
      ApiEndpoint.getLanguageStrings,
      headers: {
        ApiParams.language: language,
      },
      fromJsonT: (json) => json as Map<String, dynamic>,
    );
  }

  Future<ResponseState<CountryResponse>> getCountries() async {
    return apiClient.get<CountryResponse>(
      ApiEndpoint.getCountries,
      fromJsonT: (json) => CountryResponse.fromJson(json),
    );
  }

  Future<ResponseState<dynamic>> checkRegistered(
      CheckRegisteredRequest request) async {
    return apiClient.post<dynamic>(
      ApiEndpoint.checkRegistered,
      body: request.toJson(),
    );
  }

  Future<ResponseState<dynamic>> generateOtp(GenerateOtpRequest request) async {
    return apiClient.post<dynamic>(
      ApiEndpoint.generateOtp,
      body: request.toJson(),
    );
  }

  Future<ResponseState<VerifyOtpResponse>> verifyOtp(
      VerifyOtpRequest request) async {
    return apiClient.postRaw<VerifyOtpResponse>(
      ApiEndpoint.verifyOtp,
      body: request.toJson(),
      fromJson: (json) => VerifyOtpResponse.fromJson(json),
    );
  }

  Future<ResponseState<dynamic>> signIn(SignInRequest request) async {
    return apiClient.post<dynamic>(
      ApiEndpoint.stringIn,
      body: request.toJson(),
    );
  }

  Future<ResponseState<dynamic>> signOut() async {
    return apiClient.post<dynamic>(
      ApiEndpoint.signOut,
    );
  }

  Future<ResponseState<dynamic>> signUp(SignUpRequest request) async {
    return apiClient.post<dynamic>(
      ApiEndpoint.signUp,
      body: request.toJson(),
    );
  }

  /// Reverse geocode - get address from lat/lng
  Future<ResponseState<GeocodeResponse>> reverseGeocode({
    required double latitude,
    required double longitude,
    required String apiKey,
  }) async {
    return apiClient.getRaw<GeocodeResponse>(
      ApiEndpoint.googleGeocode,
      queryParameters: {
        'latlng': '$latitude,$longitude',
        'key': apiKey,
      },
      fromJson: (json) => GeocodeResponse.fromJson(json),
    );
  }

  /// Get directions between multiple points
  Future<ResponseState<GeocodeResponse>> getDirections({
    required String origin,
    required String destination,
    List<String>? waypoints,
    required String apiKey,
  }) async {
    final queryParameters = <String, String>{
      'origin': origin,
      'destination': destination,
      'key': apiKey,
    };

    if (waypoints != null && waypoints.isNotEmpty) {
      queryParameters['waypoints'] = waypoints.join('|');
    }

    return apiClient.getRaw<GeocodeResponse>(
      ApiEndpoint.googleDirections,
      queryParameters: queryParameters,
      fromJson: (json) => GeocodeResponse.fromJson(json),
    );
  }

  Future<ResponseState<dynamic>> changePassword(
      ChangePasswordRequest request) async {
    return apiClient.post<dynamic>(
      ApiEndpoint.changePassword,
      body: request.toJson(),
    );
  }

  /// Get business types based on location
  Future<ResponseState<CheckBusinessResponse>> getBusinessType(
      BusinessTypeRequest request) async {
    return apiClient.post<CheckBusinessResponse>(
      ApiEndpoint.getBusinessType,
      body: request.toJson(),
      fromJsonT: (json) => CheckBusinessResponse.fromJson(json),
    );
  }

  /// Get vehicle types for taxi business
  Future<ResponseState<GetVehicleTypeResponse>> getVehicleTypes(
      GetVehicleTypesRequest request) async {
    return apiClient.post<GetVehicleTypeResponse>(
      ApiEndpoint.getVehicleTypes,
      body: request.toJson(),
      fromJsonT: (json) => GetVehicleTypeResponse.fromJson(json),
    );
  }

  Future<ResponseState<NearestDriversResponse>> findNearestDrivers(
      FindNearestDriversRequest request) async {
    return apiClient.post<NearestDriversResponse>(
      ApiEndpoint.findNearestDrivers,
      body: request.toJson(),
      fromJsonT: (json) => NearestDriversResponse.fromJson(json),
    );
  }

  /// Call Google Routes Distance Matrix API (proxied through backend)
  /// Headers: X-Goog-Api-Key + X-Goog-FieldMask
  /// Response: list of RouteDistanceMatrix with destinationIndex, duration ("Xs"), distanceMeters
  Future<ResponseState<List<RouteDistanceMatrix>>> getDistanceMatrix(
      DistanceMatrixRequest request,
      {required String apiKey}) async {
    return apiClient.post<List<RouteDistanceMatrix>>(
      ApiEndpoint.googleRouteDistanceMatrix,
      headers: {
        'X-Goog-Api-Key': apiKey,
        'X-Goog-FieldMask': 'destinationIndex,duration,distanceMeters',
      },
      body: request.toJson(),
      fromJsonT: (json) => (json as List)
          .map((e) => RouteDistanceMatrix.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Update Firebase device token
  Future<ResponseState<dynamic>> updateDeviceToken(
      FirebaseDeviceTokenRequest request) async {
    return apiClient.patch<dynamic>(
      ApiEndpoint.deviceToken,
      body: request.toJson(),
    );
  }

  /// Upload live activity push token for a booking (iOS)
  Future<ResponseState<dynamic>> uploadActivityToken(
      String bookingId, String token) async {
    return apiClient.put<dynamic>(
      '${ApiEndpoint.uploadActivityToken}/$bookingId',
      body: {'token': token},
    );
  }

  /// Update user profile
  Future<ResponseState<dynamic>> updateProfile(
      UpdateProfileRequest request) async {
    return apiClient.post<dynamic>(
      ApiEndpoint.updateProfile,
      body: request.toJson(),
    );
  }

  /// Upload profile picture
  Future<ResponseState<dynamic>> uploadProfilePicture(String filePath) async {
    return apiClient.putMultipart<dynamic>(
      ApiEndpoint.profilePicture,
      filePath: filePath,
      fileFieldName: 'imageUrl',
    );
  }

  /// Get uploaded documents
  Future<ResponseState<DocumentListResponse>> getDocuments() async {
    return apiClient.get<DocumentListResponse>(
      ApiEndpoint.getDocuments,
      fromJsonT: (json) => DocumentListResponse.fromJson(json),
    );
  }

  /// Upload document
  Future<ResponseState<UploadDocumentResponse>> uploadDocument({
    required String documentId,
    String? filePath,
    String? expiryDate,
    String? uniqueCode,
  }) async {
    final path = ApiEndpoint.uploadDocument.replaceAll('{documentId}', documentId);

    final fields = <String, String>{};
    if (expiryDate != null) {
      fields[ApiParams.expiryDate] = expiryDate;
    }
    if (uniqueCode != null) {
      fields[ApiParams.uniqueCode] = uniqueCode;
    }

    return apiClient.putMultipart<UploadDocumentResponse>(
      path,
      filePath: filePath,
      fileFieldName: 'imageUrl',
      fields: fields.isNotEmpty ? fields : null,
      fromJsonT: (json) => UploadDocumentResponse.fromJson(json),
    );
  }

  /// Get wallet transaction credit history
  Future<ResponseState<TransactionCreditResponse>> getTransactionCredit({
    required int page,
    int limit = 10,
  }) async {
    return apiClient.get<TransactionCreditResponse>(
      ApiEndpoint.transactionCredit,
      queryParameters: {
        ApiParams.limit: limit.toString(),
        ApiParams.page: page.toString(),
      },
      fromJsonT: (json) => TransactionCreditResponse.fromJson(json),
    );
  }

  /// Get reward points transactions
  Future<ResponseState<RedeemPointResponse>> getRewardPoints({
    required int page,
    int limit = 10,
  }) async {
    return apiClient.get<RedeemPointResponse>(
      ApiEndpoint.getRewardPoints,
      queryParameters: {
        ApiParams.limit: limit.toString(),
        ApiParams.page: page.toString(),
      },
      fromJsonT: (json) => RedeemPointResponse.fromJson(json),
    );
  }

  /// Withdraw reward points
  Future<ResponseState<dynamic>> withdrawRewardPoints(
      RedeemWithdrawRequest request) async {
    return apiClient.post<dynamic>(
      ApiEndpoint.withdrawRewardPoints,
      body: request.toJson(),
    );
  }

  /// Get available languages
  Future<ResponseState<List<LanguageResponse>>> getLanguages() async {
    return apiClient.get<List<LanguageResponse>>(
      ApiEndpoint.getLanguage,
      fromJsonT: (json) {
        if (json is List) {
          return json.map((e) => LanguageResponse.fromJson(e)).toList();
        }
        return [];
      },
    );
  }

  /// Set user's preferred language
  Future<ResponseState<dynamic>> setLanguage(SetLanguageRequest request) async {
    return apiClient.put<dynamic>(
      ApiEndpoint.setLanguage,
      body: request.toJson(),
    );
  }

  /// Get emergency contacts
  Future<ResponseState<EmergencyContactResponse>> getEmergencyContacts() async {
    return apiClient.get<EmergencyContactResponse>(
      ApiEndpoint.getEmergencyContact,
      fromJsonT: (json) => EmergencyContactResponse.fromJson(json),
    );
  }

  /// Add emergency contact
  Future<ResponseState<EmergencyContactResponse>> addEmergencyContact(
      EmergencyContactRequest request) async {
    return apiClient.post<EmergencyContactResponse>(
      ApiEndpoint.getEmergencyContact,
      body: request.toJson(),
      fromJsonT: (json) => EmergencyContactResponse.fromJson(json),
    );
  }

  /// Update emergency contact
  Future<ResponseState<EmergencyContactResponse>> updateEmergencyContact(
      String contactId, EmergencyContactRequest request) async {
    final path = ApiEndpoint.modifyEmergencyContact.replaceAll('{contactId}', contactId);
    return apiClient.put<EmergencyContactResponse>(
      path,
      body: request.toJson(),
      fromJsonT: (json) => EmergencyContactResponse.fromJson(json),
    );
  }

  /// Delete emergency contact
  Future<ResponseState<EmergencyContactResponse>> deleteEmergencyContact(
      String contactId) async {
    final path = ApiEndpoint.modifyEmergencyContact.replaceAll('{contactId}', contactId);
    return apiClient.delete<EmergencyContactResponse>(
      path,
      fromJsonT: (json) => EmergencyContactResponse.fromJson(json),
    );
  }

  /// Delete user account
  Future<ResponseState<dynamic>> deleteAccount(
      Map<String, String> request) async {
    return apiClient.post<dynamic>(
      ApiEndpoint.deleteAccount,
      body: request,
    );
  }

  /// Get referral history
  Future<ResponseState<ReferralHistoryResponse>> getReferralHistory() async {
    return apiClient.get<ReferralHistoryResponse>(
      ApiEndpoint.referralHistory,
      fromJsonT: (json) => ReferralHistoryResponse.fromJson(json),
    );
  }

  /// Get support ticket history
  Future<ResponseState<SupportTicketHistoryResponse>> getSupportTicketHistory() async {
    return apiClient.get<SupportTicketHistoryResponse>(
      ApiEndpoint.getSupportTicketHistory,
      fromJsonT: (json) => SupportTicketHistoryResponse.fromJson(json),
    );
  }

  /// Get support ticket categories
  Future<ResponseState<SupportTicketCategoriesResponse>> getSupportTicketCategories() async {
    return apiClient.get<SupportTicketCategoriesResponse>(
      ApiEndpoint.getSupportTicketCategories,
      fromJsonT: (json) => SupportTicketCategoriesResponse.fromJson(json),
    );
  }

  /// Create support ticket
  Future<ResponseState<dynamic>> createSupportTicket(
      SupportTicketRequest request) async {
    return apiClient.post<dynamic>(
      ApiEndpoint.getSupportTicketHistory,
      body: request.toJson(),
    );
  }

  /// Add image to support ticket
  Future<ResponseState<dynamic>> addSupportTicketImage({
    required String ticketId,
    required String filePath,
  }) async {
    final path = ApiEndpoint.addSupportTicketIkmage.replaceAll('{ticketId}', ticketId);
    return apiClient.putMultipart<dynamic>(
      path,
      filePath: filePath,
      fileFieldName: 'image',
    );
  }

  /// Update support ticket status
  Future<ResponseState<dynamic>> updateTicketStatus({
    required String ticketId,
    required TicketStatusRequest request,
  }) async {
    final path = ApiEndpoint.updateTicketStatus.replaceAll('{ticketId}', ticketId);
    return apiClient.patch<dynamic>(
      path,
      body: request.toJson(),
    );
  }

  /// Get notifications
  Future<ResponseState<NotificationResponse>> getNotifications({
    required int page,
    required int limit,
    required String deviceType,
    required int userType,
    required int notificationType,
  }) async {
    return apiClient.get<NotificationResponse>(
      ApiEndpoint.getNotifications,
      queryParameters: {
        ApiParams.page: page.toString(),
        ApiParams.limit: limit.toString(),
        ApiParams.sortOrder: '-1',
        ApiParams.deviceType: deviceType,
        ApiParams.userType: userType.toString(),
        ApiParams.notificationType: notificationType.toString(),
      },
      fromJsonT: (json) => NotificationResponse.fromJson(json),
    );
  }

  /// Get saved addresses
  Future<ResponseState<AddressResponse>> getAddresses() async {
    return apiClient.get<AddressResponse>(
      ApiEndpoint.address,
      fromJsonT: (json) => AddressResponse.fromJson(json),
    );
  }

  /// Add a new saved address
  Future<ResponseState<AddressResponse>> addAddress(
      DestinationAddress address) async {
    return apiClient.post<AddressResponse>(
      ApiEndpoint.address,
      body: address.toJson(),
      fromJsonT: (json) => AddressResponse.fromJson(json),
    );
  }

  /// Update an existing saved address
  Future<ResponseState<AddressResponse>> updateAddress(
      String addressId, DestinationAddress address) async {
    final path = ApiEndpoint.modifyAddress.replaceAll('{addressId}', addressId);
    return apiClient.put<AddressResponse>(
      path,
      body: address.toJson(),
      fromJsonT: (json) => AddressResponse.fromJson(json),
    );
  }

  /// Delete a saved address
  Future<ResponseState<AddressResponse>> deleteAddress(String addressId) async {
    final path = ApiEndpoint.modifyAddress.replaceAll('{addressId}', addressId);
    return apiClient.delete<AddressResponse>(
      path,
      fromJsonT: (json) => AddressResponse.fromJson(json),
    );
  }

  /// Get cancellation policy for a vehicle price
  Future<ResponseState<CancellationPolicyResponse>> getCancellationPolicy(
      String vehiclePriceId) async {
    return apiClient.get<CancellationPolicyResponse>(
      '${ApiEndpoint.cancellationPolicy}/$vehiclePriceId',
      fromJsonT: (json) => CancellationPolicyResponse.fromJson(json),
    );
  }

  /// Get payment gateways for user
  Future<ResponseState<PaymentGatewayResponse>> getPaymentGateways({
    String? countryId,
  }) async {
    return apiClient.get<PaymentGatewayResponse>(
      ApiEndpoint.getPaymentGateways,
      queryParameters: {
        if (countryId != null) 'countryId': countryId,
      },
      fromJsonT: (json) => PaymentGatewayResponse.fromJson(json),
    );
  }

  /// Get corporate payment gateways
  Future<ResponseState<CorporatePaymentResponse>> getCorporatePaymentGateways({
    required String paymentGatewayTypes,
  }) async {
    return apiClient.get<CorporatePaymentResponse>(
      ApiEndpoint.getCorporatePaymentGateways,
      queryParameters: {
        'paymentGatewayTypes': paymentGatewayTypes,
      },
      fromJsonT: (json) => CorporatePaymentResponse.fromJson(json),
    );
  }

  /// Add card intent for payment gateway
  Future<ResponseState<AddCardIntentResponse>> addCardIntent({
    required String gateway,
    required String countryId,
  }) async {
    final path = ApiEndpoint.addCardIntent.replaceAll('{gateway}', gateway);
    return apiClient.post<AddCardIntentResponse>(
      path,
      body: {
        'countryId': countryId,
      },
      fromJsonT: (json) => AddCardIntentResponse.fromJson(json),
    );
  }

  /// Add a new card
  Future<ResponseState<dynamic>> addCard({
    required String gateway,
    required AddCardRequest request,
  }) async {
    final path = ApiEndpoint.addCard.replaceAll('{gateway}', gateway);
    return apiClient.post<dynamic>(
      path,
      body: request.toJson(),
    );
  }

  /// Select a card as default
  Future<ResponseState<dynamic>> selectCard({
    required String cardId,
  }) async {
    final path = ApiEndpoint.modifyCard.replaceAll('{cardId}', cardId);
    return apiClient.patch<dynamic>(path);
  }

  /// Delete a card
  Future<ResponseState<dynamic>> deleteCard({
    required String cardId,
  }) async {
    final path = ApiEndpoint.modifyCard.replaceAll('{cardId}', cardId);
    return apiClient.delete<dynamic>(path);
  }

  /// Create payment intent for wallet/booking payment
  Future<ResponseState<PaymentIntentResponse>> paymentIntentCreate({
    required String paymentGateway,
    required WalletPaymentRequest request,
  }) async {
    final path = ApiEndpoint.paymentIntentCreate
        .replaceAll('{paymentGateway}', paymentGateway);
    return apiClient.post<PaymentIntentResponse>(
      path,
      body: request.toJson(),
      fromJsonT: (json) => PaymentIntentResponse.fromJson(json),
    );
  }

  /// Get saved cards
  Future<ResponseState<GetCardsResponse>> getCards({
    required String countryId,
    required String paymentGatewayTypes,
  }) async {
    return apiClient.get<GetCardsResponse>(
      ApiEndpoint.getCards,
      queryParameters: {
        'countryId': countryId,
        'paymentGatewayTypes': paymentGatewayTypes,
      },
      fromJsonT: (json) => GetCardsResponse.fromJson(json),
    );
  }

  /// Transfer credit to another user
  Future<ResponseState<dynamic>> transferCredit({
    required TransferCreditRequest request,
  }) async {
    return apiClient.post<dynamic>(
      ApiEndpoint.transferCredits,
      body: request.toJson(),
    );
  }

  /// Search user for credit transfer
  Future<ResponseState<SearchUserResponse>> searchUser({
    required String countryPhoneCode,
    required String phone,
    required int type,
    required String id,
  }) async {
    return apiClient.get<SearchUserResponse>(
      ApiEndpoint.searchUser,
      queryParameters: {
        'countryPhoneCode': countryPhoneCode,
        'phone': phone,
        'type': type.toString(),
        'id': id,
      },
      fromJsonT: (json) => SearchUserResponse.fromJson(json),
    );
  }

  /// Get promo codes list
  Future<ResponseState<PromoCodeResponse>> getPromoCodes(
      PromoCodeListRequest request) async {
    return apiClient.post<PromoCodeResponse>(
      ApiEndpoint.getPromoCodes,
      body: request.toJson(),
      fromJsonT: (json) => PromoCodeResponse.fromJson(json),
    );
  }

  /// Validate promo code
  Future<ResponseState<ValidatePromoCodeResponse>> validatePromoCode(
      ValidatePromoCodeRequest request) async {
    return apiClient.post<ValidatePromoCodeResponse>(
      ApiEndpoint.validatePromo,
      body: request.toJson(),
      fromJsonT: (json) => ValidatePromoCodeResponse.fromJson(json),
    );
  }

  /// Get fare estimate with promo/payment changes
  Future<ResponseState<FareEstimateResponse>> getFareEstimate(
      FareEstimateRequest request) async {
    return apiClient.post<FareEstimateResponse>(
      ApiEndpoint.getFareEstimate,
      body: request.toJson(),
      fromJsonT: (json) => FareEstimateResponse.fromJson(json),
    );
  }

  /// Create a taxi booking
  Future<ResponseState<CreateBookingResponse>> createBooking(
      CreateBookingRequest request) async {
    return apiClient.post<CreateBookingResponse>(
      ApiEndpoint.createBooking,
      body: request.toJson(),
      fromJsonT: (json) => CreateBookingResponse.fromJson(json),
    );
  }

  /// Get active/upcoming bookings list
  Future<ResponseState<MyBookingsResponse>> getMyBookings() async {
    return apiClient.get<MyBookingsResponse>(
      ApiEndpoint.bookingList,
      fromJsonT: (json) => MyBookingsResponse.fromJson(json),
    );
  }

  /// Get booking details by ID
  Future<ResponseState<BookingDetailResponse>> getBookingDetails(
      String bookingId) async {
    final path = ApiEndpoint.getBookingDetails.replaceAll('{id}', bookingId);
    return apiClient.get<BookingDetailResponse>(
      path,
      fromJsonT: (json) => BookingDetailResponse.fromJson(json),
    );
  }

  /// Update destination address for an active booking
  Future<ResponseState<UpdateAddressResponse>> updateDestinationAddress(
      String bookingId, GetVehicleTypesRequest request) async {
    final path =
        ApiEndpoint.updateBookingAddress.replaceAll('{id}', bookingId);
    return apiClient.put<UpdateAddressResponse>(
      path,
      body: request.toJson(),
      fromJsonT: (json) => UpdateAddressResponse.fromJson(json),
    );
  }

  /// Cancel a booking
  Future<ResponseState<dynamic>> cancelBooking(
      String bookingId, CancelBookingRequest request) async {
    final path = ApiEndpoint.cancelBooking.replaceAll('{bookingId}', bookingId);
    return apiClient.put<dynamic>(
      path,
      body: request.toJson(),
    );
  }

  /// Get cancellation charges for a booking
  Future<ResponseState<CancellationChargeResponse>> getCancellationCharges(
      String bookingId) async {
    final path = ApiEndpoint.getCancellationCharges.replaceAll('{id}', bookingId);
    return apiClient.get<CancellationChargeResponse>(
      path,
      fromJsonT: (json) => CancellationChargeResponse.fromJson(json),
    );
  }

  /// Get cancellation reasons
  Future<ResponseState<CancellationReasonResponse>> getCancellationReasons(
      Map<String, String> queryParams) async {
    return apiClient.get<CancellationReasonResponse>(
      ApiEndpoint.cancellationReason,
      queryParameters: queryParams,
      fromJsonT: (json) => CancellationReasonResponse.fromJson(json),
    );
  }

  /// Submit invoice for a booking
  Future<ResponseState<dynamic>> submitInvoice(
      String bookingId, SubmitInvoiceRequest request) async {
    final path = ApiEndpoint.submitInvoice.replaceAll('{bookingId}', bookingId);
    return apiClient.put<dynamic>(
      path,
      body: request.toJson(),
    );
  }

  /// Initiate calling for a booking
  Future<ResponseState<dynamic>> calling(String bookingId) async {
    final path = ApiEndpoint.calling.replaceAll('{bookingId}', bookingId);
    return apiClient.post<dynamic>(path);
  }

  /// Initiate support calling
  Future<ResponseState<dynamic>> supportCalling() async {
    return apiClient.post<dynamic>(ApiEndpoint.supportCalling);
  }

  /// Get accessibility options
  Future<ResponseState<AccessibilityResponse>> getAccessibility() async {
    return apiClient.get<AccessibilityResponse>(
      ApiEndpoint.accessibility,
      fromJsonT: (json) => AccessibilityResponse.fromJson(json),
    );
  }

  /// Accept bidding request
  Future<ResponseState<dynamic>> acceptBidding(
      String bookingId, BiddingAcceptRequest request) async {
    final path = ApiEndpoint.acceptBidding.replaceAll('{bookingId}', bookingId);
    return apiClient.put<dynamic>(
      path,
      body: request.toJson(),
    );
  }

  /// Reject bidding request
  Future<ResponseState<dynamic>> rejectBidding(
      String bookingId, BiddingAcceptRequest request) async {
    final path = ApiEndpoint.rejectBidding.replaceAll('{bookingId}', bookingId);
    return apiClient.put<dynamic>(
      path,
      body: request.toJson(),
    );
  }

  /// Get fix group booking details
  Future<ResponseState<FixGroupDetailResponse>> getFixGroupBookingDetails(
      String bookingId) async {
    final path = ApiEndpoint.fixGroupBookingDetails.replaceAll('{id}', bookingId);
    return apiClient.get<FixGroupDetailResponse>(
      path,
      fromJsonT: (json) => FixGroupDetailResponse.fromJson(json),
    );
  }

  /// Cancel fix group booking
  Future<ResponseState<dynamic>> cancelFixGroupBooking(String bookingId) async {
    final path = ApiEndpoint.cancelFixBookingDetails.replaceAll('{id}', bookingId);
    return apiClient.put<dynamic>(path);
  }

  /// SOS call for a booking
  Future<ResponseState<dynamic>> sosCall(String bookingId) async {
    final path = ApiEndpoint.sosCall.replaceAll('{bookingId}', bookingId);
    return apiClient.post<dynamic>(path);
  }

  /// Pay by cash for partial payment
  Future<ResponseState<dynamic>> partialPaymentByCash(String bookingId) async {
    final path = ApiEndpoint.partialPaymentByCash.replaceAll('{bookingId}', bookingId);
    return apiClient.post<dynamic>(path);
  }

  /// Wallet booking payment
  Future<ResponseState<dynamic>> walletBookingPayment(String bookingId) async {
    final path = ApiEndpoint.walletBookingPayment.replaceAll('{bookingId}', bookingId);
    return apiClient.post<dynamic>(path);
  }

  /// Wallet fix group booking payment
  Future<ResponseState<dynamic>> walletFixGroupBookingPayment(String bookingId) async {
    final path = ApiEndpoint.fixGroupWalletBookingPayment.replaceAll('{bookingId}', bookingId);
    return apiClient.post<dynamic>(path);
  }

  /// Submit rating for a booking
  Future<ResponseState<dynamic>> submitRating(
      String bookingId, SubmitRatingRequest request) async {
    return apiClient.put<dynamic>(
      '${ApiEndpoint.submitRating}/$bookingId',
      body: request.toJson(),
    );
  }

  /// Get favourite drivers
  Future<ResponseState<FavouriteDriverResponse>> getFavouriteDrivers() async {
    return apiClient.get<FavouriteDriverResponse>(
      ApiEndpoint.favouriteDriver,
      fromJsonT: (json) => FavouriteDriverResponse.fromJson(json),
    );
  }

  /// Delete favourite driver
  Future<ResponseState<dynamic>> deleteFavouriteDriver(String driverId) async {
    return apiClient.delete<dynamic>(
      '${ApiEndpoint.favouriteDriver}/$driverId',
    );
  }

  /// Add favourite driver
  Future<ResponseState<dynamic>> addFavouriteDriver(
      AddFavouriteDriverRequest request) async {
    return apiClient.post<dynamic>(
      ApiEndpoint.favouriteDriver,
      body: request.toJson(),
    );
  }

  /// Wallet tip payment
  Future<ResponseState<dynamic>> walletTipPayment(
      String bookingId, WalletPaymentRequest request) async {
    final path = ApiEndpoint.walletTipPayment.replaceAll('{bookingId}', bookingId);
    return apiClient.post<dynamic>(
      path,
      body: request.toJson(),
    );
  }

  /// Get information status (missing profile/document/gender)
  Future<ResponseState<MissingInformationResponse>> getInformationStatus() async {
    return apiClient.get<MissingInformationResponse>(
      ApiEndpoint.informationStatus,
      fromJsonT: (json) => MissingInformationResponse.fromJson(json),
    );
  }

}

final appRepositoryProvider = Provider<AppRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AppRepository(apiClient);
});
