import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// Black ring-and-stem marker used for pickup and destination points.
///
/// Geometry lives in a unit box (width 1, height [aspectRatio]) so the same
/// path drives the in-app widget and the rasterised Mapbox marker. The stem
/// tip sits at bottom-centre, which is the map anchor point.
class RoutePointGlyph {
  RoutePointGlyph._();

  static const Color color = Color(0xFF111111);

  /// Height / width.
  static const double aspectRatio = 1.5;

  static const double _ringOuter = 0.5; // radius, relative to width
  static const double _ringInner = 0.22;
  static const double _stemWidth = 0.14;

  static Path path(Size size) {
    final w = size.width;
    final h = size.height;
    final unit = w; // width-relative units
    final center = Offset(w / 2, _ringOuter * unit);
    final ring = Path()
      ..fillType = PathFillType.evenOdd
      ..addOval(Rect.fromCircle(center: center, radius: _ringOuter * unit))
      ..addOval(Rect.fromCircle(center: center, radius: _ringInner * unit));
    final stemTop = center.dy + _ringOuter * unit * 0.9;
    final stem = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(
            w / 2 - _stemWidth * unit / 2,
            stemTop,
            w / 2 + _stemWidth * unit / 2,
            h,
          ),
          Radius.circular(_stemWidth * unit / 2),
        ),
      );
    // Union keeps the hole transparent while merging the stem into the ring.
    return Path.combine(PathOperation.union, ring, stem);
  }

  static void paint(Canvas canvas, Size size, {Color fill = color}) {
    canvas.drawPath(
      path(size),
      Paint()
        ..color = fill
        ..isAntiAlias = true,
    );
  }

  /// Transparent PNG for Mapbox annotations. [logicalWidth] is in logical
  /// pixels; the bitmap is rendered at [devicePixelRatio] so it is drawn at the
  /// right size with iconSize 1.0. Use IconAnchor.BOTTOM.
  static Future<Uint8List> toPng({
    required double logicalWidth,
    required double devicePixelRatio,
    Color fill = color,
  }) async {
    final pxW = (logicalWidth * devicePixelRatio).clamp(4.0, 512.0).toDouble();
    final pxH = pxW * aspectRatio;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    paint(canvas, Size(pxW, pxH), fill: fill);
    final picture = recorder.endRecording();
    final image = await picture.toImage(pxW.ceil(), pxH.ceil());
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw StateError('Could not encode route marker');
      return data.buffer.asUint8List();
    } finally {
      image.dispose();
      picture.dispose();
    }
  }
}

class _RoutePointPainter extends CustomPainter {
  final Color fill;
  const _RoutePointPainter(this.fill);

  @override
  void paint(Canvas canvas, Size size) =>
      RoutePointGlyph.paint(canvas, size, fill: fill);

  @override
  bool shouldRepaint(_RoutePointPainter old) => old.fill != fill;

  @override
  bool hitTest(Offset position) => false;
}

/// Scalable widget form of [RoutePointGlyph]. [size] is the glyph height.
class RoutePointIcon extends StatelessWidget {
  final double size;
  final Color color;
  final String? semanticLabel;

  const RoutePointIcon({
    super.key,
    this.size = 16,
    this.color = RoutePointGlyph.color,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      excludeSemantics: semanticLabel == null,
      child: SizedBox(
        width: size / RoutePointGlyph.aspectRatio,
        height: size,
        child: CustomPaint(painter: _RoutePointPainter(color)),
      ),
    );
  }
}
