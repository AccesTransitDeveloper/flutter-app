import 'dart:io';
import '../lib/features/ai/voice_activity_gate.dart';

void check(bool condition, String message) {
  if (!condition) throw StateError(message);
}

String source(String path) =>
    File.fromUri(Platform.script.resolve('../$path')).readAsStringSync();

void main() {
  final silence = VoiceActivityGate();
  check(silence.action(const Duration(seconds: 9)) == VoiceCaptureAction.wait,
      'Allow time to begin speaking.');
  check(silence.action(const Duration(seconds: 10)) == VoiceCaptureAction.noSpeech,
      'Silence must close the microphone, not be sent to AI.');
  silence.addAmplitude(double.nan, Duration.zero);
  silence.addAmplitude(double.infinity, Duration.zero);
  silence.addAmplitude(-70, Duration.zero);
  check(!silence.hasSpeech, 'Ignore invalid values and background quiet.');

  final singleClick = VoiceActivityGate();
  singleClick.addAmplitude(-15, const Duration(milliseconds: 200));
  check(singleClick.action(const Duration(seconds: 10)) ==
      VoiceCaptureAction.noSpeech, 'A single click is not speech.');

  final sentence = VoiceActivityGate();
  sentence.addAmplitude(-25, const Duration(milliseconds: 200));
  sentence.addAmplitude(-30, const Duration(milliseconds: 400));
  check(sentence.action(const Duration(milliseconds: 1900)) ==
      VoiceCaptureAction.wait, 'A brief pause must not cut off speech.');
  sentence.addAmplitude(-28, const Duration(milliseconds: 1900));
  check(sentence.action(const Duration(milliseconds: 3400)) ==
      VoiceCaptureAction.wait, 'Resume speaking resets the silence window.');
  check(sentence.action(const Duration(milliseconds: 3500)) ==
      VoiceCaptureAction.send, 'Auto-send after 1.6 seconds of silence.');

  final continuous = VoiceActivityGate();
  for (var second = 0; second < 60; second++) {
    continuous.addAmplitude(-20, Duration(seconds: second));
    if (second > 0) {
      check(continuous.action(Duration(seconds: second)) == VoiceCaptureAction.wait,
          'Continuous speech should not end early.');
    }
  }
  check(continuous.action(const Duration(seconds: 60)) == VoiceCaptureAction.send,
      'Bound microphone capture to sixty seconds.');

  final model = source('lib/features/ai/ai_viewmodel.dart');
  check(model.contains('onAmplitudeChanged(') &&
      model.contains('_amplitudeStream ??=') &&
      model.contains('.asBroadcastStream()') &&
      model.contains('unawaited(stopListening())') &&
      model.contains('void _stopVoiceDetection()') &&
      model.contains('_voiceTimer?.cancel()') &&
      model.contains('_amplitudeSubscription?.cancel()') &&
      model.contains('void suspendVoice()'),
      'End detection must auto-submit through existing transcription and clean up.');
  final main = source('lib/views/screens/main_screen.dart');
  check(main.contains('previousIndex == 2 && index != 2') &&
      main.contains('.suspendVoice()'),
      'Leaving the AI tab must stop capture without sending hidden audio.');
  final payment = source('lib/views/screens/payment/payment_screen.dart');
  final paymentBody = payment.substring(payment.indexOf('// Scrollable content'));
  check(paymentBody.indexOf('_PaymentMethodsSection(') <
      paymentBody.indexOf('_WalletDetailsSection(') &&
      RegExp(r'_PaymentMethodsSection\(').allMatches(payment).length == 2 &&
      payment.contains('showAddCard: state.showAddCard'),
      'Card section must be above wallet, once only, preserving gateway rules.');
  print('Voice end detection, microphone cleanup and customer wallet source checks passed.');
}
