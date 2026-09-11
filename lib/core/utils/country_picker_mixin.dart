import 'package:flutter/material.dart';

import '../../models/responses/auth/country_response.dart';
import '../../views/widgets/country_picker_dropdown.dart';
import '../theme/app_dimens.dart';

/// Mixin for showing country picker overlay
mixin CountryPickerMixin<T extends StatefulWidget> on State<T> {
  OverlayEntry? _countryPickerOverlay;

  /// Show country picker overlay below the given key's widget
  void showCountryPicker({
    required GlobalKey countryCodeKey,
    required List<Country> countries,
    required Country? selectedCountry,
    required void Function(Country) onCountrySelected,
  }) {
    hideCountryPicker();

    final renderBox =
        countryCodeKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final screenWidth = MediaQuery.of(context).size.width;
    final dropdownWidth = screenWidth - (AppDimens.padding * 2);

    _countryPickerOverlay = OverlayEntry(
      builder: (context) => CountryPickerOverlay(
        countries: countries,
        selectedCountry: selectedCountry,
        position: Offset(AppDimens.padding, position.dy + size.height + 4),
        width: dropdownWidth,
        onCountrySelected: (country) {
          onCountrySelected(country);
          hideCountryPicker();
        },
        onDismiss: hideCountryPicker,
      ),
    );

    Overlay.of(context).insert(_countryPickerOverlay!);
  }

  /// Hide country picker overlay
  void hideCountryPicker() {
    _countryPickerOverlay?.remove();
    _countryPickerOverlay = null;
  }

  /// Dispose overlay when state is disposed
  void disposeCountryPicker() {
    hideCountryPicker();
  }
}
