import '../lib/features/ai/ai_trip_policy.dart';
import '../lib/features/booking/cancellation_reasons.dart';

void check(bool value) { if (!value) throw StateError('Policy check failed'); }
void main() {
  check(canCancelAiTrip(status: 2, cancelUptoStatus: 3, allowed: true));
  check(!canCancelAiTrip(status: null, cancelUptoStatus: 3, allowed: true));
  check(!canCancelAiTrip(status: 4, cancelUptoStatus: 3, allowed: true));
  check(!canCancelAiTrip(status: 2, cancelUptoStatus: 3, allowed: false));
  check(sameCancellationQuote(before: 5, after: 5, beforeStatus: 2, afterStatus: 2));
  check(!sameCancellationQuote(before: 5, after: 6, beforeStatus: 2, afterStatus: 2));
  check(!sameCancellationQuote(before: 5, after: 5, beforeStatus: 2, afterStatus: 3));
  check(!sameCancellationQuote(before: double.nan, after: 5, beforeStatus: 2, afterStatus: 2));
  check(commonCancellationReasons('en').join('|') ==
    'The plans have changed.|It was a long wait.|I ordered by mistake.|'
    'I found another mode of transport.|incorrect address|Other');
  print('AI trip policy and cancellation reasons: PASS');
}
