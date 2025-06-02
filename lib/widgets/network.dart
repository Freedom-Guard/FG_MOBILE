import 'dart:async';
import 'package:Freedom_Guard/components/connect.dart';
import 'package:flutter/material.dart';
import 'package:flutter_v2ray/flutter_v2ray.dart';
import 'package:http/http.dart' as http;

class NetworkStatusWidget extends StatefulWidget {
  const NetworkStatusWidget({Key? key}) : super(key: key);

  @override
  _NetworkStatusWidgetState createState() => _NetworkStatusWidgetState();
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
    if (speed == null) return "—";
    final mbps = speed / 1000000;
    return mbps >= 1
        ? "${mbps.toStringAsFixed(1)}M"
        : "${(speed / 1000).toStringAsFixed(0)}K";
  }

  String _formatDuration(String duration) {
    return duration;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ValueListenableBuilder<V2RayStatus>(
        valueListenable: v2rayStatus,
        builder: (context, status, _) {
          return Container(
            width: MediaQuery.of(context).size.width * 0.7,
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(
                      Icons.circle,
                      color: Colors.greenAccent,
                      size: 14,
                    ),
                    Text(
                      "CONNECTED",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    _buildRefreshButton(),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildStatusTile(
                      icon: Icons.wifi,
                      color: ping == null ? Colors.grey : Colors.greenAccent,
                      value: isPinging
                          ? '...'
                          : ping != null
                              ? '$ping'
                              : '—',
                    ),
                    _buildStatusTile(
                      icon: Icons.download,
                      color: status.download == null
                          ? Colors.grey
                          : Colors.blueAccent,
                      value: _formatSpeed(status.downloadSpeed),
                    ),
                    _buildStatusTile(
                      icon: Icons.upload,
                      color: status.upload == null
                          ? Colors.grey
                          : Colors.orangeAccent,
                      value: _formatSpeed(status.uploadSpeed),
                    ),
                    _buildStatusTile(
                      icon: Icons.access_time,
                      color: status.duration == null
                          ? Colors.grey
                          : Colors.purpleAccent,
                      value: _formatDuration(status.duration),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusTile({
    required IconData icon,
    required Color color,
    required String value,
  }) {
    return Container(
      width: (MediaQuery.of(context).size.width * 0.7 - 44) / 2,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              fontFamily: 'Roboto',
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
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isPinging ? Colors.grey[800] : const Color(0xFF2C3E50),
        ),
        child: Icon(
          Icons.refresh,
          color: Colors.white.withOpacity(isPinging ? 0.5 : 0.9),
          size: 16,
        ),
      ),
    );
  }
}
