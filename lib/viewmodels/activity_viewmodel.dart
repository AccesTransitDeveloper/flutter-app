import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/common_utils.dart';
import '../core/utils/date_utils.dart';
import '../data/api/response_state.dart';
import '../data/repository/app_repository.dart';
import '../data/repository/history_repository.dart';
import '../models/responses/booking/booking_detail_response.dart';
import '../models/responses/booking/booking_history_response.dart';
import '../models/responses/booking/my_bookings_response.dart';

/// Activity screen state
class ActivityState {
  // Past bookings
  final bool isLoading;
  final bool isDataLoading;
  final Map<String, List<Bookings>> bookingHistoryList;
  final List<Bookings> previousBookingList;
  final bool isDataNotFound;
  final int selectedFilter;
  final int previousSelectedFilter;
  final bool showDateField;
  final String fromDate;
  final String toDate;
  final int? fromDateTimeStamp;
  final int? toDateTimeStamp;
  final String? error;

  // Upcoming bookings
  final bool isUpcomingLoading;
  final List<MyBooking> upcomingBookings;
  final String? upcomingError;

  // Featured card map data
  final BookingDetails? featuredBookingDetail;

  // Re-book
  final String? rebookLoadingId;
  final BookingDetailResponse? rebookData;

  const ActivityState({
    this.isLoading = false,
    this.isDataLoading = false,
    this.bookingHistoryList = const {},
    this.previousBookingList = const [],
    this.isDataNotFound = false,
    this.selectedFilter = HistoryFilterType.last7Days,
    this.previousSelectedFilter = HistoryFilterType.last7Days,
    this.showDateField = false,
    this.fromDate = '',
    this.toDate = '',
    this.fromDateTimeStamp,
    this.toDateTimeStamp,
    this.error,
    this.isUpcomingLoading = false,
    this.upcomingBookings = const [],
    this.upcomingError,
    this.featuredBookingDetail,
    this.rebookLoadingId,
    this.rebookData,
  });

  ActivityState copyWith({
    bool? isLoading,
    bool? isDataLoading,
    Map<String, List<Bookings>>? bookingHistoryList,
    List<Bookings>? previousBookingList,
    bool? isDataNotFound,
    int? selectedFilter,
    int? previousSelectedFilter,
    bool? showDateField,
    String? fromDate,
    String? toDate,
    int? fromDateTimeStamp,
    int? toDateTimeStamp,
    String? error,
    bool clearError = false,
    bool clearFromDateTimeStamp = false,
    bool clearToDateTimeStamp = false,
    bool? isUpcomingLoading,
    List<MyBooking>? upcomingBookings,
    String? upcomingError,
    bool clearUpcomingError = false,
    BookingDetails? featuredBookingDetail,
    String? rebookLoadingId,
    bool clearRebookLoadingId = false,
    BookingDetailResponse? rebookData,
    bool clearRebookData = false,
  }) {
    return ActivityState(
      isLoading: isLoading ?? this.isLoading,
      isDataLoading: isDataLoading ?? this.isDataLoading,
      bookingHistoryList: bookingHistoryList ?? this.bookingHistoryList,
      previousBookingList: previousBookingList ?? this.previousBookingList,
      isDataNotFound: isDataNotFound ?? this.isDataNotFound,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      previousSelectedFilter:
          previousSelectedFilter ?? this.previousSelectedFilter,
      showDateField: showDateField ?? this.showDateField,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      fromDateTimeStamp: clearFromDateTimeStamp
          ? null
          : (fromDateTimeStamp ?? this.fromDateTimeStamp),
      toDateTimeStamp: clearToDateTimeStamp
          ? null
          : (toDateTimeStamp ?? this.toDateTimeStamp),
      error: clearError ? null : (error ?? this.error),
      isUpcomingLoading: isUpcomingLoading ?? this.isUpcomingLoading,
      upcomingBookings: upcomingBookings ?? this.upcomingBookings,
      upcomingError: clearUpcomingError
          ? null
          : (upcomingError ?? this.upcomingError),
      featuredBookingDetail:
          featuredBookingDetail ?? this.featuredBookingDetail,
      rebookLoadingId: clearRebookLoadingId
          ? null
          : (rebookLoadingId ?? this.rebookLoadingId),
      rebookData:
          clearRebookData ? null : (rebookData ?? this.rebookData),
    );
  }
}

