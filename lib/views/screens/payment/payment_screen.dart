import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/localization/string_constants.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../models/responses/booking/booking_detail_response.dart';
import '../../../models/responses/booking/get_vehicle_type_response.dart';
import '../../../models/responses/payment/card_response.dart';
import '../../../models/responses/payment/payment_webview_response.dart';
import '../../../core/theme/app_theme.dart';
import '../../../viewmodels/payment_viewmodel.dart';
import '../../../views/widgets/app_button.dart';
import '../../../views/widgets/app_text.dart';
import '../../../views/widgets/app_toolbar.dart';
import '../../../views/widgets/app_scaffold.dart';
import '../../bottomsheets/add_card_bottom_sheet.dart';
import '../../bottomsheets/add_wallet_amount_bottom_sheet.dart';
import '../../bottomsheets/country_phone_code_bottom_sheet.dart';
import '../../bottomsheets/delete_card_bottom_sheet.dart';
import '../../bottomsheets/gateway_selection_bottom_sheet.dart';
import '../../bottomsheets/transfer_money_bottom_sheet.dart';
import '../../../core/router/app_navigation.dart';
import '../../item/card_item.dart';
import '../../widgets/app_text_field.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  /// Whether navigating from booking flow
  final bool isComeFromBooking;

  /// Vehicle type payment settings (from booking)
  final VehicleTypePaymentSetting? vehicleTypePaymentSetting;

  /// Booking payment settings (from current ride/feedback)
  final BookingPaymentSetting? myBookingPaymentSetting;

  /// Selected payment gateway type
  final int? selectedPaymentGateway;

  /// Selected card
  final CardResponse? selectedCard;

  /// Total amount for payment
  final double totalAmount;

  /// Whether corporate booking
  final bool isCorporateBooking;

  /// Selected payment method
  final CardResponse? selectedPaymentMethod;

  /// Whether this is pre-booking payment
  final bool isPreBookingPayment;

  /// Whether from current booking
  final bool isFromCurrentBooking;

  /// Whether from feedback screen
  final bool isFromFeedBack;

  /// Whether from subscription screen
  final bool isFromSubscription;

  const PaymentScreen({
    super.key,
    this.isComeFromBooking = false,
    this.vehicleTypePaymentSetting,
    this.myBookingPaymentSetting,
    this.selectedPaymentGateway,
    this.selectedCard,
    this.totalAmount = 0.0,
    this.isCorporateBooking = false,
    this.selectedPaymentMethod,
    this.isPreBookingPayment = false,
    this.isFromCurrentBooking = false,
    this.isFromFeedBack = false,
    this.isFromSubscription = false,
  });

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen>
    with WidgetsBindingObserver {
  // Track which bottom sheets are currently showing to prevent duplicates
  bool _isDeleteCardSheetShowing = false;
  bool _isAddWalletAmountSheetShowing = false;
  bool _isTransferMoneySheetShowing = false;
  bool _isCountryPhoneCodeSheetShowing = false;
  bool _isAddCardSheetShowing = false;
  bool _isGatewaySheetShowing = false;
  bool _isRedeemPointsSheetShowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Fire init events with widget params after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(paymentViewModelProvider.notifier).initWithParams(
            isComeFromBooking: widget.isComeFromBooking,
            vehicleTypePaymentSetting: widget.vehicleTypePaymentSetting,
            myBookingPaymentSetting: widget.myBookingPaymentSetting,
            selectedPaymentGateway: widget.selectedPaymentGateway,
            selectedCard: widget.selectedCard,
            totalAmount: widget.totalAmount,
            isCorporateBooking: widget.isCorporateBooking,
            selectedPaymentMethod: widget.selectedPaymentMethod,
            isPreBookingPayment: widget.isPreBookingPayment,
            isFromCurrentBooking: widget.isFromCurrentBooking,
            isFromFeedBack: widget.isFromFeedBack,
            isFromSubscription: widget.isFromSubscription,
          );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Matches Kotlin: ON_RESUME -> socketForPaymentWallet() + setTransferButton()
      ref.read(paymentViewModelProvider.notifier).socketForPaymentWallet();
      ref.read(paymentViewModelProvider.notifier).setTransferButton();
    }
  }

  void _showDeleteCardBottomSheet() {
    if (_isDeleteCardSheetShowing) return;
    _isDeleteCardSheetShowing = true;

    final state = ref.read(paymentViewModelProvider);
    final viewModel = ref.read(paymentViewModelProvider.notifier);

    DeleteCardBottomSheet.show(
      context,
      cardName: state.selectedCardForDelete?.cardName ??
          state.selectedCardForDelete?.lastFour,
      isLoading: state.isLoading,
      onCancel: () {
        viewModel.cancelDeleteCardDialog();
      },
      onConfirm: () {
        viewModel.confirmDeleteCard();
      },
    ).then((_) {
      _isDeleteCardSheetShowing = false;
      viewModel.cancelDeleteCardDialog();
    });
  }

  void _showAddWalletAmountBottomSheet() {
    if (_isAddWalletAmountSheetShowing) return;
    _isAddWalletAmountSheetShowing = true;

    final state = ref.read(paymentViewModelProvider);
    final viewModel = ref.read(paymentViewModelProvider.notifier);

    AddWalletAmountBottomSheet.show(
      context,
      cardsList: state.walletCardsList,
      selectedCard: state.selectedCardsForAddPayment,
      isLoading: state.isLoading,
      onAmountChanged: (amount) {
        final parsedAmount = double.tryParse(amount) ?? 0;
        viewModel.updateWalletAmount(parsedAmount);
      },
      onCardSelected: (card) {
        viewModel.updateSelectedCardForPayment(card);
      },
      onSubmit: () {
        viewModel.paymentIntentCreate();
      },
      onCancel: () {
        context.goBack();
      },
    ).then((_) {
      _isAddWalletAmountSheetShowing = false;
      viewModel.dismissAddWalletAmountBottomSheet();
    });
  }

  void _showTransferMoneyBottomSheet() {
    if (_isTransferMoneySheetShowing) return;
    _isTransferMoneySheetShowing = true;

    final viewModel = ref.read(paymentViewModelProvider.notifier);

    // Use showModalBottomSheet with Consumer to react to state changes
    // This matches Kotlin's reactive pattern where bottom sheet content
    // updates when ViewModel state changes
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.colorBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimens.padding),
        ),
      ),
      builder: (_) => Consumer(
        builder: (context, ref, _) {
          final state = ref.watch(paymentViewModelProvider);
          return TransferMoneyBottomSheet(
            userMenuList: state.userMenuList,
            selectedUserMenu: state.selectedUserMenu,
            countryPhoneCode: state.countryPhoneCode,
            selectedUser: state.selectedUser,
            isLoading: state.isLoading,
            isShowSendMoneyButton: state.isShowSendMoneyButton,
            isShowNoDataFound: state.isShowNoDataFound,
            formattedWalletAmount: state.formattedWalletAmount,
            onUserMenuSelected: (menu) {
              viewModel.updateSelectedUserMenu(menu);
            },
            onCountryCodeTap: () {
              viewModel.toggleCountryPhoneCodeBottomSheet();
            },
            onPhoneNumberChanged: (phone) {
              viewModel.updatePhoneNumber(phone);
            },
            onAmountChanged: (amount) {
              viewModel.updateAmount(amount);
            },
            onSearchUser: () {
              viewModel.onSearchPhoneNumber();
            },
            onSendMoney: () {
              viewModel.onTransferMoneyClick();
            },
          );
        },
      ),
    ).then((_) {
      _isTransferMoneySheetShowing = false;
      viewModel.dismissTransferMoneyBottomSheet();
    });
  }

  void _showCountryPhoneCodeBottomSheet() {
    if (_isCountryPhoneCodeSheetShowing) return;
    _isCountryPhoneCodeSheetShowing = true;

    final state = ref.read(paymentViewModelProvider);
    final viewModel = ref.read(paymentViewModelProvider.notifier);

    CountryPhoneCodeBottomSheet.show(
      context,
      phoneCodeList: state.multiplePhoneCodeCountryList,
      selectedPhoneCode: state.countryPhoneCode,
      onPhoneCodeSelected: (country) {
        viewModel.updateCountryPhoneCode(country);
      },
    ).then((_) {
      _isCountryPhoneCodeSheetShowing = false;
      viewModel.dismissCountryPhoneCodeBottomSheet();
    });
  }

  void _showAddCardBottomSheet() {
    if (_isAddCardSheetShowing) return;
    _isAddCardSheetShowing = true;

    final state = ref.read(paymentViewModelProvider);
    final viewModel = ref.read(paymentViewModelProvider.notifier);

    AddCardBottomSheet.show(
      context,
      gatewayList: state.paymentGatewayList,
      selectedGateway: state.paymentGatewayToAddCard,
      isLoading: state.isAddCardLoading,
      onGatewaySelected: (gateway) {
        viewModel.updateSelectedGatewayForAddCard(gateway);
      },
      onCardDetailsChanged: (cardDetails) {
        viewModel.updateCardDetails(cardDetails);
      },
      onSubmit: () {
        viewModel.addCardIntent();
      },
      onCancel: () {
        context.goBack();
      },
    ).then((_) {
      _isAddCardSheetShowing = false;
      viewModel.dismissAddCardBottomSheet();
    });
  }

  void _showGatewaySelectionBottomSheet() {
    if (_isGatewaySheetShowing) return;
    _isGatewaySheetShowing = true;

    final state = ref.read(paymentViewModelProvider);

    GatewaySelectionBottomSheet.show(
      context,
      gatewayList: state.paymentGatewayList,
      selectedGateway: state.paymentGatewayToAddCard,
      onGatewaySelected: (gateway) {
        // Update selected gateway
      },
    ).then((_) {
      _isGatewaySheetShowing = false;
    });
  }

  void _showRedeemPointsBottomSheet() {
    if (_isRedeemPointsSheetShowing) return;
    _isRedeemPointsSheetShowing = true;

    final viewModel = ref.read(paymentViewModelProvider.notifier);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.colorBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimens.padding),
        ),
      ),
      builder: (_) => Consumer(
        builder: (context, ref, _) {
          final state = ref.watch(paymentViewModelProvider);
          final colors = context.colors;
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(AppDimens.padding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.title(
                      getString(appStr.headingRedeemPoints, 'heading_redeem_points'),
                      fontWeight: FontWeight.w600,
                    ),
                    const SizedBox(height: AppDimens.paddingXL),
                    AppTextField(
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (value) {
                        viewModel.updateRedeemPoint(value);
                      },
                      hintText: getString(appStr.hintEnterPoints, 'hint_enter_points'),
                    ),
                    const SizedBox(height: AppDimens.paddingS),
                    AppText.caption(
                      getString(appStr.descriptionEquivalent, 'description_equivalent').replacePlaceholders({
                        StringConstant.value: state.convertedRedeemPointPrice,
                      }),
                      color: colors.colorText,
                    ),
                    const SizedBox(height: AppDimens.paddingS),
                    AppText.caption(
                      getString(appStr.descriptionAvailablePointsValue, 'description_available_points_value').replacePlaceholders({
                        StringConstant.value: (state.totalRedeemPoints ?? 0).toInt().toString(),
                      }),
                      color: colors.colorText,
                    ),
                    const SizedBox(height: AppDimens.paddingXL),
                    AppFilledButton(
                      text: getString(appStr.buttonRedeem, 'button_redeem'),
                      isLoading: state.isLoading,
                      onPressed: viewModel.withDrawRedeemPoints,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ).then((_) {
      _isRedeemPointsSheetShowing = false;
      viewModel.dismissRedeemPointBottomSheet();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paymentViewModelProvider);
    final viewModel = ref.read(paymentViewModelProvider.notifier);

    // Listen for bottom sheet state changes
    ref.listen<PaymentState>(paymentViewModelProvider, (previous, next) {
      // Delete card bottom sheet
      if (next.showDeleteCardBottomSheet &&
          !(previous?.showDeleteCardBottomSheet ?? false)) {
        _showDeleteCardBottomSheet();
      }

      // Add wallet amount bottom sheet
      if (next.showAddWalletAmountBottomSheet &&
          !(previous?.showAddWalletAmountBottomSheet ?? false)) {
        _showAddWalletAmountBottomSheet();
      }

      // Transfer money bottom sheet
      if (next.showTransferMoneyBottomSheet &&
          !(previous?.showTransferMoneyBottomSheet ?? false)) {
        _showTransferMoneyBottomSheet();
      }

      // Country phone code bottom sheet
      if (next.showCountryPhoneCodeBottomSheet &&
          !(previous?.showCountryPhoneCodeBottomSheet ?? false)) {
        _showCountryPhoneCodeBottomSheet();
      }

      // Add card bottom sheet
      if (next.showAddCardBottomSheet &&
          !(previous?.showAddCardBottomSheet ?? false)) {
        _showAddCardBottomSheet();
      }

      // Gateway selection bottom sheet
      if (next.showGatewayBottomSheet &&
          !(previous?.showGatewayBottomSheet ?? false)) {
        _showGatewaySelectionBottomSheet();
      }

      // Redeem points bottom sheet
      if (next.showRedeemPointBottomSheet &&
          !(previous?.showRedeemPointBottomSheet ?? false)) {
        _showRedeemPointsBottomSheet();
      }

      // Close redeem points bottom sheet when state changes to false
      if (!next.showRedeemPointBottomSheet &&
          (previous?.showRedeemPointBottomSheet ?? false) &&
          _isRedeemPointsSheetShowing) {
        context.goBack();
        _isRedeemPointsSheetShowing = false;
      }

      // Close add card bottom sheet when state changes to false
      if (!next.showAddCardBottomSheet &&
          (previous?.showAddCardBottomSheet ?? false) &&
          _isAddCardSheetShowing) {
        context.goBack();
        _isAddCardSheetShowing = false;
      }

      // Close add wallet amount bottom sheet when state changes to false
      if (!next.showAddWalletAmountBottomSheet &&
          (previous?.showAddWalletAmountBottomSheet ?? false) &&
          _isAddWalletAmountSheetShowing) {
        context.goBack();
        _isAddWalletAmountSheetShowing = false;
      }

      // Close transfer money bottom sheet when state changes to false
      if (!next.showTransferMoneyBottomSheet &&
          (previous?.showTransferMoneyBottomSheet ?? false) &&
          _isTransferMoneySheetShowing) {
        context.goBack();
        _isTransferMoneySheetShowing = false;
      }

      // Navigate to WebView screen
      if (next.isNavigateToWebView != (previous?.isNavigateToWebView ?? false) &&
          next.navigateURL != null) {
        debugPrint('💳 PaymentScreen: Navigating to WebView');
        viewModel.resetNavigationState();
        context.navigateToWebView(
          webViewData: next.navigateURL,
          onPaymentData: (message) {
            debugPrint('💳 PaymentScreen: Payment callback received - $message');
            context.goBack();
            // Parse JSON response
            final paymentResponse = PaymentWebViewResponse.fromJsonString(message);
            final success = paymentResponse?.success ?? false;
            final responseMessage = paymentResponse?.message;
            // Show snackbar with response message
            if (responseMessage != null && responseMessage.isNotEmpty) {
              viewModel.showSnackBar(responseMessage, isError: !success);
            }
            viewModel.getEntityDetail();
            viewModel.getCards();
          },
        );
      }

      // Navigate back (for subscription flow)
      if (next.isNavigateToBack && !(previous?.isNavigateToBack ?? false)) {
        context.goBack(next.selectedPaymentMethod);
      }

      // Show snackbar (unified approach like Kotlin)
      if (next.snackBarMessage != null &&
          next.snackBarMessage!.isNotEmpty &&
          next.snackBarMessage != previous?.snackBarMessage) {
        if (next.isSnackBarError) {
          context.showErrorSnackBar(next.snackBarMessage!);
        } else {
          context.showSnackBar(next.snackBarMessage!);
        }
        viewModel.clearSnackBar();
      }
    });

    // Adding and deleting a card are round trips with nothing on screen to show
    // for them — the delete sheet closes on confirm, so the user was left
    // looking at an unchanged list wondering whether the tap registered.
    final isCardWorkInProgress =
        state.isAddCardLoading || state.isDeleteCardLoading;

    return AppScaffold(
      body: Stack(
        children: [
          SafeArea(
        child: Column(
          children: [
            // App bar
            AppToolbar(
              title: getString(appStr.headingPayments, 'heading_payments'),
              showBackButton: true,
            ),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Wallet Details Section (only show when not from booking flow)
                    if (state.isWalletVisible)
                      _WalletDetailsSection(
                        formattedAmount: state.formattedWalletAmount ?? '0.00',
                        isShowTransferButton: state.isShowTransferMoneyButton,
                        isDisableTransferButton:
                            state.isDisableTransferMoneyButton,
                        onTap: () {
                          context.navigateToWalletHistory();
                        },
                        onTransferTap: () {
                          viewModel.toggleTransferMoneyBottomSheet();
                        },
                        onAddTap: () {
                          viewModel.toggleAddWalletAmountBottomSheet();
                        },
                      ),

                    // Redeem Points Section (only show when not from booking and has points)
                    if (!state.isComeFromBooking &&
                        !state.isFromCurrentBooking &&
                        !state.isFromFeedBack &&
                        state.isShowRedeemPoints &&
                        (state.totalRedeemPoints ?? 0) > 0)
                      _RedeemPointsSection(
                        totalPoints: state.totalRedeemPoints ?? 0,
                        onRedeemTap: () {
                          viewModel.toggleRedeemPointBottomSheet();
                        },
                      ),

                    // Payment Methods Section
                    //
                    // Also render when the gateway supports cards but none are
                    // saved yet — the "Add card" row lives inside this section,
                    // so gating purely on having cards meant a new user could
                    // never add their first one. Native gates the same way:
                    // `isCardAndBankVisible() || paymentCardsList().isNotEmpty()`
                    if (state.isCardAndBankVisible ||
                        state.cardsList.isNotEmpty ||
                        state.cards.isNotEmpty)
                      _PaymentMethodsSection(
                        cards: state.cards,
                        cardsList: state.cardsList,
                        selectedCard: state.selectedPaymentMethod,
                        isShowDeleteCard: state.isShowDeleteCard,
                        isComeFromBooking: state.isComeFromBooking,
                        isFromCurrentBooking: state.isFromCurrentBooking,
                        isFromFeedBack: state.isFromFeedBack,
                        showAddCard: state.showAddCard,
                        onCardSelected: (card) {
                          viewModel.onPaymentMethodChange(card);
                        },
                        onCardDelete: (card) {
                          viewModel.showDeleteCardDialog(card);
                        },
                        onAddCardTap: () {
                          viewModel.onAddCardClick();
                        },
                      ),
                  ],
                ),
              ),
            ),
            ],
          ),
          ),
          if (isCardWorkInProgress)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x66000000),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}

/// Wallet details section widget
class _WalletDetailsSection extends StatelessWidget {
  final String formattedAmount;
  final bool isShowTransferButton;
  final bool isDisableTransferButton;
  final VoidCallback? onTap;
  final VoidCallback? onTransferTap;
  final VoidCallback? onAddTap;

  const _WalletDetailsSection({
    required this.formattedAmount,
    this.isShowTransferButton = false,
    this.isDisableTransferButton = false,
    this.onTap,
    this.onTransferTap,
    this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      margin: const EdgeInsets.all(AppDimens.padding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
        boxShadow: [
          BoxShadow(
            color: colors.colorText.withValues(alpha: 0.08),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(AppDimens.padding),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
          color: colors.colorBackground, // base dark color
          gradient: LinearGradient(
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
            colors: [
              colors.colorText.withValues(alpha: 0.10), // light at right edge
              colors.colorText.withValues(alpha: 0.040), // soft mid light
              colors.colorText.withValues(alpha: 0.001),// VERY subtle light at left
            ],
            stops: const [0.0, 0.45, 1.0],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Wallet info row
            GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText.body(
                          getString(appStr.descriptionWallet, 'description_wallet'),
                          color: colors.colorText,
                          fontWeight: FontWeight.w500,
                        ),
                        const SizedBox(height: AppDimens.paddingXS),
                        AppText.heading(
                          formattedAmount,
                          color: colors.colorText,
                          fontWeight: FontWeight.w700,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: colors.colorText,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimens.padding),

            // Action buttons
            Row(
              children: [
                // Transfer button
                if (isShowTransferButton)
                  Expanded(
                    flex: 2,
                    child: AppFilledButton(
                      text: getString(appStr.buttonTransferMoney, 'button_transfer_money'),
                      icon: Icons.swap_horiz,
                      enabled: !isDisableTransferButton,
                      onPressed: onTransferTap,
                      borderRadius: 50,
                      height: 40,
                    ),
                  ),
                if (isShowTransferButton) const SizedBox(width: AppDimens.paddingM),
                // Add button
                Expanded(
                  child: AppFilledButton(
                    text: getString(appStr.buttonAdd, 'button_add'),
                    icon: Icons.add,
                    onPressed: onAddTap,
                    borderRadius: 50,
                    height: 40,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Redeem points section widget
class _RedeemPointsSection extends StatelessWidget {
  final double totalPoints;
  final VoidCallback? onRedeemTap;

  const _RedeemPointsSection({
    required this.totalPoints,
    this.onRedeemTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimens.padding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
        boxShadow: [
          BoxShadow(
            color: colors.colorText.withValues(alpha: 0.08),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(AppDimens.padding),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
          color: colors.colorBackground,
          gradient: LinearGradient(
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
            colors: [
              colors.colorText.withValues(alpha: 0.10),
              colors.colorText.withValues(alpha: 0.040),
              colors.colorText.withValues(alpha: 0.001),
            ],
            stops: const [0.0, 0.45, 1.0],
          ),
        ),
        child: InkWell(
          onTap: onRedeemTap,
          borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
          child: Row(
            children: [
              Icon(
                Icons.stars,
                color: colors.colorPrimary,
                size: AppDimens.iconSize,
              ),
              const SizedBox(width: AppDimens.paddingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.body(
                      getString(appStr.headingRedeemPoints, 'heading_redeem_points'),
                      fontWeight: FontWeight.w600,
                    ),
                    const SizedBox(height: AppDimens.paddingXS),
                    AppText.caption(
                      getString(appStr.descriptionRewardPointsValue, 'description_reward_points_value')
                          .replacePlaceholders({StringConstant.redeemPoints: totalPoints.toInt()}),
                      color: colors.colorText,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: colors.colorText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Payment methods section widget
class _PaymentMethodsSection extends StatelessWidget {
  final List<CardResponse> cards;
  final List<CardResponse> cardsList;
  final CardResponse? selectedCard;
  final bool isShowDeleteCard;
  final bool isComeFromBooking;
  final bool isFromCurrentBooking;
  final bool isFromFeedBack;
  final bool showAddCard;
  final ValueChanged<CardResponse>? onCardSelected;
  final ValueChanged<CardResponse>? onCardDelete;
  final VoidCallback? onAddCardTap;

  const _PaymentMethodsSection({
    required this.cards,
    required this.cardsList,
    this.selectedCard,
    this.isShowDeleteCard = true,
    this.isComeFromBooking = false,
    this.isFromCurrentBooking = false,
    this.isFromFeedBack = false,
    this.showAddCard = false,
    this.onCardSelected,
    this.onCardDelete,
    this.onAddCardTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // Combine cards from both lists, preferring saved cards
    final allCards = <CardResponse>[...cardsList];
    for (final card in cards) {
      if (!allCards.any((c) => c.id == card.id)) {
        allCards.add(card);
      }
    }

    return Container(
      margin: const EdgeInsets.all(AppDimens.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          AppText.body(
            getString(appStr.subHeadingPaymentMethods, 'sub_heading_payment_methods'),
            fontWeight: FontWeight.w600,
          ),
          const SizedBox(height: AppDimens.paddingM),

          // Card list
          ...allCards.asMap().entries.map((entry) {
            final index = entry.key;
            final card = entry.value;
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < allCards.length - 1 ? AppDimens.paddingS : 0,
              ),
              child: CardItem(
                card: card,
                isSelected: selectedCard?.id == card.id,
                showDeleteButton: isShowDeleteCard &&
                    !isComeFromBooking &&
                    !isFromCurrentBooking &&
                    !isFromFeedBack &&
                    card.paymentGatewayType != null &&
                    card.paymentGatewayType != 0 && // Not cash
                    card.paymentGatewayType != 1, // Not wallet
                onTap: () => onCardSelected?.call(card),
                onDelete: () => onCardDelete?.call(card),
              ),
            );
          }),

          // Add card row (like in Kotlin - at bottom of list).
          //
          // Native gates this on `showAddCard` alone (PaymentMethodList.kt),
          // which already accounts for the gateway and corporate checks. The
          // extra booking-flow conditions here hid the row for anyone who
          // reached Payments from a booking, leaving no way to add a first card.
          if (showAddCard)
            Padding(
              padding: EdgeInsets.only(
                top: allCards.isNotEmpty ? AppDimens.paddingS : 0,
              ),
              child: InkWell(
                onTap: onAddCardTap,
                borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.paddingM,
                    vertical: AppDimens.paddingM,
                  ),
                  decoration: BoxDecoration(
                    color: colors.colorBackgroundGray,
                    borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.add_circle_outline,
                        color: colors.colorPrimary,
                        size: AppDimens.iconSize,
                      ),
                      const SizedBox(width: AppDimens.padding),
                      AppText.body(
                        getString(appStr.buttonAddNewCard, 'button_add_new_card'),
                        color: colors.colorText,
                        fontWeight: FontWeight.w500,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

