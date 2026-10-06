import 'dart:async';
import 'package:customer/core/preferences/shared_preference_manager.dart';
import 'package:customer/models/responses/auth/entity_detail_response.dart';
import 'package:customer/features/support/support_api.dart';
import 'package:customer/features/support/support_controller.dart';
import 'package:customer/features/support/support_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

SupportChat chat(String id, String content) => SupportChat.fromJson({
  'id': id, 'ticketNumber': 'SUP-TEST', 'subject': content, 'status': 'open',
  'updatedAt': '2026-10-06T12:00:00Z', 'lastMessage': content,
  'messages': [{'id': 'msg-test', 'sequence': 42, 'senderName': 'Synthetic Customer', 'senderRole': 'user', 'content': content, 'timestamp': '2026-10-06T12:00:00Z'}],
});
class FakeSupportApi extends SupportApi {
  FakeSupportApi(super.preferences);
  bool timeoutOnce = false, reject = false;
  final attempts = <String>[];
  @override
  Future<List<SupportChat>> list() async => [];
  @override
  Future<SupportChat> send({String? chatId, required String text, required String messageId, required List<String> attachmentIds, SupportLocation? location}) async {
    attempts.add('$messageId|$text|${attachmentIds.join(',')}|${location?.capturedAt}');
    if (timeoutOnce) { timeoutOnce = false; throw TimeoutException('Simulated response loss'); }
    if (reject) throw const SupportApiException('Invalid file', 400);
    return chat('chat-test', text);
  }
}
void main() {
  test('after a long background gap, pagination retrieves the missing middle', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferenceManager.create();
    await prefs.setEntity(Entity(id: 'history-customer', type: 2));
    await prefs.setAuthorization('synthetic-history-auth');
    final api = HistorySupportApi(prefs);
    final controller = SupportController(prefs, supportApi: api);
    await controller.initialize();
    await controller.openChat(api.page(1));
    expect(controller.messages.first.sequence, 1);
    api.latestStart = 201;
    await controller.refresh();
    expect(controller.messages.first.sequence, 201);
    expect(controller.hasMoreMessages, isTrue);
    await controller.loadOlder();
    expect(controller.messages.first.sequence, 101);
    await controller.loadOlder();
    expect(controller.messages.map((m) => m.sequence).toList(), List.generate(300, (i) => i + 1));
    expect(controller.hasMoreMessages, isFalse);
    controller.dispose();
  });
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferenceManager preferences;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = SharedPreferenceManager(await SharedPreferences.getInstance());
    await preferences.setEntity(Entity(id: 'synthetic-customer', type: 2));
    await preferences.setAuthorization('synthetic-authorization');
  });
  test('an interrupted creation retains its exact UUID and draft across reopening', () async {
    final api = FakeSupportApi(preferences)..timeoutOnce = true;
    var controller = SupportController(preferences, supportApi: api);
    await controller.initialize(); await controller.openChat(null);
    controller.updateText('Please help with dispatch');
    await controller.send();
    expect(controller.locked, isTrue);
    expect(controller.text, 'Please help with dispatch');
    expect(controller.messages, isEmpty);
    controller.updateText('Must not replace an ambiguous payload');
    expect(controller.text, 'Please help with dispatch');
    controller.dispose();
    controller = SupportController(preferences, supportApi: api);
    await controller.initialize(); await controller.openChat(null);
    expect(controller.locked, isTrue);
    await controller.send();
    expect(api.attempts.length, 2);
    expect(api.attempts[0], api.attempts[1]);
    expect(controller.locked, isFalse);
    expect(controller.text, '');
    expect(controller.selectedChat?.id, 'chat-test');
    expect(controller.messages.single.content, 'Please help with dispatch');
    controller.dispose();
  });
  test('validation rejection leaves an editable draft, without pretending it was sent', () async {
    final api = FakeSupportApi(preferences)..reject = true;
    final controller = SupportController(preferences, supportApi: api);
    await controller.initialize(); await controller.openChat(null);
    controller.updateText('My draft');
    await controller.send();
    expect(controller.locked, isFalse);
    expect(controller.text, 'My draft');
    expect(controller.messages, isEmpty);
    controller.updateText('Corrected draft');
    api.reject = false; await controller.send();
    expect(controller.messages.single.content, 'Corrected draft');
    controller.dispose();
  });
  test('drafts and pending retries do not appear in another account', () async {
    var controller = SupportController(preferences, supportApi: FakeSupportApi(preferences)..timeoutOnce = true);
    await controller.initialize(); await controller.openChat(null);
    controller.updateText('Private driver draft'); await controller.send(); controller.dispose();
    await preferences.setEntity(Entity(id: 'different-customer', type: 2));
    controller = SupportController(preferences, supportApi: FakeSupportApi(preferences));
    await controller.initialize(); await controller.openChat(null);
    expect(controller.text, '');
    expect(controller.locked, isFalse);
    controller.dispose();
  });
}

class HistorySupportApi extends SupportApi {
  HistorySupportApi(super.preferences);
  int latestStart = 1;
  SupportChat page(int start) => SupportChat.fromJson({
    'id': 'chat-history', 'ticketNumber': 'SUP-HISTORY', 'subject': 'History',
    'status': 'open', 'updatedAt': '2026-10-06T12:00:00Z',
    'hasMoreMessages': start > 1,
    'messages': List.generate(100, (i) => {
      'id': 'msg-${start + i}', 'sequence': start + i,
      'senderName': 'Synthetic Customer', 'senderRole': 'user',
      'content': 'Message ${start + i}', 'timestamp': '2026-10-06T12:00:00Z',
    }),
  });
  @override
  Future<List<SupportChat>> list() async => [page(latestStart)];
  @override
  Future<SupportChat> get(String id, {int? before}) async =>
      page(before == null ? latestStart : (before - 100).clamp(1, latestStart).toInt());
}
