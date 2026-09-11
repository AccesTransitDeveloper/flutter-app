import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';

import '../../data/ai/ai_repository.dart';
import '../../core/preferences/shared_preference_manager.dart';
import 'ai_models.dart';

final aiRepositoryProvider = Provider.autoDispose<AiRepository>((ref) {
  final repository = AiRepository();
  ref.onDispose(repository.close);
  return repository;
});

final aiAssistantProvider =
    StateNotifierProvider.autoDispose<AiAssistantViewModel, AiAssistantState>(
  (ref) => AiAssistantViewModel(ref.watch(aiRepositoryProvider)),
);

class AiAssistantViewModel extends StateNotifier<AiAssistantState> {
  final AiRepository repository;
  final String sessionId =
      '${DateTime.now().microsecondsSinceEpoch}-${DateTime.now().millisecondsSinceEpoch % 100000}';
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  String? _recordingPath;
  StreamSubscription<void>? _completionSubscription;
  Future<void> _recorderQueue = Future<void>.value();
  Future<void> _playerQueue = Future<void>.value();
  int _generation = 0;
  bool _busy = false;
  bool _disposed = false;
  late final Future<void> _ready;

  AiAssistantViewModel(this.repository) : super(const AiAssistantState()) {
    _ready = _initializeGreeting();
  }

