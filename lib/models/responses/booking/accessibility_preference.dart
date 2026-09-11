import 'package:json_annotation/json_annotation.dart';

part 'accessibility_preference.g.dart';

@JsonSerializable()
class AccessibilityPreference {
  @JsonKey(name: '_id')
  final String? id;
  final String? accessibility;
  final String? priceStr;
  final double? price;

  @JsonKey(includeFromJson: false, includeToJson: false)
  final bool isSelected;

  AccessibilityPreference({
    this.id,
    this.accessibility,
    this.priceStr,
    this.price,
    this.isSelected = false,
  });

  factory AccessibilityPreference.fromJson(Map<String, dynamic> json) =>
      _$AccessibilityPreferenceFromJson(json);

  Map<String, dynamic> toJson() => _$AccessibilityPreferenceToJson(this);

  AccessibilityPreference copyWith({
    String? id,
    String? accessibility,
    String? priceStr,
    double? price,
    bool? isSelected,
  }) {
    return AccessibilityPreference(
      id: id ?? this.id,
      accessibility: accessibility ?? this.accessibility,
      priceStr: priceStr ?? this.priceStr,
      price: price ?? this.price,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}
