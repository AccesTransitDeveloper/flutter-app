import 'package:geolocator/geolocator.dart';
import '../../core/map/interface/map_interface.dart';
import '../../models/requests/get_vehicle_types_request.dart';

/// Only coordinates captured by the device may become an automatic pickup.
/// No account token, owner ID or payment data is sent to the AI service.
class AiPickupResolver {
  final MapInterface Function() createMap;
  DestinationAddress? _cached;
  DateTime? _captured;

  AiPickupResolver(this.createMap);

  Future<DestinationAddress?> resolve({bool requestPermission = false}) async {
    if (_captured != null &&
        DateTime.now().difference(_captured!) < const Duration(seconds: 60)) {
      return _cached;
    }
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied && requestPermission) {
      permission = await Geolocator.requestPermission();
    }
    if (permission != LocationPermission.always &&
        permission != LocationPermission.whileInUse) return null;
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 15)),
    );
    final captured = position.timestamp;
    if (DateTime.now().difference(captured).abs() > const Duration(minutes: 1)) {
      return null; // Never guess pickup from stale saved GPS.
    }
    final map = createMap();
    try {
      final address = await map.getPlaceDetailWithCoordinates(
        position.latitude, position.longitude,
      );
      if (address.address?.trim().isEmpty != false) return null;
      // Preserve the actual GPS position rather than a geocoder's street center.
      final pickup = DestinationAddress.fromJson({
        ...address.toJson(),
        'latitude': position.latitude,
        'longitude': position.longitude,
      });
      _cached = pickup;
      _captured = captured;
      return pickup;
    } finally {
      map.dispose();
    }
  }
}
