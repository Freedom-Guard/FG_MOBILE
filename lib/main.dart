import 'dart:async';
import 'dart:io';
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
import 'package:flutter/services.dart';
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
  MethodChannel _channel = const MethodChannel('vpn_quick_tile');
  _channel.setMethodCallHandler((call) async {
    if (call.method == "onTileClicked") {
      bool isOn = call.arguments == true;
      if (isOn) {
        LogOverlay.addLog("🟢 VPN روشن شد از Tile");
      } else {
        LogOverlay.addLog("🔴 VPN خاموش شد از Tile");
      }
    }
  });
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
  String backgroundPath = BackgroundService.getRandomBackground();
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
      sleep(Duration(seconds: 3));
      setState(() async {
        isConnected = await checker.checkVPN();
      });
      await checkForUpdate(context);
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
        var selectedServer =
            (await serverM.getSelectedServer() as String).trim();
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
            connStat = await connect.ConnectFG(
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
          if (selectedServer.startsWith("http") ||
              selectedServer.startsWith("freedom-guard")) {
            connStat = await connect.ConnectSub(
                selectedServer.replaceAll("freedom-guard://", ""),
                selectedServer.startsWith("freedom-guard") ? "fgAuto" : "sub");
          } else {
            connStat = await connect.ConnectVibe(selectedServer, {});
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
          if ((await settings.getValue("f_link")) == "true") {
            donateCONFIG(selectedServer.split("#")[0]);
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
                    duration: const Duration(milliseconds: 300),
                    width: isPressed ? 110 : 130,
                    height: isPressed ? 110 : 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: isConnected
                            ? [Colors.green.shade400, Colors.teal.shade700]
                            : isConnecting
                                ? [Colors.blue.shade300, Colors.teal.shade800]
                                : [Colors.blueGrey.shade900, Colors.black],
                        radius: 0.75,
                        center: Alignment.center,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isConnected
                              ? Colors.green.shade500.withOpacity(0.4)
                              : Colors.blue.shade500.withOpacity(0.4),
                          blurRadius: isPressed ? 20 : 12,
                          spreadRadius: isPressed ? 4 : 1,
                          offset: const Offset(0, 2),
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
                            opacity: isConnecting ? 0.7 : 0.0,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                            child: Container(
                              width: 130,
                              height: 130,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.25),
                                    Colors.transparent,
                                  ],
                                  radius: 0.65,
                                ),
                              ),
                            ),
                          ),
                          if (isConnecting)
                            AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, child) {
                                return Container(
                                  width: 130,
                                  height: 130,
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
                            scale: isPressed ? 0.92 : 1.0,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              transitionBuilder: (child, animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: ScaleTransition(
                                    scale: animation,
                                    child: child,
                                  ),
                                );
                              },
                              child: Tooltip(
                                message: isConnected ? 'قطع اتصال' : 'اتصال',
                                child: Icon(
                                  isConnected
                                      ? Icons.vpn_key_off
                                      : Icons.vpn_key,
                                  key: ValueKey(isConnected),
                                  size: 50,
                                  color: Colors.white.withOpacity(0.9),
                                  shadows: [
                                    Shadow(
                                      color: isConnected
                                          ? Colors.blue.shade700
                                              .withOpacity(0.6)
                                          : Colors.grey.shade800
                                              .withOpacity(0.4),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
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
                if (!isConnected) Spacer(flex: 1),
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
      label: label,
      tooltip: label,
    );
  }
}

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