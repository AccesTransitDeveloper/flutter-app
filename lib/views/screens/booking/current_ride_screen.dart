import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/map/interface/map_interface.dart';
import '../../../core/map/widgets/map_host.dart';
import '../../../core/map/providers/map_provider.dart';
import '../../../core/router/app_navigation.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/common_utils.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../data/api/server_config.dart';
import '../../../models/chat/chat_config.dart';
import '../../../models/responses/booking/booking_detail_response.dart';
import '../../../viewmodels/current_ride_viewmodel.dart';
import '../../../viewmodels/main_viewmodel.dart';
import '../../bottomsheets/call_options_bottom_sheet.dart';
import '../../bottomsheets/cancel_trip_bottom_sheet.dart';
import '../../../core/utils/invoice_util.dart';
import '../../../models/responses/booking/get_vehicle_type_response.dart';
import '../../bottomsheets/fare_estimation_bottom_sheet.dart';
import '../../bottomsheets/no_provider_found_bottom_sheet.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_draggable_scrollable_sheet.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_text.dart';

/// Screen for displaying the current active ride
class CurrentRideScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const CurrentRideScreen({super.key, required this.bookingId});

  @override
  ConsumerState<CurrentRideScreen> createState() => _CurrentRideScreenState();
}

class _CurrentRideScreenState extends ConsumerState<CurrentRideScreen>
    with WidgetsBindingObserver {
  late final MapInterface _mapManager;
  final AppSheetController _sheetController = AppSheetController();
  CurrentRideParams? _params;


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    debugPrint(
      '🖥️ CurrentRideScreen - initState bookingId: ${widget.bookingId}',
    );
    _mapManager = ref.read(mapManagerProvider)();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Create params once we have access to context for colors
    _params ??= CurrentRideParams(
      bookingId: widget.bookingId,
      mapManager: _mapManager,
      primaryColor: context.colors.colorPrimary.toARGB32(),
      secondaryColor: context.colors.colorSecondary.toARGB32(),
    );

    // The sheet covers roughly the bottom half, and the map fills the whole
    // stack behind it. Without this the camera centres the driver in the middle
    // of the *window*, which is underneath the sheet — the car was simply not
    // on screen. Native does the same via `setPadding(bottom = sheetPeekHeight)`.
    final screenHeight = MediaQuery.of(context).size.height;
    _mapManager.setMapPadding(
      EdgeInsets.only(bottom: screenHeight * 0.5),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _params != null) {
      ref.read(currentRideViewModelProvider(_params!).notifier).refreshBookingDetails();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    debugPrint(
      '🖥️ CurrentRideScreen - dispose bookingId: ${widget.bookingId}',
    );
    _sheetController.dispose();
    _mapManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Wait for params to be initialized
    final params = _params;
    if (params == null) {
      return const AppScaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final colors = context.colors;

    return AppScaffold(
      body: Stack(
        children: [
          // Layer 1: Map (outside Consumer to prevent rebuilds from state changes)
          Positioned.fill(child: MapHost(manager: _mapManager)),

          // Layer 2: Bottom sheet (uses Consumer to only rebuild when state changes)
          Consumer(
            builder: (context, ref, _) {
              final state = ref.watch(currentRideViewModelProvider(params));
              final viewModel = ref.read(currentRideViewModelProvider(params).notifier);

              // Listen for state changes (like payment screen)
              ref.listen<CurrentRideState>(
                currentRideViewModelProvider(params),
                (previous, next) {
                  if (!context.mounted) return;

                  // Navigate to WebView for payment
                  if (next.isNavigateToWebView &&
                      !(previous?.isNavigateToWebView ?? false) &&
                      next.navigateURL != null) {
                    debugPrint('🖥️ CurrentRideScreen - Navigating to WebView for payment');
                    viewModel.resetNavigationFlags();
                    context.navigateToWebView(
                      webViewData: next.navigateURL,
                      onPaymentData: (message) {
                        debugPrint('🖥️ CurrentRideScreen - Payment callback: $message');
                        context.goBack();
                        // Check for success in JSON format ("success":true) or URL format (success=true)
                        final success = message?.contains('"success":true') == true ||
                            message?.contains('success=true') == true;
                        viewModel.handlePaymentWebViewResponse(success, message);
                        viewModel.refreshBookingDetails();
                      },
                    );
                  }

                  // Navigate to feedback screen
                  if (next.isNavigateToFeedback && !(previous?.isNavigateToFeedback ?? false)) {
                    debugPrint('🖥️ CurrentRideScreen - Navigating to feedback');
                    viewModel.resetNavigationFlags();
                    ref.read(mainViewModelProvider.notifier).refreshEntityDetail();
                    context.push(
                      '/feedback/${widget.bookingId}',
                      extra: {'isFromHistory': false},
                    );
                  }

                  // Navigate to home
                  if ((next.isNavigateToHome || next.shouldNavigateToHome) &&
                      !(previous?.isNavigateToHome ?? false) &&
                      !(previous?.shouldNavigateToHome ?? false)) {
                    debugPrint('🖥️ CurrentRideScreen - Navigating to home');
                    ref.read(mainViewModelProvider.notifier).refreshEntityDetail();
                    context.navigateToHome();
                  }

                  // Show no provider found bottom sheet
                  if (next.showNoProviderFoundSheet &&
                      !(previous?.showNoProviderFoundSheet ?? false)) {
                    showNoProviderFoundBottomSheet(
                      context: context,
                      onClose: () {
                        ref.read(mainViewModelProvider.notifier).refreshEntityDetail();
                        // Dismiss any remaining bottom sheets (e.g., cancel trip)
                        // before navigating, since go() doesn't clean up imperative modal routes
                        Navigator.of(context).popUntil((route) => route.isFirst);
                        context.navigateToHome();
                      },
                    );
                  }

                  // Navigate to chat screen
                  if (next.isNavigateToChat &&
                      !(previous?.isNavigateToChat ?? false)) {
                    viewModel.onRedirectToChat();
                    final booking = next.bookingDetail?.booking;
                    if (booking != null) {
                      context.navigateToChat(
                        chatConfig: ChatConfig(
                          chatType: ChatType.CUSTOMER_DRIVER_CHAT.name,
                          chatId: null,
                          referenceId: booking.id,
                          receiverImage: booking.confirmedDriver?.imageUrl,
                          receiverName: booking.confirmedDriver?.name,
                        ),
                      );
                    }
                  }

                  // Show call options bottom sheet
                  if (next.showCallOptionsBottomSheet &&
                      !(previous?.showCallOptionsBottomSheet ?? false)) {
                    viewModel.dismissCallOptionsBottomSheet();
                    CallOptionsBottomSheet.show(
                      context,
                      onCallDriver: () => viewModel.onCallDriverClick(),
                      onCallSupport: () => viewModel.onCallSupportClick(),
                      isDriverCallingLoading: next.isDriverCallingLoading,
                      isSupportCallingLoading: next.isSupportCallingLoading,
                    );
                  }

                  // Show cancel trip bottom sheet (reactive via Consumer)
                  if (next.showCancelTripBottomSheet &&
                      !(previous?.showCancelTripBottomSheet ?? false)) {
                    viewModel.dismissCancelTripBottomSheet();
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: context.colors.colorBackground,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      builder: (_) => Consumer(
                        builder: (context, ref, _) {
                          final cancelState = ref.watch(
                            currentRideViewModelProvider(params),
                          );
                          final cancelViewModel = ref.read(
                            currentRideViewModelProvider(params).notifier,
                          );
                          return CancelTripBottomSheet(
                            reasons: cancelState.cancellationReasonList,
                            cancellationCharge: cancelState.cancellationCharge,
                            isCancelTripLoading: cancelState.isCancelTripLoading,
                            onReasonSelected: (reason) {
                              Navigator.pop(context);
                              cancelViewModel.cancelTrip(reason);
                            },
                            onDismiss: () => Navigator.pop(context),
                          );
                        },
                      ),
                    );
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
                },
              );

              // Collapse sheet when showInvoice is true
              if (state.showInvoice) {
                _sheetController.collapse();
              }

              return AppDraggableScrollableSheet(
                controller: _sheetController,
                maxChildSize: 0.9,
                sheetColor: colors.colorBackground,
                initialState: AppSheetInitialState.collapsed,
                isDraggable: !state.showInvoice,
                collapsedContent: _buildCollapsedContent(colors, state),
                expandedContent: _buildExpandedContent(colors, state),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Build invoice content for the bottom sheet (matches Kotlin InvoiceBottomSheet)
  Widget _buildInvoiceContent(AppColorPalette colors, CurrentRideState state) {
    final booking = state.bookingDetail?.booking;
    final bookingInvoice = booking?.bookingInvoice;
    final isArrivedAtDestination =
        state.bookingStatus == BookingStatus.arrivedAtDestination;
    final isCorporateTrip = booking?.corporateId?.isNotEmpty == true;
    final paymentMode = state.paymentMode ?? bookingInvoice?.paymentMode;
    final paymentGateway = PaymentGatewayType.fromValue(paymentMode);
    final isAdvancePaymentLimit = state.isAdvancePaymentLimit;
    final isPartial = isAdvancePaymentLimit && isArrivedAtDestination;
    final isSubmitInvoiceFailed = state.isSubmitInvoiceFailed;

    // Get showPayByCashButton from state
    final showPayByCashButton = state.showPayByCashButton;

    // Get invoice price - use state.invoicePrice or calculate from booking
    final invoicePrice = state.invoicePrice ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.padding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),

          // Title: Invoice
          AppText.title(
            getString(appStr.headingInvoice, 'heading_invoice'),
            color: colors.colorText,
          ),

          const SizedBox(height: 15),

          // Price row with View Receipt button
          Row(
            children: [
              Expanded(
                child: AppText(
                  invoicePrice,
                  color: colors.colorText,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isArrivedAtDestination)
                AppFilledButton(
                  text: getString(
                    appStr.buttonViewReceipt,
                    'button_view_receipt',
                  ),
                  height: 32,
                  shrinkWrap: true,
                  backgroundColor: colors.colorBackgroundGray,
                  textColor: colors.colorText,
                  onPressed: () {
                    final bookingDetail = state.bookingDetail;
                    if (bookingDetail != null) {
                      context.navigateToReceipt(
                          bookingDetailResponse: bookingDetail);
                    }
                  },
                ),
            ],
          ),

          // "You need to pay above amount" text
          if (!isCorporateTrip) ...[
            const SizedBox(height: 4),
            AppText.body(
              getString(
                appStr.descriptionYouNeedToPayAboveAmount,
                'description_you_need_to_pay_above_amount',
              ),
              color: colors.colorText.withValues(alpha: 0.6),
            ),
          ],

          // Payment Failed section
          if (isSubmitInvoiceFailed) ...[
            const SizedBox(height: 10),
            AppText.body(getString(null, 'error_payment_failed'), color: colors.colorWarning),
            AppText.caption(
              getString(null, 'error_payment_unsuccessful'),
              color: colors.colorText,
            ),
          ],

          // Payment method row (if not corporate)
          if (!isCorporateTrip) ...[
            const SizedBox(height: 10),
            InkWell(
                onTap: (isSubmitInvoiceFailed || isPartial)
                    ? () async {
                        final paymentSetting =
                            state.myBookingPaymentSetting;
                        if (paymentSetting == null) return;
                        final card = await context.navigateToPayment(
                          myBookingPaymentSetting: paymentSetting.copyWith(
                            isPartialPayment: state.isAdvancePaymentLimit,
                          ),
                          isCorporateBooking: isCorporateTrip,
                          selectedPaymentMethod: state.selectedCard,
                          isPreBookingPayment: state.isPreBookingPayment,
                          isFromCurrentBooking: true,
                        );
                        if (card != null && _params != null) {
                          ref
                              .read(currentRideViewModelProvider(_params!)
                                  .notifier)
                              .setCardData(card);
                        }
                      }
                    : null,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: colors.colorBackgroundGray,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: AppText.body(
                          paymentGateway?.getName() ??
                              getString(
                                appStr.descriptionPayment,
                                'description_payment',
                              ),
                          color: colors.colorText,
                          fontWeight: FontWeight.w500,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (paymentGateway != PaymentGatewayType.razorpay)
                        Icon(
                          paymentGateway == PaymentGatewayType.cash
                              ? Icons.payments_outlined
                              : Icons.credit_card,
                          color: colors.colorPrimary,
                          size: 25,
                        ),
                      const SizedBox(width: 16),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 10),
          ],

          const SizedBox(height: 16),

          // Action buttons row
          _buildInvoiceActionButtons(
            colors: colors,
            state: state,
            isArrivedAtDestination: isArrivedAtDestination,
            isCorporateTrip: isCorporateTrip,
            showPayByCashButton: showPayByCashButton,
            isSubmitInvoiceFailed: isSubmitInvoiceFailed,
            onSubmitInvoice: () {
              ref.read(currentRideViewModelProvider(_params!).notifier).submitInvoice();
            },
            onPayBookingPayment: () {
              ref.read(currentRideViewModelProvider(_params!).notifier).payBookingPayment();
            },
            onCancelBooking: () {
              ref.read(currentRideViewModelProvider(_params!).notifier).onCancelTripClick();
            },
          ),

          // The action button ends the sheet, so this only has to clear the
          // floating nav pill — the sheet contributes the bottom safe area
          // itself. 80 left a wide empty band under "Give Rating".
          const SizedBox(height: AppDimens.paddingS),
        ],
      ),
    );
  }

  /// Build action buttons for invoice content (matches Kotlin InvoiceBottomSheet)
  Widget _buildInvoiceActionButtons({
    required AppColorPalette colors,
    required CurrentRideState state,
    required bool isArrivedAtDestination,
    required bool isCorporateTrip,
    required bool showPayByCashButton,
    required bool isSubmitInvoiceFailed,
    required VoidCallback onSubmitInvoice,
    required VoidCallback onPayBookingPayment,
    required VoidCallback onCancelBooking,
  }) {
    final isInvoicePaid = state.isInvoicePaid;
    final isLoading = state.isSubmitInvoiceLoading;

    // Case 1: Invoice is paid and arrived at destination - show Submit Invoice
    if (isInvoicePaid && isArrivedAtDestination) {
      return AppFilledButton(
        text: getString(appStr.buttonSubmitInvoice, 'button_submit_invoice'),
        isLoading: isLoading,
        onPressed: onSubmitInvoice,
      );
    }

    // Case 2: Show pay by cash button
    if (showPayByCashButton) {
      return AppFilledButton(
        text: getString(appStr.buttonPayByCash, 'button_pay_by_cash'),
        isLoading: isLoading,
        onPressed: onSubmitInvoice,
      );
    }

    // Case 3: Default - show Pay/PayAgain and Cancel buttons
    return Row(
      children: [
        if (!isSubmitInvoiceFailed)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 5),
              child: AppFilledButton(
                text: isCorporateTrip
                    ? getString(
                        appStr.buttonSubmitInvoice,
                        'button_submit_invoice',
                      )
                    : getString(appStr.buttonPay, 'button_pay'),
                onPressed: onPayBookingPayment,
              ),
            ),
          )
        else
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 5),
              child: AppOutlinedButton(
                text: getString(appStr.buttonPayAgain, 'button_pay_again'),
                onPressed: onPayBookingPayment,
              ),
            ),
          ),
        if (!isArrivedAtDestination)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 5),
              child: AppOutlinedButton(
                text: getString(
                  appStr.buttonCancelBooking,
                  'button_cancel_booking',
                ),
                onPressed: onCancelBooking,
              ),
            ),
          ),
      ],
    );
  }

  /// Build collapsed content for the bottom sheet
  Widget _buildCollapsedContent(
    AppColorPalette colors,
    CurrentRideState state,
  ) {
    final booking = state.bookingDetail?.booking;
    final driver = booking?.confirmedDriver;
    final vehicleDetail = driver?.vehicleDetail;
    final vehicleType = booking?.vehicleType;
    final showDriverEstimation = state.activeSetting.contains(
      CustomerBookingSettings.showDriverArrivedEstimation,
    );

    if (state.showInvoice) {
      return _buildInvoiceContent(colors, state);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.padding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Driver time estimation (e.g., "Pickup in 3 min")
          if (showDriverEstimation && state.driverTimeEstimation != null) ...[
            AppText.title(
              state.driverTimeEstimation!,
              color: colors.colorText,
              fontWeight: FontWeight.w700,
            ),
            const SizedBox(height: AppDimens.paddingM),
          ],

          // OTP/PIN verification (if available)
          if (state.showOtpVerification &&
              state.verificationCode != null &&
              state.verificationCode!.isNotEmpty) ...[
            _buildPinVerificationRow(colors, state),
            const SizedBox(height: AppDimens.paddingM),
          ],

          // Progress bar when searching for driver (hide when bidding is active — Kotlin: showConnectingToNearbyDriver = false)
          if (state.bookingStatus.value < BookingStatus.accepted.value &&
              !state.isShowBiddingRequest) ...[
            LinearProgressIndicator(color: colors.colorSecondary),
            const SizedBox(height: AppDimens.paddingM),
          ],

          // Ride details box (hide when bidding is active — Kotlin: isShowTripDetails = false)
          if (state.tripStatusText.isNotEmpty &&
              !state.isShowBiddingRequest) ...[
            _buildRideDetailsBox(colors, state, showMoreButton: true),
            const SizedBox(height: AppDimens.paddingM),
          ],

          // Address list when searching for driver or bidding
          if (state.bookingStatus.value < BookingStatus.accepted.value ||
              state.isShowBiddingRequest) ...[
            _buildAddressListCard(
              colors,
              booking,
              canEditAddress: state.canEditAddress,
              isEditAddressLoading: state.isEditAddressLoading,
              onEditDestination: () => _onEditDestination(state),
            ),
            const SizedBox(height: AppDimens.paddingM),
          ],

          // Bidding request list
          if (state.isShowBiddingRequest) ...[
            _buildBiddingRequestSection(colors, state),
            const SizedBox(height: AppDimens.paddingM),
          ],

          // Driver info section (only show if driver is available)
          if (driver != null && driver.name?.isNotEmpty == true)
            _buildDriverInfoSection(
              colors,
              driver,
              vehicleDetail,
              vehicleType,
              state.activeSetting,
            ),

          // Error message
          if (state.error != null) ...[
            const SizedBox(height: AppDimens.padding),
            AppText.body(state.error!, color: colors.colorWarning),
          ],

          // Cancel booking — a real button in the collapsed sheet rather than
          // an entry buried in the 3-dot menu. Native shows it the same way,
          // as a button pinned over the peeking sheet
          // (CurrentRideScreen: `if (isShowCancelButton() && sheetPeekHeight > 0)`).
          // The menu keeps the entry for the expanded sheet, where this row is
          // scrolled away.
          if (state.isShowCancelButton) ...[
            const SizedBox(height: AppDimens.paddingS),
            SizedBox(
              width: double.infinity,
              child: AppOutlinedButton(
                text: getString(
                  appStr.buttonCancelBooking,
                  'button_cancel_booking',
                ),
                borderColor: colors.colorWarning,
                textColor: colors.colorWarning,
                onPressed: () => ref
                    .read(currentRideViewModelProvider(_params!).notifier)
                    .onCancelTripClick(),
              ),
            ),
            // The button already sits at the very bottom of the sheet, so it
            // only needs to clear the floating nav pill — the 24 below is for
            // content that ends higher up.
            const SizedBox(height: AppDimens.paddingS),
          ] else
            // Clearance for the floating bottom nav bar. The sheet already adds
            // the bottom safe area itself, so this only has to clear the pill —
            // 80 left a large empty band between the last card and the nav bar.
            const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Build expanded content for the bottom sheet
  Widget _buildExpandedContent(AppColorPalette colors, CurrentRideState state) {
    final booking = state.bookingDetail?.booking;
    final driver = booking?.confirmedDriver;
    final vehicleDetail = driver?.vehicleDetail;
    final vehicleType = booking?.vehicleType;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.padding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with booking unique ID
          Center(
            child: AppText.title(
              booking?.uniqueId ??
                  getString(appStr.headingRideDetails, 'heading_ride_details'),
              color: colors.colorText,
            ),
          ),
          const SizedBox(height: AppDimens.paddingXL),

          // OTP/PIN verification (if available)
          if (state.showOtpVerification &&
              state.verificationCode != null &&
              state.verificationCode!.isNotEmpty) ...[
            _buildPinVerificationRow(colors, state),
            const SizedBox(height: AppDimens.paddingM),
          ],

          // Ride details box (in expanded: only show more button if cancel is allowed)
          if (state.tripStatusText.isNotEmpty) ...[
            _buildRideDetailsBox(
              colors,
              state,
              showMoreButton: state.isShowCancelButton,
              isExpanded: true,
            ),
            const SizedBox(height: AppDimens.paddingM),
          ],

          // Address list with connecting line (above driver details)
          _buildAddressListCard(
            colors,
            booking,
            canEditAddress: state.canEditAddress,
            isEditAddressLoading: state.isEditAddressLoading,
            onEditDestination: () => _onEditDestination(state),
          ),
          const SizedBox(height: AppDimens.paddingM),

          // Selected Ride section (vehicle type, time, price)
          _buildSelectedRideSection(colors, state),
          const SizedBox(height: AppDimens.paddingM),

          // Selected Payment Option section
          _buildSelectedPaymentSection(colors, booking),
          const SizedBox(height: AppDimens.paddingXL),

          // Driver info section (only show if driver is available)
          if (driver != null && driver.name?.isNotEmpty == true)
            _buildDriverInfoSection(
              colors,
              driver,
              vehicleDetail,
              vehicleType,
              state.activeSetting,
            ),

          // Error message
          if (state.error != null) ...[
            const SizedBox(height: AppDimens.padding),
            AppText.body(state.error!, color: colors.colorWarning),
          ],
        ],
      ),
    );
  }

  /// Handle edit destination tap — navigate to select location and update
  Future<void> _onEditDestination(CurrentRideState state) async {
    final currentDest = state.bookingDetail?.booking?.destinationAddresses?.lastOrNull;
    final pickupCountryCode = state.bookingDetail?.booking?.pickupAddress?.countryCode;
    final newAddress = await context.navigateToSelectLocation(
      initialAddress: currentDest,
      countryCode: pickupCountryCode,
    );
    if (newAddress != null && _params != null) {
      ref
          .read(currentRideViewModelProvider(_params!).notifier)
          .editDestinationAddress(newAddress);
    }
  }

  /// Build address list card with connecting line (similar to plan ride)
  Widget _buildAddressListCard(
    AppColorPalette colors,
    BookingDetails? booking, {
    bool canEditAddress = false,
    bool isEditAddressLoading = false,
    VoidCallback? onEditDestination,
  }) {
    final pickupAddress = booking?.pickupAddress;
    final destinations = booking?.destinationAddresses ?? [];

    // If destinations empty and can edit, show 1 row for "add destination"
    final hasDestinations = destinations.isNotEmpty;
    final totalRows = 1 + (hasDestinations ? destinations.length : (canEditAddress ? 1 : 0));
    final rowHeight = 48.0;
    final totalHeight = totalRows * rowHeight;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.paddingM,
        vertical: AppDimens.paddingS,
      ),
      decoration: BoxDecoration(
        color: colors.colorBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.colorText.withValues(alpha: 0.18),
            blurRadius: 4,
            offset: Offset.zero,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left column: icons with connecting line
          SizedBox(
            width: 24,
            height: totalHeight,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Vertical connecting line
                if (totalRows > 1)
                  Positioned(
                    top: rowHeight / 2,
                    bottom: rowHeight / 2,
                    child: Container(
                      width: 1.5,
                      color: colors.colorPrimary.withValues(alpha: 0.3),
                    ),
                  ),

                // Pickup icon (circle outline)
                Positioned(
                  top: (rowHeight / 2) - 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: colors.colorBackground,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.colorPrimary, width: 2),
                    ),
                  ),
                ),

                // Stop/destination icons
                if (hasDestinations)
                  for (int i = 0; i < destinations.length; i++)
                    Positioned(
                      top: rowHeight + (i * rowHeight) + (rowHeight / 2) - 10,
                      child: i == destinations.length - 1
                          // Final destination - drop off icon
                          ? Image.asset(
                              'assets/images/ic_drop_off.png',
                              width: 20,
                              height: 20,
                              color: colors.colorPrimary,
                              colorBlendMode: BlendMode.srcIn,
                            )
                          // Intermediate stop - numbered square
                          : Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: colors.colorPrimary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Center(
                                child: AppText(
                                  '${i + 1}',
                                  color: colors.colorBackground,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                    ),

                // Empty destination placeholder icon (when no destinations but can edit)
                if (!hasDestinations && canEditAddress)
                  Positioned(
                    top: rowHeight + (rowHeight / 2) - 10,
                    child: Image.asset(
                      'assets/images/ic_drop_off.png',
                      width: 20,
                      height: 20,
                      color: colors.colorPrimary,
                      colorBlendMode: BlendMode.srcIn,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppDimens.paddingM),

          // Right column: address texts
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Pickup row
                SizedBox(
                  height: rowHeight,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: AppText.body(
                      pickupAddress?.address ?? '',
                      color: colors.colorText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),

                // Destination rows
                if (hasDestinations)
                  for (int i = 0; i < destinations.length; i++)
                    GestureDetector(
                      onTap: (canEditAddress && i == destinations.length - 1)
                          ? onEditDestination
                          : null,
                      child: SizedBox(
                        height: rowHeight,
                        child: Row(
                          children: [
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: AppText.body(
                                  destinations[i].address ?? '',
                                  color: colors.colorText,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            if (canEditAddress && i == destinations.length - 1)
                              isEditAddressLoading
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: colors.colorPrimary,
                                      ),
                                    )
                                  : Icon(
                                      Icons.edit_outlined,
                                      size: 18,
                                      color: colors.colorPrimary,
                                    ),
                          ],
                        ),
                      ),
                    ),

                // Empty destination placeholder (when no destinations but can edit)
                if (!hasDestinations && canEditAddress)
                  GestureDetector(
                    onTap: onEditDestination,
                    child: SizedBox(
                      height: rowHeight,
                      child: Row(
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: AppText.body(
                                getString(
                                  null,
                                  'hint_set_your_destination',
                                ),
                                color: colors.colorText.withValues(alpha: 0.5),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          isEditAddressLoading
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colors.colorPrimary,
                                  ),
                                )
                              : Icon(
                                  Icons.add_circle_outline,
                                  size: 18,
                                  color: colors.colorPrimary,
                                ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build selected ride section showing vehicle type, time, and price with fare info
  Widget _buildSelectedRideSection(
    AppColorPalette colors,
    CurrentRideState state,
  ) {
    final booking = state.bookingDetail?.booking;
    final vehicleType = booking?.vehicleType;
    final bookingInvoice = booking?.bookingInvoice;
    final estimated = bookingInvoice?.estimated;
    final citySetting = state.bookingDetail?.citySetting;
    final bookingSettings = citySetting?.bookingSetting ?? [];

    final vehicleName = vehicleType?.name ?? '';
    final vehicleImageUrl = vehicleType?.imageUrl != null
        ? ServerConfig.getFullImageUrl(vehicleType!.imageUrl)
        : null;

    // Ride type title
    final rideType = RideType.fromValue(booking?.bookingType);
    final titleText = switch (rideType) {
      RideType.rental => getString(
          appStr.headingSelectedRentalRide, 'heading_selected_rental_ride'),
      RideType.normal || RideType.sharing => getString(
          appStr.headingSelectedRide, 'heading_selected_ride'),
      _ => getString(appStr.headingSelectedVehicle, 'heading_selected_vehicle'),
    };

    // Schedule badge: "Now" if NOW tag, otherwise bookingTimeStr
    final bookingTags = booking?.bookingTags ?? [];
    final isNow = bookingTags.contains('NOW');
    final bookingTimeStr = booking?.bookingTimeStr ?? '';
    final scheduleBadgeText = isNow
        ? getString(appStr.descriptionNow, 'description_now')
        : bookingTimeStr.isNotEmpty
            ? bookingTimeStr
            : getString(appStr.descriptionSchedule, 'description_schedule');

    // Price display — use bid price if bidding
    final showFareEstimation =
        bookingSettings.contains(BookingSettingConstant.showFareEstimation);
    final currencySign = bookingInvoice?.currencySign ?? '\u20B9';
    final decimalPointValue = bookingInvoice?.decimalPointValue ?? 2;
    final biddingDetail = booking?.biddingDetail;
    double totalPrice;
    if (biddingDetail?.isBidding == true) {
      totalPrice = (biddingDetail?.finalBidPrice ?? 0) > 0
          ? biddingDetail!.finalBidPrice!
          : (biddingDetail?.customerBidPrice ?? estimated?.total ?? 0.0);
    } else {
      totalPrice = estimated?.total ?? 0.0;
    }
    final formattedPrice =
        '$currencySign${totalPrice.toStringAsFixed(decimalPointValue)}';

    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingM),
      decoration: BoxDecoration(
        color: colors.colorBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.colorText.withValues(alpha: 0.18),
            blurRadius: 4,
            offset: Offset.zero,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: ride type title + schedule badge
          Row(
            children: [
              Expanded(
                child: AppText.title(
                  titleText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: colors.colorPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_month,
                      size: 15,
                      color: colors.colorPrimary,
                    ),
                    const SizedBox(width: 8),
                    AppText.caption(
                      scheduleBadgeText,
                      color: colors.colorPrimary,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDimens.paddingM),

          // Vehicle info row: image + name + price
          Row(
            children: [
              // Vehicle image
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 75,
                  height: 50,
                  child: vehicleImageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: vehicleImageUrl,
                          fit: BoxFit.contain,
                          placeholder: (context, url) => Icon(
                            Icons.directions_car,
                            color: colors.colorText.withValues(alpha: 0.5),
                            size: 32,
                          ),
                          errorWidget: (context, url, error) => Icon(
                            Icons.directions_car,
                            color: colors.colorText.withValues(alpha: 0.5),
                            size: 32,
                          ),
                        )
                      : Icon(
                          Icons.directions_car,
                          color: colors.colorText.withValues(alpha: 0.5),
                          size: 32,
                        ),
                ),
              ),
              const SizedBox(width: AppDimens.paddingM),

              // Vehicle name
              Expanded(
                child: AppText.title(
                  vehicleName,
                  fontWeight: FontWeight.w600,
                ),
              ),

              // Price with info button
              if (showFareEstimation)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppText.title(formattedPrice, color: colors.colorText),
                    const SizedBox(width: AppDimens.paddingS),
                    GestureDetector(
                      onTap: () => _showFareEstimation(state),
                      child: Icon(
                        Icons.info_outline,
                        color: colors.colorText.withValues(alpha: 0.6),
                        size: 20,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Rental package info
          if (booking?.packageDetail != null)
            _buildRentalPackageCard(colors, booking!),
        ],
      ),
    );
  }

  /// Show fare estimation bottom sheet
  void _showFareEstimation(CurrentRideState state) {
    final booking = state.bookingDetail?.booking;
    final bookingInvoice = booking?.bookingInvoice;
    final invoiceDetail = bookingInvoice?.estimated;

    if (invoiceDetail == null) return;

    showFareEstimationBottomSheet(
      context: context,
      invoiceDetail: invoiceDetail,
      currencySign: bookingInvoice?.currencySign ?? '\u20B9',
      currencyDirection: bookingInvoice?.setCurrencySign ?? 0,
      decimalPointValue: bookingInvoice?.decimalPointValue ?? 2,
      distanceUnit: bookingInvoice?.distanceUnit,
      customPrices: state.customPrices,
      accessibilities: state.accessibilities,
    );
  }

  /// Build rental package card for selected ride section
  Widget _buildRentalPackageCard(AppColorPalette colors, BookingDetails booking) {
    final packageDetail = booking.packageDetail!;
    final bookingInvoice = booking.bookingInvoice;
    final sign = bookingInvoice?.currencySign ?? '\u20B9';
    final decimalPointValue = bookingInvoice?.decimalPointValue ?? 2;
    final currencyDirection = bookingInvoice?.setCurrencySign ?? 0;

    final invoiceUtil = InvoiceUtil(
      currencyDirection: currencyDirection,
      currencySign: sign,
      decimalPointValue: decimalPointValue,
      distanceUnit: bookingInvoice?.distanceUnit,
    );
    final packageInvoiceList = invoiceUtil.getPackageInvoiceList(
      PackageDetail(
        distancePrice: packageDetail.distancePrice,
        timePrice: packageDetail.timePrice,
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(top: AppDimens.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.body(
            packageDetail.packageName ?? '',
            fontWeight: FontWeight.w600,
            color: colors.colorText,
          ),
          if (packageInvoiceList.isNotEmpty) ...[
            const SizedBox(height: AppDimens.paddingXS),
            ...packageInvoiceList.map((invoice) => Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (invoice.title != null && invoice.title!.isNotEmpty)
                    Text(
                      invoice.title!,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.colorText.withValues(alpha: 0.6),
                      ),
                    ),
                  if (invoice.subTitle != null && invoice.subTitle!.isNotEmpty)
                    Text(
                      invoice.subTitle!,
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.colorText.withValues(alpha: 0.5),
                      ),
                    ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  /// Build selected payment option section
  Widget _buildSelectedPaymentSection(
    AppColorPalette colors,
    BookingDetails? booking,
  ) {
    final bookingInvoice = booking?.bookingInvoice;
    final paymentMode = bookingInvoice?.paymentMode;

    // Get payment gateway type from payment mode
    final paymentGateway = PaymentGatewayType.fromValue(paymentMode);
    final paymentName =
        paymentGateway?.getName() ??
        getString(appStr.descriptionPayment, 'description_payment');

    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingM),
      decoration: BoxDecoration(
        color: colors.colorBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.colorText.withValues(alpha: 0.18),
            blurRadius: 4,
            offset: Offset.zero,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          AppText.caption(
            getString(
              appStr.headingSelectedPaymentOption,
              'heading_selected_payment_option',
            ),
            color: colors.colorText.withValues(alpha: 0.6),
          ),
          const SizedBox(height: AppDimens.paddingM),

          Row(
            children: [
              // Payment icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.colorBackgroundGray,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getPaymentIcon(paymentGateway),
                  color: colors.colorPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppDimens.paddingM),

              // Payment name
              Expanded(
                child: AppText.title(
                  paymentName,
                  color: colors.colorText,
                  fontWeight: FontWeight.w500,
                ),
              ),

            ],
          ),
        ],
      ),
    );
  }

  /// Get appropriate icon for payment gateway type
  IconData _getPaymentIcon(PaymentGatewayType? type) {
    return switch (type) {
      PaymentGatewayType.cash => Icons.payments_outlined,
      PaymentGatewayType.wallet => Icons.account_balance_wallet_outlined,
      _ => Icons.credit_card,
    };
  }

  /// Build driver info section matching the screenshot layout
  Widget _buildDriverInfoSection(
    AppColorPalette colors,
    ConfirmedDriver driver,
    DriverVehicleDetail? vehicleDetail,
    BookingVehicleType? vehicleType,
    Set<CustomerBookingSettings> activeSetting,
  ) {
    final showRating = activeSetting.contains(
      CustomerBookingSettings.showRating,
    );
    final allowChat = activeSetting.contains(
      CustomerBookingSettings.allowChatWithDriver,
    );
    final allowCall =
        activeSetting.contains(CustomerBookingSettings.allowCallToDriver) ||
        activeSetting.contains(CustomerBookingSettings.allowCallToSupport);
    final driverImageUrl = driver.imageUrl != null
        ? ServerConfig.getFullImageUrl(driver.imageUrl)
        : null;
    final vehicleImageUrl = vehicleType?.imageUrl != null
        ? ServerConfig.getFullImageUrl(vehicleType!.imageUrl)
        : null;

    // Build vehicle description: "Color Brand Model"
    final vehicleDescription = [
      vehicleDetail?.color,
      vehicleDetail?.brand,
      vehicleDetail?.model,
    ].where((s) => s != null && s.isNotEmpty).join(' ');

    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingM),
      decoration: BoxDecoration(
        color: colors.colorBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.colorText.withValues(alpha: 0.18),
            blurRadius: 4,
            offset: Offset.zero,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Left: Driver photo with vehicle image stacked
              SizedBox(
                width: 140,
                height: 92,
                child: Stack(
                  children: [
                    // Vehicle image (fills the box as background)
                    if (vehicleImageUrl != null)
                      Positioned.fill(
                        child: CachedNetworkImage(
                          imageUrl: vehicleImageUrl,
                          fit: BoxFit.contain,
                          placeholder: (context, url) =>
                              const SizedBox.shrink(),
                          errorWidget: (context, url, error) =>
                              const SizedBox.shrink(),
                        ),
                      ),
                    // Driver image aligned to center-left
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Driver circular image
                          ClipOval(
                            child: SizedBox(
                              width: 70,
                              height: 70,
                              child: driverImageUrl != null
                                  ? CachedNetworkImage(
                                      imageUrl: driverImageUrl,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                        color: colors.colorBackgroundGray,
                                        child: Icon(
                                          Icons.person,
                                          color: colors.colorText.withValues(
                                            alpha: 0.5,
                                          ),
                                          size: 32,
                                        ),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          Container(
                                            color: colors.colorBackgroundGray,
                                            child: Icon(
                                              Icons.person,
                                              color: colors.colorText
                                                  .withValues(alpha: 0.5),
                                              size: 32,
                                            ),
                                          ),
                                    )
                                  : Container(
                                      color: colors.colorBackgroundGray,
                                      child: Icon(
                                        Icons.person,
                                        color: colors.colorText.withValues(
                                          alpha: 0.5,
                                        ),
                                        size: 32,
                                      ),
                                    ),
                            ),
                          ),
                          // Rating badge at bottom center
                          if (showRating && driver.rate != null)
                            Positioned(
                              bottom: -4,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colors.colorText,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.star,
                                        color: colors.colorWarning,
                                        size: 10,
                                      ),
                                      const SizedBox(width: 2),
                                      AppText(
                                        driver.rate!.toStringAsFixed(2),
                                        color: colors.colorBackground,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 10,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: AppDimens.paddingS),

              // Right: Vehicle plate and description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Vehicle licence number. The driver app dropped the plate
                    // number in favour of this, so showing the plate here left
                    // the two apps naming the same car differently.
                    if (vehicleDetail?.vehicleLicense?.isNotEmpty == true)
                      AppText.heading(
                        vehicleDetail!.vehicleLicense!,
                        color: colors.colorText,
                        fontWeight: FontWeight.w800,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    // Vehicle description
                    if (vehicleDescription.isNotEmpty)
                      AppText.caption(
                        vehicleDescription,
                        color: colors.colorText.withValues(alpha: 0.6),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.paddingM),
          // Action buttons
          Row(
            children: [
              // Send message button (only if allowed)
              if (allowChat)
                Expanded(
                  child: _buildActionButton(
                    colors: colors,
                    icon: Icons.chat_bubble_outline,
                    label: getString(
                      appStr.buttonSendMessage,
                      'button_send_message',
                    ),
                    onTap: () {
                      ref.read(currentRideViewModelProvider(_params!).notifier).onChatClick();
                    },
                  ),
                ),
              // Call button (only if allowed)
              if (allowCall) ...[
                const SizedBox(width: AppDimens.paddingM),
                _buildActionButton(
                  colors: colors,
                  icon: Icons.phone,
                  onTap: () {
                    ref.read(currentRideViewModelProvider(_params!).notifier).onCallClick();
                  },
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// Build PIN verification row
  Widget _buildPinVerificationRow(
    AppColorPalette colors,
    CurrentRideState state,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText.body(
          getString(appStr.descriptionPinForRide, 'description_pin_for_ride'),
          color: colors.colorText,
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: state.verificationCode!.split('').map((digit) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: colors.colorSecondary,
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.center,
              child: AppText(
                digit,
                color: colors.colorSelectedText,
                fontWeight: FontWeight.bold,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Build ride details box with trip status
  Widget _buildRideDetailsBox(
    AppColorPalette colors,
    CurrentRideState state, {
    bool showMoreButton = true,
    bool isExpanded = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingM),
      decoration: BoxDecoration(
        color: colors.colorBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.colorText.withValues(alpha: 0.18),
            blurRadius: 4,
            offset: Offset.zero,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // "Ride details" label
                AppText.caption(
                  getString(
                    appStr.subHeadingRideDetails,
                    'sub_heading_ride_details',
                  ),
                  color: colors.colorText.withValues(alpha: 0.6),
                ),
                const SizedBox(height: 4),
                // Trip status (bold)
                AppText.title(
                  state.tripStatusText,
                  color: colors.colorText,
                  fontWeight: FontWeight.w700,
                ),
                // Waiting time (if available)
                if (state.waitingTimeStr != null &&
                    state.activeSetting.contains(
                      CustomerBookingSettings.showWaitingTime,
                    )) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: colors.colorWarning,
                      ),
                      const SizedBox(width: 4),
                      AppText(
                        state.waitingTimeStr!,
                        color: colors.colorWarning,
                        fontSize: 10,
                      ),
                    ],
                  ),
                ],
                // Total time and distance (if available)
                if (state.activeSetting.contains(
                      CustomerBookingSettings.showTotalTimeAndDistance,
                    ) &&
                    (state.totalTimeStr != null ||
                        state.totalDistance != null)) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (state.totalTimeStr != null) ...[
                        AppText(
                          '${getString(appStr.descriptionTotalTime, 'description_total_time')}: ${state.totalTimeStr}',
                          color: colors.colorText,
                          fontSize: 10,
                        ),
                      ],
                      if (state.totalTimeStr != null &&
                          state.totalDistance != null) ...[
                        const SizedBox(width: 2),
                        AppText('|', color: colors.colorText, fontSize: 12),
                        const SizedBox(width: 2),
                      ],
                      if (state.totalDistance != null) ...[
                        AppText(
                          '${getString(appStr.descriptionTotalDistance, 'description_total_distance')}: ${state.totalDistance}',
                          color: colors.colorText,
                          fontSize: 10,
                        ),
                      ],
                    ],
                  ),
                ],
                // Stop waiting time and traffic time row
                if (state.activeSetting.contains(
                          CustomerBookingSettings.showStopWaitingTime,
                        ) &&
                        state.stopWaitingTimeStr != null ||
                    state.activeSetting.contains(
                          CustomerBookingSettings.showTrafficTime,
                        ) &&
                        state.trafficTimeStr != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (state.activeSetting.contains(
                            CustomerBookingSettings.showStopWaitingTime,
                          ) &&
                          state.stopWaitingTimeStr != null) ...[
                        AppText(
                          state.stopWaitingTimeStr!,
                          color: colors.colorSecondary,
                          fontSize: 10,
                        ),
                      ],
                      if (state.activeSetting.contains(
                            CustomerBookingSettings.showStopWaitingTime,
                          ) &&
                          state.stopWaitingTimeStr != null &&
                          state.activeSetting.contains(
                            CustomerBookingSettings.showTrafficTime,
                          ) &&
                          state.trafficTimeStr != null) ...[
                        const SizedBox(width: 2),
                        AppText(
                          '|',
                          color: colors.colorSecondary,
                          fontSize: 12,
                        ),
                        const SizedBox(width: 2),
                      ],
                      if (state.activeSetting.contains(
                            CustomerBookingSettings.showTrafficTime,
                          ) &&
                          state.trafficTimeStr != null) ...[
                        AppText(
                          '${getString(appStr.descriptionTrafficTime, 'description_traffic_time')}: ${state.trafficTimeStr}',
                          color: colors.colorSecondary,
                          fontSize: 10,
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
          // 3-dot popup menu button
          if (showMoreButton)
            _buildMorePopupMenu(colors, state, isExpanded: isExpanded),
        ],
      ),
    );
  }

  /// Build popup menu for the 3-dot button in ride details box
  Widget _buildMorePopupMenu(
    AppColorPalette colors,
    CurrentRideState state, {
    bool isExpanded = false,
  }) {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(AppDimens.paddingM),
        decoration: BoxDecoration(
          color: colors.colorBackgroundGray,
          borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
        ),
        child: Icon(Icons.more_horiz, color: colors.colorText, size: 20),
      ),
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: colors.colorBackground,
      onSelected: (value) {
        if (value == 'trip_details') {
          _sheetController.expand();
        } else if (value == 'cancel_trip') {
          ref.read(currentRideViewModelProvider(_params!).notifier).onCancelTripClick();
        }
      },
      itemBuilder: (context) => [
        // "Trip details" option only in collapsed view
        if (!isExpanded)
          PopupMenuItem<String>(
            value: 'trip_details',
            child: AppText.body(
              getString(appStr.subHeadingTripDetails, 'sub_heading_trip_details'),
              color: colors.colorText,
            ),
          ),
        // "Cancel trip" only in the expanded sheet — collapsed now has its own
        // button, and offering it in both places would be redundant.
        if (state.isShowCancelButton && isExpanded)
          PopupMenuItem<String>(
            value: 'cancel_trip',
            child: AppText.body(
              getString(appStr.descriptionCancelTrip, 'description_cancel_trip'),
              color: colors.colorWarning,
            ),
          ),
      ],
    );
  }

  /// Build bidding request section with header + bid list
  Widget _buildBiddingRequestSection(
    AppColorPalette colors,
    CurrentRideState state,
  ) {
    final booking = state.bookingDetail?.booking;
    final bookingInvoice = booking?.bookingInvoice;
    final currencyDirection = booking?.setCurrencySign ?? 1;
    final currencySign = bookingInvoice?.currencySign ?? '\u20B9';
    final decimalPointValue = bookingInvoice?.decimalPointValue ?? 2;

    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingM),
      decoration: BoxDecoration(
        color: colors.colorBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.colorText.withValues(alpha: 0.18),
            blurRadius: 4,
            offset: Offset.zero,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: title + timer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText.title(
                getString(
                  appStr.headingBiddingRequest,
                  'heading_bidding_request',
                ),
                color: colors.colorText,
                fontWeight: FontWeight.w600,
              ),
              if (state.bidRequestTimeStr != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.paddingM,
                    vertical: AppDimens.paddingXS,
                  ),
                  decoration: BoxDecoration(
                    color: colors.colorWarning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: colors.colorWarning,
                      ),
                      const SizedBox(width: 4),
                      AppText.body(
                        state.bidRequestTimeStr!,
                        color: colors.colorWarning,
                        fontWeight: FontWeight.w600,
                      ),
                    ],
                  ),
                ),
            ],
          ),

          // Customer bid price (pre-formatted with applyPriceSetting in viewmodel)
          if (state.formattedCustomerBidPrice != null) ...[
            const SizedBox(height: AppDimens.paddingS),
            AppText.body(
              '${getString(appStr.descriptionBidAmountFor, 'description_bid_amount_for')}: ${state.formattedCustomerBidPrice}',
              color: colors.colorText.withValues(alpha: 0.7),
            ),
          ],

          const SizedBox(height: AppDimens.paddingM),

          // Bid list
          ...state.biddingList.asMap().entries.map((entry) {
            final index = entry.key;
            final bid = entry.value;
            return _buildBidItem(colors, bid, index, currencyDirection, currencySign, decimalPointValue);
          }),
        ],
      ),
    );
  }

  /// Build a single bid item row
  Widget _buildBidItem(
    AppColorPalette colors,
    Bid bid,
    int index,
    int currencyDirection,
    String currencySign,
    int decimalPointValue,
  ) {
    final driverImageUrl = bid.imageUrl != null
        ? ServerConfig.getFullImageUrl(bid.imageUrl)
        : null;
    final formattedPrice = (bid.price ?? 0).toDouble().applyPriceSetting(
      currencyDirection: currencyDirection,
      currencySign: currencySign,
      decimalPointValue: decimalPointValue,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.paddingM),
      child: Row(
        children: [
          // Driver image
          ClipOval(
            child: SizedBox(
              width: 44,
              height: 44,
              child: driverImageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: driverImageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: colors.colorBackgroundGray,
                        child: Icon(
                          Icons.person,
                          color: colors.colorText.withValues(alpha: 0.5),
                          size: 24,
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: colors.colorBackgroundGray,
                        child: Icon(
                          Icons.person,
                          color: colors.colorText.withValues(alpha: 0.5),
                          size: 24,
                        ),
                      ),
                    )
                  : Container(
                      color: colors.colorBackgroundGray,
                      child: Icon(
                        Icons.person,
                        color: colors.colorText.withValues(alpha: 0.5),
                        size: 24,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: AppDimens.paddingM),

          // Driver name, rating, price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.body(
                  bid.name ?? '',
                  color: colors.colorText,
                  fontWeight: FontWeight.w600,
                ),
                Row(
                  children: [
                    AppText.title(
                      formattedPrice,
                      color: colors.colorPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    if (bid.rate != null) ...[
                      const SizedBox(width: AppDimens.paddingM),
                      Icon(
                        Icons.star,
                        color: colors.colorWarning,
                        size: 14,
                      ),
                      const SizedBox(width: 2),
                      AppText.caption(
                        bid.rate!.toStringAsFixed(1),
                        color: colors.colorText,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Accept button
          GestureDetector(
            onTap: () {
              final driverId = bid.id;
              if (driverId != null && _params != null) {
                ref
                    .read(currentRideViewModelProvider(_params!).notifier)
                    .acceptBid(driverId);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.paddingM,
                vertical: AppDimens.paddingS,
              ),
              decoration: BoxDecoration(
                color: colors.colorPrimary,
                borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
              ),
              child: AppText.body(
                getString(appStr.buttonAccept, 'button_accept'),
                color: colors.colorBackground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppDimens.paddingS),

          // Reject button
          GestureDetector(
            onTap: () {
              final driverId = bid.id;
              if (driverId != null && _params != null) {
                ref
                    .read(currentRideViewModelProvider(_params!).notifier)
                    .rejectBid(driverId, index);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.paddingM,
                vertical: AppDimens.paddingS,
              ),
              decoration: BoxDecoration(
                color: colors.colorBackgroundGray,
                borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
              ),
              child: AppText.body(
                getString(appStr.buttonReject, 'button_reject'),
                color: colors.colorText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build a single action button
  Widget _buildActionButton({
    required AppColorPalette colors,
    required IconData icon,
    String? label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: label != null ? AppDimens.padding : AppDimens.paddingM,
          vertical: AppDimens.paddingM,
        ),
        decoration: BoxDecoration(
          color: colors.colorBackgroundGray,
          borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: colors.colorText, size: 20),
            if (label != null) ...[
              const SizedBox(width: AppDimens.paddingS),
              Flexible(
                child: AppText.body(
                  label,
                  color: colors.colorText,
                  fontWeight: FontWeight.w500,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
