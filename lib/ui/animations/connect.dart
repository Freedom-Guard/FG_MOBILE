import 'package:flutter/material.dart';
import 'dart:math' as math;

class ConnectPainter extends CustomPainter {
  final bool isConnecting;
  final double animationValue;

  ConnectPainter(this.isConnecting, {required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width * 0.45;

    if (!isConnecting) {
      final basePaint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.blue.shade400.withOpacity(0.5),
            Colors.cyan.shade600.withOpacity(0.2),
            Colors.transparent,
          ],
          stops: const [0.2, 0.6, 1.0],
        ).createShader(
            Rect.fromCircle(center: center, radius: maxRadius * 0.7));
      canvas.drawCircle(center, maxRadius * 0.7, basePaint);

      final glowPaint = Paint()
        ..color = Colors.cyan.shade300.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0);
      canvas.drawCircle(center, maxRadius * 0.55, glowPaint);
      return;
    }

    final t = animationValue;
    for (int i = 0; i < 3; i++) {
      final progress = (t + i * 0.33) % 1.0;
      final radius = maxRadius * 0.4 + progress * maxRadius * 0.5;
      final opacity = (0.8 - progress * 0.5).clamp(0.3, 0.8);
      final strokeWidth = 3.0 + (1.0 - progress) * 4.0;

      final wavePaint = Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.blue.shade300.withOpacity(opacity),
            Colors.cyan.shade500.withOpacity(opacity * 0.9),
            Colors.teal.shade600.withOpacity(opacity * 0.6),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);
      canvas.drawCircle(center, radius, wavePaint);

      final dropletPaint = Paint()
        ..color = Colors.cyan.shade200.withOpacity(opacity * 0.7)
        ..style = PaintingStyle.fill;
      final angle = progress * 2 * math.pi + i * (2 * math.pi / 3);
      final dropletRadius = radius * 0.8;
      final dropletOffset = Offset(
        center.dx + dropletRadius * math.cos(angle),
        center.dy + dropletRadius * math.sin(angle),
      );
      canvas.drawCircle(dropletOffset, 4.0 * (1.0 - progress), dropletPaint);
    }

    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.9),
          Colors.cyan.shade400.withOpacity(0.6),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius * 0.3));
    canvas.drawCircle(center, maxRadius * 0.3, corePaint);

    final ripplePaint = Paint()
      ..color = Colors.blue.shade400.withOpacity(0.5 * (1.0 - t))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
    canvas.drawCircle(center, maxRadius * 0.4 * (1.0 + t), ripplePaint);

    final orbitPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          Colors.cyan.shade300.withOpacity(0.8),
          Colors.blue.shade500.withOpacity(0.6),
          Colors.teal.shade400.withOpacity(0.8),
          Colors.cyan.shade300.withOpacity(0.8),
        ],
        stops: const [0.0, 0.4, 0.7, 1.0],
        transform: GradientRotation(t * 2 * math.pi),
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius * 0.6))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7.0);
    canvas.drawCircle(center, maxRadius * 0.6, orbitPaint);
  }

  @override
  bool shouldRepaint(covariant ConnectPainter oldDelegate) =>
      isConnecting != oldDelegate.isConnecting ||
      animationValue != oldDelegate.animationValue;

  @override
  bool shouldRebuildSemantics(covariant ConnectPainter oldDelegate) => false;
}
