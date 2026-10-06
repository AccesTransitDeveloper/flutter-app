import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/support/support_controller.dart';
import 'support_message_widgets.dart';

class SupportComposer extends StatefulWidget {
  final SupportController controller;
  const SupportComposer({super.key, required this.controller});
  @override
  State<SupportComposer> createState() => _SupportComposerState();
}

class _SupportComposerState extends State<SupportComposer> {
  final _text = TextEditingController();
  final _picker = ImagePicker();
  String? _chatKey;
  SupportController get c => widget.controller;

  @override
  void dispose() { _text.dispose(); super.dispose(); }

  void _sync() {
    final key = c.selectedChat?.id ?? 'new';
    if (_chatKey != key || (c.text != _text.text && (c.text.isEmpty || c.locked == false && _text.text.isEmpty))) {
      _chatKey = key;
      _text.value = TextEditingValue(text: c.text, selection: TextSelection.collapsed(offset: c.text.length));
    }
  }

  Future<void> _pickImage(ImageSource s) async {
    try {
      final x = await _picker.pickImage(source: s, maxWidth: 2048, imageQuality: 85);
      if (x == null) return;
      await c.addFile(x.path, x.name.contains('.') ? x.name : '${x.name}.jpg');
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s == ImageSource.camera ? 'Camera is unavailable. Check permission in Settings.' : 'Could not open your photos. Check permission in Settings.')));
    }
  }

  Future<void> _pickFile() async {
    try {
      final r = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'gif', 'pdf', 'txt', 'csv', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'zip']);
      final f = r?.files.single;
      if (f == null || f.path == null) return;
      await c.addFile(f.path!, f.name);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open that file.')));
    }
  }

  void _menu() {
    final col = context.colors;
    showModalBottomSheet<void>(
      context: context, backgroundColor: col.colorBackground, showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _opt(ctx, Icons.photo_library_outlined, 'Photo library', 'JPG, PNG, WEBP, GIF', () => _pickImage(ImageSource.gallery)),
          _opt(ctx, Icons.photo_camera_outlined, 'Take a photo', 'Vehicle, document, scene', () => _pickImage(ImageSource.camera)),
          _opt(ctx, Icons.attach_file_rounded, 'File', 'PDF, Office, TXT, CSV, ZIP · up to 4 MB', _pickFile),
          _opt(ctx, Icons.my_location_rounded, 'Current location', 'Sent as a map pin to dispatch', c.shareCurrentLocation),
        ]),
      )),
    );
  }

  Widget _opt(BuildContext ctx, IconData i, String t, String s, VoidCallback f) {
    final col = context.colors;
    return ListTile(
      leading: CircleAvatar(backgroundColor: col.colorPrimary.withValues(alpha: 0.1), child: Icon(i, color: col.colorPrimary)),
      title: Text(t, style: const TextStyle(fontWeight: FontWeight.w600)), subtitle: Text(s, style: const TextStyle(fontSize: 12)),
      onTap: () { Navigator.pop(ctx); f(); },
    );
  }

  @override
  Widget build(BuildContext context) {
    _sync();
    final col = context.colors;
    final locked = c.locked;
    final canSend = !c.sending && (c.text.trim().isNotEmpty || c.files.isNotEmpty || c.location != null);
    final retry = locked && !c.sending;
    return Material(
      color: col.colorBackground, elevation: 6, shadowColor: Colors.black26,
      child: SafeArea(top: false, child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 220), curve: Curves.easeOutCubic, alignment: Alignment.topCenter,
            child: (c.files.isEmpty && c.location == null) ? const SizedBox(width: double.infinity) : SizedBox(
              height: 64,
              child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.fromLTRB(4, 0, 4, 8), children: [
                if (c.location != null) _chip(col, Icons.location_on_rounded, 'Location ±${c.location!.accuracyMeters.round()} m', null, c.removeLocation),
                for (var i = 0; i < c.files.length; i++) _chip(col, supportFileIcon(c.files[i].name), c.files[i].name, c.files[i].path, () => c.removeFile(i)),
              ]),
            ),
          ),
          if (locked && !c.sending)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
              child: Row(children: [
                Icon(Icons.lock_outline_rounded, size: 14, color: col.colorWarning), const SizedBox(width: 6),
                Expanded(child: Text('Message not confirmed. Retry sends this exact message; editing is locked until it succeeds.', style: TextStyle(fontSize: 12, color: col.colorText.withValues(alpha: 0.75)))),
              ]),
            ),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            IconButton(tooltip: 'Attach photo, file or location', onPressed: locked ? null : _menu, icon: Icon(Icons.add_circle_outline_rounded, color: locked ? col.colorTextHint : col.colorPrimary, size: 28)),
            Expanded(child: TextField(
              controller: _text, enabled: !locked, minLines: 1, maxLines: 5, textCapitalization: TextCapitalization.sentences,
              inputFormatters: [LengthLimitingTextInputFormatter(4000)],
              onChanged: (v) { c.updateText(v); },
              decoration: InputDecoration(
                hintText: 'Message AT dispatch', filled: true, fillColor: col.colorBackgroundGray, isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
              ),
            )),
            const SizedBox(width: 6),
            Semantics(
              button: true, enabled: canSend, label: retry ? 'Retry sending message' : c.sending ? 'Sending' : 'Send message',
              child: AnimatedScale(
                scale: canSend ? 1 : 0.9, duration: const Duration(milliseconds: 150),
                child: Material(
                  color: canSend ? col.colorButtonBackground : col.colorBackgroundGray, shape: const StadiumBorder(),
                  child: InkWell(
                    customBorder: const StadiumBorder(), onTap: canSend ? () { HapticFeedback.selectionClick(); c.send(); } : null,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 48, minHeight: 48), padding: EdgeInsets.symmetric(horizontal: retry ? 14 : 0),
                      alignment: Alignment.center,
                      child: c.sending
                          ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2, color: col.colorButtonText))
                          : retry
                              ? Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.refresh_rounded, size: 18, color: col.colorButtonText), const SizedBox(width: 4), Text('Retry', style: TextStyle(color: col.colorButtonText, fontWeight: FontWeight.w700))])
                              : Icon(Icons.arrow_upward_rounded, color: canSend ? col.colorButtonText : col.colorTextHint),
                    ),
                  ),
                ),
              ),
            ),
          ]),
        ]),
      )),
    );
  }

  Widget _chip(AppColorPalette col, IconData icon, String label, String? imagePath, VoidCallback remove) {
    final isImg = imagePath != null && RegExp(r'\.(jpe?g|png|webp|gif)$', caseSensitive: false).hasMatch(imagePath);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 190),
        decoration: BoxDecoration(color: col.colorBackgroundGray, borderRadius: BorderRadius.circular(14), border: Border.all(color: col.colorPrimary.withValues(alpha: 0.25))),
        clipBehavior: Clip.antiAlias,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(width: 54, height: 56, child: isImg ? Image.file(File(imagePath), fit: BoxFit.cover, errorBuilder: (_, _, _) => Icon(icon)) : Icon(icon, color: col.colorPrimary)),
          Flexible(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)))),
          IconButton(tooltip: 'Remove $label', visualDensity: VisualDensity.compact, onPressed: c.locked ? null : remove, icon: const Icon(Icons.close_rounded, size: 18)),
        ]),
      ),
    );
  }
}
