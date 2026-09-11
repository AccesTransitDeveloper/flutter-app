import 'dart:convert';

import 'requests/create_booking_request.dart';

/// Result from the ride-for-other selection flow.
/// Follows the same pattern as ScheduleRideResult — plain data class passed through navigation.
class RideForOtherResult {
  final bool isForMe;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? countryPhoneCode;

  const RideForOtherResult.forMe()
      : isForMe = true,
        firstName = null,
        lastName = null,
        phone = null,
        countryPhoneCode = null;

  const RideForOtherResult.forOther({
    required String this.firstName,
    this.lastName,
    required String this.phone,
    this.countryPhoneCode,
  }) : isForMe = false;

  /// Display label for the chip
  String get chipLabel => isForMe ? 'For me' : (firstName ?? 'Other');

  /// Full display name
  String get displayName {
    if (isForMe) return 'Me';
    final parts = [firstName, lastName].where((s) => s != null && s.isNotEmpty);
    return parts.join(' ');
  }

  /// Convert to CustomerDetail for booking request
  CustomerDetail? toCustomerDetail() {
    if (isForMe) return null;
    return CustomerDetail(
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      countryPhoneCode: countryPhoneCode,
    );
  }

  /// Serialize to JSON string for SharedPreferences storage
  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'countryPhoneCode': countryPhoneCode,
      };

  /// Deserialize from JSON
  factory RideForOtherResult.fromJson(Map<String, dynamic> json) {
    return RideForOtherResult.forOther(
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String?,
      phone: json['phone'] as String? ?? '',
      countryPhoneCode: json['countryPhoneCode'] as String?,
    );
  }

  /// Encode list of recent riders to JSON string
  static String encodeList(List<RideForOtherResult> list) {
    return jsonEncode(list.map((e) => e.toJson()).toList());
  }

  /// Decode list of recent riders from JSON string
  static List<RideForOtherResult> decodeList(String jsonString) {
    try {
      final list = jsonDecode(jsonString) as List;
      return list
          .map((e) => RideForOtherResult.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
