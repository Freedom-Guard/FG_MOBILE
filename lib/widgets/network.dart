import 'dart:async';
import 'dart:convert';
import 'package:Freedom_Guard/components/connect.dart';
import 'package:Freedom_Guard/components/global.dart';
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
  String? country;
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
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!isPinging) _fetchPingAndCountry();
    });
    _fetchPingAndCountry();
  }

  Future<void> _fetchPingAndCountry() async {
    setState(() => isPinging = true);
    int attempts = 0;
    const maxAttempts = 2;

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
        });
        return;
      } catch (_) {
        attempts++;
        if (attempts == maxAttempts) {
          setState(() {
            ping = null;
            country = 'Unknown';
            isPinging = false;
          });
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
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ValueListenableBuilder<V2RayStatus>(
        valueListenable: v2rayStatus,
        builder: (context, status, _) {
          return Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.75,
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Color(0xFF1C1C1C),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.circle,
                          color: Colors.greenAccent, size: 10),
                      const SizedBox(width: 6),
                      Text(
                        country ?? "Connecting...",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      _buildRefreshButton(),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
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
      width: (MediaQuery.of(context).size.width * 0.75 - 38) / 2,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
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
                    fontSize: 12,
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
      width: (MediaQuery.of(context).size.width * 0.75 - 38) / 2,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(type == "speed" ? Icons.speed : Icons.data_usage_sharp,
              color: Colors.blueAccent, size: 16),
          const SizedBox(width: 6),
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
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '↑ ${_formatSpeed(status.uploadSpeed)}',
                            style: const TextStyle(
                              color: Colors.orangeAccent,
                              fontSize: 11,
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
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '↑ ${_formatSize(status.upload)}',
                            style: TextStyle(
                              color: Colors.orangeAccent.withOpacity(0.8),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
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
    return GestureDetector(
      onTap: isPinging ? null : _fetchPingAndCountry,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isPinging ? Colors.grey[700] : Color(0xFF2A3A4A),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Icon(
          Icons.refresh,
          size: 16,
          color: Colors.white.withOpacity(isPinging ? 0.4 : 0.9),
        ),
      ),
    );
  }
}
