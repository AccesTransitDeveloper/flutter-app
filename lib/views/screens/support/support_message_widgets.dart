import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/support/support_api.dart';
import '../../../features/support/support_models.dart';

/// Authenticated image bytes cache (never loads private URLs unauthenticated).
class SupportImageCache {
  final SupportApi api;
  final Map<String, Future<Uint8List>> _bytes = {};
  SupportImageCache(this.api);
  Future<Uint8List> load(String id) => _bytes.putIfAbsent(id, () => api.download(id)..catchError((_) { _bytes.remove(id); return Uint8List(0); }));
  void retry(String id) => _bytes.remove(id);
}

String supportSize(int b) => b < 1024 ? '$b B' : b < 1048576 ? '${(b / 1024).toStringAsFixed(0)} KB' : '${(b / 1048576).toStringAsFixed(1)} MB';
String supportTime(DateTime t) {
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  return '$h:${t.minute.toString().padLeft(2, '0')} ${t.hour < 12 ? 'AM' : 'PM'}';
}

IconData supportFileIcon(String name) {
  switch (name.split('.').last.toLowerCase()) {
    case 'pdf': return Icons.picture_as_pdf_outlined;
    case 'xls': case 'xlsx': case 'csv': return Icons.table_chart_outlined;
    case 'zip': return Icons.folder_zip_outlined;
    case 'ppt': case 'pptx': return Icons.slideshow_outlined;
    case 'jpg': case 'jpeg': case 'png': case 'webp': case 'gif': return Icons.image_outlined;
    default: return Icons.description_outlined;
  }
}

Future<void> shareSupportAttachment(BuildContext context, SupportApi api, SupportAttachment a) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final bytes = await api.download(a.id);
    final dir = await getTemporaryDirectory();
    final safe = a.fileName.replaceAll(RegExp(r'[^\w.\-]'), '_');
    final file = await File('${dir.path}/support_${a.id.hashCode.abs()}_$safe').writeAsBytes(bytes, flush: true);
    await Share.shareXFiles([XFile(file.path, mimeType: a.fileType, name: a.fileName)]);
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e is SupportApiException ? e.message : 'Could not open this file. Try again.')));
  }
}

class SupportBubble extends StatelessWidget {
  final SupportMessage message;
  final SupportApi api;
  final SupportImageCache cache;
  final bool showSender;
  const SupportBubble({super.key, required this.message, required this.api, required this.cache, this.showSender = true});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final mine = message.isMine;
    final bg = mine ? c.colorPrimary : c.colorBackgroundGray;
    final fg = mine ? c.colorButtonText : c.colorText;
    final images = message.attachments.where((a) => a.isImage).toList();
    final files = message.attachments.where((a) => !a.isImage).toList();
    final hasText = message.content.isNotEmpty && message.content != 'Shared attachment' && message.content != 'Shared location' ||
        (message.attachments.isEmpty && message.location == null);
    return Semantics(
      container: true,
      label: '${mine ? 'You' : message.senderName}, ${supportTime(message.timestamp)}. ${message.content}'
          '${message.attachments.isNotEmpty ? '. ${message.attachments.length} attachments' : ''}${message.location != null ? '. Shared location' : ''}',
      child: Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
          child: Column(
            crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!mine && showSender)
                Padding(
                  padding: const EdgeInsets.only(left: 6, bottom: 3),
                  child: Text('${message.senderName} · AT dispatch', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c.colorTextHint)),
                ),
              Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18), topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(mine ? 18 : 4), bottomRight: Radius.circular(mine ? 4 : 18),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final a in images) SupportImageTile(attachment: a, cache: cache, api: api),
                    for (final a in files) SupportFileRow(name: a.fileName, size: a.sizeBytes, fg: fg, onTap: () => shareSupportAttachment(context, api, a)),
                    if (message.location != null) SupportLocationCard(location: message.location!, fg: fg),
                    if (hasText)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                        child: SelectableText(message.content, style: TextStyle(fontSize: 15, height: 1.35, color: fg)),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 2, 12, 8),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(supportTime(message.timestamp), style: TextStyle(fontSize: 10.5, color: fg.withValues(alpha: 0.65))),
                          if (mine) ...[const SizedBox(width: 4), Icon(Icons.check_rounded, size: 13, color: fg.withValues(alpha: 0.65), semanticLabel: 'Delivered')],
                        ]),
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
}

class SupportImageTile extends StatefulWidget {
  final SupportAttachment attachment;
  final SupportImageCache cache;
  final SupportApi api;
  const SupportImageTile({super.key, required this.attachment, required this.cache, required this.api});
  @override
  State<SupportImageTile> createState() => _SupportImageTileState();
}

