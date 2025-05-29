import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:Freedom_Guard/components/connect.dart';
import 'package:Freedom_Guard/components/f-link.dart';
import 'package:Freedom_Guard/components/local.dart';
import 'package:Freedom_Guard/components/services.dart';
import 'package:Freedom_Guard/components/update.dart';
import 'package:Freedom_Guard/components/servers.dart';
import 'package:Freedom_Guard/components/settings.dart';
import 'package:Freedom_Guard/pages/browser.dart';
import 'package:Freedom_Guard/pages/f-link.dart';
import 'package:Freedom_Guard/pages/servers.dart';
import 'package:Freedom_Guard/pages/settings.dart';
import 'package:Freedom_Guard/pages/speedtest.dart';
import 'package:Freedom_Guard/widgets/fragment.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/logs.dart';
import 'components/LOGLOG.dart';
import 'widgets/network.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initTranslations();
  try {} catch (e) {}
  try {
    await Firebase.initializeApp();
    await FirebaseMessaging.instance.setAutoInitEnabled(true);
    print("🔥 Firebase Initialized Successfully");
  } catch (e) {
    print("❌ Firebase Initialization Failed: $e");
  }

  FirebaseAnalytics.instance.logEvent(
    name: "app_opened",
    parameters: {"time": DateTime.now().toString()},
  );

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (context) => ServersM())],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (context) => FreedomGuardApp(),
          '/home': (context) => FreedomGuardApp(),
        },
      ),
    ),
  );
}

class FreedomGuardApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: LogOverlay.navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF0099FF),
          secondary: Color(0xFF8A2BE2),
          surface: Color(0xFF1A1B26),
          error: Color(0xFFFF1744),
          onPrimary: Colors.black,
          onSecondary: Colors.white,
          onSurface: Color(0xFFB0BEC5),
          onError: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
      ),
      home: Directionality(
        textDirection:
            getDir() == "rtl" ? TextDirection.rtl : TextDirection.ltr,
        child: HomePage(),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  bool isConnected = false;
  String backgroundPath = "";
  bool isPressed = false;
  bool isConnecting = false;
  Connect connect = new Connect();
  ServersM serverM = new ServersM();
  Settings settings = new Settings();
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  Map<String, String> defSet = {
    "fgconfig":
        "https://raw.githubusercontent.com/Freedom-Guard/Freedom-Guard/refs/heads/main/config/index.json",
  };
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    Future.microtask(() async {
      Timer.periodic(Duration(seconds: 45), (timer) {
        setState(() async {
          isConnected = await checker.checkVPN();
        });
      });
      setState(() async {
        isConnected = await checker.checkVPN();
      });
      await checkForUpdate(context);
      setState(() async {
        backgroundPath = BackgroundService.getRandomBackground();
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> toggleConnection() async {
    if (isConnecting) {
      await connect.disConnect();
      setState(() {
        isConnected = false;
        isConnecting = false;
      });
      LogOverlay.showLog("Connection process stopped.", type: "warning");
      return;
    }

    LogOverlay.clearLogs();
    setState(() {
      isConnecting = true;
    });

    if (isConnected) {
      setState(() {
        isConnected = false;
      });
      await connect.disConnect();
    } else {
      try {
        var connStat = false;
        var selectedServer = await serverM.getSelectedServer() as String;
        if (selectedServer.split("#")[0].isEmpty) {
          LogOverlay.showLog("connecting to FL mode...");
          connStat =
              await connectFL().timeout(Duration(seconds: 20), onTimeout: () {
            LogOverlay.showLog("Connection to FL mode timed out.");
            return false;
          });
          if (!connStat) {
            LogOverlay.showLog(
              "connecting to Repo mode...",
              backgroundColor: Colors.blueAccent,
            );
            var timeout = int.tryParse(
                  await settings.getValue("timeout_auto").toString(),
                ) ??
                110000;
            connStat = await connect.ConnectAuto(
              defSet["fgconfig"]!,
              110000,
            ).timeout(
              Duration(milliseconds: timeout),
              onTimeout: () {
                LogOverlay.showLog("Connection to Auto mode timed out.",
                    type: "error");
                return false;
              },
            );
          }
        } else {
          LogOverlay.showLog(
            "connecting to config:\n${selectedServer.split("#")[0]}",
          );
          if (selectedServer.startsWith("http")) {
            var bestConfig = await connect.getBestConfigFromSub(
              selectedServer.split("#")[0],
            );
            if (bestConfig != null) {
              connStat = await connect.ConnectVibe(bestConfig, "args");
            }
          } else if (selectedServer.startsWith("wireguard") ||
              selectedServer.startsWith("wire:::")) {
            connStat = await connect.ConnectWarp(selectedServer, []);
          } else {
            connStat = await connect.ConnectVibe(selectedServer, "args");
          }
        }

        setState(() {
          isConnected = connStat;
        });

        if (connStat) {
          FirebaseAnalytics.instance.logEvent(
            name: "connected",
            parameters: {
              "time": DateTime.now().toString(),
              "core": await settings.getValue("core_vpn"),
              "isp": await settings.getValue("user_isp"),
            },
          );

          if ((await settings.getValue("f_link").toString()) == "true") {
            donateCONFIG(selectedServer.split("#")[0]);
          }
          if (await settings.getValue("core_vpn") == "auto" ||
              await settings.getValue("core_vpn") == "") {
            connect.startConfigUpdateTimer(defSet["fgconfig"]!, 150000);
          }
          LogOverlay.showLog(
              "connected to ${await settings.getValue("core_vpn")} mode",
              type: "success");
          refreshCache();
        } else {
          if (await settings.getValue("core_vpn") == "auto") {
            FirebaseAnalytics.instance.logEvent(
              name: "not_connected",
              parameters: {
                "time": DateTime.now().toString(),
                "core": await settings.getValue("core_vpn"),
                "isp": await settings.getValue("user_isp"),
              },
            );
          }
          LogOverlay.showLog(
              "not connected to ${await settings.getValue("core_vpn")} mode",
              type: "error");
        }
      } catch (e) {
        setState(() {
          isConnected = false;
        });
        LogOverlay.showLog("خطا در اتصال: $e", type: "error");
      }
    }

    setState(() {
      isConnecting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(backgroundPath),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(kToolbarHeight),
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: AppBar(
                  backgroundColor: Colors.black.withOpacity(0.7),
                  elevation: 0,
                  centerTitle: true,
                  leading: IconButton(
                    icon: const Icon(Icons.cable),
                    color: Theme.of(context).colorScheme.onSurface,
                    onPressed: () {
                      openXraySettings(context);
                    },
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.volunteer_activism,
                          color: Colors.red),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PremiumDonateConfigPage(),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.public),
                      color: Colors.grey,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FreedomBrowser(),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.network_check),
                      color: Colors.grey,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SpeedTestPage(),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.bug_report_sharp),
                      color: Colors.grey,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => LogPage()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(backgroundPath),
                fit: BoxFit.cover,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Spacer(flex: isConnected ? 2 : 1),
                GestureDetector(
                  onTapDown: (_) => setState(() => isPressed = true),
                  onTapUp: (_) => setState(() => isPressed = false),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    width: isPressed ? 130 : 150,
                    height: isPressed ? 130 : 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: isConnected
                            ? [Colors.green.shade400, Colors.teal.shade900]
                            : isConnecting
                                ? [Colors.blue.shade300, Colors.indigo.shade800]
                                : [
                                    const Color(0xFF1F2525),
                                    const Color(0xFF0D1117),
                                  ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isConnected
                              ? Colors.green.shade700.withOpacity(0.6)
                              : isConnecting
                                  ? Colors.blue.shade700.withOpacity(0.5)
                                  : Colors.black.withOpacity(0.3),
                          blurRadius: isPressed ? 30 : 20,
                          spreadRadius: isPressed ? 6 : 2,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: toggleConnection,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedOpacity(
                            opacity: isConnecting ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeInOutCubic,
                            child: Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.15),
                                    Colors.transparent,
                                  ],
                                  radius: 0.7,
                                  stops: const [0.0, 1.0],
                                ),
                              ),
                            ),
                          ),
                          if (isConnecting)
                            AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, child) {
                                return Container(
                                  width: 150,
                                  height: 150,
                                  child: CustomPaint(
                                    painter: ConnectPainter(
                                      isConnecting,
                                      animationValue: _pulseAnimation.value,
                                    ),
                                  ),
                                );
                              },
                            ),
                          AnimatedScale(
                            scale: isPressed ? 0.85 : 1.0,
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.elasticOut,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder: (child, animation) {
                                return ScaleTransition(
                                  scale: animation,
                                  child: child,
                                );
                              },
                              child: Icon(
                                isConnected
                                    ? Icons.lock_rounded
                                    : Icons.power_settings_new_rounded,
                                key: ValueKey(isConnected),
                                size: 80,
                                color: Colors.white.withOpacity(0.95),
                                shadows: [
                                  Shadow(
                                    color: isConnected
                                        ? Colors.green.shade900.withOpacity(0.7)
                                        : Colors.blueGrey.shade900
                                            .withOpacity(0.5),
                                    blurRadius: 15,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 25),
                if (isConnected) NetworkStatusWidget(),
                Spacer(flex: 1),
              ],
            ),
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromARGB(45, 26, 27, 38),
                  Color.fromARGB(78, 42, 43, 54)
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 4,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: BottomNavigationBar(
                  backgroundColor: Colors.transparent,
                  selectedItemColor: Colors.white,
                  unselectedItemColor: Colors.grey.shade500,
                  showSelectedLabels: false,
                  showUnselectedLabels: false,
                  elevation: 0,
                  type: BottomNavigationBarType.fixed,
                  currentIndex: 1,
                  items: [
                    _buildNavItem(
                      Icons.settings_sharp,
                      tr("settings"),
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SettingsPage()),
                      ),
                    ),
                    _buildNavItem(Icons.home, "خانه", () {}),
                    _buildNavItem(
                      Icons.cloud_sync_outlined,
                      tr("manage-servers-page"),
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ServersPage()),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  BottomNavigationBarItem _buildNavItem(
      IconData icon, String label, VoidCallback onTap) {
    return BottomNavigationBarItem(
      icon: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 60,
          padding: EdgeInsets.all(10),
          margin: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.shade900.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            size: 26,
            color: Colors.grey.shade400,
          ),
        ),
      ),
      activeIcon: Container(
        width: 60,
        padding: EdgeInsets.all(4),
        margin: EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF6B46F6),
              Color(0xFF48B0F8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF6B46F6).withOpacity(0.4),
              blurRadius: 8,
              spreadRadius: 2,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 24,
          color: Colors.white,
        ),
      ),
      label: '',
      tooltip: label,
    );
  }
}

