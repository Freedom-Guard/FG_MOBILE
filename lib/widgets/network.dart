import 'dart:async';
import 'package:Freedom_Guard/components/connect.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:vibe_core/flutter_v2ray.dart';

class NetworkStatusWidget extends StatefulWidget {
  const NetworkStatusWidget({Key? key}) : super(key: key);

  @override
  State<NetworkStatusWidget> createState() => _NetworkStatusWidgetState();
}

class _NetworkStatusWidgetState extends State<NetworkStatusWidget> {
  bool isPinging = false;
  int? ping;
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!isPinging) _fetchPing();
    });
  }

  Future<void> _fetchPing() async {
    setState(() => isPinging = true);
    final stopwatch = Stopwatch()..start();
    try {
      final response = await http
          .get(Uri.parse('https://www.google.com'))
          .timeout(const Duration(seconds: 5));
      stopwatch.stop();
      setState(() {
        ping =
            response.statusCode == 200 ? stopwatch.elapsedMilliseconds : null;
        isPinging = false;
      });
    } catch (_) {
      setState(() {
        ping = null;
        isPinging = false;
      });
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
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ValueListenableBuilder<V2RayStatus>(
        valueListenable: v2rayStatus,
        builder: (context, status, _) {
          return Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.circle,
                          color: Colors.greenAccent, size: 12),
                      const SizedBox(width: 8),
                      const Text(
                        'CONNECTED',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Spacer(),
                      _buildRefreshButton(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildTile('Ping', Icons.wifi,
                          ping == null ? '—' : '$ping ms', Colors.greenAccent),
                      _buildTile(
                          'Uptime',
                          Icons.timer,
                          _formatDuration(status.duration),
                          Colors.purpleAccent),
                      _buildNetworkTile(status, "speed"),
                      _buildNetworkTile(status, "network"),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTile(String label, IconData icon, String value, Color color) {
    return Container(
      width: (MediaQuery.of(context).size.width * 0.85 - 44) / 2,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
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

  Widget _buildNetworkTile(V2RayStatus status, String type) {
    return Container(
      width: (MediaQuery.of(context).size.width * 0.85 - 44) / 2,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(type == "speed" ? Icons.speed : Icons.data_usage_sharp,
              color: Colors.blueAccent, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  type == "speed" ? "Speed" : "Total",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    type == 'speed'
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '↓ ${_formatSpeed(status.downloadSpeed)}',
                                style: const TextStyle(
                                  color: Colors.blueAccent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '↑ ${_formatSpeed(status.uploadSpeed)}',
                                style: const TextStyle(
                                  color: Colors.orangeAccent,
                                  fontSize: 13,
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
                                  color: Colors.blueAccent.withOpacity(0.8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '↑ ${_formatSize(status.upload)}',
                                style: TextStyle(
                                  color: Colors.orangeAccent.withOpacity(0.8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
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
    return GestureDetector(
      onTap: isPinging ? null : _fetchPing,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isPinging ? Colors.grey[800] : const Color(0xFF2C3E50),
        ),
        child: Icon(
          Icons.refresh,
          size: 20,
          color: Colors.white.withOpacity(isPinging ? 0.5 : 1),
        ),
      ),
    );
  }
}
