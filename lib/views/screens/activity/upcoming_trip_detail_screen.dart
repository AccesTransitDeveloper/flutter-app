import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/localization/string_constants.dart';
import '../../../core/map/interface/map_interface.dart';
import '../../../core/map/widgets/map_host.dart';
import '../../../core/map/providers/map_provider.dart';
import '../../../core/router/app_navigation.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/invoice_util.dart';
import '../../../data/api/server_config.dart';
import '../../../models/chat/chat_config.dart';
import '../../../models/requests/get_vehicle_types_request.dart';
import '../../../models/responses/booking/booking_detail_response.dart';
import '../../../models/responses/booking/get_vehicle_type_response.dart';
import '../../../models/responses/setting/cancellation_reason_response.dart';
import '../../../viewmodels/upcoming_trip_detail_viewmodel.dart';
import '../../bottomsheets/call_options_bottom_sheet.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_text.dart';
import '../../widgets/app_toolbar.dart';
import '../../../core/utils/snackbar_utils.dart';

class UpcomingTripDetailScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const UpcomingTripDetailScreen({super.key, required this.bookingId});

  @override
  ConsumerState<UpcomingTripDetailScreen> createState() =>
      _UpcomingTripDetailScreenState();
}

class _UpcomingTripDetailScreenState
    extends ConsumerState<UpcomingTripDetailScreen> {
  late final MapInterface _mapManager;
  UpcomingTripDetailParams? _params;

  @override
  void initState() {
    super.initState();
    _mapManager = ref.read(mapManagerProvider)();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _params ??= UpcomingTripDetailParams(
      bookingId: widget.bookingId,
      mapManager: _mapManager,
      primaryColor: context.colors.colorPrimary.toARGB32(),
    );
  }

  @override
  void dispose() {
    _mapManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (_params == null) return const SizedBox.shrink();
    final state = ref.watch(upcomingTripDetailViewModelProvider(_params!));

    // If cancelled, go back. Show cancel errors as snackbar.
    ref.listen(upcomingTripDetailViewModelProvider(_params!), (prev, next) {
      if (next.isCancelled && !(prev?.isCancelled ?? false)) {
        if (context.mounted) context.pop();
      }
      if (next.cancelError != null && next.cancelError != prev?.cancelError) {
        if (context.mounted) context.showErrorSnackBar(next.cancelError!);
      }
    });

    return AppScaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppToolbar(title: getString(appStr.subHeadingTripDetails, 'sub_heading_trip_details')),
            if (state.isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (state.error != null)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimens.padding),
                    child: AppText.body(
                      state.error!,
                      color: colors.colorText.withValues(alpha: 0.5),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              )
            else if (state.booking != null)
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.padding,
                  ),
                  child: _buildContent(colors, state),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
      AppColorPalette colors, UpcomingTripDetailState state) {
    final booking = state.booking!;
    final driver = booking.confirmedDriver;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Map
        _buildMap(colors),

        const SizedBox(height: AppDimens.paddingL),

        // Status badge
        if (state.statusLabel.isNotEmpty) ...[
          _buildStatusBadge(colors, state.statusLabel, booking.status),
          const SizedBox(height: AppDimens.paddingS),
        ],

        // Ride title + Driver avatar
        _buildRideHeader(colors, booking, driver),

        // Rental package info
        if (booking.packageDetail != null)
          _buildRentalPackageInfo(colors, booking),

        const SizedBox(height: AppDimens.paddingS),

        // Booking ID
        if (booking.uniqueId != null && booking.uniqueId!.isNotEmpty) ...[
          AppText.body(
            getString(appStr.descriptionBookingIdWithSeparator, 'description_booking_id_with_separator')
                .replacePlaceholders({StringConstant.unitValue: booking.uniqueId!}),
            color: colors.colorText.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppDimens.paddingXS),
        ],

        // Date and time
        if (state.dateTimeStr != null)
          AppText.body(
            state.dateTimeStr!,
            color: colors.colorText.withValues(alpha: 0.5),
          ),

        const SizedBox(height: AppDimens.paddingXS),

        // Price (estimated)
        if (state.priceStr != null)
          AppText.body(
            state.priceStr!,
            color: colors.colorText.withValues(alpha: 0.5),
          ),

        const SizedBox(height: AppDimens.paddingXL),

        // Addresses
        if (state.addressList.isNotEmpty)
          _buildAddressSection(colors, state.addressList),

        Divider(
          color: colors.colorBackgroundGray,
          height: AppDimens.paddingXXL,
        ),

        // Driver details section
        if (state.isDriveDetailVisible) ...[
          _buildDriverDetails(colors, state, driver!),

          // Action buttons (chat + call)
          _buildActionButtons(colors, state, driver),

          Divider(
            color: colors.colorBackgroundGray,
            height: AppDimens.paddingXXL,
          ),
        ],

        // Rating (read-only driver rating)
        if (state.activeSetting.contains(CustomerBookingSettings.showRating) &&
            state.isDriveDetailVisible) ...[
          _buildDriverRatingRow(colors, driver!),
          Divider(
            color: colors.colorBackgroundGray,
            height: AppDimens.paddingXXL,
          ),
        ],

        // Help & safety section
        _buildHelpAndSafety(colors),

        const SizedBox(height: AppDimens.paddingXL),

        // Cancel booking button
        if (state.isAllowCancelBooking) ...[
          SizedBox(
            width: double.infinity,
            child: AppOutlinedButton(
              text: getString(appStr.buttonCancelBooking, 'button_cancel_booking'),
              textColor: colors.colorWarning,
              borderColor: colors.colorWarning,
              onPressed: () => _showCancelBottomSheet(context),
            ),
          ),
          const SizedBox(height: AppDimens.paddingXL),
        ],

        const SizedBox(height: AppDimens.padding),
      ],
    );
  }

  /// Map showing the route
  Widget _buildMap(AppColorPalette colors) {
    return Container(
      height: 200,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.colorBackgroundGray,
        borderRadius: BorderRadius.circular(AppDimens.paddingM),
      ),
      child: IgnorePointer(child: MapHost(manager: _mapManager)),
    );
  }

  /// Status badge
  Widget _buildStatusBadge(
      AppColorPalette colors, String label, int? statusValue) {
    final status = BookingStatus.fromValue(statusValue);
    final badgeColor = switch (status) {
      BookingStatus.requested => colors.colorPrimary,
      BookingStatus.accepted ||
      BookingStatus.assigned =>
        Colors.green,
      BookingStatus.inRoute ||
      BookingStatus.arrivedAtPickup =>
        Colors.blue,
      BookingStatus.started => Colors.teal,
      _ => colors.colorPrimary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.paddingM,
        vertical: AppDimens.paddingXS,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimens.paddingS),
      ),
      child: AppText.caption(
        label.replaceAll(RegExp(r'(?<=[a-z])(?=[A-Z])'), ' ').toUpperCase(),
        color: badgeColor,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  /// Ride title with driver avatar
  Widget _buildRideHeader(
    AppColorPalette colors,
    BookingDetails booking,
    ConfirmedDriver? driver,
  ) {
    final vehicleName = booking.vehicleType?.name ?? '';
    final driverName = driver?.name ?? '';
    final title = driverName.isNotEmpty
        ? getString(appStr.descriptionRideWithDriver, 'description_ride_with_driver')
            .replacePlaceholders({
              StringConstant.leftParam: vehicleName,
              StringConstant.rightParam: driverName,
            })
        : getString(appStr.descriptionRide, 'description_ride')
            .replacePlaceholders({StringConstant.value: vehicleName});

    final imageUrl = driver?.imageUrl != null
        ? ServerConfig.getFullImageUrl(driver!.imageUrl)
        : null;

    return Row(
      children: [
        Expanded(
          child: AppText.title(
            title,
            fontWeight: FontWeight.bold,
            fontSize: AppTypos.textXXL,
          ),
        ),
        if (driver != null) ...[
          const SizedBox(width: AppDimens.paddingM),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: colors.colorBackgroundGray,
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            child: imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Icon(
                      Icons.person,
                      color: colors.colorText.withValues(alpha: 0.4),
                      size: 28,
                    ),
                    errorWidget: (context, url, error) => Icon(
                      Icons.person,
                      color: colors.colorText.withValues(alpha: 0.4),
                      size: 28,
                    ),
                  )
                : Icon(
                    Icons.person,
                    color: colors.colorText.withValues(alpha: 0.4),
                    size: 28,
                  ),
          ),
        ],
      ],
    );
  }

  /// Address section with pickup/drop icons and connecting line
  Widget _buildAddressSection(
    AppColorPalette colors,
    List<DestinationAddress> addressList,
  ) {
    const double rowHeight = 48;
    final totalRows = addressList.length;
    final totalHeight = totalRows * rowHeight;
    final destinations = addressList.length > 1 ? addressList.sublist(1) : [];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icons column with connecting line
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

              // Pickup icon
              Positioned(
                top: (rowHeight / 2) - 10,
                child: Image.asset(
                  'assets/images/ic_pickup.png',
                  width: 20,
                  height: 20,
                  color: colors.colorPrimary,
                  colorBlendMode: BlendMode.srcIn,
                ),
              ),

              // Destination/stop icons
              for (int i = 0; i < destinations.length; i++)
                Positioned(
                  top: rowHeight +
                      (i * rowHeight) +
                      (rowHeight / 2) -
                      10,
                  child: i == destinations.length - 1
                      ? Image.asset(
                          'assets/images/ic_drop_off.png',
                          width: 20,
                          height: 20,
                          color: colors.colorPrimary,
                          colorBlendMode: BlendMode.srcIn,
                        )
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
            ],
          ),
        ),

        const SizedBox(width: AppDimens.paddingM),

        // Address text column
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: addressList.map((address) {
              return SizedBox(
                height: rowHeight,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AppText.body(
                    address.address ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// Driver details section
  Widget _buildDriverDetails(
    AppColorPalette colors,
    UpcomingTripDetailState state,
    ConfirmedDriver driver,
  ) {
    final vehicle = driver.vehicleDetail;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.title(
          getString(appStr.headingRideDetails, 'heading_ride_details'),
          fontWeight: FontWeight.bold,
          fontSize: AppTypos.textXXL,
        ),
        const SizedBox(height: AppDimens.padding),
        if (state.distanceStr != null)
          _buildDetailRow(colors, getString(appStr.descriptionDistance, 'description_distance'), state.distanceStr!),
        if (state.estimatedTimeStr != null)
          _buildDetailRow(colors, getString(appStr.descriptionDuration, 'description_duration'), state.estimatedTimeStr!),
        if (vehicle != null) ...[
          // Licence rather than plate, matching the driver app — and the label
          // moves with it so the row isn't headed "Plate No".
          if (vehicle.vehicleLicense != null && vehicle.vehicleLicense!.isNotEmpty)
            _buildDetailRow(colors, getString(null, 'hint_vehicle_license'), vehicle.vehicleLicense!),
          if (vehicle.color != null && vehicle.color!.isNotEmpty)
            _buildDetailRow(colors, getString(appStr.hintVehicleColor, 'hint_vehicle_color'), vehicle.color!),
          if (vehicle.model != null && vehicle.model!.isNotEmpty)
            _buildDetailRow(colors, getString(appStr.headingVehicle, 'heading_vehicle'), vehicle.model!),
        ],
      ],
    );
  }

  Widget _buildDetailRow(AppColorPalette colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.paddingS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppText.body(
            label,
            color: colors.colorText.withValues(alpha: 0.5),
          ),
          AppText.body(value, fontWeight: FontWeight.w500),
        ],
      ),
    );
  }

  /// Action buttons row (chat + call)
  Widget _buildActionButtons(
    AppColorPalette colors,
    UpcomingTripDetailState state,
    ConfirmedDriver driver,
  ) {
    final showChat = state.activeSetting
        .contains(CustomerBookingSettings.allowChatWithDriver);
    final showCall = state.activeSetting
            .contains(CustomerBookingSettings.allowCallToDriver) ||
        state.activeSetting
            .contains(CustomerBookingSettings.allowCallToSupport);

    if (!showChat && !showCall) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppDimens.paddingM),
      child: Row(
        children: [
          if (showChat) ...[
            _buildActionChip(
              colors,
              icon: Icons.chat_bubble_outline,
              label: getString(appStr.hintMessage, 'hint_message'),
              onTap: () {
                final booking = state.booking;
                if (booking != null) {
                  context.navigateToChat(
                    chatConfig: ChatConfig(
                      chatType: ChatType.CUSTOMER_DRIVER_CHAT.name,
                      referenceId: booking.id,
                      receiverImage: driver.imageUrl,
                      receiverName: driver.name,
                    ),
                  );
                }
              },
            ),
            const SizedBox(width: AppDimens.paddingS),
          ],
          if (showCall)
            _buildActionChip(
              colors,
              icon: Icons.call,
              label: getString(appStr.buttonCall, 'button_call'),
              onTap: () => _handleCallTap(state),
            ),
        ],
      ),
    );
  }

  /// Handle call tap — show bottom sheet if both options available
  void _handleCallTap(UpcomingTripDetailState state) {
    final driverPhone =
        state.booking?.confirmedDriver?.phone ?? '';
    final showDriverCall = state.activeSetting
            .contains(CustomerBookingSettings.allowCallToDriver) &&
        driverPhone.length > 5;
    final showSupportCall = state.activeSetting
        .contains(CustomerBookingSettings.allowCallToSupport);
    final vm =
        ref.read(upcomingTripDetailViewModelProvider(_params!).notifier);

    if (showDriverCall && showSupportCall) {
      CallOptionsBottomSheet.show(
        context,
        onCallDriver: vm.callDriver,
        onCallSupport: vm.callSupport,
      );
    } else if (showSupportCall) {
      vm.callSupport();
    } else if (showDriverCall) {
      vm.callDriver();
    }
  }

  /// Pill-shaped action chip
  Widget _buildActionChip(
    AppColorPalette colors, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.padding,
          vertical: AppDimens.paddingS,
        ),
        decoration: BoxDecoration(
          color: colors.colorBackgroundGray,
          borderRadius: BorderRadius.circular(AppDimens.paddingXL),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: colors.colorText),
            const SizedBox(width: AppDimens.paddingS),
            AppText.body(
              label,
              fontWeight: FontWeight.w500,
              color: colors.colorText,
            ),
          ],
        ),
      ),
    );
  }

  /// Driver rating row (read-only)
  Widget _buildDriverRatingRow(
      AppColorPalette colors, ConfirmedDriver driver) {
    final rate = driver.rate ?? 0;

    return Row(
      children: [
        Icon(
          Icons.star,
          size: 22,
          color: colors.colorText,
        ),
        const SizedBox(width: AppDimens.paddingM),
        AppText.body(getString(appStr.descriptionDriverRating, 'description_driver_rating')),
        const Spacer(),
        AppText.body(
          rate > 0 ? rate.toStringAsFixed(1) : 'N/A',
          fontWeight: FontWeight.w500,
        ),
        if (rate > 0) ...[
          const SizedBox(width: AppDimens.paddingXS),
          Icon(Icons.star, size: 16, color: colors.colorText),
        ],
      ],
    );
  }

  /// Help & safety section
  Widget _buildHelpAndSafety(AppColorPalette colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.title(
          getString(appStr.headingHelpAndSafety, 'heading_help_and_safety'),
          fontWeight: FontWeight.bold,
          fontSize: AppTypos.textXXL,
        ),
        const SizedBox(height: AppDimens.padding),
        InkWell(
          onTap: () => context.navigateToContactUs(),
          child: Row(
            children: [
              Icon(
                Icons.help_outline,
                size: 28,
                color: colors.colorText.withValues(alpha: 0.6),
              ),
              const SizedBox(width: AppDimens.paddingM),
              Expanded(
                child: AppText.body(
                  getString(appStr.buttonGetHelp, 'button_get_help'),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: colors.colorText.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Show cancel bottom sheet with reasons
  void _showCancelBottomSheet(BuildContext context) {
    final colors = context.colors;
    final viewModel = ref.read(
        upcomingTripDetailViewModelProvider(_params!).notifier);

    // Fetch cancellation reasons
    viewModel.getCancellationReasons();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.colorBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => Consumer(
        builder: (context, ref, _) {
          final state = ref.watch(
              upcomingTripDetailViewModelProvider(_params!));
          return _CancelBottomSheet(
            colors: colors,
            reasons: state.cancellationReasons,
            isLoading: state.isCancelLoading,
            onCancel: (reason) async {
              final success = await ref
                  .read(upcomingTripDetailViewModelProvider(_params!)
                      .notifier)
                  .cancelBooking(reason);
              if (success && sheetContext.mounted) {
                Navigator.pop(sheetContext);
              }
            },
            onClose: () => Navigator.pop(sheetContext),
          );
        },
      ),
    );
  }

  /// Build rental package info section
  Widget _buildRentalPackageInfo(AppColorPalette colors, BookingDetails booking) {
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
      padding: const EdgeInsets.only(top: AppDimens.paddingS),
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
}

/// Cancel booking bottom sheet
class _CancelBottomSheet extends StatefulWidget {
  final AppColorPalette colors;
  final List<CancellationReason> reasons;
  final bool isLoading;
  final Future<void> Function(String reason) onCancel;
  final VoidCallback onClose;

  const _CancelBottomSheet({
    required this.colors,
    required this.reasons,
    required this.isLoading,
    required this.onCancel,
    required this.onClose,
  });

  @override
  State<_CancelBottomSheet> createState() => _CancelBottomSheetState();
}

class _CancelBottomSheetState extends State<_CancelBottomSheet> {
  int? _selectedIndex;
  String _otherReason = '';

  /// The appended "Others" entry is always last; picking it swaps the radio for
  /// a free-text box, same as the running trip's cancel sheet.
  bool get _isOthersSelected =>
      _selectedIndex != null && _selectedIndex == widget.reasons.length - 1;

  bool get _canSubmit => _selectedIndex != null &&
      (!_isOthersSelected || _otherReason.trim().isNotEmpty);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppDimens.padding,
          right: AppDimens.padding,
          top: AppDimens.padding,
          bottom: AppDimens.padding + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: AppText.title(
                getString(appStr.headingCancelBooking, 'heading_cancel_booking'),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppDimens.paddingM),
            Divider(color: widget.colors.colorBackgroundGray),
            const SizedBox(height: AppDimens.paddingM),

            if (widget.isLoading && widget.reasons.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppDimens.paddingXL),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              AppText.body(
                getString(appStr.descriptionSelectReasonForCancellation, 'description_select_reason_for_cancellation'),
                color: widget.colors.colorText.withValues(alpha: 0.6),
              ),
              const SizedBox(height: AppDimens.paddingM),

              // Reasons list
              RadioGroup<int>(
                groupValue: _selectedIndex,
                onChanged: (val) => setState(() => _selectedIndex = val),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: widget.reasons.asMap().entries.map((entry) {
                    final index = entry.key;
                    final reason = entry.value;
                    return InkWell(
                      onTap: () => setState(() => _selectedIndex = index),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppDimens.paddingS,
                        ),
                        child: Row(
                          children: [
                            Radio<int>(value: index),
                            const SizedBox(width: AppDimens.paddingS),
                            Expanded(
                              child: AppText.body(reason.reasons ?? ''),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              if (_isOthersSelected) ...[
                const SizedBox(height: AppDimens.paddingM),
                AppTextField(
                  onChanged: (value) => setState(() => _otherReason = value),
                  maxLines: 2,
                  hintText: getString(appStr.hintWriteSpecificReason,
                      'hint_write_specific_reason'),
                  borderRadius: 12,
                  borderColor:
                      widget.colors.colorText.withValues(alpha: 0.2),
                ),
              ],

              const SizedBox(height: AppDimens.paddingXL),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: AppFilledButton(
                      text: getString(appStr.buttonCancelBooking, 'button_cancel_booking'),
                      backgroundColor: widget.colors.colorWarning,
                      isLoading: widget.isLoading,
                      onPressed: _canSubmit
                          ? () {
                              final reason = _isOthersSelected
                                  ? _otherReason.trim()
                                  : (widget.reasons[_selectedIndex!].reasons ??
                                      '');
                              widget.onCancel(reason);
                            }
                          : null,
                    ),
                  ),
                  const SizedBox(width: AppDimens.paddingM),
                  Expanded(
                    child: AppOutlinedButton(
                      text: getString(appStr.buttonGoBack, 'button_go_back'),
                      onPressed: widget.onClose,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
