import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/router/app_navigation.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../models/invoice.dart';
import '../../../models/responses/booking/booking_detail_response.dart';
import '../../../viewmodels/receipt_viewmodel.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_text.dart';

class ReceiptScreen extends ConsumerWidget {
  final BookingDetailResponse? bookingDetailResponse;

  const ReceiptScreen({super.key, required this.bookingDetailResponse});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

    if (bookingDetailResponse == null) {
      return AppScaffold(
        body: SafeArea(
          child: Column(
            children: [
              _buildBackButton(context, colors),
              Expanded(
                child: Center(
                  child: AppText.body(
                    getString(appStr.descriptionNoInvoiceData, 'description_no_invoice_data'),
                    color: colors.colorTextHint,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final state = ref.watch(receiptViewModelProvider(bookingDetailResponse!));

    // Listen for snackbar messages
    ref.listen(
      receiptViewModelProvider(bookingDetailResponse!),
      (previous, next) {
        if (next.snackBarMessage.isNotEmpty &&
            previous?.snackBarMessage != next.snackBarMessage) {
          context.showErrorSnackBar(next.snackBarMessage);
        }
      },
    );

    return AppScaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header section (blue bg + back button + greeting)
            Stack(
              clipBehavior: Clip.none,
              children: [
                _CurvedHeader(colors: colors),
                SafeArea(
                  bottom: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildBackButton(context, colors),
                      _buildHeaderContent(colors, state),
                    ],
                  ),
                ),
                // Car overlaps curve edge — bottom half on white
                Positioned(
                  right: AppDimens.paddingXL,
                  bottom: -30,
                  child: Image.asset(
                    'assets/images/ic_receipt_car.png',
                    width: 120,
                    height: 120,
                  ),
                ),
              ],
            ),

            // Space for the car overflow
            const SizedBox(height: 30),

            // White card
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.padding,
              ),
              child: _buildReceiptCard(colors, state),
            ),

            const SizedBox(height: AppDimens.padding),

            // Disclaimer
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.paddingXL,
              ),
              child: AppText.caption(
                getString(appStr.descriptionReceiptDisclaimer, 'description_receipt_disclaimer'),
                color: colors.colorTextHint,
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: AppDimens.paddingXXL),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context, AppColorPalette colors) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(
          left: AppDimens.paddingS,
          top: AppDimens.paddingS,
        ),
        child: IconButton(
          onPressed: () => context.goBack(),
          icon: Icon(
            Icons.arrow_back,
            color: colors.colorButtonText,
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderContent(AppColorPalette colors, ReceiptState state) {
    final greeting = state.customerName.isNotEmpty
        ? getString(appStr.descriptionThanksForRiding, 'description_thanks_for_riding')
            .replaceAll('{{_CUSTOMER_NAME}}', state.customerName)
        : getString(appStr.descriptionThanksForRidingNoName, 'description_thanks_for_riding_no_name');

    return Padding(
      padding: const EdgeInsets.only(
        left: AppDimens.paddingXL,
        right: AppDimens.padding,
        top: AppDimens.paddingM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.rideDate.isNotEmpty)
            AppText.caption(
              state.rideDate,
              color: colors.colorButtonText,
            ),
          const SizedBox(height: AppDimens.paddingXS),
          AppText.heading(
            greeting,
            color: colors.colorButtonText,
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptCard(AppColorPalette colors, ReceiptState state) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.colorBackground,
        borderRadius: BorderRadius.circular(AppDimens.paddingM),
        boxShadow: [
          BoxShadow(
            color: colors.colorText.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total row
          Padding(
            padding: const EdgeInsets.only(
              left: AppDimens.padding,
              right: AppDimens.padding,
              top: AppDimens.paddingXL,
              bottom: AppDimens.paddingM,
            ),
            child: Row(
              children: [
                Expanded(
                  child: AppText.title(
                    getString(appStr.descriptionTotal, 'description_total'),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                AppText.title(
                  state.bookingPrice,
                  fontWeight: FontWeight.w700,
                ),
              ],
            ),
          ),

          _buildDivider(colors),

          // Invoice line items
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.padding,
              vertical: AppDimens.paddingS,
            ),
            child: Column(
              children: state.invoiceList
                  .map((invoice) => _InvoiceItem(
                        invoice: invoice,
                        colors: colors,
                      ))
                  .toList(),
            ),
          ),

          // Minimum fare applied
          if (state.isMinFareApplied)
            Padding(
              padding: const EdgeInsets.only(
                left: AppDimens.padding,
                right: AppDimens.padding,
                bottom: AppDimens.paddingS,
              ),
              child: AppText.caption(
                getString(appStr.descriptionMinimumFareApplied, 'description_minimum_fare_applied'),
                color: colors.colorWarning,
              ),
            ),

          _buildDivider(colors),

          // Subtotal row
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.padding,
              vertical: AppDimens.paddingM,
            ),
            child: Row(
              children: [
                Expanded(
                  child: AppText.body(
                    getString(appStr.descriptionSubtotal, 'description_subtotal'),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                AppText.body(
                  state.bookingPrice,
                  fontWeight: FontWeight.w600,
                ),
              ],
            ),
          ),

          // Thick divider before payments
          Container(
            height: AppDimens.paddingS,
            color: colors.colorBackgroundGray,
          ),

          // Payments section
          Padding(
            padding: const EdgeInsets.all(AppDimens.padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.body(
                  getString(appStr.headingPayments, 'heading_payments'),
                  fontWeight: FontWeight.w700,
                ),
                const SizedBox(height: AppDimens.paddingM),
                _buildPaymentRow(colors, state),
              ],
            ),
          ),

          // Bottom info section (distance, time, waiting times)
          if (_hasBottomInfo(state)) ...[
            _buildDivider(colors),
            Padding(
              padding: const EdgeInsets.all(AppDimens.padding),
              child: _InvoiceBottomList(state: state, colors: colors),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentRow(AppColorPalette colors, ReceiptState state) {
    return Row(
      children: [
        // Payment method icon
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colors.colorBackgroundGray,
            borderRadius: BorderRadius.circular(AppDimens.paddingS),
          ),
          child: Icon(
            _getPaymentIcon(state.paymentMode),
            size: AppDimens.iconSize,
            color: colors.colorText,
          ),
        ),
        const SizedBox(width: AppDimens.paddingM),
        // Payment name + date
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.body(
                state.payment,
                fontWeight: FontWeight.w600,
              ),
              if (state.paymentDate.isNotEmpty)
                AppText.caption(
                  state.paymentDate,
                  color: colors.colorTextHint,
                ),
            ],
          ),
        ),
        // Amount
        AppText.body(
          state.bookingPrice,
          fontWeight: FontWeight.w600,
        ),
      ],
    );
  }

  IconData _getPaymentIcon(int paymentMode) {
    final type = PaymentGatewayType.fromValue(paymentMode);
    return switch (type) {
      PaymentGatewayType.cash => Icons.payments_outlined,
      PaymentGatewayType.wallet => Icons.account_balance_wallet_outlined,
      _ => Icons.credit_card,
    };
  }

  bool _hasBottomInfo(ReceiptState state) {
    return state.distance.isNotEmpty ||
        state.time.isNotEmpty ||
        state.payment.isNotEmpty ||
        state.waitingTime.isNotEmpty ||
        state.stopWaitingTime.isNotEmpty ||
        state.trafficTime.isNotEmpty;
  }

  Widget _buildDivider(AppColorPalette colors) {
    return Divider(
      height: 1,
      thickness: 1,
      color: colors.colorBackgroundGray,
    );
  }
}

/// Single invoice line item with expandable children
class _InvoiceItem extends StatefulWidget {
  final Invoice invoice;
  final AppColorPalette colors;

  const _InvoiceItem({required this.invoice, required this.colors});

  @override
  State<_InvoiceItem> createState() => _InvoiceItemState();
}

class _InvoiceItemState extends State<_InvoiceItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final invoice = widget.invoice;
    final colors = widget.colors;
    final hasChildren = invoice.invoiceChild?.isNotEmpty == true;
    final isFree = invoice.isFree == true;
    final hasDiscount =
        invoice.discount != null && invoice.discount!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main row
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              // Left side: title + arrow + subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: AppText.body(
                            invoice.title ?? '',
                            color: colors.colorTextHint,
                          ),
                        ),
                        if (hasChildren)
                          GestureDetector(
                            onTap: () =>
                                setState(() => _isExpanded = !_isExpanded),
                            child: Transform.rotate(
                              angle: _isExpanded ? 3.14159 : 0,
                              child: Icon(
                                Icons.keyboard_arrow_down,
                                color: colors.colorTextHint,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (invoice.subTitle != null &&
                        invoice.subTitle!.isNotEmpty)
                      AppText.caption(
                        invoice.subTitle!,
                      ),
                  ],
                ),
              ),

              // Free badge
              if (isFree)
                Container(
                  margin: const EdgeInsets.only(left: 5),
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: colors.colorSecondary,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: AppText.body(
                    getString(appStr.descriptionFree, 'description_free'),
                    color: colors.colorButtonText,
                  ),
                ),

              // Discount amount
              if (hasDiscount)
                Padding(
                  padding: const EdgeInsets.only(left: 5),
                  child: AppText.body(
                    invoice.discount!,
                    color: colors.colorTextHint,
                  ),
                ),

              // Amount — always shown, linethrough if free or discount
              Padding(
                padding: const EdgeInsets.only(left: 5),
                child: AppText.body(
                  invoice.amount ?? '',
                  color: colors.colorTextHint,
                  decoration: (isFree || hasDiscount)
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
            ],
          ),
        ),

        // Expandable children
        if (hasChildren && _isExpanded)
          ...invoice.invoiceChild!.map((child) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: AppText.body(
                      child.title ?? '',
                      fontWeight: FontWeight.w500,
                      fontSize: AppTypos.textS,
                    ),
                  ),
                  AppText.body(
                    child.amount ?? '',
                    fontWeight: FontWeight.w500,
                    fontSize: AppTypos.textS,
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}

/// Bottom info section — grid layout
/// Row 1: Distance + Time + Payment (each weight 1)
/// Row 2: WaitingTime + StopWaitingTime + TrafficTime (each weight 1)
class _InvoiceBottomList extends StatelessWidget {
  final ReceiptState state;
  final AppColorPalette colors;

  const _InvoiceBottomList({required this.state, required this.colors});

  @override
  Widget build(BuildContext context) {
    // Row 1 items
    final row1 = <Widget>[];

    if (state.activeSetting
            .contains(CustomerBookingSettings.showTotalTimeAndDistance) &&
        state.distance.isNotEmpty) {
      row1.add(_buildBottomItem(getString(appStr.descriptionTotalDistance, 'description_total_distance'), state.distance));
    }
    if (state.activeSetting
            .contains(CustomerBookingSettings.showTotalTimeAndDistance) &&
        state.time.isNotEmpty) {
      row1.add(_buildBottomItem(getString(appStr.descriptionTotalTime, 'description_total_time'), state.time));
    }
    // Payment is always shown
    row1.add(_buildBottomItem(getString(appStr.descriptionPayment, 'description_payment'), state.payment));

    // Row 2 items
    final row2 = <Widget>[];

    if (state.activeSetting
        .contains(CustomerBookingSettings.showWaitingTime)) {
      row2.add(_buildBottomItem(getString(appStr.descriptionWaitingTime, 'description_waiting_time'), state.waitingTime));
    }
    if (state.activeSetting
        .contains(CustomerBookingSettings.showStopWaitingTime)) {
      row2.add(_buildBottomItem(getString(appStr.descriptionStopTime, 'description_stop_time'), state.stopWaitingTime));
    }
    if (state.activeSetting
        .contains(CustomerBookingSettings.showTrafficTime)) {
      row2.add(_buildBottomItem(getString(appStr.descriptionTrafficTime, 'description_traffic_time'), state.trafficTime));
    }

    return Column(
      children: [
        if (row1.isNotEmpty) Row(children: row1),
        if (row2.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(children: row2),
          ),
      ],
    );
  }

  Widget _buildBottomItem(String title, String value) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.body(
              title,
              maxLines: 1,
            ),
            AppText.body(
              value,
              fontWeight: FontWeight.w600,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}

/// Curved header background using colorPrimary
class _CurvedHeader extends StatelessWidget {
  final AppColorPalette colors;

  const _CurvedHeader({required this.colors});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _CurvedHeaderClipper(),
      child: Container(
        height: 280,
        width: double.infinity,
        color: colors.colorPrimary,
      ),
    );
  }
}

class _CurvedHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    // Top-left corner
    path.lineTo(0, 0);

    // Down the left edge to full height
    path.lineTo(0, size.height);

    // FLAT LEFT: straight line at bottom (~35% width)
    path.lineTo(size.width * 0.35, size.height);

    // CURVE UP: cubic with horizontal tangents at both ends (no kinks)
    path.cubicTo(
      size.width * 0.5, size.height,
      size.width * 0.6, size.height * 0.85,
      size.width * 0.72, size.height * 0.85,
    );

    // FLAT RIGHT: straight line at higher position (~28% width)
    path.lineTo(size.width, size.height * 0.85);

    // Up to top-right and close
    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
