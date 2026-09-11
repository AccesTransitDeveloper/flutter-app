import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../constants/app_constants.dart';
import '../localization/app_strings.dart';
import '../utils/delivery_order_status.dart';
import 'live_activity_manager.dart';
import 'permission_manager.dart';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔔 Background message: ${message.messageId}');
  debugPrint('🔔 Background message data: ${message.data}');

  // On iOS, if the message has a notification payload, iOS already displayed it.
  // Only show local notification for data-only messages.
  if (Platform.isIOS && message.notification != null) {
    debugPrint('🔔 [iOS] Notification payload present - iOS already displayed it');
    return;
  }

  // Show notification for data-only messages (both platforms) and Android
  await NotificationManager.instance.showNotificationFromMessage(message);
}

/// Notification channel IDs - must match Android native channels
class NotificationChannels {
  static const String regularChannelId = 'regular_notification_channel';
  static const String regularChannelName = 'Regular Notifications';
  static const String regularChannelDesc = 'Regular app notifications';

  static const String liveChannelId = 'live_notification_channel_id';
  static const String liveChannelName = 'Live Booking';
  static const String liveChannelDesc = 'Live booking status updates';

  static const String highPriorityChannelId = 'high_priority_channel';
  static const String highPriorityChannelName = 'Important Notifications';
  static const String highPriorityChannelDesc = 'Important notifications that require immediate attention';
}

/// Notification Manager for handling FCM push notifications
class NotificationManager {
  NotificationManager._();
  static final NotificationManager instance = NotificationManager._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final AudioPlayer _audioPlayer = AudioPlayer();

  String? _fcmToken;
  String? _apnsToken;

  /// Callback for when FCM token is refreshed
  void Function(String token)? onTokenRefreshed;

  /// Callback for when a notification is tapped
  void Function(Map<String, dynamic> data)? onNotificationTapped;

  /// Get current FCM token
  String? get fcmToken => _fcmToken;

  /// Get current APNS token (iOS only)
  String? get apnsToken => _apnsToken;

