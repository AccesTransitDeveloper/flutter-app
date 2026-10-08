import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/preferences/shared_preference_manager.dart';
import '../../../features/sos/sos_contract.dart';
import '../../../features/sos/sos_service.dart';

class SosScreen extends StatefulWidget {
  final SharedPreferenceManager preferences;
  final VoidCallback callDispatch;
  const SosScreen({super.key, required this.preferences, required this.callDispatch});
  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> with WidgetsBindingObserver {
  late final SosService _service;
  SosConfirmation? _alert;
  Map<String, dynamic>? _pending;
  String? _trip;
  String? _error;
  String? _gpsWarning;
  bool _busy = true, _consent = false, _foreground = true, _pointBusy = false;
  DateTime _retryAt = DateTime.fromMillisecondsSinceEpoch(0);
  int _retryDelay = 5;
  bool _autoRetry = true;
  StreamSubscription<Position>? _gps;
  Timer? _timer;
  final _reason = TextEditingController();
  late final VoidCallback _logout;
  List<String> get _trips => (widget.preferences.getEntity()?.bookingIds ?? [])
      .where((id) => RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(id)).toSet().toList();

  @override
  void initState() {
    super.initState();
    _service = SosService(widget.preferences);
    WidgetsBinding.instance.addObserver(this);
    _logout = () {
      _stopGps();
      _timer?.cancel();
      if (mounted) setState(() { _consent = false; _alert = null; _pending = null; _error = 'Signed out. GPS stopped.'; });
    };
    SosSession.onSignOut = _logout;
    _restore();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _tick());
  }

