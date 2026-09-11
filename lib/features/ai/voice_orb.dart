import 'dart:math' as math;

import 'package:flutter/material.dart';

enum VoiceOrbMode { idle, listening, thinking, speaking }

class VoiceOrb extends StatefulWidget {
  final VoiceOrbMode mode;
  final double size;

  const VoiceOrb({super.key, required this.mode, this.size = 96});

  @override
  State<VoiceOrb> createState() => _VoiceOrbState();
}

class _VoiceOrbState extends State<VoiceOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final statusLabel = switch (widget.mode) {
      VoiceOrbMode.idle => 'AT AI voice is ready',
      VoiceOrbMode.listening => 'AT AI is listening',
      VoiceOrbMode.thinking => 'AT AI is thinking',
      VoiceOrbMode.speaking => 'AT AI is speaking',
    };
    return Semantics(
      label: statusLabel,
      liveRegion: true,
      image: true,
      child: ExcludeSemantics(
        child: TickerMode(
          enabled: !reduceMotion,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final progress = reduceMotion ? 0.0 : _controller.value;
              return SizedBox(
                width: widget.size,
                height: widget.size,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: Size.square(widget.size),
                      painter: _OrbPainter(
                        widget.mode,
                        progress,
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    if (widget.mode != VoiceOrbMode.speaking)
                      Image.asset(
                        'assets/images/at_ai_logo.png',
                        width: widget.size * .34,
                        height: widget.size * .34,
                        fit: BoxFit.contain,
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _OrbPainter extends CustomPainter {
  final VoiceOrbMode mode;
  final double progress;
  final Color color;

  _OrbPainter(this.mode, this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * .23;
    if (mode == VoiceOrbMode.idle) {
      canvas.drawCircle(
        center,
        radius * 1.65,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = color.withValues(alpha: .35),
      );
    } else if (mode == VoiceOrbMode.listening) {
      for (var i = 0; i < 3; i++) {
        final t = (progress + i / 3) % 1;
        canvas.drawCircle(
          center,
          radius + radius * 2.2 * t,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = color.withValues(alpha: (1 - t) * .7),
        );
      }
    } else if (mode == VoiceOrbMode.thinking) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius * 1.8),
        progress * math.pi * 2,
        math.pi * 1.25,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 4
          ..color = color,
      );
    } else {
      for (var i = 0; i < 5; i++) {
        final height = radius * (.8 + .7 * math.sin(progress * math.pi * 2 + i));
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(
                center.dx - radius * 1.3 + i * radius * .65,
                center.dy,
              ),
              width: 4,
              height: height.abs(),
            ),
            const Radius.circular(3),
          ),
          Paint()..color = color,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _OrbPainter old) =>
      old.mode != mode || old.progress != progress || old.color != color;
}