  /// Initialize notification manager
  Future<void> init() async {
    // Initialize local notifications
    await _initLocalNotifications();

    // Create notification channels (Android)
    await _createNotificationChannels();

    // Request permission
    await _requestPermission();

    // Get FCM token
    await _getToken();

    // Listen to token refresh
    _messaging.onTokenRefresh.listen((token) {
      debugPrint('🔔 FCM Token refreshed: $token');
      _fcmToken = token;
      _onTokenRefresh(token);
    });

    // iOS: Let iOS display notifications natively in foreground
    // (matches native app's willPresent: .banner, .sound, .badge)
    if (Platform.isIOS) {
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Check if app was opened from a terminated state via notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  /// Initialize local notifications plugin
  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@drawable/ic_stat_notification');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  /// Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    if (!Platform.isAndroid) return;

    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return;

    // Regular notifications channel (IMPORTANCE_DEFAULT)
    const regularChannel = AndroidNotificationChannel(
      NotificationChannels.regularChannelId,
      NotificationChannels.regularChannelName,
      description: NotificationChannels.regularChannelDesc,
      importance: Importance.defaultImportance,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    // Live booking updates channel (IMPORTANCE_LOW, silent)
    const liveChannel = AndroidNotificationChannel(
      NotificationChannels.liveChannelId,
      NotificationChannels.liveChannelName,
      description: NotificationChannels.liveChannelDesc,
      importance: Importance.low,
      playSound: false,
      enableVibration: false,
      showBadge: false,
    );

    // High priority notifications channel (IMPORTANCE_HIGH)
    const highPriorityChannel = AndroidNotificationChannel(
      NotificationChannels.highPriorityChannelId,
      NotificationChannels.highPriorityChannelName,
      description: NotificationChannels.highPriorityChannelDesc,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await androidPlugin.createNotificationChannel(regularChannel);
    await androidPlugin.createNotificationChannel(liveChannel);
    await androidPlugin.createNotificationChannel(highPriorityChannel);

    debugPrint('🔔 Notification channels created');
  }

  bool _isPermissionGranted = false;

  /// Check if notification permission is granted
  bool get isPermissionGranted => _isPermissionGranted;

  /// Request notification permission
  /// Uses Firebase Messaging for iOS (required for APNS) and PermissionManager for Android
  Future<void> _requestPermission() async {
    if (Platform.isIOS) {
      debugPrint('🔔 [iOS] Requesting notification permission...');

      // iOS: Use Firebase Messaging's requestPermission for proper APNS integration
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('🔔 [iOS] Permission status: ${settings.authorizationStatus}');
      debugPrint('🔔 [iOS] Alert setting: ${settings.alert}');
      debugPrint('🔔 [iOS] Badge setting: ${settings.badge}');
      debugPrint('🔔 [iOS] Sound setting: ${settings.sound}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('🔔 [iOS] User granted notification permission');
        _isPermissionGranted = true;
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('🔔 [iOS] User granted provisional notification permission');
        _isPermissionGranted = true;
      } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('🔔 [iOS] User denied notification permission');
        _isPermissionGranted = false;
      } else {
        debugPrint('🔔 [iOS] Notification permission not determined');
        _isPermissionGranted = false;
      }
    } else {
      // Android: Use PermissionManager
      final result = await PermissionManager.instance.requestNotification();
      PermissionManager.instance.logResult('Notification', result);

      if (result == PermissionResult.granted) {
        debugPrint('🔔 User granted notification permission');
        _isPermissionGranted = true;
      } else if (result == PermissionResult.permanentlyDenied) {
        debugPrint('🔔 Notification permission permanently denied - user must enable in settings');
        _isPermissionGranted = false;
      } else {
        debugPrint('🔔 User declined notification permission');
        _isPermissionGranted = false;
      }
    }
  }

  /// Get FCM token
  /// On iOS, this may return null initially - the token will arrive via onTokenRefresh
  Future<String?> _getToken() async {
    try {
      debugPrint('🔔 [getToken] Starting token retrieval...');

      if (Platform.isIOS) {
        debugPrint('🔔 [iOS] Permission granted: $_isPermissionGranted');

        if (!_isPermissionGranted) {
          debugPrint('🔔 [iOS] Skipping token - notification permission not granted');
          return null;
        }

        // On iOS, get the APNS token to send to the backend
        final apnsToken = await _messaging.getAPNSToken();
        if (apnsToken != null) {
          _apnsToken = apnsToken;
          debugPrint('🔔 [iOS] APNS Token: $_apnsToken');
        } else {
          debugPrint('🔔 [iOS] APNS not ready yet');
        }
      }

      _fcmToken = await _messaging.getToken();
      debugPrint('🔔 FCM Token: $_fcmToken');
      return _fcmToken;
    } catch (e, stackTrace) {
      debugPrint('🔔 ❌ Error getting FCM token: $e');
      debugPrint('🔔 ❌ Stack trace: $stackTrace');
      return null;
    }
  }

  /// Handle token refresh - this is the reliable way to get FCM token on iOS
  void _onTokenRefresh(String token) {
    debugPrint('🔔 [onTokenRefresh] FCM Token received: $token');
    _fcmToken = token;
    onTokenRefreshed?.call(token);
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('🔔 Foreground message received:');
    debugPrint('🔔 Data: ${message.data}');

    // Native handles this on receipt (in `handleIntent`), not only when the
    // notification is tapped, so an approval applies while the app is open.
    _processNotificationAction(message.data);

    if (Platform.isIOS) {
      // iOS: Notification with payload is displayed natively via
      // setForegroundNotificationPresentationOptions (banner + sound + badge).
      // Only show local notification for data-only messages.
      if (message.notification == null) {
        showNotificationFromMessage(message);
      }
    } else {
      // Android: Always show local notification (Android doesn't auto-display in foreground)
      showNotificationFromMessage(message);
    }
  }

  /// Handle notification tap (when app opens from notification)
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('🔔 Notification tapped:');
    debugPrint('🔔 Data: ${message.data}');

    _processNotificationAction(message.data);
    onNotificationTapped?.call(message.data);
  }

  /// Handle local notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('🔔 Local notification tapped: ${response.payload}');
    onNotificationTapped?.call({'payload': response.payload});
  }

