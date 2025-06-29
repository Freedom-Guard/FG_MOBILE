import 'dart:ui';
import 'package:Freedom_Guard/components/local.dart';
import 'package:Freedom_Guard/screens/logs.dart';
import 'package:Freedom_Guard/screens/servers.dart';
import 'package:Freedom_Guard/screens/settings.dart';
import 'package:Freedom_Guard/screens/speedtest.dart';
import 'package:flutter/material.dart';

class CBar extends StatelessWidget {
  final bool isConnected;

  const CBar({Key? key, required this.isConnected}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        opacity: isConnected ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Visibility(
          visible: isConnected,
          child: ClipRRect(
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(16)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C2D).withOpacity(0.8),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      icon: Icons.speed,
                      tooltip: tr("speed_test"),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => SpeedTestPage()),
                      ),
                    ),
                    _buildActionButton(
                      icon: Icons.vpn_key,
                      tooltip: tr("change_server"),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ServersPage()),
                      ),
                    ),
                    _buildActionButton(
                      icon: Icons.settings,
                      tooltip: tr("settings"),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SettingsPage()),
                      ),
                    ),
                    _buildActionButton(
                      icon: Icons.bug_report,
                      tooltip: tr("logs"),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LogPage()),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF9A66FF).withOpacity(0.3),
                  const Color(0xFF00C2FF).withOpacity(0.3),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 24,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ),
      ),
    );
  }
}
