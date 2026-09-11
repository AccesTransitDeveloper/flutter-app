import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/constants/socket_constants.dart';
import '../core/managers/socket_manager.dart';
import '../core/localization/app_strings.dart';
import '../core/localization/string_constants.dart';
import '../core/payments/payment_interface.dart';
import '../core/payments/paystack_manager.dart';
import '../core/payments/stripe_payment_manager.dart';
import '../core/payments/webview_payment_manager.dart';
import '../core/preferences/shared_preference_manager.dart';
import '../core/providers/app_providers.dart';
import '../core/utils/common_utils.dart';
import '../core/utils/validator/validator.dart';
import '../data/api/response_state.dart';
import '../data/repository/app_repository.dart';
import '../models/requests/entity_detail_request.dart';
import '../models/requests/redeem_withdraw_request.dart';
import '../models/requests/add_card_request.dart';
import '../models/requests/transfer_credit_request.dart';
import '../models/responses/payment/add_card_intent_response.dart';
import '../models/requests/wallet_payment_request.dart';
import '../models/responses/booking/booking_detail_response.dart';
import '../models/responses/booking/get_vehicle_type_response.dart';
import '../models/responses/payment/card_response.dart';
import '../models/responses/payment/corporate_payment_response.dart';
import '../models/responses/payment/payment_gateway_response.dart';
import '../models/responses/payment/payment_intent_response.dart';
import '../models/responses/auth/country_response.dart';
import '../models/responses/payment/search_user_response.dart';
import '../models/webview_data_model.dart';

/// Dropdown model for user menu list (matches Kotlin DropDownModel)
class DropDownModel {
  final int type;
  final String name;

  const DropDownModel({
    required this.type,
    required this.name,
  });
}

/// Payment screen state
class PaymentState {
  final List<PaymentGateway> allPaymentGatewayList;
  final List<PaymentGateway> paymentGatewayList;
  final PaymentGateway? paymentGatewayToAddCard;
  final List<CardResponse> cards;
  final List<CardResponse> cardsList;
  final List<CardResponse> walletCardsList;
  final CardResponse? selectedCardsForAddPayment;
  final CardResponse? selectedPaymentMethod;
  final bool isLoading;
  final bool isDataLoading;
  final String? error;
  final String? snackBarMessage;
  final bool isSnackBarError;
  final double? totalWalletAmount;
  final String? formattedWalletAmount;
  final double? totalRedeemPoints;
  final double? totalAmount;
  final bool isComeFromBooking;
  final bool isFromCurrentBooking;
  final bool isFromFeedBack;
  final bool isPreBookingPayment;
  final bool isCorporateBooking;
  final bool isShowTransferMoneyButton;
  final bool isDisableTransferMoneyButton;
  final bool showAddWalletAmount;
  final bool isCardAndBankVisible;
  final bool isWalletVisible;
  final bool isShowDeleteCard;
  final double walletAmount;
  final int? selectedPaymentType;
  final WebViewDataModel? navigateURL;
  final bool isNavigateToWebView;
  final VehicleTypePaymentSetting? vehicleTypePaymentSetting;
  final BookingPaymentSetting? myBookingPaymentSetting;
  final int businessType;
  final bool isShowSendMoneyButton;
  final SearchUser? selectedUser;
  final bool isShowNoDataFound;
  final bool hideKeyBoard;
  final String redeemPoint;
  final bool showRedeemPointBottomSheet;
  final String convertedRedeemPointPrice;
  final bool showTransferMoneyBottomSheet;
  final bool isFromSubscription;
  final bool isNavigateToBack;
  final bool showAddCardBottomSheet;
  final bool showGatewayBottomSheet;
  final bool isAddCard;
  final bool isAddCardLoading;

  /// Kept apart from [isLoading] so the delete spinner can't be cleared by an
  /// unrelated refresh finishing first.
  final bool isDeleteCardLoading;
  final CardDetails? selectedCardDetails;
  final PaymentInterface? paymentManager;
  final List<Country> countryList;

  // Added missing properties to match Kotlin ViewModel
  final List<DropDownModel> userMenuList;
  final DropDownModel? selectedUserMenu;
  final String phoneNumber;
  final String amount;
  final String countryPhoneCode;
  final bool isTransferUsingQR;
  final bool isShowRedeemPoints;
  final bool isCashAvailable;
  final bool showAddCard;
  final bool showAddWalletAmountBottomSheet;
  final bool showDeleteCardBottomSheet;
  final CardResponse? selectedCardForDelete;
  final PaymentGateway? selectedPaymentGateway;
  final int? selectedUserTypeIndex;
  final bool showCountryPhoneCodeBottomSheet;
  final List<Country> multiplePhoneCodeCountryList;
  final bool showPermissionDialog;
  final bool useWalletAmount;

  const PaymentState({
    this.allPaymentGatewayList = const [],
    this.paymentGatewayList = const [],
    this.paymentGatewayToAddCard,
    this.cards = const [],
    this.cardsList = const [],
    this.walletCardsList = const [],
    this.selectedCardsForAddPayment,
    this.selectedPaymentMethod,
    this.isLoading = false,
    this.isDataLoading = false,
    this.error,
    this.snackBarMessage,
    this.isSnackBarError = false,
    this.totalWalletAmount,
    this.formattedWalletAmount,
    this.totalRedeemPoints,
    this.totalAmount,
    this.isComeFromBooking = false,
    this.isFromCurrentBooking = false,
    this.isFromFeedBack = false,
    this.isPreBookingPayment = false,
    this.isCorporateBooking = false,
    this.isShowTransferMoneyButton = false,
    this.isDisableTransferMoneyButton = false,
    this.showAddWalletAmount = false,
    this.isCardAndBankVisible = false,
    this.isWalletVisible = true,
    this.isShowDeleteCard = true,
    this.walletAmount = 0,
    this.selectedPaymentType,
    this.navigateURL,
    this.isNavigateToWebView = false,
    this.vehicleTypePaymentSetting,
    this.myBookingPaymentSetting,
    this.businessType = BusinessType.taxi,
    this.isShowSendMoneyButton = false,
    this.selectedUser,
    this.isShowNoDataFound = false,
    this.hideKeyBoard = false,
    this.redeemPoint = '',
    this.showRedeemPointBottomSheet = false,
    this.convertedRedeemPointPrice = '',
    this.showTransferMoneyBottomSheet = false,
    this.isFromSubscription = false,
    this.isNavigateToBack = false,
    this.showAddCardBottomSheet = false,
    this.showGatewayBottomSheet = false,
    this.isAddCard = false,
    this.isAddCardLoading = false,
    this.isDeleteCardLoading = false,
    this.selectedCardDetails,
    this.paymentManager,
    this.countryList = const [],
    // Added missing properties to match Kotlin ViewModel
    this.userMenuList = const [],
    this.selectedUserMenu,
    this.phoneNumber = '',
    this.amount = '',
    this.countryPhoneCode = '',
    this.isTransferUsingQR = false,
    this.isShowRedeemPoints = false,
    this.isCashAvailable = false,
    // Native's PaymentState defaults this to `true` — the plain Payments
    // screen never recomputes it, so defaulting to false hid "Add card"
    // everywhere except the booking flow.
    this.showAddCard = true,
    this.showAddWalletAmountBottomSheet = false,
    this.showDeleteCardBottomSheet = false,
    this.selectedCardForDelete,
    this.selectedPaymentGateway,
    this.selectedUserTypeIndex,
    this.showCountryPhoneCodeBottomSheet = false,
    this.multiplePhoneCodeCountryList = const [],
    this.showPermissionDialog = false,
    this.useWalletAmount = false,
  });

