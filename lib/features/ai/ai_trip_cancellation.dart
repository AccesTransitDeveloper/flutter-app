import '../../core/preferences/shared_preference_manager.dart';
import '../../data/api/response_state.dart';
import '../../data/repository/app_repository.dart';
import '../../models/requests/cancel_booking_request.dart';
import '../../models/requests/entity_detail_request.dart';
import '../../models/responses/booking/booking_detail_response.dart';
import 'ai_trip_policy.dart';

class AiCancellationReview {
  final String bookingId;
  final BookingDetailResponse details;
  final double fee;
  final String currency;
  AiCancellationReview(this.bookingId, this.details, this.fee, this.currency);
  bool get allowed => canCancelAiTrip(
    status: details.booking?.status, cancelUptoStatus: details.cancelUptoStatus,
    allowed: details.isAllowCancelBooking);
}

class AiCancellationChanged implements Exception {
  final AiCancellationReview review;
  AiCancellationChanged(this.review);
}

/// All mutations use the existing native Core client. AI receives no account
/// token, booking ID, payment details or authority to execute a cancellation.
class AiTripCancellation {
  final AppRepository repository;
  final SharedPreferenceManager preferences;
  final String? _account;
  final String? _token;

  AiTripCancellation(this.repository, this.preferences)
      : _account = preferences.getEntity()?.id,
        _token = preferences.getAuthorization();

  void assertSession() {
    if (_account == null || _token == null || !preferences.isLoggedIn() ||
        preferences.getEntity()?.id != _account ||
        preferences.getAuthorization() != _token) {
      throw StateError('Your account changed. Reopen the cancellation request.');
    }
  }

  Future<List<String>> activeBookings() async {
    assertSession();
    final response = await repository.getEntityDetail(
      EntityDetailRequest(countryCode: preferences.getEntity()?.countryCode));
    assertSession();
    if (response is! Success || response.data?.entity?.id != _account ||
        response.data?.entity?.type != 2) {
      throw StateError('Could not verify your current trips. Please retry.');
    }
    return (response.data?.entity?.bookingIds ?? <String>[])
        .where((id) => id.isNotEmpty).toSet().toList();
  }

  Future<AiCancellationReview> review(String id) async {
    final owned = await activeBookings();
    if (!owned.contains(id)) {
      throw StateError('This trip is no longer active on your account.');
    }
    final response = await repository.getBookingDetails(id);
    assertSession();
    if (response is! Success || response.data?.booking?.id != id) {
      throw StateError('Could not verify this trip. Please retry.');
    }
    final details = response.data!;
    final charges = await repository.getCancellationCharges(id);
    assertSession();
    if (charges is! Success || charges.data?.total == null ||
        !charges.data!.total!.isFinite || charges.data!.total! < 0) {
      throw StateError('Could not check the cancellation fee. No trip was cancelled.');
    }
    final currency = details.booking?.bookingInvoice?.currencySign ?? '';
    if (charges.data!.total! > 0 && currency.isEmpty) {
      throw StateError('Cancellation fee currency is unavailable. Use the trip screen.');
    }
    return AiCancellationReview(id, details, charges.data!.total!, currency);
  }

  Future<void> cancel(AiCancellationReview accepted, String reason) async {
    // Re-read ownership, eligibility and fees immediately before the mutation.
    final fresh = await review(accepted.bookingId);
    if (!fresh.allowed) {
      throw StateError('This trip cannot be cancelled at its current stage.');
    }
    if (!sameCancellationQuote(before: accepted.fee, after: fresh.fee,
        beforeStatus: accepted.details.booking?.status,
        afterStatus: fresh.details.booking?.status) ||
        fresh.currency != accepted.currency ||
        fresh.details.booking?.confirmedDriver?.id !=
            accepted.details.booking?.confirmedDriver?.id) {
      throw AiCancellationChanged(fresh);
    }
    assertSession();
    final result = await repository.cancelBooking(fresh.bookingId,
      CancelBookingRequest(bookingId: fresh.bookingId,
        cancellationReason: reason.trim()));
    assertSession();
    if (result is! Success) {
      throw StateError('Cancellation was not confirmed. Check the trip before retrying.');
    }
  }
}
