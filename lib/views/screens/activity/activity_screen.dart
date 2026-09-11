import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/map/interface/map_interface.dart';
import '../../../core/map/widgets/map_host.dart';
import '../../../core/map/models/map_types.dart';
import '../../../core/map/providers/map_provider.dart';
import '../../../core/router/app_navigation.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/rebook_utils.dart';
import '../../../models/responses/booking/booking_detail_response.dart';
import '../../../viewmodels/activity_viewmodel.dart';
import '../../item/past_activity_item.dart';
import '../../item/upcoming_activity_item.dart';
import '../../widgets/app_text.dart';
import '../../widgets/app_button.dart';

class ActivityScreen extends ConsumerStatefulWidget {
  final bool showBackButton;
  final VoidCallback? onNavigateToHome;

  const ActivityScreen({super.key, this.showBackButton = true, this.onNavigateToHome});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  final ScrollController _scrollController = ScrollController();
  late final MapInterface _featuredMapManager;
  bool _isMapConfigured = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _featuredMapManager = ref.read(mapManagerProvider)();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _featuredMapManager.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      ref.read(activityViewModelProvider.notifier).loadNextPage();
    }
  }

  void _configureMap(BookingDetails booking) {
    if (_isMapConfigured) return;
    _isMapConfigured = true;

    final primaryColor = context.colors.colorPrimary.toARGB32();
    final markers = <MapMarker>[];
    final boundsPoints = <LatLng>[];

    // Pickup marker
    final pickup = booking.pickupAddress;
    if (pickup != null && pickup.latitude != null && pickup.longitude != null) {
      final pos = LatLng(pickup.latitude!, pickup.longitude!);
      markers.add(MapMarker(
        id: 'pickup',
        position: pos,
        title: '',
        snippet: pickup.address,
        iconAsset: 'assets/images/ic_pickup.png',
        iconWidth: 32,
        iconHeight: 32,
        iconColor: primaryColor,
      ));
      boundsPoints.add(pos);
    }

    // Destination markers
    final destinations = booking.destinationAddresses ?? [];
    for (int i = 0; i < destinations.length; i++) {
      final dest = destinations[i];
      if (dest.latitude != null && dest.longitude != null) {
        final pos = LatLng(dest.latitude!, dest.longitude!);
        final isLast = i == destinations.length - 1;
        markers.add(MapMarker(
          id: 'destination_$i',
          position: pos,
          title: '',
          snippet: dest.address,
          iconAsset: isLast ? 'assets/images/ic_drop_off.png' : null,
          iconWidth: isLast ? 32 : 20,
          iconHeight: isLast ? 32 : 20,
          iconColor: primaryColor,
          stopNumber: isLast ? null : i + 1,
        ));
        boundsPoints.add(pos);
      }
    }

    _featuredMapManager.setMarkers(markers);

    // Polyline from direction path
    final directionPath =
        booking.bookingInvoice?.actual?.directionPath ??
        booking.bookingInvoice?.estimated?.directionPath;
    if (directionPath != null && directionPath.isNotEmpty) {
      _featuredMapManager.setPolyline(MapPolyline.fromEncoded(
        encoded: directionPath,
        color: primaryColor,
      ));
    }

    if (boundsPoints.isNotEmpty) {
      _featuredMapManager.fitBounds(boundsPoints, padding: 80);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = ref.watch(activityViewModelProvider);

    // Configure map when featured booking detail arrives
    ref.listen(activityViewModelProvider, (prev, next) {
      if (next.featuredBookingDetail != null &&
          prev?.featuredBookingDetail == null) {
        _configureMap(next.featuredBookingDetail!);
      }
    });

    // Navigate when rebook data arrives
    ref.listen(
      activityViewModelProvider.select((s) => s.rebookData),
      (prev, next) {
        if (next != null) {
          ref.read(activityViewModelProvider.notifier).clearRebookData();
          _navigateForRebook(next);
        }
      },
    );

    // Flatten all formatted bookings
    final allBookings = state.bookingHistoryList.values
        .expand((list) => list)
        .toList();

    // 2 fixed items (upcoming, past label) + booking items + loading
    final hasBookings = !state.isDataLoading &&
        !state.isDataNotFound &&
        allBookings.isNotEmpty;
    final bookingCount = hasBookings ? allBookings.length : 0;
    // +1 for empty/loading state when no bookings, or loading indicator at bottom
    final extraCount = state.isDataLoading ||
            (!hasBookings && !state.isDataLoading) ||
            state.isLoading
        ? 1
        : 0;
    final itemCount = 2 + bookingCount + extraCount;

    final content = SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fixed header
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimens.padding,
              AppDimens.padding,
              AppDimens.padding,
              0,
            ),
            child: Row(
              children: [
                if (widget.showBackButton) ...[
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Icon(Icons.arrow_back, size: 24),
                  ),
                  const SizedBox(width: AppDimens.paddingM),
                ],
                AppText.heading(getString(appStr.headingActivity, 'heading_activity')),
              ],
            ),
          ),

          // Scrollable content
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.padding),
              itemCount: itemCount,
              itemBuilder: (context, index) {
                // 0: Upcoming section
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(top: AppDimens.paddingXL),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText.title(
                          getString(appStr.headingUpcoming, 'heading_upcoming'),
                          color: colors.colorText,
                          fontWeight: FontWeight.w600,
                        ),
                        const SizedBox(height: AppDimens.paddingM),
                        _buildUpcomingSection(state, colors),
                      ],
                    ),
                  );
                }

                // 1: Past label + Filter button
                if (index == 1) {
                  return Padding(
                    padding: const EdgeInsets.only(top: AppDimens.paddingXL),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AppText.title(
                          getString(appStr.headingPast, 'heading_past'),
                          color: colors.colorText,
                          fontWeight: FontWeight.w600,
                        ),
                        AppFilterButton(
                          onPressed: () => _showFilterBottomSheet(context),
                          size: 40,
                          hasShadow: false,
                          iconColor: colors.colorText,
                        ),
                      ],
                    ),
                  );
                }

                // 2+: Booking items or states
                final bookingIndex = index - 2;

          // Data loading shimmer
          if (state.isDataLoading && bookingIndex == 0) {
            return _buildPastShimmer(colors);
          }

          // Empty state
          if (!hasBookings && !state.isDataLoading && bookingIndex == 0) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                  vertical: AppDimens.paddingXL),
              child: Column(
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: colors.colorText.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: AppDimens.padding),
                  AppText.body(
                    getString(appStr.descriptionNoPastBookingsFound, 'description_no_past_bookings_found'),
                    color: colors.colorText.withValues(alpha: 0.5),
                  ),
                ],
              ),
            );
          }

          // Booking items
          if (bookingIndex < bookingCount) {
            final booking = allBookings[bookingIndex];

            // First item as featured card
            if (bookingIndex == 0) {
              return Padding(
                padding: const EdgeInsets.only(top: AppDimens.paddingM),
                child: PastActivityFeaturedCard(
                  booking: booking,
                  isRebookLoading: state.rebookLoadingId == booking.id,
                  mapWidget: IgnorePointer(
                    child: MapHost(manager: _featuredMapManager),
                  ),
                  onTap: () =>
                      context.push('/trip-detail/${booking.id ?? ''}'),
                  onRebook: () => _onRebook(booking.id),
                ),
              );
            }

            return Column(
              children: [
                PastActivityItem(
                  booking: booking,
                  isRebookLoading: state.rebookLoadingId == booking.id,
                  onTap: () =>
                      context.push('/trip-detail/${booking.id ?? ''}'),
                  onRebook: () => _onRebook(booking.id),
                ),
                if (bookingIndex < bookingCount - 1)
                  Divider(color: colors.colorBackgroundGray, height: 1),
              ],
            );
          }

          // Pagination loading indicator
          if (state.isLoading && hasBookings) {
            return const Padding(
              padding: EdgeInsets.all(AppDimens.padding),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );

    if (widget.showBackButton) {
      return Scaffold(body: content);
    }
    return content;
  }

  Widget _buildShimmerBox({
    double? width,
    required double height,
    double radius = AppDimens.paddingXS,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  Widget _buildUpcomingShimmer(AppColorPalette colors) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: Container(
        padding: const EdgeInsets.all(AppDimens.padding),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildShimmerBox(width: 80, height: 12),
                  const SizedBox(height: AppDimens.paddingS),
                  _buildShimmerBox(width: 140, height: 20),
                  const SizedBox(height: AppDimens.paddingS),
                  _buildShimmerBox(width: 120, height: 12),
                  const SizedBox(height: AppDimens.paddingXS),
                  _buildShimmerBox(width: 100, height: 12),
                ],
              ),
            ),
            const SizedBox(width: AppDimens.paddingM),
            _buildShimmerBox(width: 64, height: 64, radius: AppDimens.paddingS),
          ],
        ),
      ),
    );
  }

  Widget _buildPastShimmer(AppColorPalette colors) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: Column(
        children: [
          // Featured card shimmer
          Padding(
            padding: const EdgeInsets.only(top: AppDimens.paddingM),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppDimens.paddingM),
                color: Colors.white,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Map placeholder
                  Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppDimens.paddingM),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppDimens.padding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildShimmerBox(width: 120, height: 16),
                        const SizedBox(height: AppDimens.paddingS),
                        _buildShimmerBox(width: 160, height: 12),
                        const SizedBox(height: AppDimens.paddingXS),
                        _buildShimmerBox(width: 100, height: 12),
                        const SizedBox(height: AppDimens.paddingM),
                        _buildShimmerBox(width: 80, height: 32, radius: AppDimens.paddingXL),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // List item shimmers
          for (int i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppDimens.paddingM),
              child: Row(
                children: [
                  _buildShimmerBox(width: 60, height: 60, radius: AppDimens.paddingS),
                  const SizedBox(width: AppDimens.paddingS),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildShimmerBox(width: 100, height: 14),
                        const SizedBox(height: AppDimens.paddingXS),
                        _buildShimmerBox(width: 140, height: 12),
                        const SizedBox(height: AppDimens.paddingXS),
                        _buildShimmerBox(width: 80, height: 12),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppDimens.paddingS),
                  _buildShimmerBox(width: 70, height: 32, radius: AppDimens.paddingXL),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _onRebook(String? bookingId) {
    if (bookingId == null || bookingId.isEmpty) return;
    ref.read(activityViewModelProvider.notifier).fetchBookingForRebook(bookingId);
  }

  void _navigateForRebook(BookingDetailResponse response) {
    final booking = response.booking;
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

  /// Upcoming trips section
  Widget _buildUpcomingSection(ActivityState state, AppColorPalette colors) {
    // Loading shimmer
    if (state.isUpcomingLoading) {
      return _buildUpcomingShimmer(colors);
    }

    // Empty state
    if (state.upcomingBookings.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppDimens.padding),
        decoration: BoxDecoration(
          color: colors.colorBackgroundGray,
          borderRadius: BorderRadius.circular(AppDimens.paddingM),
        ),
        child: GestureDetector(
          onTap: widget.onNavigateToHome ?? () => context.navigateToHome(),
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.body(
                      getString(appStr.descriptionNoUpcomingTrips, 'description_no_upcoming_trips'),
                      fontWeight: FontWeight.w500,
                    ),
                    const SizedBox(height: AppDimens.paddingXS),
                    AppText.caption(
                      getString(appStr.descriptionReserveYourRide, 'description_reserve_your_ride'),
                      color: colors.colorText.withValues(alpha: 0.5),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.calendar_today,
                size: 32,
                color: colors.colorText.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      );
    }

    // Upcoming bookings list
    return Column(
      children: state.upcomingBookings.map((booking) {
        final isSchedule =
            booking.bookingTags?.contains('SCHEDULE') == true;
        final scheduleLabel = isSchedule
            ? (booking.dateTimeStr ?? '')
            : BookingStatus.fromValue(booking.status).name;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppDimens.paddingS),
          child: UpcomingActivityItem(
            vehicleTypeName: booking.vehicleType?.name ?? '',
            scheduleLabel: scheduleLabel,
            bookingId: booking.uniqueId,
            dateTime: booking.timeStr ?? '',
            vehicleImageUrl: booking.vehicleType?.imageUrl,
            onTap: () async {
              await context.push('/upcoming-trip-detail/${booking.id ?? ''}');
              ref.invalidate(activityViewModelProvider);
            },
          ),
        );
      }).toList(),
    );
  }

  /// Show filter bottom sheet
  void _showFilterBottomSheet(BuildContext context) {
    final colors = context.colors;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.colorBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => Consumer(
        builder: (context, ref, _) {
          final state = ref.watch(activityViewModelProvider);
          final viewModel = ref.read(activityViewModelProvider.notifier);
          return _FilterBottomSheet(
            colors: colors,
            selectedFilter: state.selectedFilter,
            showDateField: state.showDateField,
            fromDate: state.fromDate,
            toDate: state.toDate,
            fromDateTimeStamp: state.fromDateTimeStamp,
            toDateTimeStamp: state.toDateTimeStamp,
            onFilterSelected: (index) => viewModel.selectFilter(index),
            onApply: () {
              viewModel.applySelectedFilter();
              Navigator.pop(sheetContext);
            },
            onCancel: () => Navigator.pop(sheetContext),
            onFromDateTap: () => _showDatePicker(
              context: sheetContext,
              isFromDate: true,
              initialDate: state.fromDateTimeStamp,
            ),
            onToDateTap: () => _showDatePicker(
              context: sheetContext,
              isFromDate: false,
              initialDate: state.toDateTimeStamp,
            ),
          );
        },
      ),
    );
  }

  void _showDatePicker({
    required BuildContext context,
    required bool isFromDate,
    int? initialDate,
  }) async {
    final now = DateTime.now();
    final initial = initialDate != null
        ? DateTime.fromMillisecondsSinceEpoch(initialDate)
        : now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: now,
    );

    if (picked != null) {
      ref
          .read(activityViewModelProvider.notifier)
          .selectDate(picked.millisecondsSinceEpoch, isFromDate);
    }
  }
}