  PaymentState copyWith({
    List<PaymentGateway>? allPaymentGatewayList,
    List<PaymentGateway>? paymentGatewayList,
    PaymentGateway? paymentGatewayToAddCard,
    List<CardResponse>? cards,
    List<CardResponse>? cardsList,
    List<CardResponse>? walletCardsList,
    CardResponse? selectedCardsForAddPayment,
    CardResponse? selectedPaymentMethod,
    bool? isLoading,
    bool? isDataLoading,
    String? error,
    bool clearError = false,
    String? snackBarMessage,
    bool? isSnackBarError,
    bool clearSnackBar = false,
    bool clearNavigateURL = false,
    double? totalWalletAmount,
    String? formattedWalletAmount,
    double? totalRedeemPoints,
    double? totalAmount,
    bool? isComeFromBooking,
    bool? isFromCurrentBooking,
    bool? isFromFeedBack,
    bool? isPreBookingPayment,
    bool? isCorporateBooking,
    bool? isShowTransferMoneyButton,
    bool? isDisableTransferMoneyButton,
    bool? showAddWalletAmount,
    bool? isCardAndBankVisible,
    bool? isWalletVisible,
    bool? isShowDeleteCard,
    double? walletAmount,
    int? selectedPaymentType,
    WebViewDataModel? navigateURL,
    bool? isNavigateToWebView,
    VehicleTypePaymentSetting? vehicleTypePaymentSetting,
    BookingPaymentSetting? myBookingPaymentSetting,
    int? businessType,
    bool? isShowSendMoneyButton,
    SearchUser? selectedUser,
    bool clearSelectedUser = false,
    bool? isShowNoDataFound,
    bool? hideKeyBoard,
    String? redeemPoint,
    bool? showRedeemPointBottomSheet,
    String? convertedRedeemPointPrice,
    bool? showTransferMoneyBottomSheet,
    bool? isFromSubscription,
    bool? isNavigateToBack,
    bool? showAddCardBottomSheet,
    bool? showGatewayBottomSheet,
    bool? isAddCard,
    bool? isAddCardLoading,
    bool? isDeleteCardLoading,
    bool clearSelectedPaymentMethod = false,
    CardDetails? selectedCardDetails,
    PaymentInterface? paymentManager,
    List<Country>? countryList,
    // Added missing properties to match Kotlin ViewModel
    List<DropDownModel>? userMenuList,
    DropDownModel? selectedUserMenu,
    bool clearSelectedUserMenu = false,
    String? phoneNumber,
    String? amount,
    String? countryPhoneCode,
    bool? isTransferUsingQR,
    bool? isShowRedeemPoints,
    bool? isCashAvailable,
    bool? showAddCard,
    bool? showAddWalletAmountBottomSheet,
    bool? showDeleteCardBottomSheet,
    CardResponse? selectedCardForDelete,
    bool clearSelectedCardForDelete = false,
    PaymentGateway? selectedPaymentGateway,
    int? selectedUserTypeIndex,
    bool clearSelectedUserTypeIndex = false,
    bool? showCountryPhoneCodeBottomSheet,
    List<Country>? multiplePhoneCodeCountryList,
    bool? showPermissionDialog,
    bool? useWalletAmount,
  }) {
    return PaymentState(
      allPaymentGatewayList:
          allPaymentGatewayList ?? this.allPaymentGatewayList,
      paymentGatewayList: paymentGatewayList ?? this.paymentGatewayList,
      paymentGatewayToAddCard:
          paymentGatewayToAddCard ?? this.paymentGatewayToAddCard,
      cards: cards ?? this.cards,
      cardsList: cardsList ?? this.cardsList,
      walletCardsList: walletCardsList ?? this.walletCardsList,
      selectedCardsForAddPayment:
          selectedCardsForAddPayment ?? this.selectedCardsForAddPayment,
      selectedPaymentMethod: clearSelectedPaymentMethod
          ? null
          : (selectedPaymentMethod ?? this.selectedPaymentMethod),
      isLoading: isLoading ?? this.isLoading,
      isDataLoading: isDataLoading ?? this.isDataLoading,
      error: clearError ? null : (error ?? this.error),
      snackBarMessage: clearSnackBar ? null : (snackBarMessage ?? this.snackBarMessage),
      isSnackBarError: clearSnackBar ? false : (isSnackBarError ?? this.isSnackBarError),
      totalWalletAmount: totalWalletAmount ?? this.totalWalletAmount,
      formattedWalletAmount:
          formattedWalletAmount ?? this.formattedWalletAmount,
      totalRedeemPoints: totalRedeemPoints ?? this.totalRedeemPoints,
      totalAmount: totalAmount ?? this.totalAmount,
      isComeFromBooking: isComeFromBooking ?? this.isComeFromBooking,
      isFromCurrentBooking: isFromCurrentBooking ?? this.isFromCurrentBooking,
      isFromFeedBack: isFromFeedBack ?? this.isFromFeedBack,
      isPreBookingPayment: isPreBookingPayment ?? this.isPreBookingPayment,
      isCorporateBooking: isCorporateBooking ?? this.isCorporateBooking,
      isShowTransferMoneyButton:
          isShowTransferMoneyButton ?? this.isShowTransferMoneyButton,
      isDisableTransferMoneyButton:
          isDisableTransferMoneyButton ?? this.isDisableTransferMoneyButton,
      showAddWalletAmount: showAddWalletAmount ?? this.showAddWalletAmount,
      isCardAndBankVisible: isCardAndBankVisible ?? this.isCardAndBankVisible,
      isWalletVisible: isWalletVisible ?? this.isWalletVisible,
      isShowDeleteCard: isShowDeleteCard ?? this.isShowDeleteCard,
      walletAmount: walletAmount ?? this.walletAmount,
      selectedPaymentType: selectedPaymentType ?? this.selectedPaymentType,
      navigateURL: clearNavigateURL ? null : (navigateURL ?? this.navigateURL),
      isNavigateToWebView: isNavigateToWebView ?? this.isNavigateToWebView,
      vehicleTypePaymentSetting:
          vehicleTypePaymentSetting ?? this.vehicleTypePaymentSetting,
      myBookingPaymentSetting:
          myBookingPaymentSetting ?? this.myBookingPaymentSetting,
      businessType: businessType ?? this.businessType,
      isShowSendMoneyButton:
          isShowSendMoneyButton ?? this.isShowSendMoneyButton,
      selectedUser: clearSelectedUser ? null : (selectedUser ?? this.selectedUser),
      isShowNoDataFound: isShowNoDataFound ?? this.isShowNoDataFound,
      hideKeyBoard: hideKeyBoard ?? this.hideKeyBoard,
      redeemPoint: redeemPoint ?? this.redeemPoint,
      showRedeemPointBottomSheet:
          showRedeemPointBottomSheet ?? this.showRedeemPointBottomSheet,
      convertedRedeemPointPrice:
          convertedRedeemPointPrice ?? this.convertedRedeemPointPrice,
      showTransferMoneyBottomSheet:
          showTransferMoneyBottomSheet ?? this.showTransferMoneyBottomSheet,
      isFromSubscription: isFromSubscription ?? this.isFromSubscription,
      isNavigateToBack: isNavigateToBack ?? this.isNavigateToBack,
      showAddCardBottomSheet:
          showAddCardBottomSheet ?? this.showAddCardBottomSheet,
      showGatewayBottomSheet:
          showGatewayBottomSheet ?? this.showGatewayBottomSheet,
      isAddCard: isAddCard ?? this.isAddCard,
      isAddCardLoading: isAddCardLoading ?? this.isAddCardLoading,
      isDeleteCardLoading: isDeleteCardLoading ?? this.isDeleteCardLoading,
      selectedCardDetails: selectedCardDetails ?? this.selectedCardDetails,
      paymentManager: paymentManager ?? this.paymentManager,
      countryList: countryList ?? this.countryList,
      // Added missing properties to match Kotlin ViewModel
      userMenuList: userMenuList ?? this.userMenuList,
      selectedUserMenu: clearSelectedUserMenu ? null : (selectedUserMenu ?? this.selectedUserMenu),
      phoneNumber: phoneNumber ?? this.phoneNumber,
      amount: amount ?? this.amount,
      countryPhoneCode: countryPhoneCode ?? this.countryPhoneCode,
      isTransferUsingQR: isTransferUsingQR ?? this.isTransferUsingQR,
      isShowRedeemPoints: isShowRedeemPoints ?? this.isShowRedeemPoints,
      isCashAvailable: isCashAvailable ?? this.isCashAvailable,
      showAddCard: showAddCard ?? this.showAddCard,
      showAddWalletAmountBottomSheet:
          showAddWalletAmountBottomSheet ?? this.showAddWalletAmountBottomSheet,
      showDeleteCardBottomSheet:
          showDeleteCardBottomSheet ?? this.showDeleteCardBottomSheet,
      selectedCardForDelete: clearSelectedCardForDelete
          ? null
          : (selectedCardForDelete ?? this.selectedCardForDelete),
      selectedPaymentGateway:
          selectedPaymentGateway ?? this.selectedPaymentGateway,
      selectedUserTypeIndex: clearSelectedUserTypeIndex
          ? null
          : (selectedUserTypeIndex ?? this.selectedUserTypeIndex),
      showCountryPhoneCodeBottomSheet:
          showCountryPhoneCodeBottomSheet ?? this.showCountryPhoneCodeBottomSheet,
      multiplePhoneCodeCountryList:
          multiplePhoneCodeCountryList ?? this.multiplePhoneCodeCountryList,
      showPermissionDialog: showPermissionDialog ?? this.showPermissionDialog,
      useWalletAmount: useWalletAmount ?? this.useWalletAmount,
    );
  }
}

/// Payment screen ViewModel
class PaymentViewModel extends StateNotifier<PaymentState> {
  final AppRepository _appRepository;
  final SharedPreferenceManager? _sharedPref;
  final SocketManager _socketManager;

  PaymentViewModel(this._appRepository, this._sharedPref, this._socketManager)
      : super(const PaymentState()) {
    debugPrint('💳 PaymentViewModel - initialized');
    _initialize();
  }

  /// Initialize ViewModel - matches Kotlin init block flow
  void _initialize() {
    // 1. Get payment gateways (matches Kotlin: getPaymentGateway())
    getPaymentGateways();

    // 2. Setup user menu list for credit transfer (matches Kotlin userMenuList setup)
    _setupUserMenuList();

    // 3. Initialize state from settings/entity (matches Kotlin state updates)
    final entity = _sharedPref?.getEntity();
    final setting = _sharedPref?.getSetting();
    final isTransferUsingQR =
        setting?.creditTransferConfig?.transferUsing?.contains(TransferUsing.qrCode) ?? false;

    state = state.copyWith(
      countryPhoneCode: entity?.countryPhoneCode ?? '',
      isTransferUsingQR: isTransferUsingQR,
      isShowRedeemPoints: setting?.rewardPointConfig?.isActive ?? false,
    );

    // 4. Get wallet details (matches Kotlin: getWalletDetails())
    getWalletDetails();

    // 5. Get countries (matches Kotlin: getCountries())
    getCountries();

    // 6. Get entity detail (matches Kotlin: getEntityDetail())
    getEntityDetail();
  }

