import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:Freedom_Guard/components/settings.dart';
import 'package:Freedom_Guard/services/config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:vibe_core/flutter_v2ray.dart';
import 'package:Freedom_Guard/components/connect.dart';
import 'package:Freedom_Guard/components/global.dart';

class NetworkStatusWidget extends StatefulWidget {
  const NetworkStatusWidget({Key? key}) : super(key: key);

  @override
  State<NetworkStatusWidget> createState() => _NetworkStatusWidgetState();
}

class _NetworkStatusWidgetState extends State<NetworkStatusWidget>
    with TickerProviderStateMixin {
  bool isPinging = false;
  int? ping;
  String? country;
  Timer? _autoRefreshTimer;
  String serverName = "FG Server";
  late AnimationController _refreshController;

  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _startAutoRefresh() async {
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!isPinging) _fetchPingAndCountry();
    });
    await Future.delayed(Duration(seconds: 3));
    _fetchPingAndCountry();
  }

  Future<void> _fetchPingAndCountry() async {
    setState(() => isPinging = true);
    _refreshController.repeat();
    int attempts = 0;
    const maxAttempts = 2;
    String serverNameTemp =
        getNameByConfig(await Settings().getValue("config_backup"));
    while (attempts < maxAttempts) {
      try {
        var pingConnected = await connect.getConnectedDelay();
        final countryResponse = await http
            .get(Uri.parse('http://ip-api.com/json'))
            .timeout(const Duration(seconds: 5));
        final countryData = jsonDecode(countryResponse.body);

        setState(() {
          ping = pingConnected >= 0 ? pingConnected : null;
          country = countryData['country'] ?? 'Unknown';
          isPinging = false;
          serverName = serverNameTemp;
        });
        _refreshController.reset();
        return;
      } catch (_) {
        attempts++;
        if (attempts == maxAttempts) {
          if (!mounted) return;
          setState(() {
            ping = null;
            country = 'Unknown';
            isPinging = false;
            serverName = serverNameTemp;
          });
          _refreshController.reset();
        }
      }
    }
  }

  String _formatSpeed(int? speed) {
    if (speed == null) return '—';
    final mbps = speed / 1000000;
    return mbps >= 1
        ? '${mbps.toStringAsFixed(1)} Mbps'
        : '${(speed / 1000).toStringAsFixed(0)} Kbps';
  }

  String _formatSize(int? bytes) {
    if (bytes == null) return '—';
    final gb = bytes / (1024 * 1024 * 1024);
    final mb = bytes / (1024 * 1024);
    return gb >= 1
        ? '${gb.toStringAsFixed(1)} GB'
        : '${mb.toStringAsFixed(1)} MB';
  }

  String _formatDuration(String? duration) => duration ?? '—';

  @override
  Widget build(BuildContext context) {
    final double containerWidth = MediaQuery.of(context).size.width * 0.85;
    final double tileWidth = (containerWidth - 20) / 2;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: ValueListenableBuilder<V2RayStatus>(
        valueListenable: v2rayStatus,
        builder: (context, status, _) {
          return Center(
            child: Container(
              width: containerWidth,
              margin: const EdgeInsets.symmetric(vertical: 14),
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.05),
                          Colors.white.withOpacity(0.02)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.circle,
                                      size: 10, color: Colors.greenAccent),
                                  const SizedBox(width: 6),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        country ?? "Connecting...",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        serverName,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w400,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  _buildRefreshButton(),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 10,
                                alignment: WrapAlignment.center,
                                runSpacing: 10,
                                children: [
                                  _animatedTile(
                                      _buildTile(
                                          'Ping',
                                          Icons.wifi,
                                          ping == null ? '—' : '$ping ms',
                                          Colors.greenAccent,
                                          tileWidth),
                                      0),
                                  _animatedTile(
                                      _buildTile(
                                          'Uptime',
                                          Icons.timer,
                                          _formatDuration(status.duration),
                                          Colors.purpleAccent,
                                          tileWidth),
                                      1),
                                  _animatedTile(
                                      _buildNetworkTile(
                                          status, "speed", tileWidth),
                                      2),
                                  _animatedTile(
                                      _buildNetworkTile(
                                          status, "network", tileWidth),
                                      3),
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
        },
      ),
    );
  }

  Widget _buildTile(
      String label, IconData icon, String value, Color color, double width) {
    return Container(
      width: (MediaQuery.of(context).size.width * 0.75 - 10) / 2,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkTile(V2RayStatus status, String type, double width) {
    return Container(
      width: (MediaQuery.of(context).size.width * 0.75 - 10) / 2,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            type == "speed" ? Icons.speed : Icons.data_usage,
            color: Colors.blueAccent,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type == "speed" ? "Speed" : "Total",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                type == 'speed'
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '↓ ${_formatSpeed(status.downloadSpeed)}',
                            style: const TextStyle(
                              color: Colors.blueAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '↑ ${_formatSpeed(status.uploadSpeed)}',
                            style: const TextStyle(
                              color: Colors.orangeAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '↓ ${_formatSize(status.download)}',
                            style: TextStyle(
                              color: Colors.blueAccent.withOpacity(0.85),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '↑ ${_formatSize(status.upload)}',
                            style: TextStyle(
                              color: Colors.orangeAccent.withOpacity(0.85),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefreshButton() {
    return AnimatedBuilder(
      animation: _refreshController,
      builder: (context, child) {
        return Transform.rotate(
          angle: _refreshController.value * 6.3,
          child: GestureDetector(
            onTap: isPinging ? null : _fetchPingAndCountry,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: const Icon(Icons.refresh, size: 16, color: Colors.white),
            ),
          ),
        );
      },
    );
  }

  Widget _animatedTile(Widget child, int index) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 500 + index * 100),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, value, _) {
        return Opacity(
          opacity: value as double,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - (value))),
            child: child,
          ),
        );
      },
    );
  }
}
