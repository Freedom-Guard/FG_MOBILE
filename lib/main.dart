import 'package:flutter/material.dart';
import 'pages/settings.dart';
import 'pages/servers.dart';
import 'components/connect.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/services.dart' show ByteData, rootBundle;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await copyCoreFolder();
  runApp(const FreedomGuardApp());
}

class FreedomGuardApp extends StatelessWidget {
  const FreedomGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('fa', 'IR'),
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: Colors.deepPurpleAccent,
          secondary: Colors.purpleAccent,
          surface: Colors.black,
        ),
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

  void toggleConnection() {
    CoreService.showHelpDialog(context);
    setState(() {
      isConnected = !isConnected;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      appBar: AppBar(
        title: const Text(
          "Freedom Guard",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.black,
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
              isConnected ? "متصل شد" : "متصل نیست",
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

Future<void> copyCoreFolder() async {
  try {
    Directory appDir = await getApplicationSupportDirectory();
    String coreDir = "${appDir.path}/core";

    List<String> files = ["vibe/vibe-core", "vibe/lib/libcore.so"];

    for (String file in files) {
      String assetPath = "assets/core/$file";
      String destPath = "$coreDir/$file";
      File destFile = File(destPath);

      await Directory(destFile.parent.path).create(recursive: true);

      if (!await destFile.exists()) {
        print("📥 در حال کپی کردن: $assetPath → $destPath");

        ByteData data = await rootBundle.load(
          assetPath,
        ); // ⬅ ممکنه اینجا ارور بده
        List<int> bytes = data.buffer.asUint8List();
        await destFile.writeAsBytes(bytes, flush: true);

        if (file.contains("-core")) {
          await Process.run('chmod', ['+x', destPath]);
        }
      }
    }
  } catch (e) {
    print("❌ خطا در کپی کردن فایل‌ها: $e");
  }
}
