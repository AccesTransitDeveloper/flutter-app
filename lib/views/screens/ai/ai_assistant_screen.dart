import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../features/ai/ai_models.dart';
import '../../../features/ai/ai_viewmodel.dart';
import '../../../features/ai/voice_orb.dart';

class AiAssistantScreen extends ConsumerStatefulWidget {
  final ValueChanged<OrderSuggestion>? onContinueInPlanRide;

  const AiAssistantScreen({super.key, this.onContinueInPlanRide});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  String _languageCode = 'en';

  static const _languages = <_AiLanguage>[
    _AiLanguage('en', 'EN', 'English', 'Message'),
    _AiLanguage('ru', 'RU', 'Русский', 'Сообщение'),
    _AiLanguage('es', 'ES', 'Español', 'Mensaje'),
    _AiLanguage('ar', 'AR', 'العربية', 'رسالة'),
    _AiLanguage('zh', 'ZH', '中文', '消息'),
    _AiLanguage('hi', 'HI', 'हिन्दी', 'संदेश'),
    _AiLanguage('tr', 'TR', 'Türkçe', 'Mesaj'),
    _AiLanguage('ja', 'JA', '日本語', 'メッセージ'),
  ];

  _AiLanguage get _selectedLanguage =>
      _languages.firstWhere((language) => language.code == _languageCode);

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
      backgroundColor: const Color(0xFF071A36),
      appBar: AppBar(
        automaticallyImplyLeading: widget.onContinueInPlanRide == null,
        backgroundColor: const Color(0xFF071A36),
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text('AT AI'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Select language',
            initialValue: _languageCode,
            onSelected: (value) => setState(() => _languageCode = value),
            itemBuilder: (context) => [
              for (final language in _languages)
                PopupMenuItem(
                  value: language.code,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 34,
                        child: Text(
                          language.shortLabel,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Text(language.name),
                    ],
                  ),
                ),
            ],
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: .12)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.language_rounded, size: 18),
                  const SizedBox(width: 5),
                  Text(
                    _selectedLanguage.shortLabel,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 17),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            onPressed: state.messages.isEmpty ? null : viewModel.clear,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear conversation',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: widget.onContinueInPlanRide == null ? 0 : 82,
          ),
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Travel & ride assistant',
                  style: TextStyle(
                    color: Color(0xFF93A8C7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              VoiceOrb(mode: mode, size: 126),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: Text(
                  _statusText(state),
                  key: ValueKey(mode),
                  style: const TextStyle(
                    color: Color(0xFFB8C7DE),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                _selectedLanguage.name,
                style: const TextStyle(
                  color: Color(0xFF38BDF8),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
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
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  itemCount: state.messages.length,
                  itemBuilder: (_, index) => _bubble(state.messages[index]),
                ),
              ),
              if (state.isLoading) const _ThinkingBubble(),
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
                      onPressed: () =>
                          ref.read(aiAssistantProvider.notifier).clearError(),
                      child: const Text('Dismiss'),
                    ),
                  ],
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF102744),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: .10),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: .22),
                              blurRadius: 16,
                              offset: const Offset(0, 7),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _input,
                          style: const TextStyle(color: Colors.white),
                          textInputAction: TextInputAction.send,
                          onChanged: (_) => setState(() {}),
                          onSubmitted: (_) => _send(),
                          decoration: InputDecoration(
                            hintText: _selectedLanguage.messageHint,
                            hintStyle: const TextStyle(
                              color: Color(0xFF8294AF),
                              fontSize: 18,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 15,
                            ),
                            suffixIcon: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              child: _input.text.trim().isEmpty
                                  ? const Icon(
                                      Icons.motion_photos_on_outlined,
                                      key: ValueKey('idle'),
                                      color: Color(0xFF8294AF),
                                    )
                                  : IconButton(
                                      key: const ValueKey('send'),
                                      onPressed: state.isLoading ? null : _send,
                                      icon: const Icon(
                                        Icons.arrow_upward_rounded,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Semantics(
                      button: true,
                      label: state.isListening
                          ? 'Stop voice message'
                          : 'Record voice message in ${_selectedLanguage.name}',
                      child: Material(
                        color: state.isListening
                            ? const Color(0xFFE5484D)
                            : const Color(0xFF102744),
                        shape: const CircleBorder(),
                        elevation: 8,
                        shadowColor: Colors.black.withValues(alpha: .35),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: state.isLoading
                              ? null
                              : (state.isListening
                                    ? viewModel.stopListening
                                    : viewModel.startListening),
                          child: SizedBox.square(
                            dimension: 56,
                            child: Icon(
                              state.isListening
                                  ? Icons.stop_rounded
                                  : Icons.mic_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bubble(AiMessage message) {
    return Align(
      alignment: message.fromUser
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.fromUser) ...[
            const CircleAvatar(
              radius: 15,
              backgroundImage: AssetImage('assets/images/at_ai_avatar.png'),
            ),
            const SizedBox(width: 7),
          ],
          Flexible(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 5),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
              constraints: const BoxConstraints(maxWidth: 310),
              decoration: BoxDecoration(
                gradient: message.fromUser
                    ? const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF1557C0)],
                      )
                    : const LinearGradient(
                        colors: [Color(0xFF152E50), Color(0xFF102744)],
                      ),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(message.fromUser ? 20 : 5),
                  bottomRight: Radius.circular(message.fromUser ? 5 : 20),
                ),
                border: Border.all(color: Colors.white.withValues(alpha: .08)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .16),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: const TextStyle(color: Colors.white, height: 1.35),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _statusText(AiAssistantState state) {
    if (state.isListening) return 'Listening…';
    if (state.isLoading) return 'Thinking…';
    if (state.isSpeaking) return 'Speaking…';
    return 'Ready to help';
  }

  Widget _orderCard(OrderSuggestion suggestion) {
    return Card(
      color: const Color(0xFF102744),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Route ready',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (suggestion.pickup != null)
              Text(
                'From: ${suggestion.pickup}',
                style: const TextStyle(color: Color(0xFFB8C7DE)),
              ),
            if (suggestion.destination != null)
              Text(
                'To: ${suggestion.destination}',
                style: const TextStyle(color: Color(0xFFB8C7DE)),
              ),
            const SizedBox(height: 6),
            OutlinedButton(
              onPressed: () {
                final onContinue = widget.onContinueInPlanRide;
                if (onContinue != null) {
                  onContinue(suggestion);
                } else {
                  context.pop<OrderSuggestion>(suggestion);
                }
              },
              child: const Text('Continue in Plan Ride'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiLanguage {
  final String code;
  final String shortLabel;
  final String name;
  final String messageHint;

  const _AiLanguage(this.code, this.shortLabel, this.name, this.messageHint);
}

class _ThinkingBubble extends StatefulWidget {
  const _ThinkingBubble();

  @override
  State<_ThinkingBubble> createState() => _ThinkingBubbleState();
}

class _ThinkingBubbleState extends State<_ThinkingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(54, 0, 12, 5),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 3; i++)
                Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF67E8F9).withValues(
                      alpha:
                          .28 +
                          .72 *
                              (.5 +
                                  .5 *
                                      math.sin(
                                        _controller.value * math.pi * 2 -
                                            i * .9,
                                      )),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
