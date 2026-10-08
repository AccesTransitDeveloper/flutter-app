import 'dart:async';
import 'dart:convert';

/// Strict, versioned allowlist shared by remote, local and cold-start taps.
/// No message text, filenames or coordinates are included in notifications.
class SupportPush {
  final String eventId, chatId, ownerId, sequence;
  const SupportPush(this.eventId, this.chatId, this.ownerId, this.sequence);
  static SupportPush? parse(Map<String, dynamic> data) {
    if (data['type'] != 'AT_SUPPORT_REPLY' || data['version'] != '1') return null;
    final event = data['eventId'], chat = data['chatId'];
    final owner = data['ownerId'], seq = data['sequence'];
    if (event is! String || chat is! String || owner is! String || seq is! String ||
        !RegExp(r'^msg-[a-zA-Z0-9-]{1,100}$').hasMatch(event) ||
        !RegExp(r'^chat-[a-zA-Z0-9-]{1,100}$').hasMatch(chat) ||
        !RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(owner) ||
        !RegExp(r'^[1-9][0-9]{0,18}$').hasMatch(seq)) return null;
    return SupportPush(event, chat, owner, seq);
  }
  static SupportPush? fromPayload(String? payload) {
    try {
      final value = jsonDecode(payload ?? '');
      return value is Map ? parse(Map<String, dynamic>.from(value)) : null;
    } catch (_) { return null; }
  }
  Map<String, String> get data => {
    'type': 'AT_SUPPORT_REPLY', 'version': '1', 'eventId': eventId,
    'chatId': chatId, 'ownerId': ownerId, 'sequence': sequence,
  };
  String get payload => jsonEncode(data);
  int get notificationId {
    // Stable across processes and platforms, unlike String.hashCode.
    var hash = 2166136261;
    for (final byte in utf8.encode(eventId)) { hash = ((hash ^ byte) * 16777619) & 0x7fffffff; }
    return hash;
  }
}

class SupportPushHub {
  static final instance = SupportPushHub();
  final _updates = StreamController<SupportPush>.broadcast();
  Stream<SupportPush> get updates => _updates.stream;
  SupportPush? _pending;
  void Function(SupportPush)? _onTap;
  Future<void> Function()? onSignOut;
  String? visibleOwnerId, visibleChatId;

  set onTap(void Function(SupportPush)? value) {
    _onTap = value;
    if (value != null && _pending != null) {
      final next = _pending!; _pending = null;
      scheduleMicrotask(() { if (_onTap == value) value(next); else _pending = next; });
    }
  }
  void tapped(SupportPush push) {
    final callback = _onTap;
    if (callback == null) { _pending = push; } else { callback(push); }
  }
  void received(SupportPush push) => _updates.add(push);
  bool isVisible(SupportPush push) => visibleOwnerId == push.ownerId && visibleChatId == push.chatId;
  Future<void> signedOut() async {
    _pending = null; visibleOwnerId = null; visibleChatId = null;
    _onTap = null;
    await onSignOut?.call();
  }
}
