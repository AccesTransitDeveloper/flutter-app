import 'package:flutter/material.dart';

import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme.dart';

/// A reusable widget for displaying a group of filter chips
class FilterChipGroup<T> extends StatelessWidget {
  final String title;
  final List<T> items;
  final bool Function(T item) isSelected;
  final String Function(T item) getLabel;
  final void Function(int index) onItemTap;
  final bool isMultiSelect;

  const FilterChipGroup({
    super.key,
    required this.title,
    required this.items,
    required this.isSelected,
    required this.getLabel,
    required this.onItemTap,
    this.isMultiSelect = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: AppTypos.textM,
            fontWeight: FontWeight.w600,
            color: colors.colorText,
          ),
        ),
        const SizedBox(height: AppDimens.paddingM),
        Wrap(
          spacing: AppDimens.paddingS,
          runSpacing: AppDimens.paddingS,
          children: items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final selected = isSelected(item);

            return _FilterChip(
              label: getLabel(item),
              isSelected: selected,
              onTap: () => onItemTap(index),
            );
          }).toList(),
        ),
        const SizedBox(height: AppDimens.padding),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.padding,
          vertical: AppDimens.paddingS,
        ),
        decoration: BoxDecoration(
          color: isSelected ? colors.colorPrimary : colors.colorBackgroundGray,
          borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
          border: Border.all(
            color: isSelected ? colors.colorPrimary : colors.colorBackgroundGray,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: AppTypos.text,
            fontWeight: FontWeight.w500,
            color: isSelected ? colors.colorButtonText : colors.colorText,
          ),
        ),
      ),
    );
  }
}