  /// Show notification from FCM message
  Future<void> showNotificationFromMessage(RemoteMessage message) async {
    debugPrint('🔔 [showNotificationFromMessage] Processing message...');
    debugPrint('🔔 [showNotificationFromMessage] Message ID: ${message.messageId}');
    debugPrint('🔔 [showNotificationFromMessage] Data: ${message.data}');
    debugPrint('🔔 [showNotificationFromMessage] Notification: ${message.notification?.title} - ${message.notification?.body}');

    final data = message.data;

    final title = data['title'] ?? message.notification?.title ?? '';
    final body = data['body'] ?? message.notification?.body ?? '';
    final sound = data['sound'];
    final image = data['image'];

    debugPrint('🔔 [showNotificationFromMessage] Title: $title, Body: $body');

    // Check if it's a live notification (has progress data)
    final progress = data['progress'];
    if (progress != null) {
      final event = data['event'];
      final bookingId = data['bookingId'] ?? '';
      final uniqueId = data['uniqueId'] ?? '';
      final status = int.tryParse(data['status']?.toString() ?? '') ?? 0;
      final progressValue = int.tryParse(progress.toString()) ?? 0;
      final destinationPoint = int.tryParse(data['destinationPoint']?.toString() ?? '') ?? 100;
      final pickupPointStr = data['pickupPoint']?.toString() ?? '';
      final pickupPoints = pickupPointStr.isNotEmpty
          ? pickupPointStr.split(',').map((e) => int.tryParse(e.trim()) ?? 0).where((v) => v > 0 && v <= 100).toList()
          : <int>[];

      final businessType =
          int.tryParse(data['businessType']?.toString() ?? '');

      await _handleLiveNotification(
        event: event?.toString(),
        bookingId: bookingId.toString(),
        uniqueId: uniqueId.toString(),
        status: status,
        progress: progressValue,
        destinationPoint: destinationPoint,
        pickupPoints: pickupPoints,
        businessType: businessType,
      );
      return;
    }

    if (title.isEmpty && body.isEmpty) {
      debugPrint('🔔 [showNotificationFromMessage] ⚠️ Empty title and body - skipping');
      return;
    }

    await showNotification(
      title: title,
      body: body,
      sound: sound,
      imageUrl: image,
      payload: message.messageId,
    );
  }

  /// Show a local notification
  Future<void> showNotification({
    required String title,
    required String body,
    String? sound,
    String? imageUrl,
    String? payload,
    bool isHighPriority = false,
  }) async {
    // Determine if we should play default sound or custom
    final bool hasCustomSound = sound != null && sound.isNotEmpty && sound != 'default' && sound != 'null';

    // Use high priority channel for important notifications
    final channelId = isHighPriority
        ? NotificationChannels.highPriorityChannelId
        : NotificationChannels.regularChannelId;
    final channelName = isHighPriority
        ? NotificationChannels.highPriorityChannelName
        : NotificationChannels.regularChannelName;
    final channelDesc = isHighPriority
        ? NotificationChannels.highPriorityChannelDesc
        : NotificationChannels.regularChannelDesc;

    // Download image if provided (matches Kotlin BigPictureStyle + iOS NotificationServiceExtension)
    String? imagePath;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      imagePath = await _downloadNotificationImage(imageUrl);
    }

    // Build style: BigPictureStyle if image available, otherwise BigTextStyle
    StyleInformation styleInfo;
    if (imagePath != null) {
      styleInfo = BigPictureStyleInformation(
        FilePathAndroidBitmap(imagePath),
        contentTitle: title,
        summaryText: body,
        largeIcon: FilePathAndroidBitmap(imagePath),
      );
    } else {
      styleInfo = BigTextStyleInformation(body);
    }

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: isHighPriority ? Importance.high : Importance.defaultImportance,
      priority: isHighPriority ? Priority.high : Priority.defaultPriority,
      playSound: !hasCustomSound, // Don't play channel sound if we have custom sound
      styleInformation: styleInfo,
      largeIcon: imagePath != null ? FilePathAndroidBitmap(imagePath) : null,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      attachments: imagePath != null
          ? [DarwinNotificationAttachment(imagePath)]
          : null,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Generate unique notification ID
    final notificationId = DateTime.now().millisecondsSinceEpoch.hashCode;

