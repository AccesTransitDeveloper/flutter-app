import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/socket_constants.dart';
import '../core/managers/live_activity_manager.dart';
import '../core/constants/app_constants.dart';
import '../core/managers/notification_manager.dart';
import 'home_viewmodel.dart';
import '../core/managers/socket_manager.dart';
import '../core/preferences/shared_preference_manager.dart';
import '../core/providers/app_providers.dart';
import '../data/api/response_state.dart';
import '../data/api/server_config.dart';
import '../data/repository/app_repository.dart';
import '../models/requests/entity_detail_request.dart';
import '../models/requests/firebase_device_token_request.dart';
import '../models/responses/auth/entity_detail_response.dart';

/// State for the Main screen
class MainState {
  final bool isLoading;
  final Entity? entity;
  final String? error;

  const MainState({
    this.isLoading = false,
    this.entity,
    this.error,
  });

  MainState copyWith({
    bool? isLoading,
    Entity? entity,
    String? error,
    bool clearError = false,
    bool clearEntity = false,
  }) {
    return MainState(
      isLoading: isLoading ?? this.isLoading,
      entity: clearEntity ? null : (entity ?? this.entity),
      error: clearError ? null : (error ?? this.error),
    );
  }

  /// Check if user has active bookings
  bool get hasActiveBookings =>
      entity?.bookingIds != null && entity!.bookingIds!.isNotEmpty;

  /// Get the first booking ID (for current ride display)
  String? get firstBookingId =>
      hasActiveBookings ? entity!.bookingIds!.first : null;
}

/// ViewModel for the Main screen
class MainViewModel extends StateNotifier<MainState> {
  final AppRepository _appRepository;
  final SharedPreferenceManager _sharedPref;
  final SocketManager _socketManager;
  final Ref _ref;

  MainViewModel(
    this._appRepository,
    this._sharedPref,
    this._socketManager,
    this._ref,
  ) : super(const MainState()) {
    debugPrint('📱 MainViewModel created');
    _loadEntity();
    _connectSocket();
    _updateDeviceToken();
    _registerNotificationCallbacks();
  }

  /// Register notification callbacks
  void _registerNotificationCallbacks() {
    // Send refreshed FCM token to backend
    NotificationManager.instance.onTokenRefreshed = (token) {
      debugPrint('📱 FCM token refreshed, sending to server: $token');
      final request = FirebaseDeviceTokenRequest(deviceToken: token);
      _appRepository.updateDeviceToken(request);
    };

    // Admin approve / decline / block arrives as an ENTITY_STATUS push; native
    // reloads the entity on it so the blocked/declined screen updates without
    // a restart. PENDING is not handled here — native's customer app only
    // reacts to DECLINE, BLOCK and APPROVE.
    NotificationManager.instance.onEntityStatusChanged = (status) {
      if (status != EntityTypeStatus.decline &&
          status != EntityTypeStatus.block &&
          status != EntityTypeStatus.approve) {
        return;
      }

      debugPrint('📱 ENTITY_STATUS push ($status) - refreshing entity');
      _applyEntityStatusChange();
    };

    // Handle notification tap - refresh entity detail to check status changes
    NotificationManager.instance.onNotificationTapped = (data) {
      debugPrint('📱 Notification tapped, refreshing entity detail');
      refreshEntityDetail();
    };

    // Handle iOS Live Activity push token - upload to backend
    LiveActivityManager.instance.onPushTokenUpdated = (bookingId, token) {
      debugPrint('📱 Live Activity token for booking $bookingId, uploading...');
      _appRepository.uploadActivityToken(bookingId, token);
    };
  }

  /// Connect to socket and emit SIGN_UP event
  void _connectSocket() {
    _socketManager.connect(onConnected: () {
      debugPrint('📱 Socket connected, emitting SIGN_UP');
      _socketManager.emitEvent(
        SocketConstants.eventSignUp,
        ackCallback: (ackData) {
          debugPrint('📱 SIGN_UP ack received: $ackData');
        },
      );
    });
  }

  /// Load entity from shared preferences
  void _loadEntity() {
    final entity = _sharedPref.getEntity();
    if (entity != null) {
      state = state.copyWith(entity: entity);
      debugPrint('📱 Entity loaded from prefs: bookingIds=${entity.bookingIds}');

      // Subscribe to FCM topic for mass notifications
      final countryId = entity.countryId;
      if (countryId != null && countryId.isNotEmpty) {
        NotificationManager.instance.subscribeToCountryTopic(countryId);
      }
    }
  }

