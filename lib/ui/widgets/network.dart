import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:vibe_core/vibe_core.dart';
import 'package:Freedom_Guard/components/settings.dart';
import 'package:Freedom_Guard/services/config.dart';
import 'package:Freedom_Guard/services/share.dart';
import 'package:Freedom_Guard/ui/screens/servers_list_screen.dart';
import 'package:Freedom_Guard/components/connect.dart';

class NetworkStatusWidget extends StatefulWidget {
  const NetworkStatusWidget({Key? key}) : super(key: key);

  @override
  State<NetworkStatusWidget> createState() => _NetworkStatusWidgetState();
}

class _NetworkStatusWidgetState extends State<NetworkStatusWidget>
    with TickerProviderStateMixin {
  bool isPinging = false;
  int? ping;
  String? country, ipAddress;
  String serverName = "Freedom Guard";
  String protocol = "XRAY";
  late AnimationController _refreshController;
  late AnimationController _entranceController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));

    _entranceController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.2, 0), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _entranceController, curve: Curves.easeOutQuart));

    _entranceController.forward();
    _fetchPingAndCountry();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _fetchPingAndCountry() async {
    if (!mounted || isPinging) return;
    setState(() => isPinging = true);
    _refreshController.repeat();

    try {
      final String? config = await SettingsApp().getValue("config_backup");
      if (config != null && config.isNotEmpty) {
        serverName = getNameByConfig(config);
        protocol = config.split("#")[0].split("://").first.toUpperCase();
      }

      int? delay;
      const testUrl = 'https://www.google.com/generate_204';

      try {
        final uri = Uri.parse(testUrl);
        final stopwatch = Stopwatch()..start();

        await http.head(uri).timeout(const Duration(seconds: 5));

        stopwatch.stop();
        delay = stopwatch.elapsedMilliseconds;
      } catch (_) {
        delay = null;
      }

      final res = await http
          .get(Uri.parse('http://ip-api.com/json'))
          .timeout(const Duration(seconds: 6));

      if (mounted && res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          ping = delay;
          country = data['country'];
          ipAddress = data['query'];
        });
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => isPinging = false);
        _refreshController.reset();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _entranceController,
        child: ValueListenableBuilder<V2RayStatus>(
          valueListenable: v2rayStatus,
          builder: (context, status, _) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.08),
                    Colors.white.withOpacity(0.03)
                  ],
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildAvatar(),
                      const SizedBox(width: 14),
                      Expanded(child: _buildLocationInfo()),
                      _buildProtocolBadge(),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildStatsRow(status),
                  const SizedBox(height: 20),
                  _buildBottomBar(context),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.language_rounded,
          size: 20, color: Colors.blueAccent),
    );
  }

  Widget _buildLocationInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(country ?? "Connecting...",
            style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3)),
        const SizedBox(height: 2),
        Text(ipAddress ?? "0.0.0.0",
            style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 11,
                fontFamily: 'monospace')),
      ],
    );
  }

  Widget _buildProtocolBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
      ),
      child: Text(protocol,
          style: const TextStyle(
              color: Colors.blueAccent,
              fontSize: 10,
              fontWeight: FontWeight.w800)),
    );
  }

  Widget _buildStatsRow(V2RayStatus status) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _statBox("${ping ?? '--'}ms", "LATENCY", Icons.sensors_rounded,
            Colors.orangeAccent),
        _statBox(_formatSize(status.upload), "UPLOAD",
            Icons.expand_less_rounded, Colors.greenAccent),
        _statBox(_formatSize(status.download), "DOWNLOAD",
            Icons.expand_more_rounded, Colors.lightBlueAccent),
      ],
    );
  }

  Widget _statBox(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color.withOpacity(0.8)),
        const SizedBox(height: 6),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold)),
        Text(label,
            style: TextStyle(
                color: Colors.white.withOpacity(0.2),
                fontSize: 8,
                fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ServerListPage())),
            borderRadius: BorderRadius.circular(15),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  const Icon(Icons.dns_outlined,
                      size: 16, color: Colors.white38),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(serverName,
                        style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      size: 10, color: Colors.white24),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _circleBtn(Icons.share_rounded, () => shareConfig(context)),
        const SizedBox(width: 10),
        _circleBtn(Icons.refresh_rounded, _fetchPingAndCountry, isRotate: true),
      ],
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback action,
      {bool isRotate = false}) {
    return GestureDetector(
      onTap: action,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: isRotate
            ? RotationTransition(
                turns: _refreshController,
                child: Icon(icon, size: 18, color: Colors.white70))
            : Icon(icon, size: 18, color: Colors.white70),
      ),
    );
  }

  String _formatSize(int? bytes) {
    if (bytes == null || bytes == 0) return '0.0 MB';
    double mb = bytes / (1024 * 1024);
    return mb > 1000
        ? '${(mb / 1024).toStringAsFixed(1)} GB'
        : '${mb.toStringAsFixed(1)} MB';
  }
}
