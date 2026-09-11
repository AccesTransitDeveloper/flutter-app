import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the floating bottom navigation bar is currently visible. Scrollable
/// screens flip this to false while the user scrolls down (reverse) and back to
/// true when they scroll up (forward), so the bar hides/reveals on scroll.
final bottomNavVisibleProvider = StateProvider<bool>((ref) => true);
