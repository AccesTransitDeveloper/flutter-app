import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../../core/preferences/shared_preference_manager.dart';
import 'support_models.dart';

class SupportApiException implements Exception {
  final String message;
  final int? status;
  const SupportApiException(this.message, [this.status]);
  @override
  String toString() => message;
}
class SupportApi {
  static const baseUrl = 'https://fashnmall.com/at-driver-web/onboarding/api/passenger-support';
  final SharedPreferenceManager preferences;
  final http.Client _client;
  SupportApi(this.preferences, {http.Client? client}) : _client = client ?? http.Client();
  Map<String, String> get authHeaders {
    final auth = preferences.getAuthorization();
    if (auth == null || auth.isEmpty) throw const SupportApiException('Sign in to the customer app first.', 401);
    final country = preferences.getEntity()?.countryCode;
    return {
      'Authorization': auth,
      if (country != null && RegExp(r'^[A-Za-z]{2}$').hasMatch(country))
        'x-support-country': country.toUpperCase(),
    };
  }
  Uri fileUri(String id) => Uri.parse('$baseUrl/files/${Uri.encodeComponent(id)}');
  Future<dynamic> _request(String path, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await (body == null
      ? _client.get(uri, headers: authHeaders)
      : _client.post(uri, headers: {...authHeaders, 'Content-Type': 'application/json'}, body: jsonEncode(body))
    ).timeout(const Duration(seconds: 40));
    return _decode(response);
  }
  dynamic _decode(http.Response response) {
    dynamic data;
    try { data = jsonDecode(response.body); }
    catch (_) { throw const SupportApiException('Support returned an invalid response. Your draft is saved.'); }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SupportApiException(data is Map && data['error'] is String ? data['error'] as String : 'Support is unavailable. Try again.', response.statusCode);
    }
    return data;
  }
  Future<List<SupportChat>> list() async => (await _request('/chats') as List).map((v) => SupportChat.fromJson(Map<String, dynamic>.from(v as Map))).toList();
  Future<SupportChat> get(String id, {int? before}) async => SupportChat.fromJson(Map<String, dynamic>.from(await _request('/chats/${Uri.encodeComponent(id)}${before == null ? '' : '?before=$before'}') as Map));
  Future<SupportChat> send({String? chatId, required String text, required String messageId, required List<String> attachmentIds, SupportLocation? location}) async {
    final body = <String, dynamic>{
      chatId == null ? 'message' : 'content': text,
      chatId == null ? 'requestId' : 'clientMessageId': messageId,
      'attachmentIds': attachmentIds, if (location != null) 'location': location.toJson(),
    };
    return SupportChat.fromJson(Map<String, dynamic>.from(await _request(chatId == null ? '/chats' : '/chats/${Uri.encodeComponent(chatId)}/messages', body: body) as Map));
  }
  Future<void> markRead(String id, int throughSequence) async {
    await _request('/chats/${Uri.encodeComponent(id)}/read', body: {'throughSequence': throughSequence});
  }
  Future<SupportAttachment> upload(File file, String fileName, String uploadId) async {
    if (!await file.exists()) throw const SupportApiException('The selected file is missing. Remove it and select it again.');
    final size = await file.length();
    if (size == 0 || size > 4 * 1024 * 1024) throw const SupportApiException('Files must be between 1 byte and 4 MB.');
    final response = await _client.post(Uri.parse('$baseUrl/files'), headers: {
      ...authHeaders, 'Content-Type': 'application/octet-stream',
      'x-file-name': Uri.encodeComponent(fileName), 'x-upload-id': uploadId,
    }, body: await file.readAsBytes()).timeout(const Duration(seconds: 50));
    return SupportAttachment.fromJson(Map<String, dynamic>.from(_decode(response) as Map));
  }
  Future<Uint8List> download(String id) async {
    final response = await _client.get(fileUri(id), headers: authHeaders).timeout(const Duration(seconds: 40));
    if (response.statusCode != 200) { _decode(response); throw const SupportApiException('Could not download this file.'); }
    if (response.bodyBytes.length > 4 * 1024 * 1024) throw const SupportApiException('Unexpected file size.');
    return response.bodyBytes;
  }
  void close() => _client.close();
}