/// Filter bottom sheet widget with date-range radio buttons
class _FilterBottomSheet extends StatelessWidget {
  final AppColorPalette colors;
  final int selectedFilter;
  final bool showDateField;
  final String fromDate;
  final String toDate;
  final int? fromDateTimeStamp;
  final int? toDateTimeStamp;
  final ValueChanged<int> onFilterSelected;
  final VoidCallback onApply;
  final VoidCallback onCancel;
  final VoidCallback onFromDateTap;
  final VoidCallback onToDateTap;

  const _FilterBottomSheet({
    required this.colors,
    required this.selectedFilter,
    required this.showDateField,
    required this.fromDate,
    required this.toDate,
    this.fromDateTimeStamp,
    this.toDateTimeStamp,
    required this.onFilterSelected,
    required this.onApply,
    required this.onCancel,
    required this.onFromDateTap,
    required this.onToDateTap,
  });

  List<String> get _filterOptions => [
    getString(appStr.descriptionLastSevenDays, 'description_last_seven_days'),
    getString(appStr.descriptionCurrentMonth, 'description_current_month'),
    getString(appStr.descriptionPreviousMonth, 'description_previous_month'),
    getString(appStr.descriptionPreviousSixMonth, 'description_previous_six_month'),
    getString(appStr.descriptionSpecificDates, 'description_specific_dates'),
  ];

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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Header
            Center(
              child: AppText.title(
                getString(appStr.headingFilter, 'heading_filter'),
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: AppDimens.paddingM),
            Divider(color: colors.colorBackgroundGray),
            const SizedBox(height: AppDimens.paddingM),

            // Radio options
            RadioGroup<int>(
              groupValue: selectedFilter,
              onChanged: (value) {
                if (value != null) onFilterSelected(value);
              },
              child: Column(
                children: List.generate(_filterOptions.length, (index) {
                  return InkWell(
                    onTap: () => onFilterSelected(index),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppDimens.paddingS,
                      ),
                      child: Row(
                        children: [
                          Radio<int>(
                            value: index,
                          ),
                          const SizedBox(width: AppDimens.paddingS),
                          AppText.body(_filterOptions[index]),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Date fields for "Specific dates"
            if (showDateField) ...[
              const SizedBox(height: AppDimens.paddingM),
              Row(
                children: [
                  Expanded(
                    child: _buildDateField(
                      label: getString(appStr.hintFrom, 'hint_from'),
                      value: fromDate,
                      onTap: onFromDateTap,
                    ),
                  ),
                  const SizedBox(width: AppDimens.paddingM),
                  Expanded(
                    child: _buildDateField(
                      label: getString(appStr.hintTo, 'hint_to'),
                      value: toDate,
                      onTap: onToDateTap,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: AppDimens.paddingXL),

            // Apply + Cancel buttons
            Row(
              children: [
                Expanded(
                  child: AppFilledButton(
                    text: getString(appStr.buttonApply, 'button_apply'),
                    onPressed: onApply,
                  ),
                ),
                const SizedBox(width: AppDimens.paddingM),
                Expanded(
                  child: AppOutlinedButton(
                    text: getString(appStr.buttonCancel, 'button_cancel'),
                    onPressed: onCancel,
                  ),
                ),
              ],
            ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingM,
          vertical: AppDimens.paddingM,
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: colors.colorText.withValues(alpha: 0.2),
          ),
          borderRadius: BorderRadius.circular(AppDimens.paddingS),
        ),
        child: Row(
          children: [
            Expanded(
              child: AppText.body(
                value.isNotEmpty ? value : label,
                color: value.isNotEmpty
                    ? colors.colorText
                    : colors.colorText.withValues(alpha: 0.4),
              ),
            ),
            Icon(
              Icons.calendar_today,
              size: 18,
              color: colors.colorText.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
