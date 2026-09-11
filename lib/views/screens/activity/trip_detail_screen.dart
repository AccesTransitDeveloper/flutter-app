import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/localization/string_constants.dart';
import '../../../core/router/app_navigation.dart';
import '../../../core/map/interface/map_interface.dart';
import '../../../core/map/widgets/map_host.dart';
import '../../../core/map/providers/map_provider.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/invoice_util.dart';
import '../../../core/utils/rebook_utils.dart';
import '../../../data/api/server_config.dart';
import '../../../models/requests/get_vehicle_types_request.dart';
import '../../../models/responses/booking/booking_detail_response.dart';
import '../../../models/responses/booking/get_vehicle_type_response.dart';
import '../../../viewmodels/trip_detail_viewmodel.dart';
import '../../bottomsheets/new_ticket_bottomsheet.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_text.dart';
import '../../widgets/app_toolbar.dart';

class TripDetailScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const TripDetailScreen({super.key, required this.bookingId});

  @override
  ConsumerState<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends ConsumerState<TripDetailScreen> {
  late final MapInterface _mapManager;
  TripDetailParams? _params;

  @override
  void initState() {
    super.initState();
    _mapManager = ref.read(mapManagerProvider)();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _params ??= TripDetailParams(
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
    final state = ref.watch(tripDetailViewModelProvider(_params!));

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

  Widget _buildContent(AppColorPalette colors, TripDetailState state) {
    final booking = state.booking!;
    final driver = booking.confirmedDriver;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Map
        _buildMap(colors),

        const SizedBox(height: AppDimens.paddingL),

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
        if (state.completedTimeStr != null)
          AppText.body(
            state.completedTimeStr!,
            color: colors.colorText.withValues(alpha: 0.5),
          ),

        const SizedBox(height: AppDimens.paddingXS),

        // Price
        if (state.priceStr != null &&
            (!state.isCancelled || state.canViewReceipt))
          AppText.body(
            state.isCancelled
                ? '${state.priceStr} · ${getString(appStr.descriptionCancelled, 'description_cancelled')}'
                : state.priceStr!,
            color: state.isCancelled
                ? colors.colorWarning
                : colors.colorText.withValues(alpha: 0.5),
          ),

        // Cancelled badge (when no price)
        if (state.isCancelled &&
            (state.priceStr == null || !state.canViewReceipt))
          AppText.body(
            getString(appStr.descriptionCancelled, 'description_cancelled'),
            color: colors.colorWarning,
          ),

        const SizedBox(height: AppDimens.padding),

        // Receipt / Re-book action chips
        if (state.canViewReceipt || booking.businessType != BusinessType.courier)
          _buildActionChips(colors, state),

        const SizedBox(height: AppDimens.paddingXL),

        // Addresses
        if (state.addressList.isNotEmpty)
          _buildAddressSection(colors, state.addressList),

        // Cancellation reason
        if (state.isCancelled &&
            booking.cancellationReason != null &&
            booking.cancellationReason!.isNotEmpty) ...[
          Divider(
            color: colors.colorBackgroundGray,
            height: AppDimens.paddingXXL,
          ),
          _buildInfoRow(
            colors,
            icon: Icons.cancel_outlined,
            text: getString(appStr.descriptionReasonPrefix, 'description_reason_prefix')
                .replacePlaceholders({StringConstant.value: booking.cancellationReason!}),
          ),
        ],

        Divider(
          color: colors.colorBackgroundGray,
          height: AppDimens.paddingXXL,
        ),

        // Driver details section
        if (state.isDriveDetailVisible && !state.isCancelled) ...[
          _buildDriverDetails(colors, state, driver!),
          Divider(
            color: colors.colorBackgroundGray,
            height: AppDimens.paddingXXL,
          ),
        ],

        // Rating row (hide for cancelled bookings)
        if (!state.isCancelled) ...[
          _buildRatingRow(colors, state),

          Divider(
            color: colors.colorBackgroundGray,
            height: AppDimens.paddingXXL,
          ),
        ],

        // Help & safety section
        _buildHelpAndSafety(colors, booking),

        const SizedBox(height: AppDimens.paddingXXL),
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
          // Driver avatar
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

  /// Receipt and Re-book action chips
  Widget _buildActionChips(AppColorPalette colors, TripDetailState state) {
    final booking = state.booking;
    final isCourier = booking?.businessType == BusinessType.courier;
    final isFixGroup = booking?.bookingType == RideType.fixGroup.value;

    return Row(
      children: [
        if (state.canViewReceipt)
          _buildChip(
            colors,
            icon: Icons.receipt_long,
            label: getString(appStr.buttonReceipt, 'button_receipt'),
            onTap: () {
              final response = state.response;
              if (response != null) {
                context.navigateToReceipt(bookingDetailResponse: response);
              }
            },
          ),
        if (!isCourier && !isFixGroup) ...[
          if (state.canViewReceipt) const SizedBox(width: AppDimens.paddingM),
          _buildChip(
            colors,
            icon: Icons.refresh,
            label: getString(appStr.buttonReBook, 'button_re_book'),
            onTap: _onRebook,
          ),
        ],
      ],
    );
  }

  void _onRebook() {
    final state = ref.read(tripDetailViewModelProvider(_params!));
    final booking = state.booking;
    if (booking == null) return;

    final rebookData = createRebookData(booking);
    if (rebookData == null) return;

    if (rebookData.isDestinationLater || rebookData.destinations.isEmpty) {
      context.navigateToPlanRide(
        pickupAddress: rebookData.pickup,
        rideType: rebookData.rideType,
        selectedVehicleTypeId: rebookData.vehicleTypeId,
      );
    } else {
      context.navigateToChooseRide(
        pickup: rebookData.pickup,
        destinations: rebookData.destinations,
        rideType: rebookData.rideType,
        selectedVehicleTypeId: rebookData.vehicleTypeId,
      );
    }
  }

  Widget _buildChip(
    AppColorPalette colors, {
    required IconData icon,
    required String label,
    VoidCallback? onTap,
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

  /// Info row with icon and text
  Widget _buildInfoRow(
    AppColorPalette colors, {
    required IconData icon,
    required String text,
  }) {
    return Row(
      children: [
        Icon(icon, size: 22, color: colors.colorText.withValues(alpha: 0.6)),
        const SizedBox(width: AppDimens.paddingM),
        Expanded(child: AppText.body(text)),
      ],
    );
  }

  /// Driver details section
  Widget _buildDriverDetails(
    AppColorPalette colors,
    TripDetailState state,
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

  /// Rating row with star display
  Widget _buildRatingRow(AppColorPalette colors, TripDetailState state) {
    final rating = state.booking?.rating;
    final driverRate = rating?.driverRate ?? 0;

    if (state.isUserRated && driverRate > 0) {
      return Row(
        children: [
          Icon(
            Icons.star,
            size: 22,
            color: colors.colorText,
          ),
          const SizedBox(width: AppDimens.paddingM),
          AppText.body(
            getString(appStr.descriptionRated, 'description_rated')
                .replacePlaceholders({StringConstant.value: driverRate}),
          ),
          const SizedBox(width: AppDimens.paddingXS),
          ...List.generate(
            driverRate,
            (index) => Padding(
              padding: const EdgeInsets.only(right: 2),
              child: Icon(Icons.star, size: 16, color: colors.colorText),
            ),
          ),
        ],
      );
    }

    return InkWell(
      onTap: () => context.push('/feedback/${widget.bookingId}'),
      child: Row(
        children: [
          Icon(
            Icons.star_outline,
            size: 22,
            color: colors.colorText.withValues(alpha: 0.6),
          ),
          const SizedBox(width: AppDimens.paddingM),
          Expanded(
            child: AppText.body(getString(appStr.descriptionNotYetRated, 'description_not_yet_rated')),
          ),
          Icon(
            Icons.chevron_right,
            color: colors.colorText.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }

  /// Help & safety section
  Widget _buildHelpAndSafety(
      AppColorPalette colors, BookingDetails booking) {
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
          onTap: () => _showNewTicketBottomSheet(context, booking),
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

  void _showNewTicketBottomSheet(
      BuildContext context, BookingDetails booking) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.colorBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => NewTicketBottomSheet(
        bookingId: booking.id,
        uniqueId: booking.uniqueId,
        onTicketCreated: () {},
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
