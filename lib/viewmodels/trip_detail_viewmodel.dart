import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/map/interface/map_interface.dart';
import '../core/map/models/map_types.dart';
import '../core/utils/common_utils.dart';
import '../core/utils/date_utils.dart';
import '../core/utils/invoice_util.dart';
import '../data/api/response_state.dart';
import '../data/repository/history_repository.dart';
import '../models/requests/get_vehicle_types_request.dart';
import '../models/responses/booking/booking_detail_response.dart';

/// Trip detail screen state
class TripDetailState {
  final bool isLoading;
  final String? error;
  final BookingDetailResponse? response;
  final BookingDetails? booking;

  // Formatted display fields
  final String? priceStr;
  final String? distanceStr;
  final String? dateTimeStr;
  final String? completedTimeStr;
  final String? estimatedTimeStr;

  // Flags
  final bool isCancelled;
  final bool canViewReceipt;
  final bool isDriveDetailVisible;
  final bool isUserRated;
  final List<DestinationAddress> addressList;

  const TripDetailState({
    this.isLoading = false,
    this.error,
    this.response,
    this.booking,
    this.priceStr,
    this.distanceStr,
    this.dateTimeStr,
    this.completedTimeStr,
    this.estimatedTimeStr,
    this.isCancelled = false,
    this.canViewReceipt = false,
    this.isDriveDetailVisible = false,
    this.isUserRated = false,
    this.addressList = const [],
  });

  TripDetailState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    BookingDetailResponse? response,
    BookingDetails? booking,
    String? priceStr,
    String? distanceStr,
    String? dateTimeStr,
    String? completedTimeStr,
    String? estimatedTimeStr,
    bool? isCancelled,
    bool? canViewReceipt,
    bool? isDriveDetailVisible,
    bool? isUserRated,
    List<DestinationAddress>? addressList,
  }) {
    return TripDetailState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      response: response ?? this.response,
      booking: booking ?? this.booking,
      priceStr: priceStr ?? this.priceStr,
      distanceStr: distanceStr ?? this.distanceStr,
      dateTimeStr: dateTimeStr ?? this.dateTimeStr,
      completedTimeStr: completedTimeStr ?? this.completedTimeStr,
      estimatedTimeStr: estimatedTimeStr ?? this.estimatedTimeStr,
      isCancelled: isCancelled ?? this.isCancelled,
      canViewReceipt: canViewReceipt ?? this.canViewReceipt,
      isDriveDetailVisible:
          isDriveDetailVisible ?? this.isDriveDetailVisible,
      isUserRated: isUserRated ?? this.isUserRated,
      addressList: addressList ?? this.addressList,
    );
  }
}

/// Params for TripDetailViewModel
class TripDetailParams {
  final String bookingId;
  final MapInterface mapManager;
  final int primaryColor;

  const TripDetailParams({
    required this.bookingId,
    required this.mapManager,
    required this.primaryColor,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TripDetailParams && other.bookingId == bookingId;
  }

  @override
  int get hashCode => bookingId.hashCode;
}

/// Trip detail screen ViewModel (past bookings via history API)
class TripDetailViewModel extends StateNotifier<TripDetailState> {
  final HistoryRepository _historyRepository;
  final TripDetailParams _params;

  TripDetailViewModel(this._historyRepository, this._params)
      : super(const TripDetailState()) {
    _getBookingDetails();
  }

  Future<void> _getBookingDetails() async {
    state = state.copyWith(isLoading: true);

    final response =
        await _historyRepository.getHistoryBookingDetails(_params.bookingId);

    switch (response) {
      case Success<BookingDetailResponse>():
        final data = response.data;
        final booking = data?.booking;
        if (booking == null) {
          state = state.copyWith(isLoading: false, error: '');
          return;
        }
        _processBookingDetails(data!, booking);

      case Error<BookingDetailResponse>():
        state = state.copyWith(
          isLoading: false,
          error: response.error?.message,
        );

      case Loading<BookingDetailResponse>():
        break;
    }
  }

