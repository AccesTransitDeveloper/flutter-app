import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

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
  require(pubspec.contains('- assets/animations/at_startup.webp'), 'Animation must be bundled offline.');
  final screen = source('lib/views/screens/splash/splash_screen.dart').readAsStringSync();
  require(screen.contains('StartupAnimation(') && !screen.contains('logo_splash.png') &&
      !screen.contains('CachedNetworkImage'), 'The startup animation must replace static/remote splash images.');
  final model = source('lib/viewmodels/splash_viewmodel.dart').readAsStringSync();
  require(model.contains('_isApiDone && _isSplashAnimationDone'), 'Startup must wait for both API and animation.');
  final bytes = source('assets/animations/at_startup.webp').readAsBytesSync();
  final data = ByteData.sublistView(bytes);
  require(ascii.decode(bytes.sublist(0, 4)) == 'RIFF' &&
      ascii.decode(bytes.sublist(8, 12)) == 'WEBP', 'Bundled animation must be WebP.');
  var frames = 0, duration = 0, loop = -1;
  for (var offset = 12; offset + 8 <= bytes.length;) {
    final type = ascii.decode(bytes.sublist(offset, offset + 4));
    final length = data.getUint32(offset + 4, Endian.little);
    final start = offset + 8;
    require(start + length <= bytes.length, 'Animation chunk must not be truncated.');
    if (type == 'ANIM') loop = data.getUint16(start + 4, Endian.little);
    if (type == 'ANMF') {
      frames++;
      duration += bytes[start + 12] | (bytes[start + 13] << 8) | (bytes[start + 14] << 16);
    }
    offset = start + length + (length % 2);
  }
  // WebP stores integer milliseconds; 24 fps conversion can round by 1 ms.
  require(frames == 144 && (duration - 6000).abs() <= 2 && loop == 1,
      'Intro must retain 144 frames / six seconds and play once.');
  print('Customer text, SOS dialer/order, offline startup and animation metadata checks passed.');
}
