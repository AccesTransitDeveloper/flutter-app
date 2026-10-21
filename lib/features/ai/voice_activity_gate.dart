enum VoiceCaptureAction { wait, send, noSpeech }

/// Local end-of-utterance detection. Never send silence for transcription.
/// All timing is monotonic and injected so the policy is testable without audio.
class VoiceActivityGate {
  static const silenceWindow = Duration(milliseconds: 1600);
  static const noSpeechLimit = Duration(seconds: 10);
  static const recordingLimit = Duration(seconds: 60);
  static const speechThresholdDb = -40.0;

  int _speechSamples = 0;
  Duration? _lastSpeechAt;
  bool get hasSpeech => _speechSamples >= 2;

  void addAmplitude(double decibels, Duration elapsed) {
    if (!decibels.isFinite || decibels < speechThresholdDb) return;
    _speechSamples++;
    _lastSpeechAt = elapsed;
  }

  VoiceCaptureAction action(Duration elapsed) {
    if (hasSpeech) {
      if (elapsed >= recordingLimit ||
          elapsed - _lastSpeechAt! >= silenceWindow) {
        return VoiceCaptureAction.send;
      }
    } else if (elapsed >= noSpeechLimit) {
      return VoiceCaptureAction.noSpeech;
    }
    return VoiceCaptureAction.wait;
  }
}
