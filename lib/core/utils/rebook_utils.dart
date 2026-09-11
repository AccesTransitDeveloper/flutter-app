import '../../models/requests/get_vehicle_types_request.dart';
import '../../models/responses/booking/booking_detail_response.dart';
import '../constants/app_constants.dart';

/// Data needed to navigate for a re-book
class RebookData {
  final DestinationAddress pickup;
  final List<DestinationAddress> destinations;
  final String? vehicleTypeId;
  final RideType? rideType;
  final bool isDestinationLater;

  const RebookData({
    required this.pickup,
    required this.destinations,
    this.vehicleTypeId,
    this.rideType,
    this.isDestinationLater = false,
  });
}

/// Creates rebook navigation data from a booking detail.
/// Returns null if pickup address is missing.
RebookData? createRebookData(BookingDetails booking) {
  final pickup = booking.pickupAddress;
  if (pickup == null) return null;

  final rideType = RideType.fromValue(booking.bookingType);
  if (rideType == RideType.fixGroup) {
    return null;
  }

  // Deduplicate: remove destinations with same placeId as pickup
  final destinations = (booking.destinationAddresses ?? [])
      .where((d) => d.placeId != pickup.placeId)
      .toList();

  // Check destination later: no destinations or pickup ≈ destination
  final isDestinationLater = destinations.isEmpty ||
      (destinations.length == 1 &&
          _isSameLocation(pickup, destinations.first));

  return RebookData(
    pickup: pickup,
    destinations: isDestinationLater ? [] : destinations,
    vehicleTypeId: booking.vehicleTypeId,
    rideType: rideType,
    isDestinationLater: isDestinationLater,
  );
}

/// Check if two addresses are approximately the same location
/// (within 2 decimal places of lat/lng, matching Kotlin behavior)
bool _isSameLocation(DestinationAddress a, DestinationAddress b) {
  if (a.latitude == null || b.latitude == null) return false;
  return a.latitude!.toStringAsFixed(2) == b.latitude!.toStringAsFixed(2) &&
      a.longitude!.toStringAsFixed(2) == b.longitude!.toStringAsFixed(2);
}