class ConnectPainter extends CustomPainter {
  final bool isConnecting;
  final double animationValue;
  final List<Paint> _pulsePaints;
  final Paint _staticPaint;
  final Paint _staticIconLinePaint;
  final Paint _staticIconArcPaint;
  final Paint _auraPaint;
  final List<Paint> _spinningBandPaints;
  final Paint _particlePaint;
  final Paint _corePaint;
  final Paint _coreBrightSpotPaint;
  final Paint _activeIconLinePaint;
  final Paint _activeIconArcPaint;

  ConnectPainter(this.isConnecting, {required this.animationValue})
      : _pulsePaints =
            List.generate(3, (_) => Paint()..style = PaintingStyle.stroke),
        _staticPaint = Paint(),
        _staticIconLinePaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round
          ..color = Colors.grey.shade800,
        _staticIconArcPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round
          ..color = Colors.grey.shade700,
        _auraPaint = Paint(),
        _spinningBandPaints =
            List.generate(2, (_) => Paint()..style = PaintingStyle.stroke),
        _particlePaint = Paint()..color = Colors.white.withOpacity(0.9),
        _corePaint = Paint(),
        _coreBrightSpotPaint = Paint(),
        _activeIconLinePaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round
          ..color = Colors.white,
        _activeIconArcPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round
          ..color = Colors.cyan.shade100 {
    _staticPaint.shader = RadialGradient(
      colors: [Colors.grey.shade400, Colors.grey.shade600],
      stops: const [0.3, 1.0],
    ).createShader(Rect.fromCircle(
        center: Offset.zero, radius: 20)); // Placeholder, updated in paint
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final t = animationValue;

    if (!isConnecting) {
      _staticPaint.shader = RadialGradient(
        colors: [Colors.grey.shade400, Colors.grey.shade600],
        stops: const [0.3, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: 20));
      canvas.drawCircle(center, 20, _staticPaint);
      _drawPowerIconSymbol(canvas, center, 1.0, false);
      return;
    }

    final double overallProgress = t;

    // 1. Outer Aura
    final auraRadius = 10 + overallProgress * 80;
    final auraOpacity = math.pow(1.0 - overallProgress, 2.5).toDouble() * 0.25;
    _auraPaint.color = Colors.cyan.withOpacity(auraOpacity.clamp(0.0, 0.25));
    canvas.drawCircle(center, auraRadius, _auraPaint);

    // 2. Pulsing Ripples
    final pulseBaseColors = [
      Colors.blue.shade300,
      Colors.cyan.shade200,
      Colors.teal.shade300,
    ];
    for (int i = 0; i < 3; i++) {
      final progress = (overallProgress * 1.2 + i * 0.25) % 1.0;
      final radius = 20 + progress * 60;
      final opacity = math.pow(1.0 - progress, 3.5).toDouble().clamp(0.0, 1.0);
      final strokeWidth = (2.8 - progress * 2.8).clamp(0.1, 2.8);

      _pulsePaints[i]
        ..color = pulseBaseColors[i].withOpacity(opacity * 0.6)
        ..strokeWidth = strokeWidth;
      canvas.drawCircle(center, radius, _pulsePaints[i]);
    }

    // 3. Spinning Energy Bands
    final spin1 = overallProgress * math.pi * 2.5;
    final spin2 = -overallProgress * math.pi * 3.0;
    final bandRadii = [23.0, 19.0];
    final bandStrokeWidths = [3.5, 2.5];
    final bandColors = [
      [Colors.cyan.shade400, Colors.blue.shade500.withOpacity(0.7)],
      [Colors.teal.shade200, Colors.cyan.shade100.withOpacity(0.7)],
    ];

    for (int i = 0; i < 2; i++) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(i == 0 ? spin1 : spin2);
      _spinningBandPaints[i]
        ..shader = SweepGradient(
          colors: bandColors[i],
          stops: const [0.0, 0.75],
          startAngle: 0.0,
          endAngle: math.pi * 1.5,
        ).createShader(
            Rect.fromCircle(center: Offset.zero, radius: bandRadii[i]))
        ..strokeWidth = bandStrokeWidths[i];
      canvas.drawCircle(Offset.zero, bandRadii[i], _spinningBandPaints[i]);
      canvas.restore();
    }

