import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/preferences/shared_preference_manager.dart';
import 'support_api.dart';
import 'support_models.dart';

class SupportDraftFile {
  final String path, name, uploadId;
  SupportAttachment? uploaded;
  SupportDraftFile(this.path, this.name, this.uploadId, {this.uploaded});
  Map<String, dynamic> toJson() => {'path': path, 'name': name, 'uploadId': uploadId, if (uploaded != null) 'uploaded': uploaded!.toJson()};
  factory SupportDraftFile.fromJson(Map<String, dynamic> j) => SupportDraftFile(
    j['path'] as String, j['name'] as String, j['uploadId'] as String,
    uploaded: j['uploaded'] == null ? null : SupportAttachment.fromJson(Map<String, dynamic>.from(j['uploaded'] as Map)),
  );
}

/// Owns durable, account-scoped drafts and frozen idempotent send attempts.
/// UI must stopPolling on background/dispose and acknowledge only visible messages.
class SupportController extends ChangeNotifier {
  final SharedPreferenceManager preferences;
  late final SupportApi api;
  late final String _accountId;
  late final String? _session;
  late final SharedPreferences _storage;
  List<SupportChat> chats = [];
  SupportChat? selectedChat;
  List<SupportMessage> messages = [];
  String text = '';
  List<SupportDraftFile> files = [];
  SupportLocation? location;
  bool loading = false, sending = false, loadingOlder = false, hasMoreMessages = false;
  bool ready = false, conversationOpen = false;
  String? error, _pendingId;
  Timer? _timer;
  bool _refreshing = false, _disposed = false;
  int _generation = 0, _readSequence = 0;
  Future<void> _writes = Future.value();
  bool get locked => sending || _pendingId != null;
  String get accountId => _accountId;
  String get _draftKey => 'at_support_draft:${Uri.encodeComponent(_accountId)}:${selectedChat?.id ?? 'new'}';
  SupportController(this.preferences, {SupportApi? supportApi}) {
    final id = preferences.getEntity()?.id;
    if (id == null || id.toString().isEmpty) throw const SupportApiException('Sign in to the customer app first.', 401);
    _accountId = id.toString();
    _session = preferences.getAuthorization();
    api = supportApi ?? SupportApi(preferences);
  }
  void _notify() { if (!_disposed) notifyListeners(); }
  void _identity() {
    if (preferences.getEntity()?.id.toString() != _accountId || preferences.getAuthorization() != _session)
      throw const SupportApiException('Your account changed. Reopen Support Chat.', 401);
  }
  Future<void> initialize() async {
    _storage = await SharedPreferences.getInstance();
    ready = true;
    await refresh();
  }
  void startPolling() {
    _timer ??= Timer.periodic(const Duration(seconds: 5), (_) { unawaited(refresh()); });
  }
  void stopPolling() { _timer?.cancel(); _timer = null; }
  Future<void> refresh() async {
    if (!ready || _disposed || _refreshing || sending || loadingOlder) return;
    _refreshing = true;
    final generation = _generation;
    loading = chats.isEmpty && !conversationOpen;
    _notify();
    try {
      _identity();
      if (conversationOpen && selectedChat != null) {
        final next = await api.get(selectedChat!.id);
        _identity();
        if (_disposed || generation != _generation) return;
        selectedChat = next;
        // A long background pause can leave a gap between two latest-100 windows.
        // Restart from the current window so paging retrieves the missing middle.
        final known = messages.map((m) => m.id).toSet();
        if (next.hasMoreMessages && messages.isNotEmpty &&
            !next.messages.any((m) => known.contains(m.id))) {
          messages = [];
          hasMoreMessages = next.hasMoreMessages;
        }
        _merge(next.messages);
        hasMoreMessages = next.hasMoreMessages && messages.length <= 100 ? true : hasMoreMessages;
      } else if (!conversationOpen) {
        final next = await api.list();
        _identity();
        if (_disposed || generation != _generation) return;
        chats = next;
      }
      error = null;
    } catch (e) { if (generation == _generation) error = _errorText(e); }
    finally { _refreshing = false; loading = false; _notify(); }
  }
  Future<void> openChat(SupportChat? chat) async {
    if (!ready || sending) return;
    await _save();
    _generation++;
    selectedChat = chat; conversationOpen = true;
    messages = []; hasMoreMessages = false; _readSequence = 0;
    _restore();
    loading = chat != null; _notify();
    // Ignore any stale list request; then load the selected conversation.
    if (chat != null) {
      final generation = _generation;
      try {
        _identity();
        final detail = await api.get(chat.id);
        _identity();
        if (_disposed || generation != _generation) return;
        selectedChat = detail; messages = detail.messages; hasMoreMessages = detail.hasMoreMessages; error = null;
      } catch (e) { if (generation == _generation) error = _errorText(e); }
      finally { loading = false; _notify(); }
    }
  }
  Future<void> openPushChat(String id) async {
    if (!ready || _disposed || sending) return;
    try {
      _identity();
      final detail = await api.get(id);
      _identity();
      if (_disposed) return;
      if (['closed', 'resolved'].contains(detail.status)) {
        error = 'This conversation is closed. You can open a new Support Chat.';
        _notify(); return;
      }
      // Do not install a payload-supplied ID or restore its draft before ACL
      // verification. Switching threads saves the current draft first.
      await openChat(detail);
    } catch (e) { error = _errorText(e); _notify(); }
  }
  Future<void> backToList() async {
    if (sending) return;
    await _save(); _generation++; conversationOpen = false; selectedChat = null;
    messages = []; error = null; _notify(); await refresh();
  }
  Future<void> loadOlder() async {
    if (!hasMoreMessages || messages.isEmpty || selectedChat == null || loadingOlder) return;
    loadingOlder = true; _notify();
    final generation = _generation;
    try {
      final detail = await api.get(selectedChat!.id, before: messages.first.sequence);
      if (_disposed || generation != _generation) return;
      _merge(detail.messages); hasMoreMessages = detail.hasMoreMessages; error = null;
    } catch (e) { error = _errorText(e); }
    finally { loadingOlder = false; _notify(); }
  }
  void _merge(List<SupportMessage> incoming) {
    final byId = {for (final m in messages) m.id: m, for (final m in incoming) m.id: m};
    messages = byId.values.toList()..sort((a, b) => a.sequence.compareTo(b.sequence));
  }
  void updateText(String value) {
    if (locked || !ready) return;
    text = value;
    unawaited(_save().catchError((Object e) { error = _errorText(e); _notify(); }));
  }
  Future<void> addFile(String path, String name) async {
    if (locked || !ready) return;
    try {
      if (files.length >= 3) throw const SupportApiException('Up to 3 files per message.');
      final source = File(path);
      final size = await source.length();
      if (size < 1 || size > 4 * 1024 * 1024) throw const SupportApiException('Each file must be smaller than 4 MB.');
      final allowed = ['jpg', 'jpeg', 'png', 'webp', 'gif', 'pdf', 'txt', 'csv', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'zip'];
      if (!allowed.contains(name.split('.').last.toLowerCase())) throw const SupportApiException('Unsupported format. Use an image, PDF, Office document, TXT, CSV or ZIP.');
      final id = supportUuid();
      final base = await getApplicationDocumentsDirectory();
      final folder = await Directory('${base.path}/at_support/${Uri.encodeComponent(_accountId)}').create(recursive: true);
      final retained = await source.copy('${folder.path}/$id.${name.split('.').last.toLowerCase()}');
      if (_disposed) return;
      files.add(SupportDraftFile(retained.path, name, id)); error = null;
      await _save();
    } catch (e) { error = _errorText(e); }
    _notify();
  }
  Future<void> removeFile(int index) async {
    if (locked || index < 0 || index >= files.length) return;
    final removed = files.removeAt(index);
    await _save(); _notify();
    await File(removed.path).delete().catchError((_) => File(removed.path));
  }
  Future<void> shareCurrentLocation() async {
    if (locked) return;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) throw const SupportApiException('Turn on Location Services to share your position.');
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) throw const SupportApiException('Location access was denied. You can enable it in Settings.');
      final position = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 20)));
      if (_disposed) return;
      location = SupportLocation(latitude: position.latitude, longitude: position.longitude, accuracyMeters: position.accuracy, capturedAt: DateTime.now().toUtc().toIso8601String());
      await _save(); error = null;
    } catch (e) { error = _errorText(e); }
    _notify();
  }
  Future<void> removeLocation() async { if (locked) return; location = null; await _save(); _notify(); }
  Future<void> send() async {
    if (!ready || sending || (text.trim().isEmpty && files.isEmpty && location == null)) return;
    if (text.trim().length > 4000) { error = 'Messages can contain up to 4000 characters.'; _notify(); return; }
    sending = true; error = null; _notify();
    try {
      _identity();
      _pendingId ??= supportUuid();
      await _save(); // Freeze the exact payload/UUID before the first network request.
      for (final file in files) {
        if (file.uploaded == null) { file.uploaded = await api.upload(File(file.path), file.name, file.uploadId); await _save(); }
      }
      final oldKey = _draftKey;
      final sent = await api.send(chatId: selectedChat?.id, text: text.trim().isNotEmpty ? text.trim() : location != null ? 'Shared location' : 'Shared attachment',
        messageId: _pendingId!, attachmentIds: files.map((f) => f.uploaded!.id).toList(), location: location);
      if (_disposed) return;
      await _storage.remove(oldKey);
      final retained = files.map((f) => f.path).toList();
      text = ''; files = []; location = null; _pendingId = null;
      selectedChat = sent; conversationOpen = true; _merge(sent.messages);
      hasMoreMessages = sent.hasMoreMessages && messages.length <= 100 ? true : hasMoreMessages;
      chats = [sent, ...chats.where((c) => c.id != sent.id)];
      for (final path in retained) { unawaited(File(path).delete().catchError((_) => File(path))); }
    } catch (e) {
      error = _errorText(e);
      // Explicit validation rejection is not an ambiguous delivery timeout.
      // Keep the selected files/text, but allow the user to correct this payload.
      if (e is SupportApiException && [400, 413].contains(e.status)) {
        _pendingId = null;
        await _save();
      }
    }
    finally { sending = false; _notify(); }
  }
  Future<bool> markVisibleMessages(int sequence) async {
    if (_disposed || selectedChat == null) return false;
    if (sequence <= _readSequence) return true;
    final id = selectedChat!.id;
    try { await api.markRead(id, sequence); if (selectedChat?.id == id) _readSequence = sequence; return true; }
    catch (_) { return false; }
  }
  Future<void> _save() {
    if (!ready || !conversationOpen) return Future.value();
    final key = _draftKey;
    final snapshot = jsonEncode({'text': text, 'files': files.map((f) => f.toJson()).toList(), 'location': location?.toJson(), 'pendingId': _pendingId});
    final write = _writes.catchError((_) {}).then((_) async {
      if (!await _storage.setString(key, snapshot)) throw const SupportApiException('Could not save your draft. Keep this screen open.');
    });
    _writes = write;
    return write;
  }
  void _restore() {
    text = ''; files = []; location = null; _pendingId = null; error = null;
    final saved = _storage.getString(_draftKey);
    if (saved == null) return;
    try {
      final j = jsonDecode(saved) as Map<String, dynamic>;
      text = j['text'] as String; _pendingId = j['pendingId'] as String?;
      files = (j['files'] as List).map((v) => SupportDraftFile.fromJson(Map<String, dynamic>.from(v as Map))).toList();
      location = j['location'] == null ? null : SupportLocation.fromJson(Map<String, dynamic>.from(j['location'] as Map));
    } catch (_) { error = 'A saved draft could not be loaded. It has not been deleted.'; }
  }
  String _errorText(Object e) => e is SupportApiException ? e.message : e is TimeoutException ? 'Connection timed out. Your draft is saved; retry sends the same message.' : 'Could not connect to Support. Your draft is saved.';
  @override
  void dispose() {
    stopPolling(); _disposed = true; _generation++;
    // Pending drafts were persisted before sending; an interrupted attempt retains its UUID.
    api.close(); super.dispose();
  }
}
