import 'dart:async';
import 'dart:math';
import 'dart:math' as math;
import 'dart:ui';

import 'package:Freedom_Guard/components/connect.dart';
import 'package:Freedom_Guard/components/f-link.dart';
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
import 'pages/LOGPAGE.dart';
import 'components/LOGLOG.dart';
import 'widgets/network.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isConnected = false;
  String backgroundPath = "";
  bool isPressed = false;
  bool isConnecting = false;
  Connect connect = new Connect();
  ServersM serverM = new ServersM();
  Settings settings = new Settings();
  Map<String, String> defSet = {
    "fgconfig":
        "https://raw.githubusercontent.com/Freedom-Guard/Freedom-Guard/refs/heads/main/config/index.json",
  };
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      Timer.periodic(Duration(seconds: 10), (timer) {
        checkVPN();
      });
      checkVPN();
      await checkForUpdate(context);
      setState(() async {
        List<String> backgroundList = [
          "10.jpg",
          "5.jpg",
          "15.jpg",
          "14.jpg",
          "4.jpg",
          "17.jpg",
          "background.jpg"
        ];
        final random = new Random();
        final randomBackground =
            backgroundList[random.nextInt(backgroundList.length)];
        backgroundPath = "assets/" + randomBackground;
      });
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
            "connecting to FL mode",
            backgroundColor: Colors.blueAccent,
          );
          connStat = await connectFL();
          if (!connStat) {
            LogOverlay.showLog(
              "connecting to Repo mode",
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
                LogOverlay.showLog("Connection to Auto mode timed out.");
                return false;
              },
            );
          }
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
          if (await settings.getValue("core_vpn") == "auto" ||
              await settings.getValue("core_vpn") == "") {
            connect.startConfigUpdateTimer(defSet["fgconfig"]!, 150000);
          }
          LogOverlay.showLog(
            "connected to ${await settings.getValue("core_vpn")} mode",
            backgroundColor: Colors.greenAccent,
          );
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
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 2000),
                              width: 150,
                              height: 150,
                              child: CustomPaint(
                                painter: ConnectPainter(isConnecting),
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
                                    color: isConnected
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
                SizedBox(height: 25),
                if (isConnected) NetworkStatusWidget() else (PingWidget()),
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
                      "Settings",
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SettingsPage()),
                      ),
                    ),
                    _buildNavItem(Icons.home, "خانه", () {}),
                    _buildNavItem(
                      Icons.cloud_sync_outlined,
                      "Manage Servers",
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
  const ConnectPainter(this.isConnecting);

  @override
  void paint(Canvas canvas, Size size) {
    if (!isConnecting) return;

    final center = Offset(size.width / 2, size.height / 2);
    final time = DateTime.now().millisecondsSinceEpoch / 500;
    final pulse = 2 + math.sin(time % (2 * math.pi)) * 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.deepPurple;

    canvas.drawCircle(center, 8 + pulse, paint);

    final core = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.deepPurple;

    canvas.drawCircle(center, 4, core);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

  @override
  bool shouldRebuildSemantics(covariant CustomPainter oldDelegate) => false;
}