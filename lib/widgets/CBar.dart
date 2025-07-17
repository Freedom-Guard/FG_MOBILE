import 'dart:ui';
import 'package:Freedom_Guard/screens/browser.dart';
import 'package:Freedom_Guard/screens/cfg.dart';
import 'package:Freedom_Guard/screens/f-link.dart';
import 'package:Freedom_Guard/screens/logs.dart';
import 'package:Freedom_Guard/screens/speedtest.dart';
import 'package:Freedom_Guard/widgets/dns.dart';
import 'package:flutter/material.dart';

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
      duration: const Duration(milliseconds: 350),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
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
    return GestureDetector(
      onTap: _closeMenu,
      child: Material(
        color: Colors.black.withOpacity(0.4),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            alignment: Alignment.topRight,
            child: Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _closeMenu,
                    child: Container(color: Colors.transparent),
                  ),
                ),
                Positioned(
                  top: kToolbarHeight + 10,
                  right: 10,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        width: 250,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.center,
                          children: [
                            _buildMenuButton(context, Icons.dns, "DNS",
                                Colors.deepPurpleAccent, () {
                              showDnsSelectionPopup(context);
                              _closeMenu();
                            }),
                            _buildMenuButton(context, Icons.rocket_launch,
                                "CFG", Colors.amberAccent, () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => CFGPage()));
                              _closeMenu();
                            }),
                            _buildMenuButton(context, Icons.volunteer_activism,
                                "Donate", Colors.redAccent, () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          PremiumDonateConfigPage()));
                              _closeMenu();
                            }),
                            _buildMenuButton(context, Icons.public, "Browser",
                                Colors.blueAccent, () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => FreedomBrowser()));
                              _closeMenu();
                            }),
                            _buildMenuButton(context, Icons.network_check,
                                "Speed Test", Colors.greenAccent, () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => SpeedTestPage()));
                              _closeMenu();
                            }),
                            _buildMenuButton(context, Icons.bug_report, "Logs",
                                Colors.orangeAccent, () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => LogPage()));
                              _closeMenu();
                            }),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context, IconData icon, String label,
      Color color, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.2),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
