import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/preferences/shared_preference_manager.dart';
import 'sos_contract.dart';

class SosFailure implements Exception {
  final String message;
  final int? status;
  const SosFailure(this.message, [this.status]);
  @override
  String toString() => message;
}

class SosService {
  static const base = 'https://fashnmall.com/at-driver-web/onboarding/api/passenger-sos';
  final SharedPreferenceManager preferences;
  final http.Client _client = http.Client();
  final String owner;
  final String? _session;
  SosService(this.preferences)
      : owner = preferences.getEntity()?.id ?? '',
        _session = preferences.getAuthorization();

  void checkSession() {
    if (owner.isEmpty || !preferences.isLoggedIn() || _session == null ||
        preferences.getEntity()?.id != owner ||
        preferences.getAuthorization() != _session) {
      throw const SosFailure('Sign in to the customer app again.', 401);
    }
  }

  Future<Map<String, dynamic>> request(String path, [Map<String, dynamic>? body]) async {
    checkSession();
    final headers = {
      'authorization': _session!,
      'Content-Type': 'application/json',
      if (preferences.getEntity()?.countryCode != null)
        'x-support-country': preferences.getEntity()!.countryCode!,
    };
    http.Response response;
    try {
      response = body == null
          ? await _client.get(Uri.parse('$base$path'), headers: headers).timeout(const Duration(seconds: 25))
          : await _client.post(Uri.parse('$base$path'), headers: headers,
              body: jsonEncode(body)).timeout(const Duration(seconds: 25));
    } catch (_) {
      checkSession();
      throw const SosFailure('Connection lost. SOS is not confirmed. Retry or call for help.');
    }
    checkSession();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      // Never display upstream HTML, private contacts or server diagnostic text.
      throw SosFailure(switch (response.statusCode) {
        401 => 'Sign in to the customer app again.',
        403 => 'This trip or SOS is not assigned to you. Call dispatch.',
        409 => 'This SOS or trip is closed, or the request changed. Call dispatch.',
        422 => 'Verified trip information is incomplete. Call dispatch.',
        429 => 'Too many requests. Retry shortly or call for help.',
        _ => 'SOS is not confirmed. Retry or call for help.',
      }, response.statusCode);
    }
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw const SosFailure('Invalid server confirmation. Retry the saved request.');
    }
  }

  String get pendingKey => 'passenger_sos_pending_$owner';
  String get activeKey => 'passenger_sos_active_$owner';
  String get pointKey => 'passenger_sos_point_$owner';
  Future<Map<String, dynamic>?> read(String key) async {
    checkSession();
    final prefs = await SharedPreferences.getInstance();
    checkSession();
    final value = prefs.getString(key);
    return value == null ? null : jsonDecode(value) as Map<String, dynamic>;
  }
  Future<void> write(String key, Map<String, dynamic> value) async {
    checkSession();
    final prefs = await SharedPreferences.getInstance();
    checkSession();
    if (!await prefs.setString(key, jsonEncode(value))) {
      throw const SosFailure('Unable to save the request. Call dispatch.');
    }
  }
  Future<void> remove(String key) async {
    checkSession();
    final prefs = await SharedPreferences.getInstance();
    checkSession();
    if (!await prefs.remove(key)) throw const SosFailure('Unable to update saved SOS state.');
  }

  Future<SosConfirmation> send(Map<String, dynamic> pending) async {
    // Saved before network I/O. Retry uses exactly this UUID and payload.
    await write(pendingKey, pending);
    final result = SosConfirmation(await request('/alerts', pending));
    if (result.tripId != pending['tripId']) {
      throw const SosFailure('The server returned a different trip. Call dispatch.');
    }
    await write(activeKey, result.toJson());
    await remove(pendingKey);
    return result;
  }
  Future<SosConfirmation> get(String id) async =>
      SosConfirmation(await request('/alerts/${Uri.encodeComponent(id)}'));
  void close() => _client.close();
}
