import 'dart:async';
import 'dart:io';
import 'package:Freedom_Guard/ui/widgets/fragment.dart';
import 'package:Freedom_Guard/utils/status_texts.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import 'package:Freedom_Guard/components/connectMode.dart';
import 'package:Freedom_Guard/ui/widgets/background_picker_dialog.dart';
import 'package:Freedom_Guard/utils/LOGLOG.dart';
import 'package:Freedom_Guard/components/f-link.dart';
import 'package:Freedom_Guard/core/global.dart';
import 'package:Freedom_Guard/services/services.dart';
import 'package:Freedom_Guard/ui/widgets/CBar.dart';
import 'package:Freedom_Guard/ui/widgets/nav.dart';
import 'package:Freedom_Guard/ui/widgets/network.dart';
import 'package:Freedom_Guard/services/update.dart';
import 'package:Freedom_Guard/components/servers.dart';
import 'package:Freedom_Guard/components/settings.dart';
import 'package:Freedom_Guard/ui/screens/servers_screen.dart';
import 'package:Freedom_Guard/ui/screens/settings_screen.dart';

class MainScreen extends StatefulWidget {
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 1;

  final List<Widget> _pages = [
    SettingsPage(),
    HomeContent(),
    ServersPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080E17),
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: _currentIndex == 1
          ? PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight + 20),
              child: Container(
                padding: const EdgeInsets.only(top: 10),
                child: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  centerTitle: true,
                  title: const Text(
                    "FREEDOM GUARD",
                    style: TextStyle(
                      letterSpacing: 2,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      color: Colors.white,
                    ),
                  ),
                  leading: _buildActionBtn(
                      Icons.cable, () => openXraySettings(context)),
                  actions: [
                    _buildActionBtn(Icons.grid_view_rounded,
                        () => showActionsMenu(context)),
                  ],
                ),
              ),
            )
          : null,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
      ),
    );
  }

  Widget _buildActionBtn(IconData icon, VoidCallback press) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 20),
        onPressed: press,
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent>
    with TickerProviderStateMixin {
  bool isConnected = false;
  bool isConnecting = false;
  late AnimationController _rippleController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 4000));
    _pulseController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1500),
        lowerBound: 0.9,
        upperBound: 1.0)
      ..repeat(reverse: true);

    Future.microtask(() async {
      final bgNotifier =
          Provider.of<BackgroundNotifier>(context, listen: false);
      String sImg = await SettingsApp().getValue("selectedIMG");
      String sCol = await SettingsApp().getValue("selectedColor");

      if (sImg != "")
        bgNotifier.setBackground(sImg);
      else if (sCol != "") bgNotifier.setBackground(sCol);

      Timer.periodic(const Duration(seconds: 10), (t) async {
        final check = await checker.checkVPN();
        if (mounted && check != isConnected) {
          setState(() {
            isConnected = check;
            if (isConnected)
              _rippleController.repeat();
            else
              _rippleController.stop();
          });
        }
      });

      final initialCheck = await checker.checkVPN();
      if (mounted) {
        setState(() {
          isConnected = initialCheck;
          if (isConnected) _rippleController.repeat();
        });
      }
      await checkForUpdate(context);
    });
  }

  @override
  void dispose() {
    _rippleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceAll("#", "");
    if (hex.length == 6) {
      hex = "FF$hex";
    }
    return Color(int.parse(hex, radix: 16));
  }

  Future<void> toggleConnection() async {
    final serverM = Provider.of<ServersM>(context, listen: false);
    final settings = Provider.of<SettingsApp>(context, listen: false);

    if (isConnecting) {
      await connect.disConnect();
      setState(() {
        isConnecting = false;
        isConnected = false;
        _rippleController.stop();
      });
      return;
    }

    LogOverlay.clearLogs();
    setState(() => isConnecting = true);

    if (isConnected) {
      setState(() {
        isConnected = false;
        _rippleController.stop();
      });
      await connect.disConnect();
    } else {
      try {
        _rippleController.repeat();
        var selected = (await serverM.getSelectedServer() as String).trim();
        final isQuick = (await settings.getValue("fast_connect")) == "true";

        if (isQuick && (await settings.getValue("config_backup") != "")) {
          selected = await settings.getValue("config_backup");
        }

        bool connStat = false;
        if (selected.startsWith("mode=auto") || selected.split("#")[0] == "")
          connStat = await connectAutoMode(context);
        else if (selected.startsWith("mode=f-link"))
          connStat = await connectFlMode(context);
        else if (selected.startsWith("mode=repo"))
          connStat = await connectRepoMode(context);
        else if (selected.startsWith("mode=auto-my"))
          connStat = await connectAutoMy(context);
        else {
          if (selected.startsWith("http") ||
              selected.startsWith("freedom-guard")) {
            connStat = await connect.ConnectSub(
                selected.replaceAll("freedom-guard://", ""),
                selected.startsWith("freedom-guard") ? "fgAuto" : "sub");
          } else {
            connStat = await connect.ConnectVibe(selected, {});
          }
        }

        setState(() => isConnected = connStat);
        if (connStat) {
          LogOverlay.showLog("Connected Successfully", type: "success");
          FirebaseAnalytics.instance.logEvent(
            name: "connected",
            parameters: {
              "time": DateTime.now().toString(),
              "core": await settings.getValue("core_vpn"),
              "isp": await settings.getValue("user_isp"),
            },
          );
          if ((await settings.getValue("f_link")) == "true") {
            donateCONFIG(selected);
          }
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
          _rippleController.stop();
        }
      } catch (e) {
        setState(() => isConnected = false);
        _rippleController.stop();
      }
    }
    setState(() => isConnecting = false);
  }

  @override
  Widget build(BuildContext context) {
    final bgValue = context.watch<BackgroundNotifier>().background;

    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: bgValue.isEmpty
              ? const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.2),
                    radius: 1.2,
                    colors: [Color(0xFF1A2A44), Color(0xFF080E17)],
                  ),
                )
              : bgValue.startsWith("#")
                  ? BoxDecoration(
                      color: _hexToColor(bgValue),
                    )
                  : BoxDecoration(
                      image: DecorationImage(
                        image: FileImage(File(bgValue)),
                        fit: BoxFit.cover,
                      ),
                    ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Spacer(flex: (!isConnected ? 3 : 1)),
            Stack(
              alignment: Alignment.center,
              children: [
                if (isConnected || isConnecting)
                  AnimatedBuilder(
                    animation: _rippleController,
                    builder: (_, __) => CustomPaint(
                      painter: ModernRipplePainter(
                          _rippleController.value,
                          isConnected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.white24),
                      size: const Size(180, 180),
                    ),
                  ),
                ScaleTransition(
                  scale: _pulseController,
                  child: GestureDetector(
                    onTap: toggleConnection,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isConnected
                            ? const Color(0xFF00D1FF).withOpacity(0.1)
                            : Colors.transparent,
                        border: Border.all(
                          color: isConnected
                              ? const Color(0xFF00D1FF)
                              : Colors.white.withOpacity(0.2),
                          width: 3,
                        ),
                        boxShadow: isConnected
                            ? [
                                BoxShadow(
                                    color: const Color(0xFF00D1FF)
                                        .withOpacity(0.3),
                                    blurRadius: 40,
                                    spreadRadius: 5),
                              ]
                            : [],
                      ),
                      child: isConnecting
                          ? Lottie.asset(
                              'assets/animations/connecting.json',
                              width: 80,
                              height: 80,
                            )
                          : isConnected
                          ? Lottie.asset(
                                'assets/animations/connected.json',
                                width: 80,
                                height: 80,
                              )
                              : Icon(
                                  Icons.shield_outlined,
                                  size: 60,
                                  color: isConnected
                                      ? const Color(0xFF00D1FF)
                                      : Colors.white,
                                ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              isConnected
                  ? "CONNECTED"
                  : (isConnecting ? "CONNECTING..." : "READY"),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3),
            ),
            const SizedBox(height: 10),
            ValueListenableBuilder<String>(
              valueListenable: GlobalFGB.connStatText,
              builder: (context, value, _) {
                final displayText = isConnected
                    ? getStatusText("connected")
                    : (isConnecting ? value : getStatusText("disconnected"));

                return Text(
                  displayText,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.4), fontSize: 14),
                );
              },
            ),
            if (!isConnected)
              const Spacer(
                flex: 3,
              ),
            if (isConnected) NetworkStatusWidget(),
            const Spacer(flex: 1),
          ],
        ),
      ],
    );
  }
}

class ModernRipplePainter extends CustomPainter {
  final double progress;
  final Color color;
  ModernRipplePainter(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    for (int i = 0; i < 3; i++) {
      final val = (progress + (i * 0.33)) % 1.0;
      final paint = Paint()
        ..color = color.withOpacity((1 - val).clamp(0, 1) * 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(center, 70 + (val * 100), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}