  void _processBookingDetails(
      BookingDetailResponse data, BookingDetails booking) {
    final invoice = booking.bookingInvoice;
    final currencyDirection = invoice?.setCurrencySign ?? 1;
    final currencySign = invoice?.currencySign ?? '';
    final decimalPointValue = invoice?.decimalPointValue ?? 2;

    // Price — use bid price if bidding, otherwise actual/estimated total
    String? priceStr;
    if (booking.biddingDetail?.isBidding == true) {
      final bidPrice = (booking.biddingDetail?.finalBidPrice ?? 0) > 0
          ? booking.biddingDetail?.finalBidPrice
          : booking.biddingDetail?.customerBidPrice;
      priceStr = (bidPrice ?? 0).toDouble().applyPriceSetting(
        currencyDirection: currencyDirection,
        currencySign: currencySign,
        decimalPointValue: decimalPointValue,
      );
    } else {
      final total = invoice?.actual?.total ?? invoice?.estimated?.total;
      priceStr = total.applyPriceSetting(
        currencyDirection: currencyDirection,
        currencySign: currencySign,
        decimalPointValue: decimalPointValue,
      );
    }

    // Distance (value is in meters, convert to km or miles)
    String? distanceStr;
    final distanceInMeters =
        invoice?.actual?.distance ?? invoice?.estimated?.distance;
    if (distanceInMeters != null) {
      final distanceUnit = invoice?.distanceUnit ?? 0;
      final isMiles = distanceUnit == DistanceUnit.miles;
      final convertedDistance = isMiles
          ? distanceInMeters / 1609.344
          : distanceInMeters / 1000.0;
      final unit = isMiles ? 'mi' : 'km';
      distanceStr = '${convertedDistance.toStringAsFixed(2)} $unit';
    }

    // Estimated time (seconds → minutes)
    String? estimatedTimeStr;
    final timeInSeconds = invoice?.actual?.time ?? invoice?.estimated?.time;
    if (timeInSeconds != null && timeInSeconds > 0) {
      final minutes = (timeInSeconds / 60).ceil();
      estimatedTimeStr = '$minutes min';
    }

    // DateTime (booking time)
    String? dateTimeStr;
    if (booking.bookingTime != null) {
      final date = DateTime.fromMillisecondsSinceEpoch(booking.bookingTime!);
      dateTimeStr =
          AppDateUtils.format(date, DateFormat.dateMonthWithSpace);
    }

    // Completed time
    String? completedTimeStr;
    if (booking.completedAt != null) {
      final date = DateTime.fromMillisecondsSinceEpoch(booking.completedAt!);
      completedTimeStr =
          AppDateUtils.format(date, DateFormat.dateMonthHourMinuteFormat);
    }

    // Address list
    final addressList = <DestinationAddress>[];
    if (booking.pickupAddress != null) {
      addressList.add(booking.pickupAddress!);
    }
    if (booking.destinationAddresses != null) {
      addressList.addAll(booking.destinationAddresses!);
    }

    final isCancelled = booking.status == BookingStatus.cancelled.value;
    final hasCancellationCharge = _hasPositiveCancellationCharge(
      invoice?.actual ?? invoice?.estimated,
    );

    state = state.copyWith(
      isLoading: false,
      response: data,
      booking: booking,
      priceStr: priceStr,
      distanceStr: distanceStr,
      dateTimeStr: dateTimeStr,
      completedTimeStr: completedTimeStr,
      estimatedTimeStr: estimatedTimeStr,
      isCancelled: isCancelled,
      canViewReceipt: !isCancelled || hasCancellationCharge,
      isDriveDetailVisible: booking.confirmedDriver != null,
      isUserRated: (booking.rating?.driverRate ?? 0) > 0,
      addressList: addressList,
    );

    // Show route on map
    _showRouteOnMap(booking);
  }

  bool _hasPositiveCancellationCharge(InvoiceDetail? invoiceDetail) {
    if (invoiceDetail == null) return false;

    bool hasPositivePrice(List<PriceData>? prices) {
      for (final priceData in prices ?? const <PriceData>[]) {
        if (priceData.title == PriceType.cancellationPrice &&
            ((priceData.discountedPrice ?? priceData.price ?? 0) > 0)) {
          return true;
        }

        if (hasPositivePrice(priceData.childs)) {
          return true;
        }
      }
      return false;
    }

    return hasPositivePrice(invoiceDetail.charges) ||
        hasPositivePrice(invoiceDetail.additionalPrices) ||
        hasPositivePrice(invoiceDetail.accessibilityPrices) ||
        hasPositivePrice(invoiceDetail.taxPrices);
  }

  // TODO: Extract shared map route logic (duplicated in UpcomingTripDetailViewModel and ActivityScreen)
  void _showRouteOnMap(BookingDetails booking) {
    final mapManager = _params.mapManager;
    final primaryColor = _params.primaryColor;

    // Markers
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

    mapManager.setMarkers(markers);

    // Polyline from direction path
    final directionPath =
        booking.bookingInvoice?.actual?.directionPath ??
        booking.bookingInvoice?.estimated?.directionPath;
    if (directionPath != null && directionPath.isNotEmpty) {
      mapManager.setPolyline(MapPolyline.fromEncoded(
        encoded: directionPath,
        color: primaryColor,
      ));
    }

    // Fit camera to show all points
    if (boundsPoints.isNotEmpty) {
      mapManager.fitBounds(boundsPoints, padding: 80);
    }
  }
}

/// Provider for TripDetailViewModel
final tripDetailViewModelProvider = StateNotifierProvider.autoDispose
    .family<TripDetailViewModel, TripDetailState, TripDetailParams>(
        (ref, params) {
  final historyRepository = ref.watch(historyRepositoryProvider);
  return TripDetailViewModel(historyRepository, params);
});
