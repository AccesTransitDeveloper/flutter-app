import 'dart:ui';

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Floating pill navigation bar. The selected tab expands into a primary-tinted
/// pill showing its icon + label; the rest stay as muted icons. Distinctive,
/// brand-coloured, and consistent across every tab.
class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  // Delivery is hidden — this build ships taxi only. To restore it, re-add
  // `_NavData(Icons.storefront_outlined, Icons.storefront, 'Delivery')` at
  // index 1 here and the matching DeliveryScreen tab in MainScreen.
  static const _items = <_NavData>[
    _NavData(Icons.home_outlined, Icons.home_rounded, 'Home'),
    _NavData(Icons.receipt_long_outlined, Icons.receipt_long, 'Activity'),
    _NavData(Icons.auto_awesome_outlined, Icons.auto_awesome, 'AT AI'),
    _NavData(Icons.inbox_outlined, Icons.inbox_rounded, 'Inbox'),
    _NavData(Icons.person_outline_rounded, Icons.person_rounded, 'Account'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      margin: EdgeInsets.fromLTRB(
        14,
        6,
        14,
        bottomInset > 0 ? bottomInset : 12,
      ),
      // Elevation lives on the outer box (a ClipRRect would clip the shadow) so
      // the translucent bar clearly floats above the screen.
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: colors.colorText.withValues(alpha: 0.22),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      // Frosted / translucent: content scrolls through behind it (extendBody).
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            decoration: BoxDecoration(
              color: colors.colorBackground.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: colors.colorText.withValues(alpha: 0.06),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (int i = 0; i < _items.length; i++)
                  _NavItem(
                    data: _items[i],
                    isSelected: currentIndex == i,
                    onTap: () => onTap(i),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavData {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const _NavData(this.icon, this.selectedIcon, this.label);
}

class _NavItem extends StatelessWidget {
  final _NavData data;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.data,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final primary = colors.colorPrimary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 13 : 10,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? data.selectedIcon : data.icon,
              color: isSelected ? primary : colors.colorTextHint,
              size: 24,
            ),
            // Label reveals with a smooth width animation only when selected.
            ClipRect(
              child: AnimatedSize(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOut,
                child: isSelected
                    ? Padding(
                        padding: const EdgeInsets.only(left: 7),
                        child: Text(
                          data.label,
                          maxLines: 1,
                          style: TextStyle(
                            color: primary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
