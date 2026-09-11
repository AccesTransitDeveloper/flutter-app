import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../features/ai/ai_models.dart';
import '../../../features/ai/ai_viewmodel.dart';
import '../../../features/ai/voice_orb.dart';

class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final text = _input.text;
    _input.clear();
    ref.read(aiAssistantProvider.notifier).send(text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiAssistantProvider);
    final viewModel = ref.read(aiAssistantProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
    final mode = state.isListening
        ? VoiceOrbMode.listening
        : state.isLoading
            ? VoiceOrbMode.thinking
            : state.isSpeaking
                ? VoiceOrbMode.speaking
                : VoiceOrbMode.idle;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AT AI'),
        actions: [
          IconButton(
            onPressed: state.messages.isEmpty ? null : viewModel.clear,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear conversation',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Travel & ride assistant',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            VoiceOrb(mode: mode, size: 82),
            Text(
              state.isListening
                  ? 'Listening…'
                  : state.isLoading
                      ? 'Thinking…'
                      : state.isSpeaking
                          ? 'Speaking…'
                          : 'Ready',
            ),
            if (state.isSpeaking)
              TextButton.icon(
                onPressed: viewModel.stopPlayback,
                icon: const Icon(Icons.stop),
                label: const Text('Stop playback'),
              ),
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.all(12),
                itemCount: state.messages.length,
                itemBuilder: (_, index) => _bubble(state.messages[index]),
              ),
            ),
            if (state.orderSuggestion != null)
              _orderCard(state.orderSuggestion!),
            if (state.error != null)
              MaterialBanner(
                content: Text(state.error!),
                actions: [
                  TextButton(
                    onPressed: state.isLoading || state.retryMessage == null
                        ? null
                        : viewModel.retryLastMessage,
                    child: const Text('Retry'),
                  ),
                  TextButton(
                    onPressed: () => ref
                        .read(aiAssistantProvider.notifier)
                        .clearError(),
                    child: const Text('Dismiss'),
                  ),
                ],
              ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      textInputAction: TextInputAction.send,
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Ask AT AI…',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: state.isLoading
                        ? null
                        : (state.isListening
                            ? viewModel.stopListening
                            : viewModel.startListening),
                    icon: Icon(
                      state.isListening ? Icons.stop_circle : Icons.mic,
                    ),
                    tooltip: 'Voice message',
                  ),
                  IconButton(
                    onPressed: state.isLoading || _input.text.trim().isEmpty
                        ? null
                        : _send,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bubble(AiMessage message) {
    final colors = Theme.of(context).colorScheme;
    return Align(
      alignment:
          message.fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 330),
        decoration: BoxDecoration(
          color: message.fromUser
              ? colors.primary
              : colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: message.fromUser ? colors.onPrimary : null,
          ),
        ),
      ),
    );
  }

  Widget _orderCard(OrderSuggestion suggestion) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Route ready',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            if (suggestion.pickup != null) Text('From: ${suggestion.pickup}'),
            if (suggestion.destination != null)
              Text('To: ${suggestion.destination}'),
            const SizedBox(height: 6),
            OutlinedButton(
              onPressed: () => context.pop<OrderSuggestion>(suggestion),
              child: const Text('Continue in Plan Ride'),
            ),
          ],
        ),
      ),
    );
  }
}