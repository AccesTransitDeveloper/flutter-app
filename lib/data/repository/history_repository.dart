import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../../core/providers/app_providers.dart';
import '../../models/responses/booking/booking_detail_response.dart';
import '../../models/responses/booking/booking_history_response.dart';
import '../api/api_client.dart';
import '../api/response_state.dart';

class HistoryRepository {
  final ApiClient apiClient;

  HistoryRepository(this.apiClient);

  Future<ResponseState<BookingHistoryResponse>> getBookingHistory({
    required String startDate,
    required String endDate,
    required int page,
    required int limit,
  }) async {
    return apiClient.get<BookingHistoryResponse>(
      HistoryApiEndpoint.bookingHistory,
      queryParameters: {
        ApiParams.startDate: startDate,
        ApiParams.endDate: endDate,
        ApiParams.page: page.toString(),
        ApiParams.limit: limit.toString(),
      },
      fromJsonT: (json) => BookingHistoryResponse.fromJson(json),
    );
  }

  Future<ResponseState<BookingDetailResponse>> getHistoryBookingDetails(
      String bookingId) async {
    return apiClient.get<BookingDetailResponse>(
      '${HistoryApiEndpoint.bookingHistory}/$bookingId',
      fromJsonT: (json) => BookingDetailResponse.fromJson(json),
    );
  }
}

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  final apiClient = ref.watch(historyApiClientProvider);
  return HistoryRepository(apiClient);
});