  /// Setup user menu list for credit transfer - matches Kotlin init block
  void _setupUserMenuList() {
    final setting = _sharedPref?.getSetting();
    final userMenuList = <DropDownModel>[];

    if (setting?.creditTransferConfig?.isCustomerToCustomer == true) {
      userMenuList.add(DropDownModel(
        type: EntityType.customer,
        name: getString(appStr.descriptionCustomer, 'description_customer'),
      ));
    }

    if (setting?.creditTransferConfig?.isCustomerToDriver == true) {
      userMenuList.add(DropDownModel(
        type: EntityType.driver,
        name: getString(appStr.descriptionDriver, 'description_driver'),
      ));
    }

    if (userMenuList.isNotEmpty) {
      state = state.copyWith(
        userMenuList: userMenuList,
        selectedUserMenu: userMenuList.first,
      );
    }
  }

  /// Get payment gateways
  Future<void> getPaymentGateways() async {
    final countryId = _sharedPref?.getEntity()?.countryId;

    state = state.copyWith(isLoading: true, isDataLoading: true, clearError: true);

    final response = await _appRepository.getPaymentGateways(
      countryId: countryId,
    );

    switch (response) {
      case Success<PaymentGatewayResponse>():
        final gateways = response.data?.paymentGateways ?? [];
        if (gateways.isNotEmpty) {
          debugPrint(
              '💳 PaymentViewModel - Success: ${gateways.length} gateways');

          // Save Stripe public key
          final stripeGateway = gateways
              .where((g) => g.type == PaymentGatewayType.stripe.value)
              .firstOrNull;
          AppConstants.stripePublishableKey =
              stripeGateway?.credential?.publicKey ?? '';

          // Create filtered payment gateway list
          final filteredList = createPaymentGatewayList(gateways);

          state = state.copyWith(
            isLoading: false,
            isDataLoading: false,
            showAddWalletAmount:
                !state.isComeFromBooking && !state.isFromCurrentBooking,
            allPaymentGatewayList: gateways,
            paymentGatewayList: filteredList,
            isCardAndBankVisible: checkCardAndBankVisibility(gateways),
          );

          // Get cards (or corporate payment gateways if corporate booking)
          if (state.isCorporateBooking) {
            await getCorporatePaymentGateways();
          } else {
            await getCards();
          }
        } else {
          state = state.copyWith(
            isDataLoading: false,
          );
        }

      case Error():
        debugPrint('💳 PaymentViewModel - Error: ${response.error?.message}');
        showSnackBar(response.error?.message ?? '', isError: true);
        state = state.copyWith(
          isLoading: false,
          isDataLoading: false,
        );

      case Loading():
        break;
    }
  }

  /// Create filtered payment gateway list (only those that allow saving cards)
  List<PaymentGateway> createPaymentGatewayList(List<PaymentGateway> list) {
    final paymentGateways =
        list.where((g) => g.isAllowSaveCard == true).toList();

    if (paymentGateways.isNotEmpty) {
      final updatedList = paymentGateways.map((gateway) {
        final gatewayType = PaymentGatewayType.fromValue(gateway.type);
        return gateway.copyWith(
          name: gatewayType?.getName() ?? gateway.name ?? '',
        );
      }).toList();

      state = state.copyWith(paymentGatewayToAddCard: updatedList.first);
      return updatedList;
    }

    return paymentGateways;
  }

  /// Check if card and bank section should be visible
  bool checkCardAndBankVisibility(List<PaymentGateway>? gateways) {
    if (gateways == null) return false;

    for (final gateway in gateways) {
      if (gateway.type == PaymentGatewayType.stripe.value ||
          gateway.type == PaymentGatewayType.paystack.value) {
        return true;
      }
    }
    return false;
  }

  /// Get saved cards
  Future<void> getCards() async {
    final countryId = _sharedPref?.getEntity()?.countryId;
    if (countryId == null) {
      // Bailing out silently left isLoading stuck on whenever a caller had
      // already set it (deleteCard does), so the screen sat spinning and the
      // list never refreshed.
      state = state.copyWith(isLoading: false);
      return;
    }

    // No early return on an empty gateway list — native calls the API either
    // way. Bailing out here meant a card added from the booking flow (where
    // vehicleTypePaymentSetting can carry no gateways) was never fetched back,
    // so the list stayed empty right after adding one.
    final gatewayTypeList = getPaymentGatewaysValue();

    state = state.copyWith(isLoading: true);

    final response = await _appRepository.getCards(
      countryId: countryId,
      paymentGatewayTypes: gatewayTypeList,
    );

    switch (response) {
      case Success<GetCardsResponse>():
        final allCardsResponse = response.data?.cards ?? [];
        debugPrint('💳 PaymentViewModel - Cards: ${allCardsResponse.length}');

        // Start with default card list (Cash, Wallet, etc.)
        final cardList = defaultCardList();

        if (allCardsResponse.isNotEmpty) {
          // Build list for wallet cards - only default cards (matches Kotlin cardAndPaymentGateWayList)
          final cardAndPaymentGatewayList = <CardResponse>[];
          CardResponse? defaultCard;

          // First loop - find default cards and add to wallet cards list
          for (final card in allCardsResponse) {
            if (card.isDefault == true) {
              if (!state.isComeFromBooking &&
                  !state.isFromFeedBack &&
                  !state.isFromCurrentBooking) {
                defaultCard = card;
              }
              cardAndPaymentGatewayList.add(card);
            }
          }

          // Second loop - label each card the way native does:
          // "**** 1234(Stripe)" for Stripe/PayStack, untouched otherwise.
          for (final card in allCardsResponse) {
            final gateway = PaymentGatewayType.fromValue(card.paymentGatewayType);
            final needsLabel = gateway == PaymentGatewayType.stripe ||
                gateway == PaymentGatewayType.paystack;

            cardList.add(
              needsLabel
                  ? card.copyWith(
                      cardName: '**** ${card.lastFour}(${gateway!.getName()})',
                    )
                  : card,
            );
          }

          // Add razorpay/mercado payment gateways to wallet cards list
          // Matches Kotlin: cardAndPaymentGateWayList.addAll(razorPayAndMercadoCardList())
          cardAndPaymentGatewayList.addAll(razorPayAndMercadoCardList());

          // Determine selected payment method
          CardResponse? selectedPaymentMethod = state.selectedPaymentMethod;
          if (defaultCard != null &&
              !state.isComeFromBooking &&
              !state.isFromFeedBack &&
              !state.isFromCurrentBooking) {
            selectedPaymentMethod = defaultCard;
          }

          state = state.copyWith(
            isLoading: false,
            cards: allCardsResponse,
            cardsList: cardList,
            walletCardsList: cardAndPaymentGatewayList,
            selectedCardsForAddPayment:
                cardAndPaymentGatewayList.isNotEmpty ? cardAndPaymentGatewayList.first : null,
            selectedPaymentMethod: selectedPaymentMethod,
          );
        } else {
          // No cards - just use defaults
          final walletCards = razorPayAndMercadoCardList();
          state = state.copyWith(
            isLoading: false,
            cards: allCardsResponse,
            cardsList: cardList,
            walletCardsList: walletCards,
            selectedCardsForAddPayment:
                walletCards.isNotEmpty ? walletCards.first : null,
          );
        }

      case Error():
        // The list endpoint answers "Card not found" rather than an empty list
        // once the last card is gone, so this branch *is* the no-cards case.
        // It reset cardsList but left `cards` holding the deleted card, and the
        // section widget merges the two — so the card stayed on screen, minus
        // the "(Stripe)" suffix that only the rebuilt cardsList entry carries.
        debugPrint(
            '💳 PaymentViewModel - Cards Error: ${response.error?.message}');
        final walletCards = razorPayAndMercadoCardList();
        state = state.copyWith(
          isLoading: false,
          cards: const [],
          cardsList: defaultCardList(),
          walletCardsList: walletCards,
          selectedCardsForAddPayment:
              walletCards.isNotEmpty ? walletCards.first : null,
          // Whatever was selected is one of the cards we just dropped.
          clearSelectedPaymentMethod: true,
        );

      case Loading():
        break;
    }
  }