  Future<void> _restore() async {
    try {
      _pending = await _service.read(_service.pendingKey);
      _trip = _pending?['tripId'] as String? ?? (_trips.isEmpty ? null : _trips.first);
      if (_pending != null) {
        _alert = await _service.send(_pending!);
        _pending = null;
      } else {
        final saved = await _service.read(_service.activeKey);
        if (saved != null) _alert = await _service.get(SosConfirmation(saved).id);
      }
    } catch (error) { _failure(error); }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _raise() async {
    if (_busy || _tickBusy) return;
    if (_pending == null) {
      if (_trip == null) return;
      final confirm = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
        title: const Text('Send SOS to dispatch?'),
        content: const Text('This alerts the AT dispatcher for this trip. It does not call 911. GPS is optional and will not delay the request.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Send SOS')),
        ],
      ));
      if (confirm != true || !mounted) return;
      _stopGps();
      _consent = false;
      _pending = {'requestId': sosUuid(), 'tripId': _trip, 'reason': _reason.text.trim()};
    }
    setState(() { _busy = true; _error = null; });
    try {
      final result = await _service.send(_pending!);
      if (!mounted) return;
      _stopGps();
      _alert = result;
      _pending = null;
      _consent = false;
      await _service.remove(_service.pointKey);
    } catch (error) { _failure(error); }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _enableGps(bool value) async {
    _stopGps();
    if (!value) {
      setState(() => _consent = false);
      try { await _service.remove(_service.pointKey); } catch (_) {}
      return;
    }
    try {
      if (!await Geolocator.isLocationServiceEnabled()) throw const SosFailure('Turn on location services to share GPS.');
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (![LocationPermission.always, LocationPermission.whileInUse].contains(permission)) {
        throw const SosFailure('GPS permission denied. Your SOS does not require GPS.');
      }
      if (!mounted) return;
      _service.checkSession();
      setState(() { _consent = true; _gpsWarning = null; });
      _startGps();
    } catch (error) {
      if (mounted) setState(() { _consent = false; _gpsWarning = error.toString(); });
    }
  }
  void _startGps() {
    if (!_consent || !_foreground || _alert == null || _alert!.status == 'resolved') return;
    _gps = Geolocator.getPositionStream(locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high, distanceFilter: 0,
    )).listen((point) => _sendPoint(point), onError: (_) {
      _stopGps();
      if (mounted) setState(() { _consent = false; _gpsWarning = 'GPS unavailable. Dispatch may have an old position.'; });
    });
  }
  void _stopGps() { _gps?.cancel(); _gps = null; }
  Future<void> _sendPoint([Position? position]) async {
    if (_pointBusy || !_consent || !_foreground || _alert == null) return;
    _pointBusy = true;
    final id = _alert!.id;
    try {
      var pending = await _service.read(_service.pointKey);
      if (pending != null && pending['alertId'] != id) {
        await _service.remove(_service.pointKey);
        pending = null;
      }
      if (pending == null && position != null) {
        pending = {'alertId': id, 'sampleId': sosUuid(), 'location': {
          'latitude': position.latitude, 'longitude': position.longitude,
          'accuracyMeters': position.accuracy,
          'capturedAt': position.timestamp.toUtc().toIso8601String(),
        }};
        await _service.write(_service.pointKey, pending);
      }
      if (pending == null || !_consent || !_foreground || _alert?.id != id) return;
      await _service.request('/alerts/${Uri.encodeComponent(id)}/location', {
        'sampleId': pending['sampleId'], 'location': pending['location'],
      });
      await _service.remove(_service.pointKey);
      _gpsWarning = null;
    } catch (error) {
      _gpsWarning = 'GPS not confirmed. Retrying the saved position.';
      if (error is SosFailure && [400, 401, 403, 404, 409, 422].contains(error.status)) {
        _stopGps(); _consent = false;
        _gpsWarning = 'GPS stopped: the session or SOS is no longer available.';
        if ([400, 422].contains(error.status)) {
          await _service.remove(_service.pointKey);
          _gpsWarning = 'GPS fix rejected. Check your device clock and enable GPS again.';
        }
      }
    } finally {
      _pointBusy = false;
      if (mounted) setState(() {});
    }
  }

  bool _tickBusy = false;
  void _failure(Object error) {
    _error = error.toString();
    _autoRetry = error is! SosFailure || error.status == null ||
        error.status == 429 || error.status! >= 500;
    _retryAt = DateTime.now().add(Duration(seconds: _retryDelay));
    _retryDelay = (_retryDelay * 2).clamp(5, 60).toInt();
  }
  Future<void> _tick() async {
    if (_tickBusy || !_foreground || _busy || !mounted) return;
    _tickBusy = true;
    try {
      _service.checkSession();
      if (_pending != null) {
        if (!_autoRetry || DateTime.now().isBefore(_retryAt)) return;
        _alert = await _service.send(_pending!);
        _pending = null; _error = null; _retryDelay = 5;
      }
      if (_alert != null && _alert!.status != 'resolved') {
        _alert = await _service.get(_alert!.id);
        _error = null;
        if (_alert!.status == 'resolved') {
          _stopGps(); _consent = false;
          await _service.remove(_service.pointKey);
        } else { await _sendPoint(); }
      }
    } catch (error) {
      _failure(error);
      if (error is SosFailure && [401, 403, 404].contains(error.status)) {
        _stopGps(); _consent = false; _timer?.cancel();
      }
    } finally {
      _tickBusy = false;
      if (mounted) setState(() {});
    }
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _stopGps();
    if (_foreground) { _startGps(); _tick(); }
  }
  @override
  void dispose() {
    _stopGps(); _timer?.cancel(); _service.close(); _reason.dispose();
    if (identical(SosSession.onSignOut, _logout)) SosSession.onSignOut = null;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final status = _alert?.status;
    return Scaffold(
      appBar: AppBar(title: const Text('SOS • Emergency help')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        const Icon(Icons.sos_rounded, color: Color(0xFFC62828), size: 72),
        const SizedBox(height: 16),
        Text('Get help from AT dispatch', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text('SOS alerts your dispatcher, not emergency services. If there is immediate danger, call emergency services now.'),
        const SizedBox(height: 20),
        if (_alert != null) Card(child: Padding(padding: const EdgeInsets.all(16), child: Text(
          status == 'resolved' ? 'SOS closed by dispatch. GPS stopped.'
          : status == 'acknowledged' ? 'Dispatch has accepted your SOS.'
          : 'CRM confirmed your SOS. Waiting for dispatch to accept.',
        ))),
        if (_alert?.locationWarning == true) const Text('SOS is saved, but the initial location was not saved.'),
        if (_trips.isNotEmpty && _pending == null) DropdownButtonFormField<String>(
          initialValue: _trips.contains(_trip) ? _trip : null,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Your active trip', border: OutlineInputBorder()),
          items: _trips.map((id) => DropdownMenuItem(value: id, child: Text('Trip $id', overflow: TextOverflow.ellipsis))).toList(),
          onChanged: _busy || _tickBusy ? null : (value) => setState(() => _trip = value),
        ),
        if (_trips.isEmpty && _pending == null) const Text('No active trip is available. You can still call dispatch or emergency services below.'),
        const SizedBox(height: 12),
        TextField(controller: _reason, enabled: !_busy && _pending == null, maxLength: 1000, maxLines: 3,
          decoration: const InputDecoration(labelText: 'Reason (optional)', border: OutlineInputBorder())),
        if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(_error!, style: const TextStyle(color: Color(0xFFC62828)))),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFFC62828), minimumSize: const Size.fromHeight(56)),
          onPressed: _busy || _tickBusy || (_trip == null && _pending == null) ? null : _raise,
          icon: _busy ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.sos_rounded),
          label: Text(_pending != null ? 'Retry saved SOS' : status == 'acknowledged' || status == 'resolved' ? 'Send a new SOS' : 'Send SOS to dispatch'),
        ),
        if (_alert != null && status != 'resolved' && _pending == null) SwitchListTile(
          contentPadding: EdgeInsets.zero, value: _consent, onChanged: _busy || _tickBusy ? null : _enableGps,
          title: const Text('Share my GPS with dispatch'),
          subtitle: const Text('Only while this screen is open and the app is in the foreground. You can stop at any time.'),
        ),
        if (_gpsWarning != null) Text(_gpsWarning!),
        const SizedBox(height: 12),
        OutlinedButton.icon(onPressed: widget.callDispatch, icon: const Icon(Icons.support_agent), label: const Text('Call AT dispatch')),
        OutlinedButton.icon(onPressed: () async {
          try {
            if (!await launchUrl(Uri.parse('tel:911'), mode: LaunchMode.externalApplication)) throw const SosFailure('Unable to open the phone app. Dial 911 manually (US).');
          } catch (_) {
            if (mounted) setState(() => _error = 'Unable to open the phone app. Dial 911 manually (US).');
          }
        }, icon: const Icon(Icons.phone), label: const Text('Call 911 (US emergency services)')),
      ]),
    );
  }
}
