import 'dart:io';
import '../lib/views/screens/splash/startup_video_html.dart';

File source(String path) => File.fromUri(Platform.script.resolve('../$path'));
void require(bool condition, String message) {
  if (!condition) throw StateError(message);
}

void main() {
  for (final path in [
    'lib/views/screens/support/support_chat_screen.dart',
    'lib/views/screens/support/sos_screen.dart',
  ]) {
    require(!RegExp(r'\bCRM\b', caseSensitive: false).hasMatch(source(path).readAsStringSync()),
        'User-facing support/SOS must not mention CRM.');
  }
  final sos = source('lib/views/screens/support/sos_screen.dart').readAsStringSync();
  require(sos.contains("_call('+16469882066')"), 'Dispatch dialer must use the requested US number.');
  require(sos.indexOf("label: const Text('Call 911") <
      sos.indexOf("label: const Text('Call AT dispatch"), '911 must appear before dispatch.');
  require(!sos.contains('widget.callDispatch'), 'SOS must not use the old configurable dispatch phone.');
  final pubspec = source('pubspec.yaml').readAsStringSync();
  require(pubspec.contains('- assets/animations/at_startup.mp4') &&
      !pubspec.contains('at_startup.webp'), 'Original MP4 must be bundled offline.');
  final screen = source('lib/views/screens/splash/splash_screen.dart').readAsStringSync();
  require(screen.contains('StartupAnimation(') && !screen.contains('logo_splash.png') &&
      !screen.contains('CachedNetworkImage'), 'The startup animation must replace static/remote splash images.');
  final model = source('lib/viewmodels/splash_viewmodel.dart').readAsStringSync();
  require(model.contains('_isApiDone && _isSplashAnimationDone'), 'Startup must wait for both API and animation.');
  require(startupVideoFinished(6, 6) && !startupVideoFinished(5.999, 6) &&
      !startupVideoFinished(6, double.nan) && !startupVideoFinished(6, 3),
      'Only complete six-second playback may open the app.');
  final html = startupVideoHtml('ORIGINAL_MP4_BYTES');
  require(html.contains('data:video/mp4;base64,ORIGINAL_MP4_BYTES') &&
      html.contains('object-fit:cover') && html.contains('object-position:center') &&
      html.contains('width:100vw;height:100vh') && !html.contains('object-fit:contain'),
      'Original video must fill the screen without bars or stretching.');
  require(html.contains("addEventListener('ended'") &&
      !html.contains('setTimeout') && !html.contains(' loop'),
      'Startup completion must follow the actual video end.');
  final playback = source('lib/views/screens/splash/startup_animation.dart').readAsStringSync();
  require(playback.contains('Retry animation') && playback.contains('startupVideoFinished') &&
      !playback.contains('AnimationController'),
      'Playback failures must allow retry rather than silently skip the intro.');
  print('Customer support presentation and original six-second startup checks passed.');
}
