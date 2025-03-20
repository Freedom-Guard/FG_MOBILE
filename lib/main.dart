// Suggested code may be subject to a license. Learn more: ~LicenseLog:557228138.
import 'package:Freedom_Guard/components/connect.dart';
import 'package:Freedom_Guard/components/servers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/settings.dart';
import 'pages/servers.dart';
import 'components/LOGLOG.dart';

Future<void> main() async {
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (context) => ServersM())],
      child: FreedomGuardApp(),
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
  String userConfig = '';
  Future<void> toggleConnection() async {
    setState(() {
      isConnecting = true;
      isPressed = true;
    });
    if (isConnected) {
      await connect.disConnect();
      setState(() {
        isConnected = false;
        isPressed = false;
      });
    } else {
      try {
        await connect.ConnectAuto(
          "https://raw.githubusercontent.com/Freedom-Guard/Freedom-Guard/main/config/index.json",
          60000,
        );
        setState(() {
          isConnected = true;
          isPressed = false;
        });
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
    isPressed = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "Freedom Guard",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 4,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTapDown: (_) => setState(() => isPressed = true),
              onTapUp: (_) => setState(() => isPressed = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isPressed ? 110 : 120,
                height: isPressed ? 110 : 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Color.fromARGB(100, 44, 21, 46),
                    width: 2,
                  ),
                  gradient: LinearGradient(
                    colors:
                        isConnected
                            ? [Colors.greenAccent, Colors.green]
                            : [Color(0xFF252836), Color(0x802f3542)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          isConnected
                              ? Colors.green.withOpacity(0.5)
                              : Colors.purple.withOpacity(0.5),
                      blurRadius: 10,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: toggleConnection,
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder:
                          (child, animation) =>
                              ScaleTransition(scale: animation, child: child),
                      child: Icon(
                        isConnected
                            ? Icons.lock_outline
                            : Icons.power_settings_new,
                        key: ValueKey<bool>(isConnected),
                        size: 60,
                        color: Colors.white,
                      ),
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
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.black87,
          boxShadow: [
            BoxShadow(color: Colors.black54, blurRadius: 10, spreadRadius: 2),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          selectedItemColor: Colors.transparent,
          unselectedItemColor: Colors.transparent,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          currentIndex: 1,
          items: [
            _buildNavItem(Icons.settings, "تنظیمات", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage()),
              );
            }),
            _buildNavItem(Icons.home_filled, "خانه", () {
              LogOverlay.showLog("message");
            }),
            _buildNavItem(Icons.cloud_sync, "سرور ها", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ServersPage()),
              );
            }),
          ],
        ),
      ),
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
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.transparent, width: 2),
          ),
          child: Icon(icon, size: 28, color: Colors.grey.shade400),
        ),
      ),
      activeIcon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.purpleAccent, width: 2),
        ),
        child: Icon(icon, size: 28, color: Colors.purpleAccent),
      ),
      label: label,
    );
  }
}