  /// Create default card list (Cash, Wallet, and payment gateways based on context)
  List<CardResponse> defaultCardList() {
    final cardList = <CardResponse>[];

    final cash = CardResponse(
      id: PaymentGatewayType.cash.name,
      paymentGatewayType: PaymentGatewayType.cash.value,
      cardName: PaymentGatewayType.cash.getName(),
    );

    final wallet = CardResponse(
      id: PaymentGatewayType.wallet.name,
      paymentGatewayType: PaymentGatewayType.wallet.value,
      cardName: PaymentGatewayType.wallet.getName(),
      isEnable: (state.totalWalletAmount ?? 0) > (state.totalAmount ?? 0),
    );

    final razorPay = CardResponse(
      id: PaymentGatewayType.razorpay.name,
      paymentGatewayType: PaymentGatewayType.razorpay.value,
      cardName: PaymentGatewayType.razorpay.getName(),
    );

    final mercado = CardResponse(
      id: PaymentGatewayType.mercado.name,
      paymentGatewayType: PaymentGatewayType.mercado.value,
      cardName: PaymentGatewayType.mercado.getName(),
    );

    final payu = CardResponse(
      id: PaymentGatewayType.payu.name,
      paymentGatewayType: PaymentGatewayType.payu.value,
      cardName: PaymentGatewayType.payu.getName(),
    );

    final pago = CardResponse(
      id: PaymentGatewayType.pago.name,
      paymentGatewayType: PaymentGatewayType.pago.value,
      cardName: PaymentGatewayType.pago.getName(),
    );

    final pagoC2p = CardResponse(
      id: PaymentGatewayType.pagoC2p.name,
      paymentGatewayType: PaymentGatewayType.pagoC2p.value,
      cardName: PaymentGatewayType.pagoC2p.getName(),
    );

    final zainCash = CardResponse(
      id: PaymentGatewayType.zaincash.name,
      paymentGatewayType: PaymentGatewayType.zaincash.value,
      cardName: PaymentGatewayType.zaincash.getName(),
    );

    final hyperPay = CardResponse(
      id: PaymentGatewayType.hyperpay.name,
      paymentGatewayType: PaymentGatewayType.hyperpay.value,
      cardName: PaymentGatewayType.hyperpay.getName(),
    );

    final nestPay = CardResponse(
      id: PaymentGatewayType.nestpay.name,
      paymentGatewayType: PaymentGatewayType.nestpay.value,
      cardName: PaymentGatewayType.nestpay.getName(),
    );

    final qiCard = CardResponse(
      id: PaymentGatewayType.qicard.name,
      paymentGatewayType: PaymentGatewayType.qicard.value,
      cardName: PaymentGatewayType.qicard.getName(),
    );

    final mpesa = CardResponse(
      id: PaymentGatewayType.mpesa.name,
      paymentGatewayType: PaymentGatewayType.mpesa.value,
      cardName: PaymentGatewayType.mpesa.getName(),
    );

    if (state.isFromCurrentBooking || state.isFromFeedBack) {
      final paymentSetting = state.myBookingPaymentSetting;
      final isPreBookingPayment = state.isPreBookingPayment;
      final isPartialPayment = paymentSetting?.isPartialPayment ?? false;

      if (!state.isFromFeedBack &&
          !isPreBookingPayment &&
          paymentSetting?.isCash == true &&
          !isPartialPayment) {
        cardList.add(cash);
      }

      if (!isPreBookingPayment &&
          paymentSetting?.isWallet == true &&
          !isPartialPayment) {
        cardList.add(wallet);
      }

      final bool isWalletVisible;
      final List<int> paymentGateways;

      if (isPartialPayment) {
        isWalletVisible = paymentSetting?.isWalletAdvancePayment == true;
        paymentGateways = state.businessType == BusinessType.courier
            ? paymentSetting?.paymentGateways ?? []
            : paymentSetting?.advancePaymentPaymentGateways ?? [];
      } else if (isPreBookingPayment) {
        isWalletVisible = false;
        paymentGateways = paymentSetting?.captureRequiredPaymentGateways ?? [];
      } else {
        isWalletVisible = paymentSetting?.isWallet == true;
        paymentGateways = paymentSetting?.paymentGateways ?? [];
      }

      state = state.copyWith(isWalletVisible: isWalletVisible);

      if (paymentGateways.contains(PaymentGatewayType.razorpay.value)) {
        cardList.add(razorPay);
      }
      if (paymentGateways.contains(PaymentGatewayType.mercado.value)) {
        cardList.add(mercado);
      }
      if (paymentGateways.contains(PaymentGatewayType.payu.value)) {
        cardList.add(payu);
      }
      if (paymentGateways.contains(PaymentGatewayType.pago.value)) {
        cardList.add(pago);
      }
      if (paymentGateways.contains(PaymentGatewayType.pagoC2p.value)) {
        cardList.add(pagoC2p);
      }
      if (paymentGateways.contains(PaymentGatewayType.zaincash.value)) {
        cardList.add(zainCash);
      }
      if (paymentGateways.contains(PaymentGatewayType.hyperpay.value)) {
        cardList.add(hyperPay);
      }
      if (paymentGateways.contains(PaymentGatewayType.nestpay.value)) {
        cardList.add(nestPay);
      }
      if (paymentGateways.contains(PaymentGatewayType.qicard.value)) {
        cardList.add(qiCard);
      }
      if (paymentGateways.contains(PaymentGatewayType.mpesa.value)) {
        cardList.add(mpesa);
      }
    } else if (state.isComeFromBooking) {
      final vehicleTypePaymentSetting = state.vehicleTypePaymentSetting;

      if (vehicleTypePaymentSetting?.isCash == true) {
        cardList.add(cash);
      }

      if (vehicleTypePaymentSetting?.isWallet == true) {
        cardList.add(wallet);
      }

      state = state.copyWith(
          isWalletVisible: vehicleTypePaymentSetting?.isWallet ?? false);

      // Native compares against `PaymentGatewayType.X.value.toString()`.
      final paymentGateways = vehicleTypePaymentSetting?.paymentGateways
              ?.whereType<String>()
              .toList() ??
          <String>[];

      if (paymentGateways.contains(PaymentGatewayType.razorpay.value.toString())) {
        cardList.add(razorPay);
      }
      if (paymentGateways.contains(PaymentGatewayType.mercado.value.toString())) {
        cardList.add(mercado);
      }
      if (paymentGateways.contains(PaymentGatewayType.payu.value.toString())) {
        cardList.add(payu);
      }
      if (paymentGateways.contains(PaymentGatewayType.pago.value.toString())) {
        cardList.add(pago);
      }
      if (paymentGateways.contains(PaymentGatewayType.pagoC2p.value.toString())) {
        cardList.add(pagoC2p);
      }
      if (paymentGateways.contains(PaymentGatewayType.zaincash.value.toString())) {
        cardList.add(zainCash);
      }
      if (paymentGateways.contains(PaymentGatewayType.hyperpay.value.toString())) {
        cardList.add(hyperPay);
      }
      if (paymentGateways.contains(PaymentGatewayType.nestpay.value.toString())) {
        cardList.add(nestPay);
      }
      if (paymentGateways.contains(PaymentGatewayType.qicard.value.toString())) {
        cardList.add(qiCard);
      }
      if (paymentGateways.contains(PaymentGatewayType.mpesa.value.toString())) {
        cardList.add(mpesa);
      }
    }

    return cardList;
  }

  /// Create list of webview-based payment gateways (Razorpay, Mercado, etc.)
  List<CardResponse> razorPayAndMercadoCardList() {
    final paymentGatewayList = <CardResponse>[];
    final allGateways = state.allPaymentGatewayList;

    if (allGateways.any((g) => g.type == PaymentGatewayType.razorpay.value)) {
      paymentGatewayList.add(CardResponse(
        id: PaymentGatewayType.razorpay.name,
        paymentGatewayType: PaymentGatewayType.razorpay.value,
        cardName: PaymentGatewayType.razorpay.getName(),
      ));
    }

    if (allGateways.any((g) => g.type == PaymentGatewayType.mercado.value)) {
      paymentGatewayList.add(CardResponse(
        id: PaymentGatewayType.mercado.name,
        paymentGatewayType: PaymentGatewayType.mercado.value,
        cardName: PaymentGatewayType.mercado.getName(),
      ));
    }

    if (allGateways.any((g) => g.type == PaymentGatewayType.payu.value)) {
      paymentGatewayList.add(CardResponse(
        id: PaymentGatewayType.payu.name,
        paymentGatewayType: PaymentGatewayType.payu.value,
        cardName: PaymentGatewayType.payu.getName(),
      ));
    }

    if (allGateways.any((g) => g.type == PaymentGatewayType.pago.value)) {
      paymentGatewayList.add(CardResponse(
        id: PaymentGatewayType.pago.name,
        paymentGatewayType: PaymentGatewayType.pago.value,
        cardName: PaymentGatewayType.pago.getName(),
      ));
    }

    if (allGateways.any((g) => g.type == PaymentGatewayType.pagoC2p.value)) {
      paymentGatewayList.add(CardResponse(
        id: PaymentGatewayType.pagoC2p.name,
        paymentGatewayType: PaymentGatewayType.pagoC2p.value,
        cardName: PaymentGatewayType.pagoC2p.getName(),
      ));
    }

    if (allGateways.any((g) => g.type == PaymentGatewayType.zaincash.value)) {
      paymentGatewayList.add(CardResponse(
        id: PaymentGatewayType.zaincash.name,
        paymentGatewayType: PaymentGatewayType.zaincash.value,
        cardName: PaymentGatewayType.zaincash.getName(),
      ));
    }

    if (allGateways.any((g) => g.type == PaymentGatewayType.hyperpay.value)) {
      paymentGatewayList.add(CardResponse(
        id: PaymentGatewayType.hyperpay.name,
        paymentGatewayType: PaymentGatewayType.hyperpay.value,
        cardName: PaymentGatewayType.hyperpay.getName(),
      ));
    }

    if (allGateways.any((g) => g.type == PaymentGatewayType.nestpay.value)) {
      paymentGatewayList.add(CardResponse(
        id: PaymentGatewayType.nestpay.name,
        paymentGatewayType: PaymentGatewayType.nestpay.value,
        cardName: PaymentGatewayType.nestpay.getName(),
      ));
    }

    if (allGateways.any((g) => g.type == PaymentGatewayType.qicard.value)) {
      paymentGatewayList.add(CardResponse(
        id: PaymentGatewayType.qicard.name,
        paymentGatewayType: PaymentGatewayType.qicard.value,
        cardName: PaymentGatewayType.qicard.getName(),
      ));
    }

    if (allGateways.any((g) => g.type == PaymentGatewayType.mpesa.value)) {
      paymentGatewayList.add(CardResponse(
        id: PaymentGatewayType.mpesa.name,
        paymentGatewayType: PaymentGatewayType.mpesa.value,
        cardName: PaymentGatewayType.mpesa.getName(),
      ));
    }

    return paymentGatewayList;
  }

