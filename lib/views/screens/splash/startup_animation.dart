import 'dart:async';

import 'package:flutter/material.dart';

/// Offline, single-play intro. Playback time starts with the first visible
/// frame, not with the network request or asset decode.
class StartupAnimation extends StatefulWidget {
  static const asset = 'assets/animations/at_startup.webp';
  static const duration = Duration(seconds: 6);
  final VoidCallback onCompleted;
  final VoidCallback onError;

  const StartupAnimation({
    super.key,
    required this.onCompleted,
    required this.onError,
  });

  @override
  State<StartupAnimation> createState() => _StartupAnimationState();
}

class _StartupAnimationState extends State<StartupAnimation>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _playback;
  Timer? _decodeTimer;
  bool _started = false;
  bool _firstFrameScheduled = false;
  bool _finished = false;
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    _playback = AnimationController(vsync: this, duration: StartupAnimation.duration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _finish();
      });
    WidgetsBinding.instance.addObserver(this);
    _foreground = WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    // A missing/corrupt asset must not permanently block sign-in.
    _decodeTimer = Timer(const Duration(seconds: 8), () => _finish(failed: true));
  }

  void _firstFrame() {
    if (!mounted || _started || _finished) return;
    _started = true;
    _decodeTimer?.cancel();
    _resume();
  }

  void _resume() {
    if (!_foreground || !_started || _finished) return;
    if (_playback.isCompleted) {
      _finish();
      return;
    }
    _playback.forward();
  }

  void _finish({bool failed = false}) {
    if (!mounted || _finished) return;
    _finished = true;
    _playback.stop();
    _decodeTimer?.cancel();
    if (failed) widget.onError();
    widget.onCompleted();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final foreground = state == AppLifecycleState.resumed;
    if (_foreground == foreground) return;
    setState(() => _foreground = foreground);
    if (foreground) {
      _resume();
    } else {
      _playback.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return TickerMode(
      enabled: _foreground,
      child: SizedBox.expand(
        child: Image.asset(
          StartupAnimation.asset,
          fit: BoxFit.contain,
          semanticLabel: 'Accessible Transit startup animation',
          frameBuilder: (context, child, frame, synchronous) {
            if (frame != null && !_firstFrameScheduled) {
              _firstFrameScheduled = true;
              WidgetsBinding.instance.addPostFrameCallback((_) => _firstFrame());
            }
            return child;
          },
          errorBuilder: (context, error, stackTrace) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _finish(failed: true));
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _playback.dispose();
    _decodeTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
