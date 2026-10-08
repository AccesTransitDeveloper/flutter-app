import 'dart:math';

String sosUuid() {
  final random = Random.secure();
  final bytes = List.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 15) | 64;
  bytes[8] = (bytes[8] & 63) | 128;
  final hex = bytes.map((v) => v.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

class SosConfirmation {
  final String id;
  final String tripId;
  final String status;
  final bool locationWarning;
  SosConfirmation(Map<String, dynamic> json)
      : id = json['id'] as String,
        tripId = json['tripId'] as String,
        status = json['status'] as String,
        locationWarning = json['locationWarning'] == true {
    if (!RegExp(r'^[a-zA-Z0-9-]{1,100}$').hasMatch(id) ||
        !RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(tripId) ||
        !['new', 'acknowledged', 'resolved'].contains(status)) {
      throw const FormatException('Invalid SOS confirmation');
    }
  }
  Map<String, dynamic> toJson() => {
    'id': id, 'tripId': tripId, 'status': status,
    'locationWarning': locationWarning,
  };
}

// Logout stops foreground GPS immediately; pending requests remain owner-scoped.
class SosSession {
  static void Function()? onSignOut;
}
