import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/router/app_route_observer.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/support/support_controller.dart';
import '../../../features/support/support_models.dart';
import '../../../features/support/support_push.dart';
import '../../../core/preferences/shared_preference_manager.dart';
import 'support_composer.dart';
import 'support_message_widgets.dart';

class SupportChatScreen extends ConsumerStatefulWidget {
  final SupportController Function(SharedPreferenceManager)? controllerFactory;
  final String? initialChatId;
  const SupportChatScreen({super.key, this.controllerFactory, this.initialChatId});
  @override
  ConsumerState<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends ConsumerState<SupportChatScreen> with WidgetsBindingObserver, RouteAware {
  SupportController? _c;
  SupportImageCache? _cache;
  String? _fatal;
  bool _subscribed = false, _foreground = true, _covered = false;
  int _ackSeq = 0, _ackScheduled = 0;
  StreamSubscription<SupportPush>? _pushSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pushSubscription = SupportPushHub.instance.updates.listen((push) {
      final c = _c;
      if (c != null && c.accountId == push.ownerId && c.selectedChat?.id == push.chatId &&
          _foreground && !_covered) { c.refresh(); }
    });
    _boot();
  }

  Future<void> _boot() async {
    setState(() => _fatal = null);
    try {
      final prefs = await ref.read(sharedPreferenceManagerProvider.future);
      final c = widget.controllerFactory?.call(prefs) ?? SupportController(prefs);
      if (!mounted) { c.dispose(); return; }
      c.addListener(_onChange);
      setState(() { _c = c; _cache = SupportImageCache(c.api); });
      await c.initialize();
      if (widget.initialChatId != null) await c.openPushChat(widget.initialChatId!);
      _syncPolling();
    } catch (e) {
      if (mounted) setState(() => _fatal = e is Exception ? e.toString() : 'Could not open Support Chat.');
    }
  }

  void _onChange() { if (mounted) { _syncVisibility(); setState(() {}); } }

  void _syncVisibility() {
    final c = _c, hub = SupportPushHub.instance;
    if (_foreground && !_covered && c?.conversationOpen == true) {
      hub.visibleOwnerId = c!.accountId; hub.visibleChatId = c.selectedChat?.id;
    } else if (hub.visibleOwnerId == c?.accountId) {
      hub.visibleOwnerId = null; hub.visibleChatId = null;
    }
  }

