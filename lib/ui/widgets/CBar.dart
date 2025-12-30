import 'dart:ui';
import 'package:Freedom_Guard/ui/widgets/feedback.dart';
import 'package:flutter/material.dart';
import 'package:Freedom_Guard/ui/screens/browser.dart';
import 'package:Freedom_Guard/ui/screens/cfg_screen.dart';
import 'package:Freedom_Guard/ui/screens/f-link_screen.dart';
import 'package:Freedom_Guard/ui/screens/host_checker.dart';
import 'package:Freedom_Guard/ui/screens/logs_screen.dart';
import 'package:Freedom_Guard/ui/screens/notif_screen.dart';
import 'package:Freedom_Guard/ui/screens/dns_screen.dart';
import 'package:Freedom_Guard/ui/screens/redirect_manager_screen.dart';
import 'package:Freedom_Guard/ui/screens/speedtest_screen.dart';
import 'package:Freedom_Guard/ui/widgets/dns.dart';
import 'package:Freedom_Guard/core/local.dart';

void showActionsMenu(BuildContext context) {
  OverlayEntry? overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) => ActionsMenu(
      onClose: () {
        overlayEntry?.remove();
      },
    ),
  );

  Overlay.of(context).insert(overlayEntry);
}

class ActionsMenu extends StatefulWidget {
  final VoidCallback onClose;

  const ActionsMenu({required this.onClose});

  @override
  State<ActionsMenu> createState() => _ActionsMenuState();
}

class _ActionsMenuState extends State<ActionsMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _closeMenu() {
    _controller.reverse().then((_) => widget.onClose());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: _closeMenu,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            FadeTransition(
              opacity: _fadeAnimation,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(color: Colors.black.withOpacity(0.5)),
              ),
            ),
            Center(
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.85,
                    constraints: const BoxConstraints(maxWidth: 400),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 40,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "Menu",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 24),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 3,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.85,
                          children: [
                            _buildItem(
                                context,
                                Icons.dns_rounded,
                                "DNS",
                                Colors.blueAccent,
                                () => showDnsSelectionPopup(context)),
                            _buildItem(
                                context,
                                Icons.feedback,
                                "Feedback",
                                Colors.white,
                                () => showFeedbackDialog(context)),
                            _buildItem(
                                context,
                                Icons.scanner_rounded,
                                tr("Dns Scanner"),
                                Colors.greenAccent,
                                () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (c) => DnsToolsPage()))),
                            _buildItem(
                                context,
                                Icons.notifications_active,
                                tr("notifications"),
                                Colors.orangeAccent,
                                () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (c) => NotificationsPage()))),
                            _buildItem(
                                context,
                                Icons.rocket_launch,
                                "CFG",
                                Colors.purpleAccent,
                                () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (c) => CFGPage()))),
                            _buildItem(
                                context,
                                Icons.favorite,
                                tr("donate"),
                                Colors.redAccent,
                                () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (c) =>
                                            PremiumDonateConfigPage()))),
                            _buildItem(
                                context,
                                Icons.language,
                                tr("browser"),
                                Colors.cyanAccent,
                                () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (c) => FreedomBrowser()))),
                            _buildItem(
                                context,
                                Icons.speed,
                                tr("speed-test"),
                                Colors.greenAccent,
                                () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (c) => SpeedTestPage()))),
                            _buildItem(
                                context,
                                Icons.terminal,
                                tr("logs"),
                                Colors.amberAccent,
                                () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (c) => LogPage()))),
                            _buildItem(
                                context,
                                Icons.security,
                                "Host",
                                Colors.tealAccent,
                                () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (c) => HostCheckerScreen()))),
                            _buildItem(
                                context,
                                Icons.alt_route,
                                "Redirect",
                                Colors.indigoAccent,
                                () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (c) =>
                                            RedirectManagerPage()))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, IconData icon, String label,
      Color color, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        _closeMenu();
        onTap();
      },
      borderRadius: BorderRadius.circular(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.4), width: 1),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
