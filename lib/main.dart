import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'core/theme/theme_notifier.dart';
import 'core/providers/app_providers.dart';
import 'core/router/app_router.dart';
import 'core/managers/live_activity_manager.dart';
import 'core/managers/session_manager.dart';
import 'core/managers/notification_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Initialize timezone database (needed to compute booking time in the
  // selected city's timezone — matches the native user app behaviour).
  tz_data.initializeTimeZones();

  // Suppress all debugPrint output in release builds
  if (!kDebugMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  // Initialize Firebase
  await Firebase.initializeApp();

  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize notification manager
  await NotificationManager.instance.init();

  // Initialize live activity manager (iOS only)
  LiveActivityManager.instance.init();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final serverConfigInit = ref.watch(serverConfigInitializerProvider);
    final router = ref.watch(goRouterProvider);

    // Initialize SessionManager with shared preferences
    ref.watch(sharedPreferenceManagerProvider).whenData((sharedPref) {
      SessionManager.instance.init(sharedPref);
    });

    // Set session expired callback to navigate to login
    SessionManager.instance.setSessionExpiredCallback(() {
      router.go('/login');
    });

    return serverConfigInit.when(
      data: (_) => MaterialApp.router(
        title: 'AT — Fair Rides NYC',
        theme: themeState.getLightTheme(),
        darkTheme: themeState.getDarkTheme(),
        themeMode: themeState.materialThemeMode,
        routerConfig: router,
      ),
      loading: () => const MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (error, stack) => MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Error initializing app: $error'),
          ),
        ),
      ),
    );
  }
}