/// Activity screen ViewModel
class ActivityViewModel extends StateNotifier<ActivityState> {
  final HistoryRepository _historyRepository;
  final AppRepository _appRepository;

  // Past bookings pagination
  int _pageNumber = 1;
  final int _limit = 10;
  int _maxItemCount = 999999;
  int _fetchedItemCount = 0;
  String _startDate = '';
  String _endDate = '';
  bool _isFirstCall = true;

  ActivityViewModel(this._historyRepository, this._appRepository)
      : super(const ActivityState()) {
    _setInitialDates();
    _getBookingsHistory();
    _getMyBookings();
  }

  // ─── Upcoming bookings ───

  /// Fetches active/upcoming bookings from API
  Future<void> _getMyBookings() async {
    state = state.copyWith(isUpcomingLoading: true);

    final response = await _appRepository.getMyBookings();

    switch (response) {
      case Success<MyBookingsResponse>():
        final bookings = response.data?.bookings ?? [];
        state = state.copyWith(
          isUpcomingLoading: false,
          upcomingBookings: _createUpcomingList(bookings),
        );

      case Error<MyBookingsResponse>():
        state = state.copyWith(
          isUpcomingLoading: false,
          upcomingBookings: [],
          upcomingError: response.error?.message,
        );

      case Loading<MyBookingsResponse>():
        break;
    }
  }

  /// Transforms raw bookings into formatted display items
  List<MyBooking> _createUpcomingList(List<MyBooking> bookings) {
    final filtered = bookings
        .where((b) => b.businessType == BusinessType.taxi)
        .toList();

    final formatted = filtered.map((booking) {
      // Format price
      String? priceStr;
      final invoice = booking.bookingInvoice;
      if (booking.biddingDetail?.isBidding == true) {
        final bidPrice = (booking.biddingDetail?.finalBidPrice ?? 0) > 0
            ? booking.biddingDetail?.finalBidPrice
            : booking.biddingDetail?.customerBidPrice;
        priceStr = (bidPrice ?? 0).toDouble().applyPriceSetting(
              currencyDirection: invoice?.setCurrencySign ?? 1,
              currencySign: invoice?.currencySign ?? '',
              decimalPointValue: invoice?.decimalPointValue ?? 2,
            );
      } else {
        priceStr = invoice?.estimated?.total.applyPriceSetting(
          currencyDirection: invoice.setCurrencySign ?? 1,
          currencySign: invoice.currencySign ?? '',
          decimalPointValue: invoice.decimalPointValue ?? 2,
        );
      }

      // Format dateTime & time
      String? dateTimeStr;
      String? timeStr;
      if (booking.bookingTime != null) {
        final date = DateTime.fromMillisecondsSinceEpoch(booking.bookingTime!);
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final tomorrow = today.add(const Duration(days: 1));
        final bookingDay = DateTime(date.year, date.month, date.day);

        if (bookingDay == today) {
          dateTimeStr = 'Today';
        } else if (bookingDay == tomorrow) {
          dateTimeStr = 'Tomorrow';
        } else {
          dateTimeStr =
              AppDateUtils.format(date, DateFormat.dateFormatWithSpace);
        }

        timeStr = AppDateUtils.format(date, DateFormat.hourMinuteFormat);
      }

      return booking.copyWith(
        priceStr: priceStr,
        dateTimeStr: dateTimeStr,
        timeStr: timeStr,
      );
    }).toList();

    // Sort by bookingTime ascending (earliest first)
    formatted.sort(
        (a, b) => (a.bookingTime ?? 0).compareTo(b.bookingTime ?? 0));

    return formatted;
  }

  // ─── Past bookings ───

  /// Sets initial date range to last 7 days
  void _setInitialDates() {
    final now = DateTime.now();
    _endDate = AppDateUtils.toApiDateString(now);
    _startDate =
        AppDateUtils.toApiDateString(now.subtract(const Duration(days: 7)));
  }

