import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:customer/core/map/widgets/route_point_glyph.dart';

void main() {
  test('pickup is dark blue, drop-off is dark red and route is dark green', () {
    expect(RoutePointGlyph.pickupColor, const Color(0xFF00008B));
    expect(RoutePointGlyph.dropoffColor, const Color(0xFF8B0000));
    expect(RoutePointGlyph.routeColor, const Color(0xFF006400));
  });
  test('glyph has a transparent hole and outside, solid ring and stem', () {
    const size = Size(40, 60);
    final path = RoutePointGlyph.path(size);
    expect(path.contains(const Offset(20, 20)), isFalse, reason: 'hole');
    expect(path.contains(const Offset(1, 58)), isFalse, reason: 'outside');
    expect(path.contains(const Offset(20, 3)), isTrue, reason: 'ring');
    expect(path.contains(const Offset(20, 57)), isTrue, reason: 'stem');
  });

  testWidgets('RoutePointIcon keeps aspect ratio', (tester) async {
    await tester.pumpWidget(
      const Center(child: RoutePointIcon(size: 18)),
    );
    final box = tester.getSize(find.byType(RoutePointIcon));
    expect(box.height, 18);
    expect(box.width, closeTo(12, 0.01));
  });
}
