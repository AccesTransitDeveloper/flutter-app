import 'dart:math';

import '../../models/requests/get_vehicle_types_request.dart';
import '../localization/app_strings.dart';

/// Utility class for validating addresses in ride booking flows.
/// Mirrors the validation logic from the Kotlin/Android app.
class AddressValidationUtil {
  AddressValidationUtil._();

  /// Minimum distance in km to consider two addresses as duplicates (9 meters).
  static const double _minDistanceKm = 0.009;

  /// Check if consecutive addresses in the route are duplicates (within 9m).
  /// Returns an error message string if duplicate found, null otherwise.
  ///
  /// Addresses are checked in order: [pickup, ...stops, dropoff].
  /// Only consecutive pairs are compared.
  static String? checkDuplicateAddresses({
    required DestinationAddress pickupAddress,
    required List<DestinationAddress> stops,
    DestinationAddress? dropoffAddress,
  }) {
    final allAddresses = <DestinationAddress>[
      pickupAddress,
      ...stops,
      if (dropoffAddress != null) dropoffAddress,
    ];

    if (allAddresses.length < 2) return null;

    for (int i = 0; i < allAddresses.length - 1; i++) {
      final current = allAddresses[i];
      final next = allAddresses[i + 1];

      if (current.latitude == null ||
          current.longitude == null ||
          next.latitude == null ||
          next.longitude == null) {
        continue;
      }

      final distance = _haversineDistanceKm(
        current.latitude!,
        current.longitude!,
        next.latitude!,
        next.longitude!,
      );

      if (distance < _minDistanceKm) {
        return _getDuplicateErrorMessage(
          index: i,
          totalCount: allAddresses.length,
          hasStops: stops.isNotEmpty,
        );
      }
    }

    return null;
  }

  /// Check if all addresses have the same country code.
  /// Returns an error message if countries differ, null otherwise.
  static String? checkSameCountry({
    required DestinationAddress pickupAddress,
    required List<DestinationAddress> stops,
    DestinationAddress? dropoffAddress,
  }) {
    final allAddresses = <DestinationAddress>[
      pickupAddress,
      ...stops,
      if (dropoffAddress != null) dropoffAddress,
    ];

    if (allAddresses.length < 2) return null;

    final firstCountryCode = allAddresses[0].countryCode;
    if (firstCountryCode == null || firstCountryCode.isEmpty) return null;

    for (int i = 1; i < allAddresses.length; i++) {
      final code = allAddresses[i].countryCode;
      if (code != null && code.isNotEmpty && code != firstCountryCode) {
        return getString(appStr.errorSelectAddressFromSameCountry, 'error_select_address_from_same_country');
      }
    }

    return null;
  }

  /// Validate pickup address has valid data.
  static String? validatePickupAddress(DestinationAddress? address) {
    if (address == null || (address.address?.isEmpty ?? true)) {
      return getString(appStr.errorPleaseEnterPickupLocation, 'error_please_enter_pickup_location');
    }
    if (address.latitude == null || address.longitude == null) {
      return getString(appStr.errorPleaseEnterValidPickupLocation, 'error_please_enter_valid_pickup_location');
    }
    return null;
  }

  /// Validate destination address has valid data.
  static String? validateDestinationAddress(DestinationAddress? address) {
    if (address == null || (address.address?.isEmpty ?? true)) {
      return getString(appStr.errorPleaseEnterDropOffAddress, 'error_please_enter_drop_off_address');
    }
    if (address.latitude == null || address.longitude == null) {
      return getString(appStr.errorPleaseEnterDropOffAddress, 'error_please_enter_drop_off_address');
    }
    return null;
  }

  /// Run all validations for a ride request.
  /// Returns error message or null if valid.
  /// When [isDestinationLater] is true, only pickup is validated.
  static String? validateRideAddresses({
    required DestinationAddress? pickupAddress,
    required List<DestinationAddress> stops,
    DestinationAddress? dropoffAddress,
    bool isDestinationLater = false,
  }) {
    // 1. Validate pickup
    final pickupError = validatePickupAddress(pickupAddress);
    if (pickupError != null) return pickupError;

    // Skip remaining checks for destination later
    if (isDestinationLater) return null;

    // 2. Validate destination (last stop or explicit dropoff)
    final effectiveDropoff =
        dropoffAddress ?? (stops.isNotEmpty ? stops.last : null);
    if (effectiveDropoff == null) {
      return getString(appStr.errorPleaseEnterDropOffAddress, 'error_please_enter_drop_off_address');
    }
    final destError = validateDestinationAddress(effectiveDropoff);
    if (destError != null) return destError;

    // 3. Check all addresses same country
    final countryError = checkSameCountry(
      pickupAddress: pickupAddress!,
      stops: stops,
      dropoffAddress: dropoffAddress,
    );
    if (countryError != null) return countryError;

    // 4. Check duplicate addresses
    final duplicateError = checkDuplicateAddresses(
      pickupAddress: pickupAddress,
      stops: stops,
      dropoffAddress: dropoffAddress,
    );
    if (duplicateError != null) return duplicateError;

    return null;
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Haversine formula to calculate distance between two points in km.
  static double _haversineDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371.0;

    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) *
            cos(_degToRad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _degToRad(double deg) => deg * (pi / 180);

  /// Get the appropriate error message based on which consecutive pair is duplicated.
  static String _getDuplicateErrorMessage({
    required int index,
    required int totalCount,
    required bool hasStops,
  }) {
    final isFirst = index == 0;
    final isLast = index == totalCount - 2;

    if (isFirst && !hasStops) {
      return getString(appStr.errorPickupDestinationMustBeDifferent, 'error_pickup_destination_must_be_different');
    } else if (isFirst && hasStops) {
      return getString(appStr.errorPickupStopMustBeDifferent, 'error_pickup_stop_must_be_different');
    } else if (isLast && hasStops) {
      return getString(appStr.errorStopDropOffDifferent, 'error_stop_drop_off_different');
    } else {
      return getString(appStr.errorConsecutiveStopMustBeDifferent, 'error_consecutive_stop_must_be_different');
    }
  }
}