    // 4. Particle System
    const int numParticles = 7;
    final particleSeed = (t * 1000).toInt();
    for (int i = 0; i < numParticles; i++) {
      final particleRandom = math.Random(particleSeed + i);
      final lifeProgress =
          (overallProgress * 1.8 + particleRandom.nextDouble() * 0.5) % 1.0;
      final angle = particleRandom.nextDouble() * math.pi * 2 +
          (i % 2 == 0 ? spin1 : spin2) * 0.3;
      final distance =
          15 + lifeProgress * (30 + particleRandom.nextDouble() * 10);
      final size = (1.8 - lifeProgress * 1.5).clamp(0.5, 2.2);
      final opacity = math.pow(1.0 - lifeProgress, 2).toDouble() *
          (0.6 + particleRandom.nextDouble() * 0.4);

      _particlePaint.color = Colors.white.withOpacity(opacity.clamp(0.0, 1.0));
      canvas.drawCircle(
        Offset(center.dx + math.cos(angle) * distance,
            center.dy + math.sin(angle) * distance),
        size,
        _particlePaint,
      );
    }

    // 5. Core Element
    final corePulse = 0.5 + 0.5 * math.sin(overallProgress * math.pi * 5);
    final baseCoreRadius = 10.0;
    final currentCoreRadius = baseCoreRadius + corePulse * 3.5;