  /// Get wallet details from local storage
  void getWalletDetails() {
    final entity = _sharedPref?.getEntity();
    final setting = _sharedPref?.getSetting();

    final formattedAmount = entity?.credit?.applyPriceSetting(
      currencyDirection: setting?.setCurrencySign ?? 1,
      currencySign: setting?.currencySign ?? '',
      decimalPointValue: setting?.decimalPointValue ?? 2,
    );

    state = state.copyWith(
      totalWalletAmount: entity?.credit,
      formattedWalletAmount: formattedAmount,
      totalRedeemPoints: entity?.reward,
    );

    setTransferButton();
    updateCardList();
  }

  /// Set transfer button visibility
  void setTransferButton() {
    final setting = _sharedPref?.getSetting();
    final entity = _sharedPref?.getEntity();

    final checkTransfer =
        setting?.creditTransferConfig?.isCustomerToCustomer == true ||
            setting?.creditTransferConfig?.isCustomerToDriver == true;

    final isShowMoneyTransfer = (entity?.credit ?? 0) >= 1 && checkTransfer;

    final isComeFromBooking = state.isComeFromBooking;
    final isFromCurrentBooking = state.isFromCurrentBooking;
    final isFromFeedBack = state.isFromFeedBack;

    final isShowTransfer = checkTransfer &&
        !isComeFromBooking &&
        !isFromCurrentBooking &&
        !isFromFeedBack;

    state = state.copyWith(
      isShowTransferMoneyButton: isShowTransfer,
      isDisableTransferMoneyButton:
          !state.isComeFromBooking ? !isShowMoneyTransfer : false,
    );
  }

  /// Check if add card option should be shown
  /// Whether the "Add card" row is offered.
  ///
  /// Native builds a list of per-gateway booleans and then calls
  /// `.any { true }` on it — the predicate ignores each element, so that check
  /// is always true and the decision comes down to the vehicle having a
  /// payment-gateway list at all and the booking not being corporate. Ported
  /// as-is: evaluating the booleans instead (as this did) hid the row for
  /// vehicles whose gateway list holds values outside the known enum.
  bool showAddCard(VehicleTypePaymentSetting? vehiclePaymentSetting) {
    final paymentGateways = vehiclePaymentSetting?.paymentGateways;
    return paymentGateways != null && !state.isCorporateBooking;
  }

  /// Delete a card
  Future<void> deleteCard(String id) async {
    state = state.copyWith(isDeleteCardLoading: true);

    final response = await _appRepository.deleteCard(cardId: id);

    switch (response) {
      case Success():
        showSnackBar(response.message ?? '');
        await getCards();
        state = state.copyWith(isDeleteCardLoading: false);

      case Error():
        showSnackBar(response.error?.message ?? '', isError: true);
        state = state.copyWith(isDeleteCardLoading: false);

      case Loading():
        break;
    }
  }

  /// Check if card is selected for payment
  bool isCardSelectedForPayment() {
    if (state.walletAmount <= 0) {
      showSnackBar(
        getString(
          appStr.errorPleaseEnterWalletAmount,
          'error_please_enter_wallet_amount',
        ),
        isError: true,
      );
      return false;
    }

    if (state.selectedCardsForAddPayment == null) {
      showSnackBar(
        getString(
          appStr.errorPleaseSelectCard,
          'error_please_select_card',
        ),
        isError: true,
      );
      return false;
    }

    return true;
  }

  /// Check if card data is valid
  bool checkCardData(CardDetails cardDetails) {
    final validName = Validator.validCardName(cardDetails.name ?? '');
    final validCard = Validator.validCardNumber(cardDetails.cardNumber ?? '');
    final validExpiryDate = Validator.validExpiryDate(cardDetails.expiryDate ?? '');
    final validCvv = Validator.validCvv(cardDetails.cvv ?? '');

    if (!validName.status) {
      showSnackBar(
        getString(
          appStr.errorPleaseEnterCardName,
          'error_please_enter_card_name',
        ),
        isError: true,
      );
      return false;
    }

    if (!validCard.status) {
      showSnackBar(
        getString(
          appStr.errorPleaseEnterValidCardNumber,
          'error_please_enter_valid_card_number',
        ),
        isError: true,
      );
      return false;
    }

    if (!validExpiryDate.status) {
      showSnackBar(
        getString(
          appStr.errorPleaseEnterValidExpiryDate,
          'error_please_enter_valid_expiry_date',
        ),
        isError: true,
      );
      return false;
    }

    if (!validCvv.status) {
      showSnackBar(
        getString(
          appStr.errorPleaseEnterValidCvv,
          'error_please_enter_valid_cvv',
        ),
        isError: true,
      );
      return false;
    }

    return true;
  }

  /// Get payment manager based on payment gateway type
  PaymentInterface _getPaymentManager(int? paymentGateway) {
    return switch (paymentGateway) {
      int g when g == PaymentGatewayType.stripe.value => StripePaymentManager(),
      int g when g == PaymentGatewayType.paystack.value => PayStackManager(),
      _ => WebViewPaymentManager(),
    };
  }

  /// Create payment intent for wallet top-up
  Future<void> paymentIntentCreate() async {
    if (!isCardSelectedForPayment()) return;

    final paymentGateway = state.selectedCardsForAddPayment?.paymentGatewayType;
    final paymentManager = _getPaymentManager(paymentGateway);

    state = state.copyWith(
      selectedPaymentType: paymentGateway,
      isLoading: true,
    );

    final paymentIntentRequest = WalletPaymentRequest(
      amount: state.walletAmount,
      countryId: _sharedPref?.getEntity()?.countryId,
      currency: _sharedPref?.getEntity()?.creditCurrencyCode,
      paymentPurpose: PaymentPurposeType.addWallet,
    );

    final response = await _appRepository.paymentIntentCreate(
      paymentGateway: paymentGateway.toString(),
      request: paymentIntentRequest,
    );

    switch (response) {
      case Success<PaymentIntentResponse>():
        if (response.data?.paymentTransactionStatus ==
            PaymentTransactionStatus.initiated) {
          paymentManager.initPaymentSdk(response.data?.intent?.publicKey ?? '');

          paymentManager.createPaymentIntent(
            intent: response.data?.intent,
            callback: PaymentCallbackImpl(
              onSuccess: (paymentMethodId, intentResponse) {
                if (paymentMethodId != null) {
                  // Stripe direct payment success - close bottom sheet and refresh data
                  state = state.copyWith(
                    isLoading: false,
                    showAddWalletAmountBottomSheet: false,
                    walletAmount: 0,
                  );
                  // Refresh entity detail and cards list
                  getEntityDetail();
                  getCards();
                } else {
                  // WebView payment - navigate to webview
                  WebViewDataModel? webViewDataModel;
                  if (intentResponse?.url != null &&
                      intentResponse!.url!.isNotEmpty) {
                    webViewDataModel = WebViewDataModel(
                      webURL: Uri.encodeFull(intentResponse.url!),
                    );
                  } else if (intentResponse?.html != null &&
                      intentResponse!.html!.isNotEmpty) {
                    webViewDataModel = WebViewDataModel(
                      webContent: intentResponse.html,
                    );
                  }
                  if (webViewDataModel != null) {
                    state = state.copyWith(
                      isLoading: false,
                      isNavigateToWebView: !state.isNavigateToWebView,
                      navigateURL: webViewDataModel,
                      showAddWalletAmountBottomSheet: false,
                      walletAmount: 0,
                    );
                  }
                }
              },
              onCapture: () {
                // Use if needed
              },
              onCardCreated: (paymentMethodId, intent) {
                // Use if needed
              },
              onError: (error) {
                showSnackBar(error.toString(), isError: true);
                state = state.copyWith(isLoading: false);
              },
            ),
          );
        } else {
          // Payment already completed
          state = state.copyWith(
            isLoading: false,
            showAddWalletAmountBottomSheet: false,
            walletAmount: 0,
          );
          getEntityDetail();
          getCards();
        }

      case Error():
        showSnackBar(response.error?.message ?? '', isError: true);
        state = state.copyWith(isLoading: false);

      case Loading():
        break;
    }
  }

  /// Reset navigation state after navigating to webview
  void resetNavigationState() {
    state = state.copyWith(
      isNavigateToWebView: false,
      clearNavigateURL: true,
    );
  }

  /// Get entity detail (refresh user data)
  Future<void> getEntityDetail() async {
    final request = EntityDetailRequest();
    final response = await _appRepository.getEntityDetail(request);

    switch (response) {
      case Success():
        if (response.data?.entity != null) {
          await _sharedPref?.setEntity(response.data!.entity!);
        }
        getWalletDetails();
        state = state.copyWith(isLoading: false);

      case Error():
        state = state.copyWith(isLoading: false);

      case Loading():
        break;
    }
  }

  /// Update wallet amount
  void updateWalletAmount(double amount) {
    state = state.copyWith(walletAmount: amount);
  }

  /// Update card list
  void updateCardList() {
    final tempList = List<CardResponse>.from(state.cardsList);
    if (tempList.isNotEmpty && tempList.length > 1 && state.isComeFromBooking) {
      tempList[1] = CardResponse(
        id: PaymentGatewayType.wallet.name,
        paymentGatewayType: PaymentGatewayType.wallet.value,
        cardName: PaymentGatewayType.wallet.getName(),
        isEnable: (state.totalWalletAmount ?? 0) > (state.totalAmount ?? 0),
      );
    }
    state = state.copyWith(cardsList: tempList);
  }