  Future<void> _initializeGreeting() async {
    try {
      final prefs = await SharedPreferenceManager.create();
      final entity = prefs.getEntity();
      final name = [entity?.firstName, entity?.lastName]
          .whereType<String>()
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .join(' ');
      final sanitizedName = name
          .replaceAll(RegExp(r'[^\p{L}\p{M}\p{N} .,\x27-]', unicode: true), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      repository.displayName = sanitizedName.isEmpty
          ? null
          : sanitizedName.length > 80
              ? sanitizedName.substring(0, 80)
              : sanitizedName;
      final greeting = await repository.initialize();
      if (!_disposed && mounted && greeting != null && greeting.isNotEmpty) {
        state = state.copyWith(
          messages: [AiMessage(text: greeting, fromUser: false)],
        );
      }
    } catch (_) {
      // The first user request will retry session initialization. Anonymous
      // web-compatible sessions remain supported when preferences are absent.
    }
  }

  bool _isCurrent(int generation) =>
      !_disposed && generation == _generation && mounted;

  Future<T> _enqueueRecorder<T>(Future<T> Function() operation) {
    final result = _recorderQueue.then((_) => operation());
    _recorderQueue = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    return result;
  }

  Future<T> _enqueuePlayer<T>(Future<T> Function() operation) {
    final result = _playerQueue.then((_) => operation());
    _playerQueue = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    return result;
  }

  Future<void> send(String text) => _sendMessage(text);

  Future<void> retryLastMessage() async {
    if (_busy || _disposed) return;
    final retryMessage = state.retryMessage;
    if (retryMessage != null && retryMessage.isNotEmpty) {
      await _sendMessage(retryMessage, addUserMessage: false);
    }
  }

  Future<void> _sendMessage(
    String text, {
    bool addUserMessage = true,
  }) async {
    final message = text.trim();
    if (message.isEmpty || _busy || state.isListening || _disposed) return;
    await _ready;
    if (_disposed) return;

    final generation = _generation;
    _busy = true;
    await stopPlayback();
    if (!_isCurrent(generation)) return;

    final priorMessages = List<AiMessage>.from(state.messages);
    final messages = addUserMessage
        ? [...priorMessages, AiMessage(text: message, fromUser: true)]
        : priorMessages;
    final failedIndex = priorMessages.lastIndexWhere(
      (item) => item.fromUser && item.text == message,
    );
    final history = addUserMessage || failedIndex < 0
        ? priorMessages
        : priorMessages.take(failedIndex).toList();

    state = state.copyWith(
      messages: messages,
      isLoading: true,
      clearError: true,
      clearRetryMessage: true,
      clearOrderSuggestion: true,
    );
    try {
      final reply = await repository.sendMessage(message, sessionId, history);
      if (!_isCurrent(generation)) return;
      state = state.copyWith(
        messages: [...messages, AiMessage(text: reply.text, fromUser: false)],
        isLoading: false,
        orderSuggestion: reply.orderSuggestion,
        clearOrderSuggestion: reply.orderSuggestion == null,
        clearRetryMessage: true,
      );
      if (reply.text.isNotEmpty) {
        await _speak(reply.text, generation);
      }
    } catch (error) {
      if (_isCurrent(generation)) {
        state = state.copyWith(
          isLoading: false,
          error: error.toString(),
          retryMessage: message,
        );
      }
    } finally {
      if (_isCurrent(generation)) {
        _busy = false;
      }
    }
  }

  Future<void> startListening() async {
    if (_busy || state.isListening || _disposed) return;
    final generation = _generation;
    _busy = true;
    try {
      await stopPlayback();
      if (!_isCurrent(generation)) return;
      final hasPermission = await _enqueueRecorder(
        () => _recorder.hasPermission(),
      );
      if (!_isCurrent(generation)) return;
      if (!hasPermission) {
        state = state.copyWith(
          error: 'Microphone permission is required for voice messages.',
        );
        return;
      }

      _recordingPath =
          '${Directory.systemTemp.path}/at-ai-${sessionId.hashCode}.m4a';
      await _enqueueRecorder(() async {
        if (!_isCurrent(generation)) return;
        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
          ),
          path: _recordingPath!,
        );
      });
      if (!_isCurrent(generation)) return;
      state = state.copyWith(isListening: true, clearError: true);
    } catch (error) {
      if (_isCurrent(generation)) {
        state = state.copyWith(
          error: 'Unable to start recording: $error',
          isListening: false,
        );
      }
    } finally {
      if (_isCurrent(generation)) {
        _busy = false;
      }
    }
  }

  Future<void> stopListening() async {
    if (!state.isListening || _busy || _disposed) return;
    final generation = _generation;
    _busy = true;
    state = state.copyWith(isListening: false, isLoading: true);
    String? path;
    try {
      path = await _enqueueRecorder(_recorder.stop);
      if (!_isCurrent(generation)) return;
      if (path == null) throw Exception('No recording was captured.');
      final bytes = await File(path).readAsBytes();
      if (!_isCurrent(generation)) return;
      final transcript =
          await repository.transcribe(base64Encode(bytes), 'audio/mp4');
      if (!_isCurrent(generation)) return;
      if (transcript.trim().isEmpty) {
        state = state.copyWith(isLoading: false);
      } else {
        _busy = false;
        await _sendMessage(transcript);
      }
    } catch (error) {
      if (_isCurrent(generation)) {
        state = state.copyWith(isLoading: false, error: error.toString());
      }
    } finally {
      if (path != null) {
        try {
          await File(path).delete();
        } catch (_) {
          // Temporary-file cleanup is best effort.
        }
      }
      if (_isCurrent(generation)) {
        _busy = false;
      }
    }
  }

  Future<void> _speak(String text, int generation) async {
    try {
      final bytes = await repository.tts(text);
      if (!_isCurrent(generation)) return;
      await _completionSubscription?.cancel();
      _completionSubscription = null;
      await _enqueuePlayer(() async {
        if (!_isCurrent(generation)) return;
        await _player.stop();
        if (!_isCurrent(generation)) return;
        state = state.copyWith(isSpeaking: true);
        _completionSubscription = _player.onPlayerComplete.listen((_) {
          if (_isCurrent(generation)) {
            state = state.copyWith(isSpeaking: false);
          }
        });
        await _player.play(BytesSource(bytes), volume: 1);
      });
    } catch (error) {
      if (_isCurrent(generation)) {
        state = state.copyWith(
          isSpeaking: false,
          error: 'Unable to play AI voice: $error',
          clearRetryMessage: true,
        );
      }
    }
  }

  Future<void> stopPlayback() async {
    final generation = _generation;
    await _completionSubscription?.cancel();
    _completionSubscription = null;
    try {
      await _enqueuePlayer(_player.stop);
    } catch (_) {
      // A stop failure must not prevent future player commands.
    }
    if (_isCurrent(generation)) {
      state = state.copyWith(isSpeaking: false);
    }
  }

  void clearError() {
    if (!_disposed) {
      state = state.copyWith(clearError: true);
    }
  }

  void clear() {
    if (_disposed) return;
    _generation++;
    _busy = false;
    final recordingPath = _recordingPath;
    _recordingPath = null;
    unawaited(_stopRecordingForReset(recordingPath));
    unawaited(stopPlayback());
    state = const AiAssistantState();
  }

  Future<void> _stopRecordingForReset(String? recordingPath) async {
    try {
      await _enqueueRecorder(_recorder.stop);
    } catch (_) {
      // The recorder may already be stopped.
    }
    if (recordingPath != null) {
      try {
        await File(recordingPath).delete();
      } catch (_) {
        // Temporary-file cleanup is best effort.
      }
    }
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _generation++;
    _busy = false;
    unawaited(_completionSubscription?.cancel());
    unawaited(_enqueueRecorder(() async {
      try {
        await _recorder.stop();
      } catch (_) {}
      try {
        await _recorder.dispose();
      } catch (_) {}
    }));
    unawaited(_enqueuePlayer(() async {
      try {
        await _player.stop();
      } catch (_) {}
      try {
        await _player.dispose();
      } catch (_) {}
    }));
    super.dispose();
  }
}