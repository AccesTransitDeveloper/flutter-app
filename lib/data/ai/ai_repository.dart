import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../features/ai/ai_models.dart';

class AiConfigurationException implements Exception {
  final String message;
  const AiConfigurationException(this.message);
  @override
  String toString() => message;
}

class AiRepository {
  static const _configuredBase = String.fromEnvironment('AT_AI_API_BASE_URL');
  final http.Client _client;
  String? displayName;
  AiRepository({http.Client? client, this.displayName})
      : _client = client ?? http.Client();

  void close() {
    _client.close();
  }

  String? _cookie;
  String? _greeting;
  Future<void>? _sessionInit;

  Uri _uri(String path) {
    final base = _configuredBase.trim().replaceFirst(RegExp(r'/+$'), '');
    if (base.isEmpty) {
      throw const AiConfigurationException(
        'AT AI is not configured. Build with '
        '--dart-define=AT_AI_API_BASE_URL=https://your-ai-server.',
      );
    }
    return Uri.parse('$base$path');
  }

  Future<void> _ensureSession() async {
    final pending = _sessionInit ??= _initializeSession();
    try {
      await pending;
    } catch (_) {
      if (identical(_sessionInit, pending)) {
        _sessionInit = null;
      }
      rethrow;
    }
  }

  Future<void> _initializeSession() async {
    final response = await _client.post(
      _uri('/api/session/init'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        if (displayName != null && displayName!.isNotEmpty)
          'displayName': displayName,
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _sessionInit = null;
      throw Exception(
        'AT AI session initialization failed (${response.statusCode}).',
      );
    }
    final setCookie = response.headers['set-cookie'];
    if (setCookie == null || setCookie.isEmpty) {
      _sessionInit = null;
      throw Exception(
        'AT AI session initialization did not return a session cookie.',
      );
    }
    final semicolon = setCookie.indexOf(';');
    _cookie =
        (semicolon < 0 ? setCookie : setCookie.substring(0, semicolon)).trim();
    if (_cookie!.isEmpty || !_cookie!.contains('=')) {
      _sessionInit = null;
      throw Exception('AT AI returned an invalid session cookie.');
    }
    final decoded = jsonDecode(response.body);
    _greeting = decoded is Map<String, dynamic>
        ? decoded['greeting']?.toString()
        : null;
  }

  Future<String?> initialize() async {
    await _ensureSession();
    return _greeting;
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    await _ensureSession();
    var response = await _send(path, body);
    if (response.statusCode == 401) {
      _cookie = null;
      _sessionInit = null;
      await _ensureSession();
      response = await _send(path, body);
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('AT AI request failed (${response.statusCode}).');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('AT AI returned an invalid response.');
    }
    return decoded;
  }

  Future<http.Response> _send(
    String path,
    Map<String, dynamic> body,
  ) {
    return _client.post(
      _uri(path),
      headers: {
        'Content-Type': 'application/json',
        if (_cookie != null) 'Cookie': _cookie!,
      },
      body: jsonEncode(body),
    );
  }

  Future<AiReply> sendMessage(
    String message,
    String sessionId,
    List<AiMessage> history,
  ) async {
    final json = await _post('/api/chat/message', {
      'message': message,
      'sessionId': sessionId,
      'conversationHistory': history.map((m) => m.toJson()).toList(),
    });
    final suggestion = json['orderSuggestion'];
    return AiReply(
      text:
          (json['message'] ?? json['response'] ?? json['reply'] ?? '').toString(),
      orderSuggestion: suggestion is Map<String, dynamic>
          ? OrderSuggestion.fromJson(suggestion)
          : null,
    );
  }

  Future<String> transcribe(String base64, String mimeType) async {
    final json = await _post('/api/chat/transcribe', {
      'audioBase64': base64,
      'mimeType': mimeType,
    });
    return (json['text'] ?? json['transcript'] ?? '').toString();
  }

  Future<List<int>> tts(String text) async {
    final json = await _post('/api/chat/tts', {'text': text});
    return base64Decode((json['audioBase64'] ?? '').toString());
  }
}