    debugPrint('🔔 [showNotification] Showing notification ID: $notificationId');
    debugPrint('🔔 [showNotification] Title: $title, Body: $body');

    try {
      await _localNotifications.show(
        notificationId,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
      debugPrint('🔔 [showNotification] ✅ Notification shown successfully');
    } catch (e) {
      debugPrint('🔔 [showNotification] ❌ Error showing notification: $e');
    }

    // Play custom sound if provided
    if (hasCustomSound) {
      await _playCustomSound(sound);
    }
  }

  /// Handle live booking notification with progress (matches Kotlin LiveNotificationManager)
  Future<void> _handleLiveNotification({
    String? event,
    required String bookingId,
    required String uniqueId,
    required int status,
    required int progress,
    required int destinationPoint,
    required List<int> pickupPoints,
    int? businessType,
  }) async {
    debugPrint('🔔 Live notification: bookingId=$bookingId, event=$event, status=$status, progress=$progress, businessType=$businessType');

    // Tear down on an explicit END, and also as soon as the driver marks the
    // arrival: the ride is over for the customer at that point, whether or not
    // the invoice is still pending. Without the status check a live push that
    // arrives after completion would rebuild the surface we just dismissed.
    // Case-insensitive: native's `LiveNotificationType.END` serialises as the
    // lowercase "end", so the old `event == 'END'` never matched a real push and
    // teardown silently depended on the status check alone.
    if (event?.toLowerCase() == 'end' ||
        status >= BookingStatus.arrivedAtDestination.value) {
      await dismissLiveNotification(bookingId);
      if (Platform.isIOS) {
        await LiveActivityManager.instance.stopActivity(bookingId);
      }
      return;
    }

    // iOS uses Live Activities and Android uses a native custom notification.
    if (Platform.isIOS || Platform.isAndroid) {
      await LiveActivityManager.instance.startActivity(
        bookingId: bookingId,
        uniqueId: uniqueId,
        statusText: _getBookingStatusText(status, businessType),
        status: status,
        progress: progress,
        pickupPoints: pickupPoints,
        destinationPoint: destinationPoint,
      );
      return;
    }
  }

  /// Get booking status text matching Kotlin's getCurrentBookingStatus.
  /// For delivery / quick-delivery bookings the taxi status labels don't fit
  /// (merchant + delivery-partner stages), so use the delivery status mapping.
  String _getBookingStatusText(int statusValue, [int? businessType]) {
    if (businessType == BusinessType.delivery ||
        businessType == BusinessType.quickDelivery) {
      return DeliveryOrderStatus.message(statusValue);
    }
    final status = BookingStatus.fromValue(statusValue);
    return switch (status) {
      BookingStatus.accepted || BookingStatus.bidding =>
        getString(appStr.descriptionDriverAccepted, 'description_driver_accepted'),
      BookingStatus.inRoute =>
        getString(appStr.bookingStatusInRoute, 'booking_status_in_route'),
      BookingStatus.arrivedAtPickup =>
        getString(appStr.bookingStatusArrivedAtPickup, 'booking_status_arrived_at_pickup'),
      BookingStatus.started =>
        getString(appStr.bookingStatusStarted, 'booking_status_started'),
      BookingStatus.arrivedAtDestination =>
        getString(appStr.descriptionArrivedAtYourDestination, 'description_arrived_at_your_destination'),
      _ => getString(appStr.headingConnectingNearbyDrivers, 'heading_connecting_nearby_drivers'),
    };
  }

  /// Dismiss live notification for a booking
  Future<void> dismissLiveNotification(String bookingId) async {
    final notificationId = bookingId.hashCode;
    if (Platform.isAndroid) {
      await LiveActivityManager.instance.stopActivity(bookingId);
      return;
    }
    await _localNotifications.cancel(notificationId);
    debugPrint('🔔 Live notification dismissed for booking: $bookingId');
  }

