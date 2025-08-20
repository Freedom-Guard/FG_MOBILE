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
      final staticPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.teal.shade300.withOpacity(0.6),
            Colors.blue.shade600.withOpacity(0.3),
            Colors.transparent,
          ],
          stops: const [0.1, 0.6, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: maxRadius * 0.8));
      canvas.drawCircle(center, maxRadius * 0.8, staticPaint);

      final staticGlow = Paint()
        ..color = Colors.teal.shade200.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15.0);
      canvas.drawCircle(center, maxRadius * 0.65, staticGlow);
      return;
    }

    final t = animationValue;
    for (int i = 0; i < 6; i++) {
      final progress = (t + i * 0.166) % 1.0;
      final radius = maxRadius * 0.25 + progress * maxRadius * 0.7;
      final opacity = (1.0 - progress * 0.6).clamp(0.4, 1.0);
      final strokeWidth = 3.0 + (1.0 - progress) * 5.0;

      final wavePaint = Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.teal.shade200.withOpacity(opacity),
            Colors.cyan.shade400.withOpacity(opacity * 0.95),
            Colors.blue.shade500.withOpacity(opacity * 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.4, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
      canvas.drawCircle(center, radius, wavePaint);

      final particlePaint = Paint()
        ..color = Colors.cyan.shade100.withOpacity(opacity * 0.9)
        ..style = PaintingStyle.fill;
      final angle = progress * 2 * math.pi + i * (math.pi / 3);
      final particleRadius = radius * 1.0;
      final particleOffset = Offset(
        center.dx + particleRadius * math.cos(angle),
        center.dy + particleRadius * math.sin(angle),
      );
      canvas.drawOval(
        Rect.fromCenter(center: particleOffset, width: 8.0 * (1.0 - progress), height: 5.0 * (1.0 - progress)),
        particlePaint,
      );
    }

    final ripplePaint = Paint()
      ..color = Colors.teal.shade400.withOpacity(0.6 * (1.0 - t))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0);
    canvas.drawCircle(center, maxRadius * 0.55 * (0.7 + t * 0.4), ripplePaint);

    final orbitPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          Colors.teal.shade300.withOpacity(0.95),
          Colors.cyan.shade500.withOpacity(0.8),
          Colors.blue.shade400.withOpacity(0.85),
          Colors.teal.shade300.withOpacity(0.95),
        ],
        stops: const [0.0, 0.3, 0.6, 1.0],
        transform: GradientRotation(t * 2 * math.pi),
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius * 0.7))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9.0);
    canvas.drawCircle(center, maxRadius * 0.7, orbitPaint);

    final arcPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.cyan.shade300.withOpacity(0.85),
          Colors.teal.shade500.withOpacity(0.65),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius * 0.5))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7.0);
    for (int i = 0; i < 5; i++) {
      final arcAngle = t * 2 * math.pi + i * (math.pi / 2.5);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: maxRadius * 0.5),
        arcAngle,
        math.pi / 2,
        false,
        arcPaint,
      );
    }

    final glowPaint = Paint()
      ..color = Colors.blue.shade200.withOpacity(0.3 * (math.sin(t * 2 * math.pi) + 1) / 2)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12.0);
    canvas.drawCircle(center, maxRadius * 0.3, glowPaint);
  }

  @override
  bool shouldRepaint(covariant ConnectPainter oldDelegate) =>
      isConnecting != oldDelegate.isConnecting ||
      animationValue != oldDelegate.animationValue;

  @override
  bool shouldRebuildSemantics(covariant ConnectPainter oldDelegate) => false;
}