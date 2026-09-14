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
                    Container(
                      width: widget.size * .66,
                      height: widget.size * .66,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: .22),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF3B82F6,
                            ).withValues(alpha: .35),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/at_ai_avatar.png',
                          fit: BoxFit.cover,
                        ),
                      ),
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
    final radius = size.shortestSide * .36;
    if (mode == VoiceOrbMode.idle) {
      final pulse = .82 + .18 * math.sin(progress * math.pi * 2).abs();
      canvas.drawCircle(
        center,
        radius * (1.18 + .08 * pulse),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5)
          ..color = const Color(0xFF38BDF8).withValues(alpha: .42 * pulse),
      );
    } else if (mode == VoiceOrbMode.listening) {
      for (var i = 0; i < 3; i++) {
        final t = (progress + i / 3) % 1;
        canvas.drawCircle(
          center,
          radius + radius * .72 * t,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5
            ..color = const Color(0xFF38BDF8).withValues(alpha: (1 - t) * .75),
        );
      }
    } else if (mode == VoiceOrbMode.thinking) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius * 1.24),
        progress * math.pi * 2,
        math.pi * 1.25,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 4
          ..shader = const SweepGradient(
            colors: [Color(0xFF2563EB), Color(0xFF67E8F9), Color(0xFF2563EB)],
          ).createShader(Rect.fromCircle(center: center, radius: radius * 1.3)),
      );
    } else {
      for (var i = 0; i < 24; i++) {
        final angle = i / 24 * math.pi * 2;
        final wave =
            .08 + .12 * (.5 + .5 * math.sin(progress * math.pi * 4 + i * .82));
        final inner = radius * 1.12;
        final outer = radius * (1.12 + wave);
        canvas.drawLine(
          Offset(
            center.dx + math.cos(angle) * inner,
            center.dy + math.sin(angle) * inner,
          ),
          Offset(
            center.dx + math.cos(angle) * outer,
            center.dy + math.sin(angle) * outer,
          ),
          Paint()
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round
            ..color = Color.lerp(
              const Color(0xFF2563EB),
              const Color(0xFF67E8F9),
              i / 23,
            )!,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _OrbPainter old) =>
      old.mode != mode || old.progress != progress || old.color != color;
}
