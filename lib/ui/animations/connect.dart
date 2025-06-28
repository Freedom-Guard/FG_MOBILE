import 'package:flutter/material.dart';

class ConnectPainter extends CustomPainter {
  final bool isConnecting;
  final double animationValue;

  ConnectPainter(this.isConnecting, {required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    if (!isConnecting) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [Colors.teal.shade100.withOpacity(0.1), Colors.transparent],
          stops: const [0.7, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: 20));
      canvas.drawCircle(center, 20, paint);
      return;
    }

    final t = animationValue;
    for (int i = 0; i < 3; i++) {
      final progress = (t + i * 0.3) % 1.0;
      final radius = 15.0 + progress * 30;
      final opacity = (0.6 - progress * 0.5).clamp(0.0, 1.0);

      final ripplePaint = Paint()
        ..color = Colors.cyan.shade100.withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;

      canvas.drawCircle(center, radius, ripplePaint);
    }
  }

  @override
  bool shouldRepaint(covariant ConnectPainter oldDelegate) =>
      isConnecting != oldDelegate.isConnecting ||
      animationValue != oldDelegate.animationValue;

  @override
  bool shouldRebuildSemantics(covariant ConnectPainter oldDelegate) => false;
}
