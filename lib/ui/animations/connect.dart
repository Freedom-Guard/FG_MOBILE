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
            Colors.teal.shade300.withOpacity(0.4),
            Colors.blue.shade700.withOpacity(0.15),
            Colors.transparent,
          ],
          stops: const [0.3, 0.7, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: maxRadius * 0.6));
      canvas.drawCircle(center, maxRadius * 0.6, basePaint);

      final glowPaint = Paint()
        ..color = Colors.teal.shade200.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
      canvas.drawCircle(center, maxRadius * 0.5, glowPaint);
      return;
    }

    final t = animationValue;
    for (int i = 0; i < 4; i++) {
      final progress = (t + i * 0.25) % 1.0;
      final radius = maxRadius * 0.3 + progress * maxRadius * 0.6;
      final opacity = (0.9 - progress * 0.65).clamp(0.25, 0.9);
      final strokeWidth = 2.0 + (1.0 - progress) * 3.0;

      final ripplePaint = Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.cyan.shade200.withOpacity(opacity),
            Colors.teal.shade400.withOpacity(opacity * 0.85),
            Colors.blue.shade600.withOpacity(opacity * 0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
      canvas.drawCircle(center, radius, ripplePaint);

      final particlePaint = Paint()
        ..color = Colors.cyan.shade100.withOpacity(opacity * 0.8)
        ..style = PaintingStyle.fill;
      final angle = progress * 2 * math.pi + i * (math.pi / 2);
      final particleRadius = radius * 0.75;
      final particleOffset = Offset(
        center.dx + particleRadius * (0.5 + 0.5 * progress) * math.cos(angle),
        center.dy + particleRadius * (0.5 + 0.5 * progress) * math.sin(angle),
      );
      canvas.drawCircle(particleOffset, 3.5 * (1.0 - progress), particlePaint);
    }

    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.8),
          Colors.teal.shade400.withOpacity(0.5),
          Colors.transparent,
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius * 0.25));
    canvas.drawCircle(center, maxRadius * 0.25, corePaint);

    final pulseCorePaint = Paint()
      ..color = Colors.cyan.shade300.withOpacity(0.4 * (1.0 - t))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);
    canvas.drawCircle(center, maxRadius * 0.35 * (1.0 - t), pulseCorePaint);

    final borderPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          Colors.cyan.shade200.withOpacity(0.9),
          Colors.teal.shade400.withOpacity(0.7),
          Colors.blue.shade600.withOpacity(0.5),
          Colors.cyan.shade200.withOpacity(0.9),
        ],
        stops: const [0.0, 0.3, 0.7, 1.0],
        transform: GradientRotation(t * 2 * math.pi),
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius * 0.5))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);
    canvas.drawCircle(center, maxRadius * 0.5, borderPaint);
  }

  @override
  bool shouldRepaint(covariant ConnectPainter oldDelegate) =>
      isConnecting != oldDelegate.isConnecting ||
      animationValue != oldDelegate.animationValue;

  @override
  bool shouldRebuildSemantics(covariant ConnectPainter oldDelegate) => false;
}