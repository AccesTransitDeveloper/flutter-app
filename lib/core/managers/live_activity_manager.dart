import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Manages platform live booking surfaces via platform channel.
/// iOS uses Live Activities and Android uses a native custom notification.
class LiveActivityManager {
  LiveActivityManager._();
  static final LiveActivityManager instance = LiveActivityManager._();

  static const _channel = MethodChannel('com.accessible.customer/live_activity');

  /// Callback when iOS Live Activity generates a push token
  /// The token should be uploaded to the backend for remote updates
  void Function(String bookingId, String token)? onPushTokenUpdated;

  /// Initialize the manager and listen for push token updates from iOS
  void init() {
    if (!Platform.isIOS) return;

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onPushTokenUpdated') {
        final args = call.arguments as Map<dynamic, dynamic>;
        final bookingId = args['bookingId'] as String;
        final token = args['token'] as String;
        debugPrint('🔔 [LiveActivity] Push token received for booking $bookingId');
        onPushTokenUpdated?.call(bookingId, token);
      }
    });
  }

  /// Start a live booking surface for a booking.
  ///
  /// The rich fields (driver / vehicle / plate / addresses / photo) are static
  /// for the life of the ride: on iOS they populate the Live Activity's
  /// immutable `attributes` (so a backend ContentState push, which only carries
  /// progress/status, never wipes them); on Android they're re-rendered into
  /// the ongoing notification on every call.
  Future<bool> startActivity({
    required String bookingId,
    required String uniqueId,
    required String statusText,
    required int status,
    required int progress,
    required List<int> pickupPoints,
    required int destinationPoint,
    String driverName = '',
    String rating = '',
    String vehicleName = '',
    String plateNo = '',
    String pickupAddress = '',
    String destinationAddress = '',
    String pickupTime = '',
    String destinationTime = '',
    String photoPath = '',
  }) async {
    if (!Platform.isIOS && !Platform.isAndroid) return false;

    try {
      final result = await _channel.invokeMethod<bool>('startActivity', {
        'bookingId': bookingId,
        'uniqueId': uniqueId,
        'statusText': statusText,
        'status': status,
        'progress': progress,
        'pickupPoints': pickupPoints,
        'destinationPoint': destinationPoint,
        'driverName': driverName,
        'rating': rating,
        'vehicleName': vehicleName,
        'plateNo': plateNo,
        'pickupAddress': pickupAddress,
        'destinationAddress': destinationAddress,
        'pickupTime': pickupTime,
        'destinationTime': destinationTime,
        'photoPath': photoPath,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('🔔 [LiveActivity] Start failed: ${e.message}');
      return false;
    }
  }

  /// Stop a live activity for a specific booking
  Future<void> stopActivity(String bookingId) async {
    if (!Platform.isIOS && !Platform.isAndroid) return;

    try {
      await _channel.invokeMethod('stopActivity', {'bookingId': bookingId});
    } on PlatformException catch (e) {
      debugPrint('🔔 [LiveActivity] Stop failed: ${e.message}');
    }
  }

  /// Stop all live activities (e.g., on logout)
  Future<void> stopAllActivities() async {
    if (!Platform.isIOS && !Platform.isAndroid) return;

    try {
      await _channel.invokeMethod('stopAllActivities');
    } on PlatformException catch (e) {
      debugPrint('🔔 [LiveActivity] StopAll failed: ${e.message}');
    }
  }

  /// Check if a live activity is active for a booking
  Future<bool> isActivityActive(String bookingId) async {
    if (!Platform.isIOS) return false;

    try {
      final result = await _channel.invokeMethod<bool>('isActivityActive', {'bookingId': bookingId});
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('🔔 [LiveActivity] Check failed: ${e.message}');
      return false;
    }
  }
}
