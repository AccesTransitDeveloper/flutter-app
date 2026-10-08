import '../lib/features/sos/sos_contract.dart';

void main() {
  final pattern = RegExp(r'^[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89ab][a-f0-9]{3}-[a-f0-9]{12}$');
  final values = List.generate(1000, (_) => sosUuid());
  if (values.toSet().length != values.length || !values.every(pattern.hasMatch)) {
    throw StateError('SOS UUIDs must be unique UUID v4 values.');
  }
  final reply = SosConfirmation({
    'id': values.first, 'tripId': 'aaaaaaaaaaaaaaaaaaaaaaaa',
    'status': 'acknowledged', 'locations': {'passenger': 'must not persist'},
    'dispatcherNote': 'must not persist',
  });
  if (reply.toJson().containsKey('locations') || reply.toJson().containsKey('dispatcherNote')) {
    throw StateError('Private dispatcher data must not be persisted.');
  }
  var rejected = false;
  try {
    SosConfirmation({'id': values.first, 'tripId': 'aaaaaaaaaaaaaaaaaaaaaaaa', 'status': 'delivered'});
  } on FormatException { rejected = true; }
  if (!rejected) throw StateError('Unknown success states must be rejected.');
  print('SOS UUID, status and privacy checks passed.');
}
