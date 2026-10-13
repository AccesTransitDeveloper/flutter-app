import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/router/app_navigation.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../viewmodels/splash_viewmodel.dart';
import '../../bottomsheets/app_update_bottom_sheet.dart';
import '../../widgets/move_server_bottom_sheet.dart';
import '../../widgets/multi_tap_detector.dart';
import 'startup_animation.dart';

/// Backdrop behind the splash artwork — only visible for the instant before the
/// image paints, and behind translucent system bars.
const _splashBackgroundColor = Color(0xFFF7F7F7);

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _animationDone = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(splashViewModelProvider.notifier).init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(splashViewModelProvider);
    final viewModel = ref.read(splashViewModelProvider.notifier);

    ref.listen<SplashState>(splashViewModelProvider, (previous, next) {
      if (next == SplashState.showAppUpdate) {
        _showAppUpdateBottomSheet(context, viewModel);
      } else if (next == SplashState.error) {
        // Native shows a snackbar on splash API failure (SplashViewModel's
        // ResponseState.Error branch) and stays put. Without this the Flutter
        // splash swallowed the failure entirely and sat on the artwork
        // forever, which reads as "the app never opens".
        final message = viewModel.errorMessage;
        if (message != null && message.isNotEmpty) {
          context.showErrorSnackBar(message);
        }
      } else if (next == SplashState.imageLoaded) {
        if (viewModel.isLoggedIn) {
          context.navigateToHome();
        } else {
          context.navigateToLogin();
        }
      }
    });

    // Draw edge-to-edge: transparent system bars so the splash artwork fills
    // the whole screen, including behind the status and navigation bars.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _splashBackgroundColor,
        body: MultiTapDetector(
          onMultiTap: () => showMoveServerBottomSheet(context, ref),
          child: _buildBody(context, state, viewModel),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, SplashState state, SplashViewModel viewModel) {
    if (!_animationDone) {
      return StartupAnimation(
        onCompleted: () {
          if (!mounted) return;
          setState(() => _animationDone = true);
          ref.read(splashViewModelProvider.notifier).onSplashAnimationCompleted();
        },
        onError: () {
          if (mounted) context.showErrorSnackBar('Startup animation could not play. Tap Retry to try again.');
        },
      );
    }
    return SafeArea(
      child: Center(
        child: state == SplashState.error
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Could not finish starting the app.'),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: viewModel.init, child: const Text('Retry')),
                ],
              )
            : const CircularProgressIndicator(),
      ),
    );
  }

  void _showAppUpdateBottomSheet(BuildContext context, SplashViewModel viewModel) {
    AppUpdateBottomSheet.show(
      context: context,
      isForceUpdate: viewModel.isForceUpdate,
      onUpdateNow: () => _openAppStore(viewModel.storeUrl),
      onSkipForNow: () {
        Navigator.pop(context);
        viewModel.skipUpdate();
      },
    );
  }

  Future<void> _openAppStore(String? storeUrl) async {
    Uri? uri;

    if (storeUrl != null && storeUrl.isNotEmpty) {
      uri = Uri.tryParse(storeUrl);
    }

    // Android fallback: try market:// first, then Play Store web URL
    if (uri == null && Platform.isAndroid) {
      uri = Uri.parse('market://details?id=com.accessible.customer');
    }

    if (uri != null) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        // Fallback to Play Store web URL
        if (Platform.isAndroid) {
          final webUri = Uri.parse(
            'https://play.google.com/store/apps/details?id=com.accessible.customer',
          );
          await launchUrl(webUri, mode: LaunchMode.externalApplication);
        }
      }
    }
  }

}
