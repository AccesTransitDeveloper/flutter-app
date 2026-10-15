import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:customer/core/map/widgets/route_point_glyph.dart';

void main() {
  test('pickup is cyan, drop-off is pink and route is cyan', () {
    expect(RoutePointGlyph.pickupColor, const Color(0xFF26C6FF));
    expect(RoutePointGlyph.dropoffColor, const Color(0xFFFF42C8));
    expect(RoutePointGlyph.routeColor, RoutePointGlyph.pickupColor);
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