  /// Search user for money transfer
  Future<void> getSearchUser({
    required String countryPhoneCode,
    required String phoneNo,
    required int type,
    required String id,
  }) async {
    state = state.copyWith(isLoading: true);

    final response = await _appRepository.searchUser(
      countryPhoneCode: countryPhoneCode,
      phone: phoneNo,
      type: type,
      id: id,
    );

    switch (response) {
      case Success<SearchUserResponse>():
        if (response.data?.user != null) {
          state = state.copyWith(
            isLoading: false,
            isShowSendMoneyButton: true,
            selectedUser: response.data!.user,
            isShowNoDataFound: false,
            hideKeyBoard: true,
          );
        } else {
          state = state.copyWith(
            isLoading: false,
            isShowSendMoneyButton: false,
            isShowNoDataFound: true,
            hideKeyBoard: true,
          );
        }

      case Error():
        showSnackBar(response.error?.message ?? '', isError: true);
        state = state.copyWith(
          isLoading: false,
          isShowSendMoneyButton: false,
          isShowNoDataFound: true,
        );

      case Loading():
        break;
    }
  }

  /// Withdraw redeem points
  Future<void> withDrawRedeemPoints() async {
    final setting = _sharedPref?.getSetting();
    final minPoints = setting?.rewardPointConfig?.minPointForWithdrawal ?? 0;

    if (state.redeemPoint.isEmpty) {
      showSnackBar(
        getString(
          appStr.errorPleaseEnterRedeemPoint,
          'error_please_enter_redeem_point',
        ),
        isError: true,
      );
      return;
    }

    final points = double.tryParse(state.redeemPoint) ?? 0;
    if (points < minPoints) {
      showSnackBar(
        getString(
          appStr.errorEnterValidRedeemPoint,
          'error_enter_valid_redeem_point',
        ).replacePlaceholders({StringConstant.value: minPoints.toString()}),
        isError: true,
      );
      return;
    }

    state = state.copyWith(isLoading: true);

    final request = RedeemWithdrawRequest(rewardPoint: points);
    final response = await _appRepository.withdrawRewardPoints(request);

    switch (response) {
      case Success():
        showSnackBar(response.message ?? '');
        state = state.copyWith(
          isLoading: false,
          showRedeemPointBottomSheet: false,
          convertedRedeemPointPrice: _calculateConvertedPrice('1'),
        );
        getEntityDetail();

      case Error():
        showSnackBar(response.error?.message ?? '', isError: true);
        state = state.copyWith(
          isLoading: false,
          showRedeemPointBottomSheet: false,
          convertedRedeemPointPrice: _calculateConvertedPrice('1'),
        );

      case Loading():
        break;
    }
  }

  /// Calculate converted price from points
  String _calculateConvertedPrice(String points) {
    final setting = _sharedPref?.getSetting();
    final valuePerPoint = setting?.rewardPointConfig?.valueOfOneRewardPoint ?? 0;
    final currency = setting?.currencySign ?? '';

    final pointsValue = double.tryParse(points) ?? 0;
    final convertedValue = pointsValue * valuePerPoint;

    return '$currency${convertedValue.toStringAsFixed(2)}';
  }

  /// Update redeem points
  void updateRedeemPoint(String points) {
    state = state.copyWith(
      redeemPoint: points,
      convertedRedeemPointPrice: _calculateConvertedPrice(points.isEmpty ? '1' : points),
    );
  }

  /// Get corporate payment gateways
  Future<void> getCorporatePaymentGateways() async {
    final gateWayList = state.vehicleTypePaymentSetting?.paymentGateways;
    if (gateWayList == null || gateWayList.isEmpty) {
      return;
    }

    // Set loading state (matches Kotlin Loading state)
    state = state.copyWith(isLoading: true, isWalletVisible: false);

    final response = await _appRepository.getCorporatePaymentGateways(
      paymentGatewayTypes: gateWayList.whereType<int>().join(','),
    );

    switch (response) {
      case Success<CorporatePaymentResponse>():
        final paymentGateways = response.data?.paymentGateways ?? [];
        state = state.copyWith(
          isLoading: false,
          cardsList: getCardListForCorporate(paymentGateways),
          isWalletVisible: false,
        );

      case Error():
        showSnackBar(response.error?.message ?? '', isError: true);
        state = state.copyWith(
          isLoading: false,
          isWalletVisible: false,
        );

      case Loading():
        break;
    }
  }

  /// Create card list for corporate bookings
  List<CardResponse> getCardListForCorporate(List<int> paymentGatewayList) {
    final cardList = <CardResponse>[];

    for (final gatewayType in paymentGatewayList) {
      final type = PaymentGatewayType.fromValue(gatewayType);
      if (type != null) {
        cardList.add(CardResponse(
          id: type.name,
          paymentGatewayType: gatewayType,
          cardName: type.getName(),
        ));
      }
    }

    return cardList;
  }

  /// Get payment gateways value based on current state
  String getPaymentGatewaysValue() {
    if (state.isComeFromBooking) {
      return state.vehicleTypePaymentSetting?.paymentGateways
              ?.whereType<String>()
              .join(',') ??
          '';
    } else if (state.isFromCurrentBooking || state.isFromFeedBack) {
      if (state.myBookingPaymentSetting?.isPartialPayment == true) {
        if (state.businessType == BusinessType.courier) {
          return state.myBookingPaymentSetting?.paymentGateways?.join(',') ??
              '';
        } else {
          return state.myBookingPaymentSetting?.advancePaymentPaymentGateways
                  ?.join(',') ??
              '';
        }
      } else if (state.isPreBookingPayment) {
        return state.myBookingPaymentSetting?.captureRequiredPaymentGateways
                ?.join(',') ??
            '';
      } else {
        return state.myBookingPaymentSetting?.paymentGateways?.join(',') ?? '';
      }
    } else {
      return state.allPaymentGatewayList.map((g) => g.type.toString()).join(',');
    }
  }

  /// Refresh payment gateways
  Future<void> refresh() async {
    await getPaymentGateways();
  }

  /// Transfer credit to another user
  Future<void> transferCredit(TransferCreditRequest request) async {
    state = state.copyWith(isLoading: true);

    final response = await _appRepository.transferCredit(request: request);

    switch (response) {
      case Success():
        showSnackBar(response.message ?? '');
        state = state.copyWith(
          isLoading: false,
          showTransferMoneyBottomSheet: false,
        );
        getEntityDetail();

      case Error():
        showSnackBar(response.error?.message ?? '', isError: true);
        state = state.copyWith(
          isLoading: false,
          showTransferMoneyBottomSheet: false,
        );

      case Loading():
        break;
    }
  }

  /// Select a card as default
  Future<void> selectCard() async {
    final selectedPaymentMethod = state.selectedPaymentMethod;
    if (selectedPaymentMethod?.id == PaymentGatewayType.wallet.name) {
      return;
    }

    state = state.copyWith(isLoading: true);

    final response = await _appRepository.selectCard(
      cardId: selectedPaymentMethod?.id ?? '',
    );

    switch (response) {
      case Success():
        await getCards();
        if (state.isFromSubscription) {
          state = state.copyWith(isNavigateToBack: true);
        }

      case Error():
        debugPrint('API selectCard: ${response.error?.message}');
        state = state.copyWith(isLoading: false);

      case Loading():
        break;
    }
  }

  /// Add a new card
  Future<void> addCard(String? paymentMethodId) async {
    final addCardRequest = AddCardRequest(
      countryId: _sharedPref?.getEntity()?.countryId,
      paymentMethod: paymentMethodId,
    );

    // isAddCardLoading rather than isLoading: getCards() below toggles isLoading
    // itself, which would drop the overlay while the list was still coming back.
    state = state.copyWith(isAddCardLoading: true);

    final response = await _appRepository.addCard(
      gateway: state.selectedPaymentType.toString(),
      request: addCardRequest,
    );

    switch (response) {
      case Success():
        state = state.copyWith(
          showAddCardBottomSheet: false,
          showGatewayBottomSheet: false,
          isAddCard: false,
        );
        await getCards();
        state = state.copyWith(isAddCardLoading: false);

      case Error():
        showSnackBar(response.error?.message ?? '', isError: true);
        state = state.copyWith(
          isAddCardLoading: false,
          showAddCardBottomSheet: false,
          showGatewayBottomSheet: false,
          isAddCard: false,
        );

      case Loading():
        break;
    }
  }

