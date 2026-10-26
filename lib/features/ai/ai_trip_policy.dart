/// Pure policy shared by the native cancellation review and its tests.
bool canCancelAiTrip({required int? status, required int? cancelUptoStatus,
  required bool? allowed}) => allowed == true && status != null &&
    cancelUptoStatus != null && status <= cancelUptoStatus;

bool sameCancellationQuote({required double before, required double after,
  required int? beforeStatus, required int? afterStatus}) =>
    before.isFinite && after.isFinite && before >= 0 && after >= 0 &&
    (before - after).abs() < 0.000001 && beforeStatus == afterStatus;