    _corePaint.shader = RadialGradient(
      colors: [
        Colors.white.withOpacity(0.9 + corePulse * 0.1),
        Colors.blue.shade300.withOpacity(0.7 + corePulse * 0.2),
        Colors.blue.shade600.withOpacity(0.6 + corePulse * 0.1)
      ],
      stops: [0.0, 0.3 + corePulse * 0.3, 1.0],
      center: Alignment.center,
    ).createShader(Rect.fromCircle(center: center, radius: currentCoreRadius));
    canvas.drawCircle(center, currentCoreRadius, _corePaint);

    _coreBrightSpotPaint.color = Colors.white.withOpacity(corePulse * 0.85);
    canvas.drawCircle(center, currentCoreRadius * (0.4 + corePulse * 0.2),
        _coreBrightSpotPaint);

    // 6. Integrated Power Icon
    _drawPowerIconSymbol(canvas, center, corePulse, true, t);
  }

  void _drawPowerIconSymbol(
      Canvas canvas, Offset center, double pulseFactor, bool isOn,
      [double t = 0.0]) {
    final double lineYOffset;
    final double arcRadius;
    final double arcStartAngle;
    final double arcSweepAngle;
    final Paint linePaint;
    final Paint arcPaint;

    if (isOn) {
      lineYOffset = 6.0 + pulseFactor * 2.0;
      arcRadius = 6.0 + pulseFactor * 1.5;
      arcStartAngle = math.pi / 2 + 0.4 - pulseFactor * 0.15;
      arcSweepAngle = math.pi * 1.6 + pulseFactor * 0.25;

      final activeLineOpacity = 0.8 + 0.2 * math.sin(t * math.pi * 8);
      _activeIconLinePaint.color = Colors.white.withOpacity(activeLineOpacity);
      linePaint = _activeIconLinePaint;

      final activeArcOpacity =
          0.7 + 0.3 * math.sin(t * math.pi * 6 + math.pi / 2);
      _activeIconArcPaint.color =
          Colors.cyan.shade100.withOpacity(activeArcOpacity);
      arcPaint = _activeIconArcPaint;
    } else {
      lineYOffset = 6.0;
      arcRadius = 6.0;
      arcStartAngle = math.pi / 2 + 0.5;
      arcSweepAngle = math.pi * 1.5;
      linePaint = _staticIconLinePaint;
      arcPaint = _staticIconArcPaint;
    }

    canvas.drawLine(
      Offset(center.dx, center.dy - lineYOffset),
      Offset(center.dx, center.dy + lineYOffset),
      linePaint,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: arcRadius),
      arcStartAngle,
      arcSweepAngle,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant ConnectPainter oldDelegate) =>
      isConnecting != oldDelegate.isConnecting ||
      animationValue != oldDelegate.animationValue;

  @override
  bool shouldRebuildSemantics(covariant ConnectPainter oldDelegate) => false;
}
