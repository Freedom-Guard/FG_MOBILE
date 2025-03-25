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
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/LOGPAGE.dart';
import 'components/LOGLOG.dart';
import 'widgets/PingWidget.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
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
      Timer.periodic(Duration(seconds: 5), (timer) {
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
        if (selectedServer.split("#")[0] == "") {
          LogOverlay.showLog(
            "connecting to auto mode",
            backgroundColor: Colors.blueAccent,
          );
          connStat = await connect.ConnectAuto(
            "https://raw.githubusercontent.com/Freedom-Guard/Freedom-Guard/refs/heads/main/config/index.json",
            110000,
          ).timeout(
            Duration(
              milliseconds:
                  int.tryParse(
                    await settings.getValue("timeout_auto").toString() == ""
                        ? "110000"
                        : await settings.getValue("timeout_auto").toString(),
                  ) ??
                  110000,
            ),
            onTimeout: () {
              LogOverlay.showLog("Connection to Auto mode timed out.");
              return false;
            },
          );
        } else {
          LogOverlay.showLog(
            "connecting to config:\n" + selectedServer.split("#")[0],
            backgroundColor: Colors.blueAccent,
          );
          if (selectedServer.startsWith("http")) {
            var bestConfig = await connect.getBestConfigFromSub(
              selectedServer.split("#")[0],
            );
            if (bestConfig != null) {
              connStat = await connect.ConnectVibe(bestConfig, "args");
            }
          } else if (selectedServer.startsWith("wireguard")) {
            connStat = await connect.ConnectWarp(selectedServer, []);
          } else if (selectedServer.startsWith("wire:::")) {
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

          if ((await settings.getValue("f_link").toString()) == "true")
               donateCONFIG(selectedServer.split("#")[0]);
          
          LogOverlay.showLog(
            "connected to " + await settings.getValue("core_vpn") + " mode",
            backgroundColor: Colors.greenAccent,
          );
        } else {
          FirebaseAnalytics.instance.logEvent(
            name: "not_connected",
            parameters: {
              "time": DateTime.now().toString(),
              "core": await settings.getValue("core_vpn"),
              "isp": await settings.getValue("user_isp"),
            },
          );
          LogOverlay.showLog(
            "not connected to " + await settings.getValue("core_vpn") + " mode",
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
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  backgroundColor: Colors.black.withOpacity(0.3),
                  elevation: 0,
                  centerTitle: true,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.bug_report_sharp),
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
                    duration: const Duration(milliseconds: 200),
                    width: isPressed ? 115 : 130,
                    height: isPressed ? 115 : 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors:
                            isConnected
                                ? [
                                  Colors.greenAccent.shade400,
                                  Colors.green.shade800,
                                ]
                                : isConnecting
                                ? [Colors.blue.shade400, Colors.blue.shade800]
                                : [
                                  const Color(0xFF2A2D3E),
                                  const Color(0xFF1A1B26),
                                ],
                        center: Alignment.center,
                        radius: isPressed ? 1.0 : 0.9,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              isConnected
                                  ? Colors.green.shade700.withOpacity(0.4)
                                  : isConnecting
                                  ? Colors.blue.shade700.withOpacity(0.1)
                                  : Colors.purple.shade700.withOpacity(0.1),
                          blurRadius: isPressed ? 20 : 15,
                          spreadRadius: isPressed ? 5 : 3,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: toggleConnection,
                      child: Center(
                        child: TweenAnimationBuilder(
                          tween: Tween<double>(
                            begin: 1.0,
                            end: isPressed ? 0.8 : 1.0,
                          ),
                          duration: const Duration(milliseconds: 200),
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Icon(
                                isConnected
                                    ? Icons.lock
                                    : Icons.power_settings_new,
                                size: 70,
                                color: Colors.white.withOpacity(
                                  isConnecting ? 0.7 : 1.0,
                                ),
                                shadows: [
                                  Shadow(
                                    color:
                                        isConnected
                                            ? Colors.green.shade900.withOpacity(
                                              0.5,
                                            )
                                            : isConnecting
                                            ? Colors.blue.shade900.withOpacity(
                                              0.5,
                                            )
                                            : Colors.purple.shade900
                                                .withOpacity(0.4),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
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
