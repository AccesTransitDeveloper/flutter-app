import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/map/interface/map_interface.dart';
import '../../core/map/models/map_types.dart';
import '../../core/map/providers/map_provider.dart';
import '../../core/map/widgets/map_host.dart';
import '../../models/requests/get_vehicle_types_request.dart';
import 'ai_models.dart';

class AiRoutePreview extends ConsumerStatefulWidget {
  final OrderSuggestion suggestion;
  final ValueChanged<ConfirmedAiRoute> onConfirmed;

  const AiRoutePreview({
    super.key,
    required this.suggestion,
    required this.onConfirmed,
  });

  @override
  ConsumerState<AiRoutePreview> createState() => _AiRoutePreviewState();
}

class _AiRoutePreviewState extends ConsumerState<AiRoutePreview> {
  late final MapInterface _mapManager;
  DestinationAddress? _pickup;
  DestinationAddress? _destination;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _mapManager = ref.read(mapManagerProvider)();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRoute());
  }

  @override
  void dispose() {
    _mapManager.dispose();
    super.dispose();
  }

  Future<DestinationAddress?> _resolveAddress(String? value) async {
    final query = value?.trim() ?? '';
    if (query.length < 3) return null;

    final matches = await _mapManager.searchPlaces(query);
    for (final match in matches) {
      if (match.latitude != null && match.longitude != null) return match;
      final placeId = match.placeId;
      if (placeId == null) continue;
      final details = await _mapManager.getPlaceDetails(placeId);
      if (details?.latitude != null && details?.longitude != null) {
        return details;
      }
    }
    return null;
  }

  Future<void> _loadRoute() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    DestinationAddress? pickup;
    DestinationAddress? destination;
    try {
      final resolved = await Future.wait([
        _resolveAddress(widget.suggestion.pickup),
        _resolveAddress(widget.suggestion.destination),
      ]);
      pickup = resolved[0];
      destination = resolved[1];
    } catch (_) {
      // The error below gives the user one clear recovery action.
    }

    if (!mounted) return;
    if (pickup == null || destination == null) {
      setState(() {
        _isLoading = false;
        _error =
            'One of these addresses could not be found. '
            'Please update it in the chat and try again.';
      });
      return;
    }

    final pickupPoint = LatLng(pickup.latitude!, pickup.longitude!);
    final destinationPoint = LatLng(
      destination.latitude!,
      destination.longitude!,
    );
    _mapManager.setMarkers([
      MapMarker(
        id: 'ai_pickup',
        position: pickupPoint,
        title: 'Pickup',
        snippet: pickup.address,
        iconAsset: 'assets/images/ic_pickup.png',
        iconWidth: 30,
        iconHeight: 30,
        iconColor: 0xFF38BDF8,
      ),
      MapMarker(
        id: 'ai_dropoff',
        position: destinationPoint,
        title: 'Drop-off',
        snippet: destination.address,
        iconAsset: 'assets/images/ic_drop_off.png',
        iconWidth: 30,
        iconHeight: 30,
        iconColor: 0xFF2563EB,
      ),
    ]);

    setState(() {
      _pickup = pickup;
      _destination = destination;
      _isLoading = false;
    });

    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (mounted) {
      await _mapManager.fitBounds([pickupPoint, destinationPoint], padding: 44);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canConfirm = !_isLoading && _pickup != null && _destination != null;

    return Card(
      color: const Color(0xFF102744),
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 150,
            child: Stack(
              fit: StackFit.expand,
              children: [
                MapHost(manager: _mapManager),
                if (_isLoading)
                  ColoredBox(
                    color: const Color(0xCC071A36),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF38BDF8),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Confirm your route',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                _AddressRow(
                  color: const Color(0xFF38BDF8),
                  label: 'Pickup',
                  address: widget.suggestion.pickup ?? '',
                ),
                const SizedBox(height: 8),
                _AddressRow(
                  color: const Color(0xFF2563EB),
                  label: 'Drop-off',
                  address: widget.suggestion.destination ?? '',
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _error!,
                    style: const TextStyle(
                      color: Color(0xFFFFB4AB),
                      fontSize: 12,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _loadRoute,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry map'),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: canConfirm
                      ? () => widget.onConfirmed(
                          ConfirmedAiRoute(
                            pickup: _pickup!,
                            destination: _destination!,
                          ),
                        )
                      : null,
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: const Text('Confirm & choose fare'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressRow extends StatelessWidget {
  final Color color;
  final String label;
  final String address;

  const _AddressRow({
    required this.color,
    required this.label,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$label\n',
                  style: const TextStyle(
                    color: Color(0xFF93A8C7),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(
                  text: address,
                  style: const TextStyle(color: Colors.white, height: 1.25),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
