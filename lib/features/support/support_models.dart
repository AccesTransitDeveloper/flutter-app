import 'dart:math';

String supportUuid() {
  final random = Random.secure();
  final bytes = List.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 15) | 64;
  bytes[8] = (bytes[8] & 63) | 128;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

class SupportAttachment {
  final String id, fileName, fileType;
  final int sizeBytes;
  const SupportAttachment({required this.id, required this.fileName, required this.fileType, required this.sizeBytes});
  bool get isImage => fileType.startsWith('image/');
  factory SupportAttachment.fromJson(Map<String, dynamic> j) => SupportAttachment(
    id: j['id'] as String, fileName: j['fileName'] as String,
    fileType: j['fileType'] as String, sizeBytes: (j['sizeBytes'] as num).toInt(),
  );
  Map<String, dynamic> toJson() => {'id': id, 'fileName': fileName, 'fileType': fileType, 'sizeBytes': sizeBytes};
}
class SupportLocation {
  final double latitude, longitude, accuracyMeters;
  final String capturedAt;
  const SupportLocation({required this.latitude, required this.longitude, required this.accuracyMeters, required this.capturedAt});
  factory SupportLocation.fromJson(Map<String, dynamic> j) => SupportLocation(
    latitude: (j['latitude'] as num).toDouble(), longitude: (j['longitude'] as num).toDouble(),
    accuracyMeters: (j['accuracyMeters'] as num).toDouble(), capturedAt: j['capturedAt'] as String,
  );
  Map<String, dynamic> toJson() => {'latitude': latitude, 'longitude': longitude, 'accuracyMeters': accuracyMeters, 'capturedAt': capturedAt};
  Uri get mapUri => Uri.https('www.openstreetmap.org', '/', {'mlat': '$latitude', 'mlon': '$longitude'}).replace(fragment: 'map=17/$latitude/$longitude');
}
class SupportMessage {
  final String id, senderName, senderRole, content;
  final int sequence;
  final DateTime timestamp;
  final List<SupportAttachment> attachments;
  final SupportLocation? location;
  const SupportMessage({required this.id, required this.senderName, required this.senderRole, required this.content, required this.sequence, required this.timestamp, required this.attachments, this.location});
  // CRM uses the "user" sender role inside the passenger namespace.
  bool get isMine => senderRole == 'user';
  factory SupportMessage.fromJson(Map<String, dynamic> j) => SupportMessage(
    id: j['id'] as String, senderName: j['senderName'] as String, senderRole: j['senderRole'] as String,
    content: j['content'] as String, sequence: (j['sequence'] as num).toInt(),
    timestamp: DateTime.parse(j['timestamp'] as String).toLocal(),
    attachments: ((j['attachments'] as List?) ?? []).map((v) => SupportAttachment.fromJson(Map<String, dynamic>.from(v as Map))).toList(),
    location: j['location'] == null ? null : SupportLocation.fromJson(Map<String, dynamic>.from(j['location'] as Map)),
  );
}
class SupportChat {
  final String id, ticketNumber, subject, status, lastMessage;
  final int unreadByClient;
  final DateTime updatedAt;
  final List<SupportMessage> messages;
  final bool hasMoreMessages;
  const SupportChat({required this.id, required this.ticketNumber, required this.subject, required this.status, required this.lastMessage, required this.unreadByClient, required this.updatedAt, required this.messages, required this.hasMoreMessages});
  factory SupportChat.fromJson(Map<String, dynamic> j) => SupportChat(
    id: j['id'] as String, ticketNumber: j['ticketNumber'] as String,
    subject: (j['subject'] as String?) ?? 'AT Support', status: j['status'] as String,
    lastMessage: (j['lastMessage'] as String?) ?? '', unreadByClient: (j['unreadByClient'] as num?)?.toInt() ?? 0,
    updatedAt: DateTime.parse(j['updatedAt'] as String).toLocal(),
    messages: ((j['messages'] as List?) ?? []).map((v) => SupportMessage.fromJson(Map<String, dynamic>.from(v as Map))).toList(),
    hasMoreMessages: j['hasMoreMessages'] == true,
  );
}