  /// Fetches booking history from API
  Future<void> _getBookingsHistory() async {
    if (_isFirstCall) {
      state = state.copyWith(isDataLoading: true);
    }
    state = state.copyWith(isLoading: true);

    final response = await _historyRepository.getBookingHistory(
      startDate: _startDate,
      endDate: _endDate,
      page: _pageNumber,
      limit: _limit,
    );

    switch (response) {
      case Success<BookingHistoryResponse>():
        _pageNumber++;
        _maxItemCount = response.data?.dataCount ?? 999999;

        final newBookings = response.data?.bookings ?? [];
        final tempList = <Bookings>[
          ...state.previousBookingList,
          ...newBookings,
        ];
        _fetchedItemCount = tempList.length;

        // Stop pagination if API returned no new items
        if (newBookings.isEmpty) {
          _maxItemCount = _fetchedItemCount;
        }

        final historyMap = _filterBookingHistoryList(tempList);
        state = state.copyWith(
          bookingHistoryList: historyMap,
          previousBookingList: tempList,
          isDataNotFound: false,
          isLoading: false,
        );
        if (_isFirstCall) {
          state = state.copyWith(isDataLoading: false);
          _isFirstCall = false;

          // Fetch details for the featured (first) booking's map
          final firstBooking = historyMap.values
              .expand((list) => list)
              .firstOrNull;
          if (firstBooking?.id != null) {
            _getFeaturedBookingDetail(firstBooking!.id!);
          }
        }

      case Error<BookingHistoryResponse>():
        // Only clear data if no previous bookings were loaded (first page error).
        // During pagination, keep existing bookings visible.
        if (state.previousBookingList.isEmpty) {
          state = state.copyWith(
            bookingHistoryList: {},
            previousBookingList: [],
            isDataNotFound: true,
            isLoading: false,
            error: response.error?.message,
          );
        } else {
          state = state.copyWith(
            isLoading: false,
          );
          // Stop further pagination attempts after an error
          _maxItemCount = _fetchedItemCount;
        }
        if (_isFirstCall) {
          state = state.copyWith(isDataLoading: false);
          _isFirstCall = false;
        }

      case Loading<BookingHistoryResponse>():
        break;
    }
  }

  /// Fetches full booking details for the featured card map
  Future<void> _getFeaturedBookingDetail(String bookingId) async {
    final response =
        await _historyRepository.getHistoryBookingDetails(bookingId);

    switch (response) {
      case Success<BookingDetailResponse>():
        final booking = response.data?.booking;
        if (booking != null) {
          state = state.copyWith(featuredBookingDetail: booking);
        }

      case Error<BookingDetailResponse>():
        break;

      case Loading<BookingDetailResponse>():
        break;
    }
  }

  /// Groups bookings by date and formats price/time
  LinkedHashMap<String, List<Bookings>> _filterBookingHistoryList(
    List<Bookings> bookings,
  ) {
    final historyMap = LinkedHashMap<String, List<Bookings>>();
    final sorted = List<Bookings>.from(bookings)
      ..sort((a, b) => (b.completedAt ?? 0).compareTo(a.completedAt ?? 0));

    for (final booking in sorted) {
      if (booking.completedAt == null) continue;
      if (booking.businessType != BusinessType.taxi) continue;

      final date = DateTime.fromMillisecondsSinceEpoch(
        booking.completedAt!,
      );
      final bookingDate =
          AppDateUtils.format(date, DateFormat.dateFormatWithSpace);

      final dateStr = AppDateUtils.format(date, DateFormat.dateMonthWithSpace);
      final timeStr = AppDateUtils.format(date, DateFormat.hourMinuteFormat);

      final formattedBooking = booking.copyWith(
        bookingPrice: booking.total.applyPriceSetting(
          currencyDirection: booking.setCurrencySign ?? 1,
          currencySign: booking.currencySign ?? '',
          decimalPointValue: booking.decimalPointValue ?? 2,
        ),
        completedTimeValue: '$dateStr • $timeStr',
      );

      if (historyMap.containsKey(bookingDate)) {
        historyMap[bookingDate]!.add(formattedBooking);
      } else {
        historyMap[bookingDate] = [formattedBooking];
      }
    }
    return historyMap;
  }

  /// Loads next page of bookings (pagination)
  void loadNextPage() {
    if (_fetchedItemCount < _maxItemCount && !state.isLoading) {
      _getBookingsHistory();
    }
  }

