import 'dart:async';
import 'package:Freedom_Guard/components/connect.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_v2ray/flutter_v2ray.dart';

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
    if (speed == null) return "—";
    final mbps = speed / 1000000;
    return mbps >= 1
        ? "${mbps.toStringAsFixed(1)} Mbps"
        : "${(speed / 1000).toStringAsFixed(0)} Kbps";
  }

  String _formatSize(int? bytes) {
    if (bytes == null) return "—";
    final mb = bytes / (1024 * 1024);
    return mb >= 1
        ? "${mb.toStringAsFixed(1)} MB"
        : "${(bytes / 1024).toStringAsFixed(0)} KB";
  }

  String _formatDuration(String? duration) {
    if (duration == null) return "—";
    return duration;
  }

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
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.circle, color: Colors.greenAccent, size: 12),
                      const SizedBox(width: 6),
                      const Text(
                        "CONNECTED",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const Spacer(),
                      _buildRefreshButton(),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    runSpacing: 16,
                    spacing: 16,
                    children: [
                      _buildTile("Ping", Icons.wifi,
                          ping == null ? "—" : "$ping ms", Colors.greenAccent),
                      _buildTile(
                          "Download",
                          Icons.download,
                          _formatSpeed(status.downloadSpeed),
                          Colors.blueAccent),
                      _buildTile(
                          "Upload",
                          Icons.upload,
                          _formatSpeed(status.uploadSpeed),
                          Colors.orangeAccent),
                      _buildTile(
                          "Uptime",
                          Icons.timer,
                          _formatDuration(status.duration),
                          Colors.purpleAccent),
                      _buildTile("Total DL", Icons.data_usage,
                          _formatSize(status.download), Colors.blue),
                      _buildTile("Total UL", Icons.upload_file,
                          _formatSize(status.upload), Colors.deepOrange),
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
      width: (MediaQuery.of(context).size.width * 0.85 - 48) / 2,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.95),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRefreshButton() {
    return GestureDetector(
      onTap: isPinging ? null : _fetchPing,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isPinging ? Colors.grey[800] : const Color(0xFF2C3E50),
        ),
        child: Icon(
          Icons.refresh,
          size: 18,
          color: Colors.white.withOpacity(isPinging ? 0.4 : 0.9),
        ),
      ),
    );
  }
}
