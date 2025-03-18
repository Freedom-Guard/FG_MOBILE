// Suggested code may be subject to a license. Learn more: ~LicenseLog:557228138.
import 'package:Freedom_Guard/components/connect.dart';
import 'package:Freedom_Guard/components/servers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/settings.dart';
import 'pages/servers.dart';

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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF0099FF),
          secondary: Color(0xFF8A2BE2),
          surface: Color(0xFF1A1B26), // پس‌زمینه اصلی
          error: Color(0xFFFF1744), // قرمز نئونی
          onPrimary: Colors.black, // متن روی دکمه‌های آبی
          onSecondary: Colors.white, // متن روی دکمه‌های بنفش
          onSurface: Color(0xFFB0BEC5), // متن و آیکون‌ها
          onError: Colors.white, // متن روی دکمه‌های قرمز
        ),
        scaffoldBackgroundColor: const Color(0xFF121212), // پس‌زمینه کل صفحه
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
  Connect connect = new Connect();
  String userConfig = '';
  Future<void> toggleConnection() async {
    if (userConfig.isEmpty) {
      final result = await showDialog<String>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Enter Config'),
              content: TextField(
                onChanged: (value) {
                  userConfig = value;
                },
                decoration: const InputDecoration(
                  hintText: "Paste config here",
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, userConfig),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
      if (result == null || result.isEmpty) return;
    }
    connect.ConnectVibe(userConfig, "--tun");
    setState(() {
      isConnected = !isConnected;
    });
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
                  border: Border.all(color: Colors.white, width: 4),
                  gradient: LinearGradient(
                    colors:
                        isConnected
                            ? [Colors.greenAccent, Colors.green]
                            : [Colors.deepPurpleAccent, Colors.indigo],
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
              isConnected ? "Connected" : "Not connected",
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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HomePage()),
              );
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