  /// Resets pagination and booking data
  void _resetData() {
    _pageNumber = 1;
    _maxItemCount = 999999;
    _fetchedItemCount = 0;
    state = state.copyWith(previousBookingList: []);
  }

  /// Selects a filter option
  void selectFilter(int index) {
    _startDate = '';
    _endDate = '';
    state = state.copyWith(
      selectedFilter: index,
      fromDate: '',
      toDate: '',
      clearFromDateTimeStamp: true,
      clearToDateTimeStamp: true,
      showDateField: index == HistoryFilterType.specificDates,
    );
  }

  /// Applies the selected filter
  void applySelectedFilter() {
    if (state.selectedFilter != state.previousSelectedFilter) {
      _resetData();
      _applyFilter(state.selectedFilter);
    }
  }

  /// Calculates date range and fetches data for the selected filter
  void _applyFilter(int filterType) {
    final now = DateTime.now();

    switch (filterType) {
      case HistoryFilterType.last7Days:
        _endDate = AppDateUtils.toApiDateString(now);
        _startDate = AppDateUtils.toApiDateString(
          now.subtract(const Duration(days: 7)),
        );
        state = state.copyWith(previousSelectedFilter: filterType);
        _getBookingsHistory();

      case HistoryFilterType.currentMonth:
        _endDate = AppDateUtils.toApiDateString(now);
        _startDate = AppDateUtils.toApiDateString(
          DateTime(now.year, now.month, 1),
        );
        state = state.copyWith(previousSelectedFilter: filterType);
        _getBookingsHistory();

      case HistoryFilterType.previousMonth:
        final prevMonth = DateTime(now.year, now.month - 1, 1);
        _startDate = AppDateUtils.toApiDateString(prevMonth);
        _endDate = AppDateUtils.toApiDateString(
          DateTime(now.year, now.month, 0),
        );
        state = state.copyWith(previousSelectedFilter: filterType);
        _getBookingsHistory();

      case HistoryFilterType.previous6Months:
        _endDate = AppDateUtils.toApiDateString(now);
        _startDate = AppDateUtils.toApiDateString(
          DateTime(now.year, now.month - 6, now.day),
        );
        state = state.copyWith(previousSelectedFilter: filterType);
        _getBookingsHistory();

      case HistoryFilterType.specificDates:
        if (_startDate.isEmpty || _endDate.isEmpty) {
          state = state.copyWith(error: 'Please enter both dates');
        } else {
          _getBookingsHistory();
        }
    }
  }

  // ─── Re-book ───

  /// Fetches full booking detail for re-book navigation
  Future<void> fetchBookingForRebook(String bookingId) async {
    state = state.copyWith(rebookLoadingId: bookingId);

    final response =
        await _historyRepository.getHistoryBookingDetails(bookingId);

    switch (response) {
      case Success<BookingDetailResponse>():
        state = state.copyWith(
          clearRebookLoadingId: true,
          rebookData: response.data,
        );

      case Error<BookingDetailResponse>():
        state = state.copyWith(clearRebookLoadingId: true);

      case Loading<BookingDetailResponse>():
        break;
    }
  }

  /// Clears rebook data after navigation
  void clearRebookData() {
    state = state.copyWith(clearRebookData: true, clearRebookLoadingId: true);
  }

  /// Selects a date for from/to field
  void selectDate(int timestamp, bool isFromDate) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final formattedDisplay = AppDateUtils.format(
      date,
      DateFormat.dateOnlyFormat,
    );
    final formattedApi = AppDateUtils.toApiDateString(date);

    if (isFromDate) {
      _startDate = formattedApi;
      state = state.copyWith(
        fromDate: formattedDisplay,
        fromDateTimeStamp: timestamp,
      );
    } else {
      _endDate = formattedApi;
      state = state.copyWith(
        toDate: formattedDisplay,
        toDateTimeStamp: timestamp,
      );
    }
  }
}

/// Provider for ActivityViewModel
final activityViewModelProvider =
    StateNotifierProvider.autoDispose<ActivityViewModel, ActivityState>((ref) {
  final historyRepository = ref.watch(historyRepositoryProvider);
  final appRepository = ref.watch(appRepositoryProvider);
  return ActivityViewModel(historyRepository, appRepository);
});
