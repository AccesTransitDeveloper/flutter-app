class FiltersResult {
  final List<String> selectedAccessibility;
  final List<String> selectedLanguage;
  final List<String> selectedGender;
  final List<String> selectedCapacity;
  final List<String> selectedLuggageCapacity;

  const FiltersResult({
    this.selectedAccessibility = const [],
    this.selectedLanguage = const [],
    this.selectedGender = const [],
    this.selectedCapacity = const [],
    this.selectedLuggageCapacity = const [],
  });

  bool get hasFilters =>
      selectedAccessibility.isNotEmpty ||
      selectedLanguage.isNotEmpty ||
      selectedGender.isNotEmpty ||
      selectedCapacity.isNotEmpty ||
      selectedLuggageCapacity.isNotEmpty;

  int get filterCount =>
      selectedAccessibility.length +
      selectedLanguage.length +
      selectedGender.length +
      selectedCapacity.length +
      selectedLuggageCapacity.length;

  FiltersResult copyWith({
    List<String>? selectedAccessibility,
    List<String>? selectedLanguage,
    List<String>? selectedGender,
    List<String>? selectedCapacity,
    List<String>? selectedLuggageCapacity,
  }) {
    return FiltersResult(
      selectedAccessibility: selectedAccessibility ?? this.selectedAccessibility,
      selectedLanguage: selectedLanguage ?? this.selectedLanguage,
      selectedGender: selectedGender ?? this.selectedGender,
      selectedCapacity: selectedCapacity ?? this.selectedCapacity,
      selectedLuggageCapacity:
          selectedLuggageCapacity ?? this.selectedLuggageCapacity,
    );
  }

  static const empty = FiltersResult();
}
