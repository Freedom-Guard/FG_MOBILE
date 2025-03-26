import 'package:flutter/material.dart';

class LoadingScreen extends StatefulWidget {
  @override
  _LoadingScreenState createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 7500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );

    _controller.forward().then((_) {
      Future.delayed(Duration(milliseconds: 500), () {
        Navigator.pushReplacementNamed(context, '/home');
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade900,
              Colors.black.withOpacity(0.95),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return CustomPaint(child: SizedBox.expand());
                },
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return ScaleTransition(
                            scale: _scaleAnimation,
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: Image.asset(
                                'assets/icon/ico.png',
                                width: 75,
                                fit: BoxFit.contain,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Spacer(flex: 1,),
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Text(
                            "آزادی، در دستان توست",
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.cyan.shade400.withOpacity(0.7),
                                  offset: Offset(0, 3),
                                  blurRadius: 15,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Spacer(flex: 1),
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Text(
                            "زن، زندگی، آزادی",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                              color: Colors.red,
                            ),
                          ),
                        ),
                        SizedBox(height: 40),
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Container(
                            width: 280,
                            height: 10,
                            child: AnimatedBuilder(
                              animation: _progressAnimation,
                              builder: (context, child) {
                                return CustomPaint(
                                  painter: ModernProgressPainter(
                                    _progressAnimation.value,
                                  ),
                                  child: SizedBox.expand(),
                                );
                              },
                            ),
                          ),
                        ),
                        SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ModernProgressPainter extends CustomPainter {
  final double animationValue;

  ModernProgressPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint =
        Paint()
          ..color = Colors.white.withOpacity(0.1)
          ..style = PaintingStyle.fill;

    final progressPaint =
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Colors.blueAccent,
              Colors.purple.shade600,
              Colors.cyan.shade400,
            ],
            stops: [0.0, 0.5, 1.0],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
          ..style = PaintingStyle.fill;

    final glowPaint =
        Paint()
          ..color = Colors.cyan.shade400.withOpacity(0.4)
          ..style = PaintingStyle.fill
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(35),
      ),
      bgPaint,
    );

    final progressWidth = size.width * animationValue;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, progressWidth, size.height),
        Radius.circular(35),
      ),
      glowPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, progressWidth, size.height),
        Radius.circular(35),
      ),
      progressPaint,
    );

    final borderPaint =
        Paint()
          ..color = Colors.white.withOpacity(0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(35),
      ),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
