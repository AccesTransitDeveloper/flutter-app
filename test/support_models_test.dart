import 'package:flutter_test/flutter_test.dart';
import 'package:customer/features/support/support_models.dart';

void main() {
  test('CRM user messages belong to the passenger; staff and driver roles do not', () {
    SupportMessage message(String role) => SupportMessage.fromJson({
      'id': 'msg-role', 'sequence': 1, 'senderName': 'Synthetic', 'senderRole': role,
      'content': 'Hello', 'timestamp': '2026-10-06T12:00:00Z',
    });
    expect(message('user').isMine, isTrue);
    expect(message('support_agent').isMine, isFalse);
    expect(message('driver').isMine, isFalse);
  });
  test('upload and send UUIDs have secure v4 layout', () {
    final ids = List.generate(200, (_) => supportUuid());
    expect(ids.toSet().length, ids.length);
    for (final id in ids) {
      expect(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$').hasMatch(id), isTrue);
    }
  });
  test('support media and location survive the real JSON contract', () {
    final chat = SupportChat.fromJson({
      'id': 'chat-test', 'ticketNumber': 'SUP-TEST', 'subject': 'Need help',
      'status': 'open', 'updatedAt': '2026-10-06T12:00:00Z', 'unreadByClient': 1,
      'hasMoreMessages': true,
      'messages': [{
        'id': 'msg-test', 'sequence': 12, 'senderName': 'AT Support', 'senderRole': 'support_agent',
        'content': 'Please send the receipt', 'timestamp': '2026-10-06T12:00:00Z',
        'attachments': [{'id': 'file-test', 'fileName': 'receipt.pdf', 'fileType': 'application/pdf', 'sizeBytes': 42}],
        'location': {'latitude': 40.7, 'longitude': -74.0, 'accuracyMeters': 5, 'capturedAt': '2026-10-06T12:00:00Z'},
      }],
    });
    expect(chat.unreadByClient, 1);
    expect(chat.hasMoreMessages, isTrue);
    expect(chat.messages.first.isMine, isFalse);
    expect(chat.messages.first.attachments.first.fileName, 'receipt.pdf');
    final location = chat.messages.first.location!;
    expect(SupportLocation.fromJson(location.toJson()).longitude, -74);
    expect(location.mapUri.host, 'www.openstreetmap.org');
    expect(location.mapUri.fragment, 'map=17/40.7/-74.0');
  });
}