  /// Download notification image to temp file for display
  Future<String?> _downloadNotificationImage(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final fileName = 'notification_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);
        return file.path;
      }
    } catch (e) {
      debugPrint('🔔 Error downloading notification image: $e');
    }
    return null;
  }

  /// Play custom sound from storage or download it
  Future<void> _playCustomSound(String soundName) async {
    try {
      final soundFile = await _getSoundFile(soundName);

      if (soundFile != null && await soundFile.exists()) {
        await _audioPlayer.play(DeviceFileSource(soundFile.path));
        debugPrint('🔔 Playing custom sound: ${soundFile.path}');
      } else {
        debugPrint('🔔 Sound file not found: $soundName');
      }
    } catch (e) {
      debugPrint('🔔 Error playing sound: $e');
    }
  }

  /// Get sound file from storage
  Future<File?> _getSoundFile(String soundName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final soundsDir = Directory('${directory.path}/sounds');

      if (!await soundsDir.exists()) {
        await soundsDir.create(recursive: true);
      }

      final soundFile = File('${soundsDir.path}/$soundName');
      return soundFile;
    } catch (e) {
      debugPrint('🔔 Error getting sound file: $e');
      return null;
    }
  }

  /// Download and save sound file
  Future<bool> downloadSound(String soundUrl, String soundName) async {
    try {
      final response = await http.get(Uri.parse(soundUrl));

      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final soundsDir = Directory('${directory.path}/sounds');

        if (!await soundsDir.exists()) {
          await soundsDir.create(recursive: true);
        }

        final soundFile = File('${soundsDir.path}/$soundName');
        await soundFile.writeAsBytes(response.bodyBytes);

        debugPrint('🔔 Sound downloaded: $soundName');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('🔔 Error downloading sound: $e');
      return false;
    }
  }

  /// Check if sound file exists
  Future<bool> soundExists(String soundName) async {
    final soundFile = await _getSoundFile(soundName);
    return soundFile != null && await soundFile.exists();
  }

  /// Process notification action based on data (matches Kotlin handleNotificationAction)
  void _processNotificationAction(Map<String, dynamic> data) {
    final status = data['status'];
    final id = data['id'];

    if (status == 'ENTITY_STATUS' && id != null && id.toString().isNotEmpty) {
      debugPrint('🔔 Entity status notification received, id=$id');
      _pendingNotificationId = id.toString();

      final entityStatus = int.tryParse(id.toString());
      if (entityStatus != null) onEntityStatusChanged?.call(entityStatus);
    }
  }

  /// Fired when an ENTITY_STATUS push arrives (admin approved / declined /
  /// blocked the account). Native reloads the entity on this — see
  /// `FirebaseCloudMessagingService.handleNotificationAction`.
  void Function(int status)? onEntityStatusChanged;

  /// Pending notification ID from entity status notification
  String? _pendingNotificationId;

  /// Get and clear pending notification ID
  String? consumePendingNotificationId() {
    final id = _pendingNotificationId;
    _pendingNotificationId = null;
    return id;
  }

  /// Current subscribed topic (for unsubscription on logout)
  String? _currentTopic;

  /// Build mass notification topic: CUSTOMER_{ANDROID|IOS}_{countryId}
  static String buildTopic(String countryId) {
    final deviceType = Platform.isIOS ? 'IOS' : 'ANDROID';
    return 'CUSTOMER_${deviceType}_$countryId';
  }

  /// Subscribe to mass notification topic for country
  Future<void> subscribeToCountryTopic(String countryId) async {
    if (countryId.isEmpty) return;
    final topic = buildTopic(countryId);
    await subscribeToTopic(topic);
    _currentTopic = topic;
  }

  /// Unsubscribe from current country topic (call on logout)
  Future<void> unsubscribeFromCurrentTopic() async {
    if (_currentTopic != null) {
      await unsubscribeFromTopic(_currentTopic!);
      _currentTopic = null;
    }
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    debugPrint('🔔 Subscribed to topic: $topic');
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    debugPrint('🔔 Unsubscribed from topic: $topic');
  }

  /// Delete FCM token (useful for logout)
  Future<void> deleteToken() async {
    await _messaging.deleteToken();
    _fcmToken = null;
    debugPrint('🔔 FCM token deleted');
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Cancel specific notification
  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  /// Dispose resources
  void dispose() {
    _audioPlayer.dispose();
  }
}