  /// Called when app resumes or when switching to home tab
  Future<void> refreshEntityDetail() async {
    debugPrint('📱 refreshEntityDetail called');
    await _fetchEntityDetail();
  }

  /// Pull the entity, then re-run the home screen's approval gating.
  ///
  /// `refreshEntityDetail` alone only updates this view model and shared prefs.
  /// The declined/approval screen is driven by HomeViewModel.getInformationStatus,
  /// which reads the stored entity — without this it kept showing the old state
  /// until the screen was rebuilt. (The driver app does the same thing inline,
  /// in getEntityDetail.)
  Future<void> _applyEntityStatusChange() async {
    await refreshEntityDetail();
    await _ref.read(homeViewModelProvider.notifier).getInformationStatus();
  }

  /// Fetch entity detail from server
  Future<void> _fetchEntityDetail() async {
    final entity = _sharedPref.getEntity();
    if (entity?.countryCode == null) {
      debugPrint('📱 No entity countryCode available');
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    final request = EntityDetailRequest(countryCode: entity!.countryCode!);
    final response = await _appRepository.getEntityDetail(request);

    switch (response) {
      case Success():
        final data = response.data;
        debugPrint('📱 Entity detail refreshed successfully');

        // Save updated entity to shared preferences and update state
        if (data?.entity != null) {
          await _sharedPref.setEntity(data!.entity!);
          state = state.copyWith(
            entity: data.entity,
            isLoading: false,
          );
          debugPrint('📱 Entity updated: bookingIds=${data.entity!.bookingIds}');
        } else {
          state = state.copyWith(isLoading: false);
        }

        // Save updated settings
        if (data?.setting != null) {
          await _sharedPref.setSetting(data!.setting!);
        }

        // Preload notification sounds
        final sounds = data?.setting?.pushNotificationSounds;
        if (sounds != null && sounds.isNotEmpty) {
          _preloadSounds(sounds);
        }

      case Error():
        debugPrint('📱 Entity detail refresh error: ${response.message}');
        state = state.copyWith(
          isLoading: false,
          error: response.message,
        );

      case Loading():
        break;
    }
  }

  /// Preload notification sounds from server
  Future<void> _preloadSounds(List<PushNotificationSounds> sounds) async {
    debugPrint('📱 Preloading ${sounds.length} notification sounds');

    for (final sound in sounds) {
      final title = sound.title;
      final fileUrl = sound.fileUrl;

      if (title == null || title.isEmpty || fileUrl == null || fileUrl.isEmpty) {
        continue;
      }

      // Check if sound already exists locally
      final exists = await NotificationManager.instance.soundExists(title);
      if (exists) {
        debugPrint('📱 Sound "$title" already exists locally');
        continue;
      }

      // Download sound from server
      final fullUrl = ServerConfig.getFullImageUrl(fileUrl);
      debugPrint('📱 Downloading sound "$title" from $fullUrl');
      await NotificationManager.instance.downloadSound(fullUrl, title);
    }

    debugPrint('📱 Finished preloading sounds');
  }

  /// Update device FCM token to server
  Future<void> _updateDeviceToken() async {
    String? fcmToken = NotificationManager.instance.fcmToken;

    // If token not available yet, wait and retry (especially for iOS)
    if (fcmToken == null || fcmToken.isEmpty) {
      debugPrint('📱 FCM token not available yet, waiting...');
      for (int i = 0; i < 10; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
        fcmToken = NotificationManager.instance.fcmToken;
        if (fcmToken != null && fcmToken.isNotEmpty) {
          debugPrint('📱 FCM token received after ${(i + 1) * 500}ms');
          break;
        }
      }
    }

    if (fcmToken == null || fcmToken.isEmpty) {
      debugPrint('📱 No FCM token available after waiting');
      return;
    }

    debugPrint('📱 Updating device token to server: $fcmToken');
    final request = FirebaseDeviceTokenRequest(deviceToken: fcmToken);
    final response = await _appRepository.updateDeviceToken(request);

    switch (response) {
      case Success():
        debugPrint('📱 Device token updated successfully');
      case Error():
        debugPrint('📱 Device token update error: ${response.message}');
      case Loading():
        break;
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// Provider for MainViewModel
final mainViewModelProvider =
    StateNotifierProvider<MainViewModel, MainState>((ref) {
  final appRepository = ref.watch(appRepositoryProvider);
  final sharedPref = ref.watch(sharedPreferenceManagerProvider).maybeWhen(
        data: (data) => data,
        orElse: () => throw Exception('SharedPreferences not initialized'),
      );
  final socketManager = ref.read(socketManagerProvider);

  return MainViewModel(appRepository, sharedPref, socketManager, ref);
});
