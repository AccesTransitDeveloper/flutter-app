import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/app_providers.dart';
import '../../core/managers/live_activity_manager.dart';
import '../../data/repository/app_repository.dart';
import '../../viewmodels/main_viewmodel.dart';
import '../booking/cancellation_reasons.dart';
import 'ai_trip_cancellation.dart';

/// Explicit native review inside the chat; an AI response can only open it.
class AiCancellationCard extends ConsumerStatefulWidget {
  final VoidCallback onCancelled, onDismiss;
  final ValueChanged<bool> onBusyChanged;
  const AiCancellationCard({super.key, required this.onCancelled,
    required this.onDismiss, required this.onBusyChanged});
  @override
  ConsumerState<AiCancellationCard> createState() => _AiCancellationCardState();
}

class _AiCancellationCardState extends ConsumerState<AiCancellationCard> {
  AiTripCancellation? _service;
  AiCancellationReview? _review;
  List<String> _ids = [];
  String? _selectedId, _reason, _error;
  final _other = TextEditingController();
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    _load();
  }
  @override
  void dispose() { _other.dispose(); super.dispose(); }

  Future<void> _load([String? selected]) async {
    setState(() { _busy = true; _error = null; _review = null; });
    try {
      final prefs = await ref.read(sharedPreferenceManagerProvider.future);
      if (!mounted) return;
      _service ??= AiTripCancellation(ref.read(appRepositoryProvider), prefs);
      final ids = await _service!.activeBookings();
      if (!mounted) return;
      _ids = ids;
      _selectedId = selected != null && ids.contains(selected)
          ? selected : ids.length == 1 ? ids.single : null;
      final review = _selectedId == null ? null
          : await _service!.review(_selectedId!);
      if (!mounted) return;
      setState(() { _review = review; });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel() async {
    if (_busy || _review?.allowed != true) return;
    final reviewed = _review!;
    setState(() { _busy = true; _error = null; });
    widget.onBusyChanged(true);
    try {
      await _service!.cancel(reviewed,
        _reason == 'Other' && _other.text.trim().isNotEmpty
          ? _other.text : _reason ?? '');
      // Report confirmed server success even if local notification cleanup fails.
      try {
        await LiveActivityManager.instance.stopActivity(reviewed.bookingId)
            .timeout(const Duration(seconds: 3));
      } catch (_) {}
      if (!mounted) return;
      _service!.assertSession();
      widget.onCancelled();
      // Refresh the existing home / current-trip surface after server success.
      ref.read(mainViewModelProvider.notifier).refreshEntityDetail();
    } on AiCancellationChanged catch (e) {
      if (mounted) setState(() {
        _review = e.review;
        _error = 'The trip or fee changed. Review the updated details and confirm again.';
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      widget.onBusyChanged(false);
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final review = _review;
    final trip = review?.details.booking;
    return Card(child: Padding(padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Cancel your trip', style: TextStyle(
          fontSize: 18, fontWeight: FontWeight.bold)),
        if (_busy) const LinearProgressIndicator(),
        if (!_busy && _ids.isEmpty && _error == null)
          const Text('You have no active trip to cancel.'),
        if (_ids.length > 1)
          DropdownButtonFormField<String>(
            value: _selectedId,
            isExpanded: true,
            hint: const Text('Choose the trip to cancel'),
            items: _ids.map((id) => DropdownMenuItem(
              value: id, child: Text('Trip $id',
                overflow: TextOverflow.ellipsis))).toList(),
            onChanged: _busy ? null : (id) { if (id != null) _load(id); }),
        if (review != null) ...[
          Text('${trip?.pickupAddress?.address ?? ''} → '
            '${trip?.destinationAddresses?.lastOrNull?.address ?? ''}'),
          if (trip?.confirmedDriver != null)
            const Text('A driver has accepted this trip. Why are you cancelling?'),
          if (trip?.confirmedDriver == null)
            const Text('Why are you cancelling?'),
          const Text('A reason is optional. Your trip stays active until you confirm.'),
          Text('Cancellation fee: ${review.currency}${review.fee.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
          Wrap(spacing: 6, children: [
            for (final reason in commonCancellationReasons('en'))
              ChoiceChip(label: Text(reason), selected: _reason == reason,
                onSelected: _busy ? null : (selected) {
                  setState(() => _reason = selected ? reason : null);
                }),
          ]),
          if (_reason == 'Other')
            TextField(controller: _other, enabled: !_busy, maxLength: 1000,
              decoration: const InputDecoration(
                labelText: 'Your reason (optional)')),
          if (!review.allowed)
            const Text('Cancellation is not allowed at this trip stage.'),
          FilledButton(
            onPressed: _busy || !review.allowed ? null : _cancel,
            child: const Text('Confirm cancellation')),
        ],
        if (_error != null) ...[
          Text(_error!, style: const TextStyle(color: Colors.red)),
          TextButton(onPressed: _busy ? null : () => _load(_selectedId),
            child: const Text('Refresh trip')),
        ],
        TextButton(onPressed: _busy ? null : widget.onDismiss,
          child: const Text('Keep trip')),
      ])));
  }
}
