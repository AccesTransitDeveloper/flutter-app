import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'startup_video_html.dart';

/// Uses the already installed native WebView's H.264 player. The bundled MP4
/// is the user's original file, not resized or recompressed.
class StartupAnimation extends StatefulWidget {
  static const asset = 'assets/animations/at_startup.mp4';
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
    with WidgetsBindingObserver {
  InAppWebViewController? _controller;
  String? _html;
  bool _failed = false;
  bool _completed = false;
  bool _foreground = true;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _foreground = WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    _load();
  }

  Future<void> _load() async {
    final generation = ++_generation;
    setState(() { _failed = false; _html = null; _controller = null; });
    try {
      final bytes = await rootBundle.load(StartupAnimation.asset)
          .timeout(const Duration(seconds: 10));
      final original = bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes);
      final html = startupVideoHtml(base64Encode(original));
      if (mounted && generation == _generation) setState(() => _html = html);
    } catch (_) { _fail(generation); }
  }

  void _fail(int generation) {
    if (!mounted || _completed || _failed || generation != _generation) return;
    setState(() => _failed = true);
    widget.onError();
    // A playback failure is never treated as six seconds of completed video.
  }

  void _ended(int generation, List<dynamic> arguments) {
    if (!mounted || _completed || _failed || generation != _generation ||
        arguments.length != 2 || !startupVideoFinished(arguments[0], arguments[1])) return;
    _completed = true;
    widget.onCompleted();
  }

  Future<void> _syncPlayback(int generation) async {
    if (_controller == null || _completed || _failed) return;
    try {
      await _controller!.evaluateJavascript(source:
          _foreground
              ? 'if(window.atStartupResume) window.atStartupResume();'
              : 'if(window.atStartupPause) window.atStartupPause();');
    } catch (_) { _fail(generation); }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    unawaited(_syncPlayback(_generation));
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Startup video could not play.'),
        const SizedBox(height: 12),
        FilledButton(onPressed: _load, child: const Text('Retry animation')),
      ]));
    }
    if (_html == null) return const Center(child: CircularProgressIndicator());
    final generation = _generation;
    return SizedBox.expand(child: InAppWebView(
      key: ValueKey(generation),
      initialData: InAppWebViewInitialData(data: _html!),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        mediaPlaybackRequiresUserGesture: false,
        allowsInlineMediaPlayback: true,
        disableHorizontalScroll: true,
        disableVerticalScroll: true,
        supportZoom: false,
        transparentBackground: true,
      ),
      onWebViewCreated: (controller) {
        _controller = controller;
        controller.addJavaScriptHandler(handlerName: 'startupVideoEnded',
            callback: (arguments) { _ended(generation, arguments); return null; });
        controller.addJavaScriptHandler(handlerName: 'startupVideoError',
            callback: (_) { _fail(generation); return null; });
      },
      onLoadStop: (_, __) => _syncPlayback(generation),
    ));
  }

  @override
  void dispose() {
    _generation++;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
