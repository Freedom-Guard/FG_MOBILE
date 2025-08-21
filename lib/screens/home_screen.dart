import 'dart:async';
import 'dart:ui';

import 'package:Freedom_Guard/components/LOGLOG.dart';
import 'package:Freedom_Guard/components/f-link.dart';
import 'package:Freedom_Guard/components/global.dart';
import 'package:Freedom_Guard/components/services.dart';
import 'package:Freedom_Guard/widgets/CBar.dart';
import 'package:Freedom_Guard/widgets/nav.dart';
import 'package:Freedom_Guard/widgets/network.dart';
import 'package:Freedom_Guard/widgets/theme/theme.dart';
import 'package:Freedom_Guard/components/update.dart';
import 'package:Freedom_Guard/components/servers.dart';
import 'package:Freedom_Guard/components/settings.dart';
import 'package:Freedom_Guard/screens/servers.dart';
import 'package:Freedom_Guard/screens/settings.dart';
import 'package:Freedom_Guard/ui/animations/connect.dart';
import 'package:Freedom_Guard/widgets/fragment.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: _currentIndex == 1 // Show AppBar only for HomeContent
          ? PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight),
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: AppBar(
                    backgroundColor: Colors.black.withOpacity(0.0),
                    centerTitle: true,
                    leading: IconButton(
                      icon: const Icon(Icons.cable),
                      onPressed: () {
                        openXraySettings(context);
                      },
                    ),
                    actions: [
                      IconButton(
                        icon: Icon(Icons.grid_view_rounded),
                        onPressed: () {
                          showActionsMenu(context);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            )
          : null, // No AppBar for other pages
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent>
    with SingleTickerProviderStateMixin {
  bool isConnected = false;
  String backgroundPath = BackgroundService.getRandomBackground();
  bool isPressed = false;
  bool isConnecting = false;
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
      Timer.periodic(Duration(seconds: 30), (timer) async {
        final connected = await checker.checkVPN();
        if (mounted) {
          setState(() {
            isConnected = connected;
          });
        }
      });
      final connected = await checker.checkVPN();
      if (mounted) {
        setState(() {
          isConnected = connected;
        });
      }
      await checkForUpdate(context);
    });
  }

  @override
  void didUpdateWidget(HomeContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (isConnecting && !_animationController.isAnimating) {
      _animationController.repeat();
    } else if (!isConnecting && _animationController.isAnimating) {
      _animationController.stop();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> toggleConnection() async {
    final serverM = Provider.of<ServersM>(context, listen: false);
    final settings = Provider.of<SettingsApp>(context, listen: false);
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
        final isQuick = (await settings.getValue("fast_connect")).isNotEmpty &&
            bool.tryParse(await settings.getValue("fast_connect")) == true;
        if (isQuick &&
            ((await settings.getValue("config_backup")) != "") &&
            (selectedServer.split("#")[0].isEmpty ||
                selectedServer.split("#")[0].startsWith("http"))) {
          if ((await connect
                  .testConfig(await settings.getValue("config_backup"))) !=
              -1) {
            selectedServer = (await settings.getValue("config_backup"));
            LogOverlay.addLog("Conneting to QUICK mode...");
          }
        }
        if (selectedServer.split("#")[0].isEmpty) {
          LogOverlay.showLog("connecting to FL mode...");
          connStat =
              await connectFL().timeout(Duration(seconds: 15), onTimeout: () {
            LogOverlay.addLog("Connection to FL mode timed out.");
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
          LogOverlay.addLog(
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
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return Stack(
      children: [
        Container(),
        Container(
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
                  duration: const Duration(milliseconds: 200),
                  width: isPressed ? 105 : 120,
                  height: isPressed ? 105 : 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isConnected
                          ? [Colors.green.shade300, Colors.teal.shade700]
                          : isConnecting
                              ? [Colors.blue.shade300, Colors.cyan.shade600]
                              : themeNotifier.getDisconnectedGradient() ??
                                  [
                                    Colors.grey.shade800,
                                    Colors.blueGrey.shade900
                                  ],
                    ),
                    border: Border.all(
                      color: isConnected
                          ? Colors.green.shade200.withOpacity(0.9)
                          : isConnecting
                              ? Colors.cyan.shade200.withOpacity(0.9)
                              : Colors.grey.shade400.withOpacity(0.6),
                      width: isPressed ? 3.5 : 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isConnected
                            ? Colors.green.shade400.withOpacity(0.5)
                            : isConnecting
                                ? Colors.cyan.shade400.withOpacity(0.5)
                                : Colors.grey.shade600.withOpacity(0.3),
                        blurRadius: isPressed ? 18 : 12,
                        spreadRadius: isPressed ? 4 : 2,
                        offset: const Offset(0, 2),
                      ),
                      BoxShadow(
                        color: isConnected
                            ? Colors.teal.shade300.withOpacity(0.3)
                            : isConnecting
                                ? Colors.blue.shade300.withOpacity(0.3)
                                : Colors.black.withOpacity(0.15),
                        blurRadius: 10,
                        spreadRadius: 1,
                        offset: const Offset(0, 0),
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
                          opacity: isConnecting ? 0.6 : 0.0,
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOutCubic,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Colors.white.withOpacity(0.25),
                                  Colors.transparent,
                                ],
                                radius: 0.7,
                              ),
                            ),
                          ),
                        ),
                        if (isConnecting)
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Container(
                                width: 120,
                                height: 120,
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
                          scale: isPressed ? 0.95 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutBack,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: ScaleTransition(
                                  scale: animation.drive(
                                    Tween(begin: 0.85, end: 1.0).chain(
                                      CurveTween(curve: Curves.easeOutCubic),
                                    ),
                                  ),
                                  child: child,
                                ),
                              );
                            },
                            child: Tooltip(
                              message: isConnected ? 'قطع اتصال' : 'اتصال',
                              child: Icon(
                                isConnected ? Icons.vpn_key_off : Icons.vpn_key,
                                key: ValueKey(isConnected),
                                size: 40,
                                color: Colors.white.withOpacity(0.95),
                                shadows: [
                                  Shadow(
                                    color: isConnected
                                        ? Colors.teal.shade800.withOpacity(0.5)
                                        : Colors.grey.shade700.withOpacity(0.4),
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
              if (isConnected) NetworkStatusWidget(),
              Spacer(flex: 1),
            ],
          ),
        ),
      ],
    );
  }
}
