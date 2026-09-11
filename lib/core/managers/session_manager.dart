import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../preferences/shared_preference_manager.dart';
import '../providers/app_providers.dart';

/// Callback type for session expiration events
typedef SessionExpiredCallback = void Function();

/// Manages user session state and handles token expiration globally
class SessionManager {
  static SessionManager? _instance;
  static SessionManager get instance => _instance ??= SessionManager._();

  SessionManager._();

  SharedPreferenceManager? _sharedPref;
  SessionExpiredCallback? _onSessionExpired;

  /// Initialize with shared preferences
  void init(SharedPreferenceManager sharedPref) {
    _sharedPref = sharedPref;
  }

  /// Set callback for session expiration
  void setSessionExpiredCallback(SessionExpiredCallback callback) {
    _onSessionExpired = callback;
  }

  /// Clear session expired callback
  void clearSessionExpiredCallback() {
    _onSessionExpired = null;
  }

  /// Handle token expiration - clear auth data and notify listeners
  Future<void> handleTokenExpired() async {
    debugPrint('🔐 SessionManager: Token expired, logging out...');

    // Clear auth data
    if (_sharedPref != null) {
      await _sharedPref!.signOut();
    }

    // Notify callback to navigate to login
    _onSessionExpired?.call();
  }

  /// Check if token is invalid based on status code and message
  bool isTokenExpired(int statusCode, String? message) {
    // 409 with "Invalid token" message indicates token expiration
    return statusCode == 409 && message?.toLowerCase().contains('invalid token') == true;
  }
}

/// Provider for SessionManager
final sessionManagerProvider = Provider<SessionManager>((ref) {
  final sharedPrefAsync = ref.watch(sharedPreferenceManagerProvider);

  sharedPrefAsync.whenData((sharedPref) {
    SessionManager.instance.init(sharedPref);
  });

  return SessionManager.instance;
});