  void _syncPolling() {
    _syncVisibility();
    final c = _c;
    if (c == null) return;
    (_foreground && !_covered) ? c.startPolling() : c.stopPolling();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (!_subscribed && route != null) { routeObserver.subscribe(this, route); _subscribed = true; }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) { _foreground = s == AppLifecycleState.resumed; if (_foreground) _ackSeq = _ackSeq; _syncPolling(); }
  @override
  void didPushNext() { _covered = true; _syncPolling(); }
  @override
  void didPopNext() { _covered = false; _syncPolling(); _c?.refresh(); }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);
    _pushSubscription?.cancel();
    _covered = true; _syncVisibility();
    _c?.removeListener(_onChange);
    _c?.dispose();
    super.dispose();
  }

  void _visible(int seq) {
    final c = _c;
    if (c == null || !_foreground || _covered || seq <= _ackSeq || seq <= _ackScheduled) return;
    _ackScheduled = seq;
    final chatId = c.selectedChat?.id;
    c.markVisibleMessages(seq).then((success) {
      if (!mounted || c.selectedChat?.id != chatId) return;
      if (success && seq > _ackSeq) _ackSeq = seq;
      if (!success) _ackScheduled = _ackSeq;
    });
  }

  Future<void> _open(SupportChat? chat) async {
    _ackSeq = 0; _ackScheduled = 0;
    await _c?.openChat(chat);
  }

  @override
  Widget build(BuildContext context) {
    final col = context.colors;
    final c = _c;
    final open = c?.conversationOpen ?? false;
    return PopScope(
      canPop: !open,
      onPopInvokedWithResult: (didPop, _) { if (!didPop) { c?.backToList(); } },
      child: Scaffold(
        backgroundColor: col.colorBackground,
        appBar: AppBar(
          backgroundColor: col.colorBackground, surfaceTintColor: Colors.transparent, elevation: 0, foregroundColor: col.colorText,
          leading: BackButton(onPressed: () { if (open) { c?.backToList(); } else { Navigator.of(context).maybePop(); } }),
          titleSpacing: 0,
          title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(open ? (c?.selectedChat?.subject ?? 'New conversation') : 'AT Support Chat', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            Text(open && c?.selectedChat != null ? 'Ticket ${c!.selectedChat!.ticketNumber} · ${c.selectedChat!.status.replaceAll('_', ' ')}' : 'Real CRM dispatchers, not AI',
                style: TextStyle(fontSize: 12, color: col.colorTextHint)),
          ]),
          bottom: PreferredSize(preferredSize: const Size.fromHeight(2), child: (c?.loading ?? false) || (c?.loadingOlder ?? false) ? const LinearProgressIndicator(minHeight: 2) : const SizedBox(height: 2)),
        ),
        body: _fatal != null
            ? _Notice(icon: Icons.lock_outline_rounded, title: 'Support Chat unavailable', body: _fatal!, action: 'Try again', onAction: _boot)
            : c == null || !c.ready
                ? const Center(child: CircularProgressIndicator())
                : AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260), switchInCurve: Curves.easeOutCubic,
                    transitionBuilder: (w, a) => FadeTransition(opacity: a, child: SlideTransition(position: Tween(begin: const Offset(0.04, 0), end: Offset.zero).animate(a), child: w)),
                    child: open ? _conversation(c, col) : _list(c, col),
                  ),
      ),
    );
  }

  Widget _errorBanner(SupportController c, AppColorPalette col) {
    final e = c.error;
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      child: e == null ? const SizedBox(width: double.infinity) : Semantics(
        liveRegion: true,
        child: Container(
          width: double.infinity, margin: const EdgeInsets.fromLTRB(12, 6, 12, 0), padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
          decoration: BoxDecoration(color: col.colorWarning.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            Icon(Icons.error_outline_rounded, size: 18, color: col.colorWarning), const SizedBox(width: 8),
            Expanded(child: Text(e, style: const TextStyle(fontSize: 13))),
            TextButton(onPressed: c.locked ? c.send : (c.conversationOpen && c.selectedChat == null ? null : c.refresh), child: Text(c.locked ? 'Retry' : 'Reload')),
          ]),
        ),
      ),
    );
  }

  Widget _list(SupportController c, AppColorPalette col) {
    return Column(key: const ValueKey('list'), children: [
      _errorBanner(c, col),
      Expanded(
        child: c.loading && c.chats.isEmpty
            ? ListView(padding: const EdgeInsets.all(16), children: [for (var i = 0; i < 4; i++) Container(height: 78, margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: col.colorBackgroundGray, borderRadius: BorderRadius.circular(16)))])
            : c.chats.isEmpty
                ? (c.error != null ? _Notice(icon: Icons.cloud_off_rounded, title: 'Could not load conversations', body: c.error!, action: 'Retry', onAction: c.refresh) : _Notice(icon: Icons.support_agent_rounded, title: 'Talk to a real dispatcher', body: 'Send a message, photos, documents or your location. A person on the AT CRM team reads and replies here.', action: 'Start a conversation', onAction: () => _open(null)))
                : RefreshIndicator(
                    onRefresh: c.refresh,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                      itemCount: c.chats.length, separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _ChatTile(chat: c.chats[i], onTap: () => _open(c.chats[i])),
                    ),
                  ),
      ),
      if (c.chats.isNotEmpty)
        SafeArea(top: false, child: Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 12), child: SizedBox(width: double.infinity, height: 52, child: FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: col.colorButtonBackground, foregroundColor: col.colorButtonText, shape: const StadiumBorder()),
          onPressed: () => _open(null), icon: const Icon(Icons.edit_outlined), label: const Text('New conversation', style: TextStyle(fontWeight: FontWeight.w700)),
        )))),
    ]);
  }

  Widget _conversation(SupportController c, AppColorPalette col) {
    final cache = _cache!;
    final msgs = c.messages.reversed.toList();
    final pending = c.locked && (c.text.trim().isNotEmpty || c.files.isNotEmpty || c.location != null);
    final extra = (pending ? 1 : 0) + (c.hasMoreMessages ? 1 : 0);
    final empty = msgs.isEmpty && !pending && !c.loading;
    return Column(key: const ValueKey('chat'), children: [
      _errorBanner(c, col),
      Expanded(
        child: empty
            ? _Notice(icon: Icons.forum_outlined, title: c.error != null && c.selectedChat != null ? 'Conversation did not load' : 'Say what you need', body: c.error != null && c.selectedChat != null ? c.error! : 'Describe the issue. Attach a photo, document or your location if it helps dispatch.', action: c.selectedChat != null ? 'Reload' : null, onAction: c.refresh)
            : ListView.builder(
                // Keep the API available in this app's minimum Flutter 3.38 SDK.
                // ignore: deprecated_member_use
                reverse: true, padding: const EdgeInsets.fromLTRB(12, 12, 12, 12), itemCount: msgs.length + extra, cacheExtent: 300,
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                itemBuilder: (ctx, i) {
                  if (pending && i == 0) return _PendingBubble(c: c);
                  final j = i - (pending ? 1 : 0);
                  if (j == msgs.length) return Center(child: TextButton.icon(onPressed: c.loadingOlder ? null : c.loadOlder, icon: const Icon(Icons.history_rounded, size: 18), label: Text(c.loadingOlder ? 'Loading…' : 'Earlier messages')));
                  final m = msgs[j];
                  final prev = j + 1 < msgs.length ? msgs[j + 1] : null;
                  final showDay = prev == null || prev.timestamp.day != m.timestamp.day || prev.timestamp.month != m.timestamp.month;
                  return Padding(
                    key: ValueKey(m.id), padding: const EdgeInsets.only(top: 6),
                    child: Column(children: [
                      if (showDay) _DayLabel(date: m.timestamp),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1), duration: const Duration(milliseconds: 260), curve: Curves.easeOutCubic,
                        builder: (_, v, w) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 10 * (1 - v)), child: w)),
                        child: SupportVisibilityProbe(sequence: m.sequence, onVisible: _visible, child: SupportBubble(message: m, api: c.api, cache: cache, showSender: prev == null || prev.isMine != m.isMine)),
                      ),
                    ]),
                  );
                },
              ),
      ),
      SupportComposer(controller: c),
    ]);
  }
}

