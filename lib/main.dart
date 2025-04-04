import 'dart:async';
import 'dart:ui';

import 'package:Freedom_Guard/components/connect.dart';
import 'package:Freedom_Guard/components/f-link.dart';
import 'package:Freedom_Guard/components/update.dart';
import 'package:Freedom_Guard/components/servers.dart';
import 'package:Freedom_Guard/components/settings.dart';
import 'package:Freedom_Guard/pages/loading.dart';
import 'package:Freedom_Guard/pages/servers.dart';
import 'package:Freedom_Guard/pages/settings.dart';
import 'package:Freedom_Guard/widgets/fragment.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/LOGPAGE.dart';
import 'components/LOGLOG.dart';
import 'widgets/PingWidget.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
          '/': (context) => LoadingScreen(),
          '/home': (context) => FreedomGuardApp(),
        },
      ),
    ),
  );
}

class FreedomGuardApp extends StatelessWidget {
  const FreedomGuardApp({super.key});

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
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isConnected = false;
  bool isPressed = false;
  bool isConnecting = false;
  Connect connect = new Connect();
  ServersM serverM = new ServersM();
  Settings settings = new Settings();

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      Timer.periodic(Duration(seconds: 10), (timer) {
        checkVPN();
      });
      await checkForUpdate(context);
    });
  }

  checkVPN() async {
    if (await checkForVPN() == true) {
      setState(() {
        isConnected = true;
      });
    }
    initSettings();
  }

  initSettings() async {
    if (await settings.getValue("core_vpn") == "")
      settings.setValue("core_vpn", "auto");
  }

  Future<void> toggleConnection() async {
    if (isConnecting) {
      await connect.disConnect();
      setState(() {
        isConnected = false;
        isConnecting = false;
      });
      LogOverlay.showLog(
        "Connection process stopped.",
        backgroundColor: Colors.orangeAccent,
      );
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
          LogOverlay.showLog(
            "connecting to auto mode",
            backgroundColor: Colors.blueAccent,
          );
          var timeout =
              int.tryParse(
                await settings.getValue("timeout_auto").toString(),
              ) ??
              110000;
          connStat = await connect.ConnectAuto(
            "https://raw.githubusercontent.com/Freedom-Guard/Freedom-Guard/refs/heads/main/config/index.json",
            110000,
          ).timeout(
            Duration(milliseconds: timeout),
            onTimeout: () {
              LogOverlay.showLog("Connection to Auto mode timed out.");
              return false;
            },
          );
        } else {
          LogOverlay.showLog(
            "connecting to config:\n${selectedServer.split("#")[0]}",
            backgroundColor: Colors.blueAccent,
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

          LogOverlay.showLog(
            "connected to ${await settings.getValue("core_vpn")} mode",
            backgroundColor: Colors.greenAccent,
          );
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
            backgroundColor: Colors.redAccent,
          );
        }
      } catch (e) {
        setState(() {
          isConnected = false;
        });
        LogOverlay.showLog("خطا در اتصال: $e");
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
              image: AssetImage("assets/background.jpg"),
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
                  title: const Text(
                    "Freedom Guard",
                    style: TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.black.withOpacity(0.3),
                  elevation: 0,
                  centerTitle: true,
                  leading: IconButton(
                    icon: const Icon(Icons.cable_rounded),
                    color: Theme.of(context).colorScheme.onSurface,
                    onPressed: () {
                      openXraySettings(context);
                    },
                  ),
                  actions: [
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
                image: AssetImage("assets/background.jpg"),
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
                        colors:
                            isConnected
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
                          color:
                              isConnected
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
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 2000),
                              width: 150,
                              height: 150,
                              child: CustomPaint(
                                painter: _PulsePainter(isConnecting),
                              ),
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
                                    color:
                                        isConnected
                                            ? Colors.green.shade900.withOpacity(
                                              0.7,
                                            )
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
                const SizedBox(height: 20),
                Text(
                  isConnecting
                      ? "Connecting..."
                      : isConnected
                      ? "Connected"
                      : "Not connected",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                if (isConnected) NetworkStatusWidget() else (PingWidget()),
                Spacer(flex: 1),
              ],
            ),
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: const Color.fromARGB(0, 255, 255, 255),
              boxShadow: [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(0),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // بلور قوی‌تر
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(0, 255, 255, 255),
                    border: const Border(
                      top: BorderSide(
                        color: Color.fromARGB(25, 255, 255, 255),
                        width: 1.5,
                      ),
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: BottomNavigationBar(
                    backgroundColor: Colors.transparent,
                    selectedItemColor: Colors.white,
                    unselectedItemColor: Colors.grey.shade400,
                    showSelectedLabels: false,
                    showUnselectedLabels: false,
                    elevation: 0,
                    type: BottomNavigationBarType.fixed,
                    currentIndex: 1,
                    items: [
                      _buildNavItem(
                        Icons.settings,
                        "تنظیمات",
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SettingsPage(),
                          ),
                        ),
                      ),
                      _buildNavItem(Icons.home_filled, "خانه", () {}),
                      _buildNavItem(
                        Icons.cloud_sync,
                        "سرور ها",
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ServersPage(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  BottomNavigationBarItem _buildNavItem(
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return BottomNavigationBarItem(
      icon: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 70,
          padding: const EdgeInsets.symmetric(vertical: 10),
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: const Color.fromARGB(255, 51, 26, 61),
            boxShadow: [
              BoxShadow(
                color: const Color.fromARGB(103, 0, 0, 0),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, size: 26, color: Colors.grey.shade300),
        ),
      ),
      activeIcon: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 70,
        padding: const EdgeInsets.symmetric(vertical: 12),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFF7C3AED),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C3AED).withOpacity(0.4),
              blurRadius: 8,
              spreadRadius: 1,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, size: 28, color: Colors.white),
      ),
      label: '',
      tooltip: label,
    );
  }
}

class _PulsePainter extends CustomPainter {
  final bool isConnecting;

  _PulsePainter(this.isConnecting);

  @override
  void paint(Canvas canvas, Size size) {
    if (!isConnecting) return;

    final center = Offset(size.width / 2, size.height / 2);
    final paint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..shader = RadialGradient(
            colors: [
              Colors.blue.shade400.withOpacity(0.9),
              Colors.blue.shade200.withOpacity(0.2),
              Colors.transparent,
            ],
            stops: [0.0, 0.7, 1.0],
          ).createShader(
            Rect.fromCircle(center: center, radius: size.width / 2),
          );

    final time = DateTime.now().millisecondsSinceEpoch / 1000;
    for (int i = 0; i < 3; i++) {
      final animationProgress = (time + i * 0.5) % 1.0;
      final radius =
          (size.width / 2) *
          (0.3 + (i * 0.25)) *
          (0.5 + 0.5 * (animationProgress * 2 - 1).abs());
      final opacity = 1.0 - animationProgress;

      canvas.drawCircle(
        center,
        radius,
        paint..strokeWidth = (2.5 * opacity).clamp(0.5, 2.5),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