class _SupportImageTileState extends State<SupportImageTile> {
  late Future<Uint8List> _future = widget.cache.load(widget.attachment.id);
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return FutureBuilder<Uint8List>(
      future: _future,
      builder: (context, snap) {
        Widget child;
        if (snap.connectionState != ConnectionState.done) {
          child = Container(height: 180, color: c.colorText.withValues(alpha: 0.06), child: const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))));
        } else if (snap.hasError || snap.data == null || snap.data!.isEmpty) {
          child = InkWell(
            onTap: () => setState(() { widget.cache.retry(widget.attachment.id); _future = widget.cache.load(widget.attachment.id); }),
            child: Container(height: 120, color: c.colorText.withValues(alpha: 0.06), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.refresh_rounded, color: c.colorTextHint), const SizedBox(height: 6),
              Text('Photo did not load. Tap to retry', style: TextStyle(fontSize: 12, color: c.colorTextHint)),
            ])),
          );
        } else {
          child = GestureDetector(
            onTap: () => Navigator.of(context).push(PageRouteBuilder(
              opaque: false, barrierColor: Colors.black87,
              transitionsBuilder: (_, a, _, w) => FadeTransition(opacity: a, child: w),
              pageBuilder: (_, _, _) => _Viewer(bytes: snap.data!, attachment: widget.attachment, api: widget.api, tag: widget.attachment.id),
            )),
            child: Hero(tag: widget.attachment.id, child: Image.memory(snap.data!, height: 220, fit: BoxFit.cover, gaplessPlayback: true, semanticLabel: 'Photo ${widget.attachment.fileName}')),
          );
        }
        return AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: SizedBox(key: ValueKey(snap.connectionState), width: double.infinity, child: child));
      },
    );
  }
}

class _Viewer extends StatelessWidget {
  final Uint8List bytes; final SupportAttachment attachment; final SupportApi api; final String tag;
  const _Viewer({required this.bytes, required this.attachment, required this.api, required this.tag});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.transparent,
    appBar: AppBar(
      backgroundColor: Colors.transparent, foregroundColor: Colors.white, elevation: 0,
      title: Text(attachment.fileName, style: const TextStyle(fontSize: 14)),
      actions: [IconButton(tooltip: 'Share photo', icon: const Icon(Icons.ios_share_rounded), onPressed: () => shareSupportAttachment(context, api, attachment))],
    ),
    body: GestureDetector(onTap: () => Navigator.pop(context), child: Center(child: Hero(tag: tag, child: InteractiveViewer(maxScale: 5, child: Image.memory(bytes))))),
  );
}

class SupportFileRow extends StatelessWidget {
  final String name; final int size; final Color fg; final VoidCallback? onTap;
  const SupportFileRow({super.key, required this.name, required this.size, required this.fg, this.onTap});
  @override
  Widget build(BuildContext context) => Semantics(
    button: onTap != null, label: 'File $name, ${supportSize(size)}${onTap != null ? '. Double tap to open or share' : ''}',
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 2),
        child: Row(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: fg.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(10)), child: Icon(supportFileIcon(name), color: fg, size: 22)),
          const SizedBox(width: 10),
          Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: fg)),
            Text(supportSize(size), style: TextStyle(fontSize: 11.5, color: fg.withValues(alpha: 0.7))),
          ])),
          if (onTap != null) ...[const SizedBox(width: 8), Icon(Icons.ios_share_rounded, size: 18, color: fg.withValues(alpha: 0.8))],
        ]),
      ),
    ),
  );
}

class SupportLocationCard extends StatelessWidget {
  final SupportLocation location; final Color fg;
  const SupportLocationCard({super.key, required this.location, required this.fg});
  @override
  Widget build(BuildContext context) => Semantics(
    button: true, label: 'Shared location, accuracy ${location.accuracyMeters.round()} meters. Double tap to open map.',
    child: InkWell(
      onTap: () async {
        final messenger = ScaffoldMessenger.of(context);
        if (!await launchUrl(location.mapUri, mode: LaunchMode.externalApplication)) {
          messenger.showSnackBar(const SnackBar(content: Text('No app available to open the map.')));
        }
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 2),
        child: Row(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: fg.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.location_on_rounded, color: fg)),
          const SizedBox(width: 10),
          Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Shared location', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: fg)),
            Text('${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)} · ±${location.accuracyMeters.round()} m',
                style: TextStyle(fontSize: 11.5, color: fg.withValues(alpha: 0.7))),
          ])),
          const SizedBox(width: 8), Icon(Icons.open_in_new_rounded, size: 17, color: fg.withValues(alpha: 0.8)),
        ]),
      ),
    ),
  );
}

/// Reports its message sequence only while at least half of it sits inside the scrollable viewport.
class SupportVisibilityProbe extends StatefulWidget {
  final int sequence; final void Function(int) onVisible; final Widget child;
  const SupportVisibilityProbe({super.key, required this.sequence, required this.onVisible, required this.child});
  @override
  State<SupportVisibilityProbe> createState() => _ProbeState();
}

class _ProbeState extends State<SupportVisibilityProbe> {
  ScrollPosition? _pos;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pos?.removeListener(_check);
    _pos = Scrollable.maybeOf(context)?.position;
    _pos?.addListener(_check);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }
  @override
  void dispose() { _pos?.removeListener(_check); super.dispose(); }
  void _check() {
    if (!mounted) return;
    final box = context.findRenderObject();
    final viewport = Scrollable.maybeOf(context)?.context.findRenderObject();
    if (box is! RenderBox || viewport is! RenderBox || !box.attached || !viewport.attached || !box.hasSize) return;
    final top = box.localToGlobal(Offset.zero, ancestor: viewport).dy;
    final visible = (top + box.size.height).clamp(0, viewport.size.height) - top.clamp(0, viewport.size.height);
    if (box.size.height > 0 && visible >= box.size.height * 0.5) { widget.onVisible(widget.sequence); }
  }
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
    return widget.child;
  }
}
