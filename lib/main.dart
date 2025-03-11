import 'package:flutter/material.dart';

void main() {
  runApp(const FreedomGuardApp());
}

class FreedomGuardApp extends StatelessWidget {
  const FreedomGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: Locale('fa', 'IR'),
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark(
          primary: Colors.deepPurpleAccent,
          secondary: Colors.purpleAccent,
          surface: Colors.black,
        ),
      ),
      home: const FreedomGuardHome(),
    );
  }
}

class FreedomGuardHome extends StatefulWidget {
  const FreedomGuardHome({super.key});

  @override
  State<FreedomGuardHome> createState() => _FreedomGuardHomeState();
}

class _FreedomGuardHomeState extends State<FreedomGuardHome> {
  bool isConnected = false;
  bool isPressed = false;

  void toggleConnection() {
    setState(() {
      isConnected = !isConnected;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(54, 85, 59, 79),
      appBar: AppBar(
        title: const Text(
          "Freedom Guard",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: const Color.fromARGB(34, 8, 95, 69),
        foregroundColor: const Color.fromARGB(255, 255, 255, 255),
        centerTitle: true,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // تنظیمات را باز کن
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/images/menu_background.png"),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text("صفحه اصلی"),
              onTap: () {
                // رفتن به صفحه اصلی
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text("درباره ما"),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text("درباره ما"),
                      content: Text(
                        " گارد آزادی یک پروژه متن‌باز برای دسترسی آزاد به اینترنت است.",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text("بستن"),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("تنظیمات"),
              onTap: () {
                // رفتن به صفحه تنظیمات
              },
            ),
          ],
        ),
      ),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTapDown: (_) => setState(() => isPressed = true),
              onTapUp: (_) => setState(() => isPressed = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: isPressed ? 110 : 120,
                height: isPressed ? 110 : 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  gradient: LinearGradient(
                    colors:
                        isConnected
                            ? [Colors.greenAccent, Colors.green]
                            : [
                              Colors.deepPurpleAccent,
                              const Color.fromARGB(137, 5, 14, 153),
                            ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          isConnected
                              ? Colors.green.withOpacity(0.5)
                              : Colors.purple.withOpacity(0.5),
                      blurRadius: 2,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Material(
                  color: const Color.fromARGB(0, 26, 6, 6),
                  shape: const CircleBorder(),
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
            ),
            const SizedBox(height: 20),
            Text(
              isConnected ? "Connected" : "Not Connected",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black54,
        selectedItemColor: Colors.purpleAccent,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.cloud), label: "Servers"),
        ],
      ),
    );
  }
}
