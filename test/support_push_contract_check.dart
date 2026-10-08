import '../lib/features/support/support_push.dart';

void check(bool value, String message) {
  if (!value) throw StateError(message);
}

Future<void> main() async {
  final valid = <String, dynamic>{
    'type': 'AT_SUPPORT_REPLY', 'version': '1', 'eventId': 'msg-abc-123',
    'chatId': 'chat-abc-123', 'ownerId': '0123456789abcdef01234567', 'sequence': '1',
    'content': 'Private message', 'attachmentUrl': 'https://private.invalid',
  };
  final push = SupportPush.parse(valid)!;
  check(!push.payload.contains('Private message') && !push.payload.contains('private.invalid'),
      'Payload must allowlist identifiers only');
  check(SupportPush.fromPayload(push.payload)?.chatId == push.chatId, 'Local and remote taps agree');
  check(SupportPush.fromPayload('not-json') == null, 'Ride payload must not parse as support');
  check(SupportPush.parse({...valid, 'version': '2'}) == null, 'Unknown contract version fails closed');
  check(SupportPush.parse({...valid, 'chatId': '../foreign'}) == null, 'Invalid chat path rejected');
  check(SupportPush.parse({...valid, 'ownerId': 'driver-id'}) == null, 'Invalid owner rejected');
  check(push.notificationId == SupportPush.fromPayload(push.payload)!.notificationId, 'Stable dedupe ID');
  final hub = SupportPushHub();
  hub.tapped(push);
  SupportPush? opened;
  hub.onTap = (p) => opened = p;
  await Future<void>.delayed(Duration.zero);
  check(opened?.chatId == push.chatId, 'Cold-start tap survives until auth handler attaches');
  hub.visibleChatId = push.chatId; hub.visibleOwnerId = push.ownerId;
  check(hub.isVisible(push), 'Matching visible conversation is silent');
  check(!hub.isVisible(SupportPush(push.eventId, push.chatId, '111111111111111111111111', '1')),
      'Same chat identifier in another account is not visible');
  hub.onTap = null;
  hub.tapped(push);
  await hub.signedOut();
  opened = null;
  hub.onTap = (p) => opened = p;
  await Future<void>.delayed(Duration.zero);
  check(opened == null, 'Logout drops queued notifications from previous account');
  print('Support push contract and cold-start checks passed');
}