  /// Add card intent for payment gateway
  /// Matches Kotlin PaymentUIEvent.AddCardButtonClick logic
  Future<void> addCardIntent() async {
    // Use paymentGatewayToAddCard type (matches Kotlin selectedPaymentGateWay)
    final gatewayType = state.paymentGatewayToAddCard?.type;
    // if (gatewayType == null) {
    //   showSnackBar('No payment gateway selected', isError: true);
    //   return;
    // }

    // Only validate card data for Stripe (matches Kotlin)
    // PayStack uses WebView and doesn't need card details
    if (gatewayType == PaymentGatewayType.stripe.value) {
      final cardDetails = state.selectedCardDetails;
      if (cardDetails == null || !checkCardData(cardDetails)) {
        return;
      }
    }

    state = state.copyWith(
      isAddCardLoading: true,
      selectedPaymentType: gatewayType,
      paymentManager: _getPaymentManager(gatewayType),
    );

    final response = await _appRepository.addCardIntent(
      gateway: gatewayType.toString(),
      countryId: _sharedPref?.getEntity()?.countryId ?? '',
    );

    switch (response) {
      case Success<AddCardIntentResponse>():
        state = state.copyWith(
          showAddCardBottomSheet: false,
          showGatewayBottomSheet: false,
          isAddCardLoading: false,
        );

        final data = response.data;
        debugPrint('addCardIntent: $data');

        state.paymentManager?.initPaymentSdk(data?.intent?.publicKey ?? '');
        state.paymentManager?.createCardIntent(
          card: state.selectedCardDetails,
          addCardIntentResponse: data?.intent,
          callback: PaymentCallbackImpl(
            onSuccess: (paymentMethodId, intentResponse) {
              // Use if needed
            },
            onCapture: () {
              // Use if needed
            },
            onCardCreated: (paymentMethodId, addCardIntentResponse) {
              debugPrint('onCardMethodCreated: $paymentMethodId');
              if (paymentMethodId != null) {
                if (state.isAddCard) {
                  state = state.copyWith(isAddCard: false);
                  addCard(paymentMethodId);
                }
              } else if (addCardIntentResponse != null) {
                final webViewDataModel = WebViewDataModel(
                  webURL: Uri.encodeFull(data?.intent?.authorizationUrl ?? ''),
                );
                state = state.copyWith(
                  isNavigateToWebView: !state.isNavigateToWebView,
                  navigateURL: webViewDataModel,
                );
              }
            },
            onError: (error) {
              showSnackBar(error.toString(), isError: true);
              state = state.copyWith(
                isAddCardLoading: false,
                showAddCardBottomSheet: false,
                showGatewayBottomSheet: false,
                isAddCard: false,
              );
            },
          ),
        );

      case Error():
        showSnackBar(response.error?.message ?? '', isError: true);
        state = state.copyWith(
          isAddCardLoading: false,
          isAddCard: false,
        );

      case Loading():
        break;
    }
  }

  /// Get countries list
  Future<void> getCountries() async {
    state = state.copyWith(isLoading: true);

    final response = await _appRepository.getCountries();

    switch (response) {
      case Success<CountryResponse>():
        state = state.copyWith(
          isLoading: false,
          countryList: response.data?.countries ?? [],
        );

      case Error():
        state = state.copyWith(isLoading: false);

      case Loading():
        break;
    }
  }

  /// Validate transfer amount - matches Kotlin validateAmount
  bool validateAmount(String? amount) {
    if (amount == null || amount.isEmpty) return true;
    // Allow only numeric values with optional decimal point
    final regex = RegExp(r'^\d*\.?\d*$');
    return regex.hasMatch(amount);
  }

  /// Update phone number for transfer
  void updatePhoneNumber(String phoneNumber) {
    state = state.copyWith(phoneNumber: phoneNumber);
  }

  /// Update transfer amount
  void updateAmount(String amount) {
    if (validateAmount(amount)) {
      state = state.copyWith(amount: amount);
    }
  }

  /// Toggle use wallet amount
  void toggleUseWalletAmount() {
    state = state.copyWith(useWalletAmount: !state.useWalletAmount);
  }

  /// Update selected user menu
  void updateSelectedUserMenu(DropDownModel? userMenu) {
    state = state.copyWith(
      selectedUserMenu: userMenu,
      clearSelectedUser: true,
      isShowSendMoneyButton: false,
      phoneNumber: '',
    );
  }

  /// Show delete card dialog
  void showDeleteCardDialog(CardResponse card) {
    state = state.copyWith(
      showDeleteCardBottomSheet: true,
      selectedCardForDelete: card,
    );
  }

  /// Cancel delete card dialog
  void cancelDeleteCardDialog() {
    state = state.copyWith(
      showDeleteCardBottomSheet: false,
      clearSelectedCardForDelete: true,
    );
  }

  /// Confirm delete card
  Future<void> confirmDeleteCard() async {
    final cardId = state.selectedCardForDelete?.id;
    state = state.copyWith(
      showDeleteCardBottomSheet: false,
      clearSelectedCardForDelete: true,
    );
    if (cardId != null) {
      await deleteCard(cardId);
    }
  }

  /// Toggle add wallet amount bottom sheet
  void toggleAddWalletAmountBottomSheet() {
    state = state.copyWith(
      showAddWalletAmountBottomSheet: !state.showAddWalletAmountBottomSheet,
      walletAmount: 0,
    );
  }

  /// Dismiss add wallet amount bottom sheet
  void dismissAddWalletAmountBottomSheet() {
    state = state.copyWith(
      showAddWalletAmountBottomSheet: false,
      walletAmount: 0,
    );
  }

  /// Update selected card for payment (add wallet)
  void updateSelectedCardForPayment(CardResponse card) {
    state = state.copyWith(selectedCardsForAddPayment: card);
  }

  /// Toggle transfer money bottom sheet
  void toggleTransferMoneyBottomSheet() {
    if (state.isShowTransferMoneyButton) {
      state = state.copyWith(
        showTransferMoneyBottomSheet: !state.showTransferMoneyBottomSheet,
        clearSelectedUser: true,
        amount: '',
        phoneNumber: '',
        clearSelectedUserTypeIndex: true,
        isShowSendMoneyButton: false,
      );
    }
  }

  /// Dismiss transfer money bottom sheet
  void dismissTransferMoneyBottomSheet() {
    state = state.copyWith(
      showTransferMoneyBottomSheet: false,
      clearSelectedUser: true,
      amount: '',
      phoneNumber: '',
      clearSelectedUserTypeIndex: true,
      isShowSendMoneyButton: false,
    );
  }

  /// Transfer money click handler - validates and calls transferCredit
  /// Matches Kotlin: PaymentUIEvent.TransferMoneyClick
  void onTransferMoneyClick() {
    final amount = state.amount;
    final totalWalletAmount = state.totalWalletAmount ?? 0.0;

    try {
      final amountDouble = double.tryParse(amount) ?? 0.0;

      // Validate: amount not empty, not zero, and within wallet balance
      if (amount.isEmpty || amountDouble == 0.0 || totalWalletAmount < amountDouble) {
        showSnackBar(
          getString(null, 'error_please_enter_valid_amount'),
          isError: true,
        );
        return;
      }

      // Create transfer request
      final transferCreditRequest = TransferCreditRequest(
        amount: amountDouble,
        typeId: state.selectedUser?.id,
        type: state.selectedUserMenu?.type,
      );

      transferCredit(transferCreditRequest);
    } catch (_) {
      showSnackBar(
        getString(null, 'error_please_enter_valid_amount'),
        isError: true,
      );
    }
  }

  /// Search phone number handler - validates and calls getSearchUser
  /// Matches Kotlin: PaymentUIEvent.SearchPhoneNumber
  void onSearchPhoneNumber() {
    if (state.phoneNumber.isNotEmpty) {
      if (state.selectedUserMenu != null) {
        getSearchUser(
          countryPhoneCode: state.countryPhoneCode,
          phoneNo: state.phoneNumber,
          type: state.selectedUserMenu!.type,
          id: '',
        );
      }
    } else {
      showSnackBar(
        getString(
          appStr.errorPleaseEnterPhoneNumber,
          'error_please_enter_phone_number',
        ),
        isError: true,
      );
    }
  }

  /// Toggle country phone code bottom sheet
  void toggleCountryPhoneCodeBottomSheet() {
    final entity = _sharedPref?.getEntity();
    final country = state.countryList.where((c) => c.id == entity?.countryId).firstOrNull;

    if (country?.phoneCodes != null && country!.phoneCodes!.isNotEmpty) {
      final multiplePhoneCodeCountryList = country.phoneCodes!
          .map((code) => Country(
                id: country.id,
                name: country.name,
                phoneCodes: [code],
                currencyCode: country.currencyCode,
                currencySign: country.currencySign,
                alpha2: country.alpha2,
                code: country.code,
                code2: country.code2,
                timezones: country.timezones,
                isBusiness: country.isBusiness,
                phoneCode: code,
              ))
          .toList();

      state = state.copyWith(
        multiplePhoneCodeCountryList: multiplePhoneCodeCountryList,
        showCountryPhoneCodeBottomSheet: true,
      );
    }
  }

  /// Dismiss country phone code bottom sheet
  void dismissCountryPhoneCodeBottomSheet() {
    state = state.copyWith(showCountryPhoneCodeBottomSheet: false);
  }

  /// Update country phone code
  void updateCountryPhoneCode(Country country) {
    state = state.copyWith(
      countryPhoneCode: country.phoneCodes?.firstOrNull ?? '',
    );
  }

  /// Toggle redeem point bottom sheet
  void toggleRedeemPointBottomSheet() {
    if ((state.totalRedeemPoints ?? 0) > 0) {
      state = state.copyWith(
        showRedeemPointBottomSheet: !state.showRedeemPointBottomSheet,
        redeemPoint: '',
        convertedRedeemPointPrice: _calculateConvertedPrice('1'),
      );
    }
  }

  /// Dismiss redeem point bottom sheet
  void dismissRedeemPointBottomSheet() {
    state = state.copyWith(
      showRedeemPointBottomSheet: false,
      convertedRedeemPointPrice: _calculateConvertedPrice('1'),
    );
  }

