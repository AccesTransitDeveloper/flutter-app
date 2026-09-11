/// Currency sign position constants
class SetCurrencySign {
  static const int left = 1;
  static const int right = 2;
}

/// Extension for applying price settings to double values
extension PriceSettingExtension on double {
  /// Formats price with currency sign based on direction
  String applyPriceSetting({
    required int currencyDirection,
    required String currencySign,
    required int decimalPointValue,
  }) {
    final formattedPrice = toStringAsFixed(decimalPointValue);
    if (currencyDirection == SetCurrencySign.left) {
      return '$currencySign$formattedPrice';
    } else {
      return '$formattedPrice$currencySign';
    }
  }
}

/// Extension for applying price settings to nullable double values
extension NullablePriceSettingExtension on double? {
  /// Formats price with currency sign based on direction, returns empty string if null
  String applyPriceSetting({
    required int currencyDirection,
    required String currencySign,
    required int decimalPointValue,
  }) {
    if (this == null) return '';
    return this!.applyPriceSetting(
      currencyDirection: currencyDirection,
      currencySign: currencySign,
      decimalPointValue: decimalPointValue,
    );
  }
}

/// Extension for formatting double values
extension DoubleFormatExtension on double {
  /// Formats double with specified decimal points
  String format(int decimalPoints) => toStringAsFixed(decimalPoints);
}

/// Extension for formatting nullable double values
extension NullableDoubleFormatExtension on double? {
  /// Formats double with specified decimal points, returns empty string if null
  String format(int decimalPoints) {
    if (this == null) return '';
    return this!.toStringAsFixed(decimalPoints);
  }
}

/// Compares two semantic version strings (e.g. "1.2.3").
/// Returns < 0 if current < latest, 0 if equal, > 0 if current > latest.
int compareVersions(String currentVersion, String latestVersion) {
  try {
    final parts1 = currentVersion.split('.');
    final parts2 = latestVersion.split('.');

    final maxLength = parts1.length > parts2.length ? parts1.length : parts2.length;

    for (int i = 0; i < maxLength; i++) {
      final part1 = i < parts1.length ? int.parse(parts1[i]) : 0;
      final part2 = i < parts2.length ? int.parse(parts2[i]) : 0;

      if (part1 != part2) {
        return part1 - part2;
      }
    }
  } catch (_) {
    // Invalid version format — treat as equal
  }

  return 0;
}

/// Get initials from a name (e.g. "John Doe" → "JD")
String getInitials(String name) {
  final parts = name.trim().split(' ').where((s) => s.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts[0][0].toUpperCase();
  return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
}