class _PendingBubble extends StatelessWidget {
  final SupportController c;
  const _PendingBubble({required this.c});
  @override
  Widget build(BuildContext context) {
    final col = context.colors;
    final failed = !c.sending;
    final fg = col.colorButtonText;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Align(alignment: Alignment.centerRight, child: Semantics(
        liveRegion: true, label: failed ? 'Message not sent. Use Retry.' : 'Sending message',
        child: Opacity(opacity: failed ? 0.9 : 0.7, child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
          padding: const EdgeInsets.fromLTRB(14, 10, 12, 8),
          decoration: BoxDecoration(color: col.colorPrimary, borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18), bottomLeft: Radius.circular(18), bottomRight: Radius.circular(4)), border: failed ? Border.all(color: col.colorWarning, width: 2) : null),
          child: Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
            if (c.text.trim().isNotEmpty) Text(c.text.trim(), style: TextStyle(color: fg, fontSize: 15, height: 1.35)),
            if (c.files.isNotEmpty) Text('${c.files.length} attachment${c.files.length > 1 ? 's' : ''}', style: TextStyle(color: fg.withValues(alpha: 0.85), fontSize: 12.5)),
            if (c.location != null) Text('Location pin', style: TextStyle(color: fg.withValues(alpha: 0.85), fontSize: 12.5)),
            const SizedBox(height: 4),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(failed ? Icons.error_outline_rounded : Icons.schedule_rounded, size: 13, color: fg), const SizedBox(width: 4),
              Text(failed ? 'Not sent · tap Retry below' : 'Sending…', style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w600)),
            ]),
          ]),
        )),
      )),
    );
  }
}

class _DayLabel extends StatelessWidget {
  final DateTime date;
  const _DayLabel({required this.date});
  @override
  Widget build(BuildContext context) {
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final now = DateTime.now();
    final today = now.year == date.year && now.month == date.month && now.day == date.day;
    return Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text(today ? 'Today' : '${m[date.month - 1]} ${date.day}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.colors.colorTextHint)));
  }
}

class _ChatTile extends StatelessWidget {
  final SupportChat chat; final VoidCallback onTap;
  const _ChatTile({required this.chat, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final col = context.colors;
    final unread = chat.unreadByClient;
    return Semantics(
      button: true, label: '${chat.subject}, ticket ${chat.ticketNumber}, ${chat.status}. ${unread > 0 ? '$unread unread. ' : ''}${chat.lastMessage}',
      child: Material(
        color: col.colorBackgroundGray, borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18), onTap: onTap,
          child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: col.colorPrimary.withValues(alpha: 0.12), shape: BoxShape.circle), child: Icon(Icons.support_agent_rounded, color: col.colorPrimary)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(chat.subject, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: unread > 0 ? FontWeight.w800 : FontWeight.w600, fontSize: 15))),
                Text(supportTime(chat.updatedAt), style: TextStyle(fontSize: 11.5, color: col.colorTextHint)),
              ]),
              const SizedBox(height: 3),
              Text(chat.lastMessage.isEmpty ? 'No messages yet' : chat.lastMessage, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: col.colorText.withValues(alpha: 0.7))),
              const SizedBox(height: 4),
              Text('${chat.ticketNumber} · ${chat.status.replaceAll('_', ' ')}', style: TextStyle(fontSize: 11, color: col.colorTextHint)),
            ])),
            if (unread > 0) Container(margin: const EdgeInsets.only(left: 8), padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: col.colorPrimary, borderRadius: BorderRadius.circular(10)), child: Text('$unread', style: TextStyle(color: col.colorButtonText, fontSize: 11, fontWeight: FontWeight.w700))),
          ])),
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  final IconData icon; final String title, body; final String? action; final VoidCallback? onAction;
  const _Notice({required this.icon, required this.title, required this.body, this.action, this.onAction});
  @override
  Widget build(BuildContext context) {
    final col = context.colors;
    return Center(child: SingleChildScrollView(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 84, height: 84, decoration: BoxDecoration(color: col.colorPrimary.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, size: 38, color: col.colorPrimary)),
      const SizedBox(height: 18),
      Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      Text(body, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, height: 1.4, color: col.colorText.withValues(alpha: 0.7))),
      if (action != null) ...[const SizedBox(height: 20), FilledButton(style: FilledButton.styleFrom(backgroundColor: col.colorButtonBackground, foregroundColor: col.colorButtonText, minimumSize: const Size(0, 48), shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(horizontal: 24)), onPressed: onAction, child: Text(action!))],
    ])));
  }
}