  /// Handle AddCardClick event - shows the add card bottom sheet
  /// Matches Kotlin PaymentUIEvent.AddCardClick
  void onAddCardClick() {
    if (state.paymentGatewayList.isEmpty) return;

    final gatewayList = state.paymentGatewayList;
    final firstGateway = gatewayList.first;

    // Determine if should show bottom sheet (matches Kotlin logic)
    // - If multiple gateways: toggle
    // - If single Stripe gateway: toggle
    // - If single PayStack gateway: don't show (call API directly)
    bool shouldShowBottomSheet;
    if (gatewayList.length != 1) {
      shouldShowBottomSheet = !state.showAddCardBottomSheet;
    } else {
      shouldShowBottomSheet = firstGateway.type == PaymentGatewayType.stripe.value
          ? !state.showAddCardBottomSheet
          : false;
    }

    state = state.copyWith(
      showAddCardBottomSheet: shouldShowBottomSheet,
      selectedPaymentType: firstGateway.type,
      paymentManager: _getPaymentManager(firstGateway.type),
      isAddCard: true,
    );

    // If only PayStack available, call addCardIntent directly (no bottom sheet needed)
    // Matches Kotlin: if paymentGatewayList.size == 1 && first.type == PAYSTACK -> addCardIntent()
    if (gatewayList.length == 1 &&
        firstGateway.type == PaymentGatewayType.paystack.value) {
      addCardIntent();
    }
  }

  /// Dismiss add card bottom sheet
  /// Note: Don't reset isAddCard here - it's reset after addCard() completes
  /// or on error in the Stripe callback. Resetting here causes race condition
  /// where Stripe SDK returns after bottom sheet closes but isAddCard is already false.
  void dismissAddCardBottomSheet() {
    state = state.copyWith(
      showAddCardBottomSheet: false,
      // isAddCard: false, // Don't reset - causes race condition with Stripe callback
    );
  }

  /// Update selected gateway for add card
  void updateSelectedGatewayForAddCard(PaymentGateway gateway) {
    state = state.copyWith(
      paymentGatewayToAddCard: gateway,
      selectedPaymentType: gateway.type,
      paymentManager: _getPaymentManager(gateway.type),
    );
  }

  /// Update card details for add card
  void updateCardDetails(CardDetails cardDetails) {
    state = state.copyWith(selectedCardDetails: cardDetails);
  }

  /// Update permission dialog state
  void updatePermissionDialog(bool isGranted) {
    state = state.copyWith(showPermissionDialog: isGranted);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Show snackbar message (matches Kotlin showSnackBar)
  void showSnackBar(String message, {bool isError = false}) {
    state = state.copyWith(
      snackBarMessage: message,
      isSnackBarError: isError,
    );
  }

  /// Clear snackbar message
  void clearSnackBar() {
    state = state.copyWith(clearSnackBar: true);
  }

  // ==================== Screen Init Events ====================
  // These methods match Kotlin PaymentUIEvent handlers

  /// Handle FromSubscriptionChange event - matches Kotlin
  void setFromSubscription(bool isFromSubscription) {
    state = state.copyWith(isFromSubscription: isFromSubscription);
  }

  /// Handle CorporateBooking event - matches Kotlin
  void setCorporateBooking(bool isCorporateBooking) {
    state = state.copyWith(isCorporateBooking: isCorporateBooking);
  }

  /// Handle FromFeedBack event - matches Kotlin
  void setFromFeedBack(bool isFromFeedBack) {
    state = state.copyWith(isFromFeedBack: isFromFeedBack);
  }

  /// Handle FromCurrentRide event - matches Kotlin
  void setFromCurrentRide(bool isFromCurrentRide) {
    state = state.copyWith(isFromCurrentBooking: isFromCurrentRide);
  }

  /// Handle IsComeFromBooking event - matches Kotlin
  void setIsComeFromBooking(
    bool isComeFromBooking,
    VehicleTypePaymentSetting? vehicleTypePaymentSetting,
  ) {
    if (!isComeFromBooking) {
      state = state.copyWith(
        isComeFromBooking: isComeFromBooking,
        vehicleTypePaymentSetting: vehicleTypePaymentSetting,
      );
      return;
    }

    // Full port of native's PaymentUIEvent.IsComeFromBooking: narrow the
    // add-card gateways to the ones this vehicle accepts, recompute the flags,
    // then reload the cards. Flutter only set the flags, so the cards request
    // still went out with the pre-booking gateway list (or none at all) and the
    // saved card never came back.
    final vehicleGateways = vehicleTypePaymentSetting?.paymentGateways;
    final gatewaysToAddCard = <PaymentGateway>[];

    for (final raw in vehicleGateways ?? const <String?>[]) {
      final type = int.tryParse(raw?.toString() ?? '');
      if (type == PaymentGatewayType.stripe.value ||
          type == PaymentGatewayType.paystack.value) {
        gatewaysToAddCard.add(
          PaymentGateway(
            type: type,
            name: PaymentGatewayType.fromValue(type)?.getName() ?? '',
          ),
        );
      }
    }

    state = state.copyWith(
      isComeFromBooking: isComeFromBooking,
      vehicleTypePaymentSetting: vehicleTypePaymentSetting,
      isCashAvailable: vehicleTypePaymentSetting?.isCash == true,
      paymentGatewayList: gatewaysToAddCard,
      showAddCard: showAddCard(vehicleTypePaymentSetting) &&
          gatewaysToAddCard.isNotEmpty,
      showAddWalletAmount: showAddCard(vehicleTypePaymentSetting),
    );

    if (state.isCorporateBooking) {
      getCorporatePaymentGateways();
    } else {
      getCards();
    }
  }

  /// Handle SetMyBookingPaymentSetting event - matches Kotlin
  void setMyBookingPaymentSetting(BookingPaymentSetting? myBookingPaymentSetting) {
    state = state.copyWith(myBookingPaymentSetting: myBookingPaymentSetting);
  }

  /// Handle TotalAmount event - matches Kotlin
  void setTotalAmount(double totalAmount) {
    state = state.copyWith(totalAmount: totalAmount);
  }

  /// Handle IsPreBookingPayment event - matches Kotlin
  void setIsPreBookingPayment(bool isPreBookingPayment) {
    state = state.copyWith(isPreBookingPayment: isPreBookingPayment);
  }

  /// Handle PaymentMethodChange event - matches Kotlin
  /// Called when user selects a card from the payment methods list
  void onPaymentMethodChange(CardResponse? selectedPaymentMethod) {
    // Skip if same card is already selected
    if (state.selectedPaymentMethod?.id == selectedPaymentMethod?.id) {
      // If from booking flow, navigate back even if same card
      if (state.isComeFromBooking) {
        state = state.copyWith(isNavigateToBack: true);
      }
      return;
    }

    // Update selected payment method
    // If from booking/feedback/currentBooking flow, also trigger navigate back
    if (!state.isComeFromBooking &&
        !state.isFromFeedBack &&
        !state.isFromCurrentBooking) {
      state = state.copyWith(selectedPaymentMethod: selectedPaymentMethod);
    } else {
      state = state.copyWith(
        selectedPaymentMethod: selectedPaymentMethod,
        isNavigateToBack: true,
      );
    }

    // Call selectCard API to save selection on server
    selectCard();
  }

  /// Handle SelectedPaymentMethod event - matches Kotlin
  /// Used for initial setting (not user selection)
  void setSelectedPaymentMethod(CardResponse? selectedPaymentMethod) {
    // Only set if currently null (matches Kotlin SelectedPaymentMethod event)
    if (state.selectedPaymentMethod == null) {
      state = state.copyWith(selectedPaymentMethod: selectedPaymentMethod);
    }
  }

  /// Handle SelectedPaymentGateway event - matches Kotlin
  void setSelectedPaymentGateway(int? selectedPaymentGateway) {
    if (selectedPaymentGateway != null) {
      state = state.copyWith(
        selectedPaymentType: selectedPaymentGateway,
        paymentManager: _getPaymentManager(selectedPaymentGateway),
      );
    }
  }

  /// Initialize screen with navigation params - call from screen initState
  void initWithParams({
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
  }) {
    // Fire all init events in sequence - matches Kotlin LaunchedEffect behavior
    setFromSubscription(isFromSubscription);
    setCorporateBooking(isCorporateBooking);
    setFromFeedBack(isFromFeedBack);
    setFromCurrentRide(isFromCurrentBooking);
    setIsComeFromBooking(isComeFromBooking, vehicleTypePaymentSetting);
    setMyBookingPaymentSetting(myBookingPaymentSetting);
    setTotalAmount(totalAmount);
    setIsPreBookingPayment(isPreBookingPayment);
    setSelectedPaymentMethod(selectedPaymentMethod ?? selectedCard);
    setSelectedPaymentGateway(selectedPaymentGateway);
  }

  /// Listen for socket event to update wallet credit - matches Kotlin socketForPaymentWallet
  void socketForPaymentWallet() {
    _socketManager.listenEvent(
      SocketConstants.eventUpdateCredit,
      (data) {
        debugPrint('💳 PaymentViewModel - Socket UPDATE_CREDIT received');
        getEntityDetail();
      },
    );
  }

  /// Stop listening to socket events
  void disposeSocket() {
    _socketManager.offEvent(SocketConstants.eventUpdateCredit);
  }

  @override
  void dispose() {
    disposeSocket();
    super.dispose();
  }
}

/// Provider for PaymentViewModel
final paymentViewModelProvider =
    StateNotifierProvider.autoDispose<PaymentViewModel, PaymentState>((ref) {
  final appRepository = ref.watch(appRepositoryProvider);
  final sharedPref = ref.watch(sharedPreferenceManagerProvider).valueOrNull;
  final socketManager = ref.watch(socketManagerProvider);
  return PaymentViewModel(appRepository, sharedPref, socketManager);
});
