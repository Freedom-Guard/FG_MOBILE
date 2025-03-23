import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PingWidget extends StatefulWidget {
  const PingWidget({Key? key}) : super(key: key);

  @override
  _PingWidgetState createState() => _PingWidgetState();
}

class _PingWidgetState extends State<PingWidget> {
  int? ping;

  @override
  void initState() {
    super.initState();
    _fetchPing();
  }

  Future<void> _fetchPing() async {
    final stopwatch = Stopwatch()..start();
    setState(() => ping = 0);
    try {
      final response = await http
          .get(Uri.parse('https://www.google.com'))
          .timeout(const Duration(seconds: 5));
      stopwatch.stop();
      setState(
        () =>
            ping =
                response.statusCode == 200
                    ? stopwatch.elapsedMilliseconds
                    : null,
      );
    } catch (e) {
      setState(() => ping = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _fetchPing,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blueGrey.shade900,
              const Color.fromARGB(109, 7, 41, 6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.signal_wifi_4_bar, color: Colors.tealAccent, size: 16),
            const SizedBox(width: 6),
            Text(
              ping != null ? '$ping ms' : '—',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NetworkStatusWidget extends StatefulWidget {
  const NetworkStatusWidget({Key? key}) : super(key: key);

  @override
  _NetworkStatusWidgetState createState() => _NetworkStatusWidgetState();
}

class _NetworkStatusWidgetState extends State<NetworkStatusWidget> {
  int? downloadSpeed;
  int? uploadSpeed;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchNetworkSpeeds();
  }

  Future<void> _fetchNetworkSpeeds() async {
    setState(() => isLoading = true);
    await _fetchDownloadSpeed();
    await _fetchUploadSpeed();
    setState(() => isLoading = false);
  }

  Future<void> _fetchDownloadSpeed() async {
    final stopwatch = Stopwatch()..start();
    try {
      final response = await http
          .get(Uri.parse('https://speed.cloudflare.com/__down?bytes=1000000'))
          .timeout(const Duration(seconds: 5));
      stopwatch.stop();
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes.length;
        final timeInSeconds = stopwatch.elapsedMilliseconds / 1000;
        setState(() => downloadSpeed = (bytes * 8 ~/ timeInSeconds).toInt());
      } else {
        setState(() => downloadSpeed = null);
      }
    } catch (e) {
      setState(() => downloadSpeed = null);
    }
  }

  Future<void> _fetchUploadSpeed() async {
    final stopwatch = Stopwatch()..start();
    try {
      // Using a more reliable upload test endpoint
      final response = await http
          .post(
            Uri.parse('https://speedtest.1and1.org/upload.php'),
            body: List.filled(1000000, 0), // 1MB of data
            headers: {'Content-Type': 'application/octet-stream'},
          )
          .timeout(const Duration(seconds: 5));
      stopwatch.stop();
      if (response.statusCode == 200 || response.statusCode == 204) {
        final timeInSeconds = stopwatch.elapsedMilliseconds / 1000;
        setState(() => uploadSpeed = (1000000 * 8 ~/ timeInSeconds).toInt());
      } else {
        setState(() => uploadSpeed = null);
      }
    } catch (e) {
      setState(() => uploadSpeed = null);
    }
  }

  String _formatSpeed(int? speed) {
    if (speed == null) return "—";
    return "${(speed / 1000000).toStringAsFixed(1)} M";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.75,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey.shade900, Colors.black],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade800.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Network",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const PingWidget(),
            ],
          ),
          const SizedBox(height: 10),
          _buildSpeedRow(
            Icons.arrow_downward,
            Colors.blueAccent.shade200,
            "",
            _formatSpeed(downloadSpeed),
          ),
          const SizedBox(height: 6),
          _buildSpeedRow(
            Icons.arrow_upward,
            Colors.orangeAccent.shade200,
            "",
            _formatSpeed(uploadSpeed),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: isLoading ? null : _fetchNetworkSpeeds,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors:
                        isLoading
                            ? [Colors.grey.shade700, Colors.grey.shade800]
                            : [
                              Colors.blueGrey.shade700,
                              Colors.blueGrey.shade900,
                            ],
                  ),
                ),
                child: Icon(
                  isLoading ? Icons.sync : Icons.refresh,
                  color: Colors.white.withOpacity(isLoading ? 0.7 : 1.0),
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedRow(
    IconData icon,
    Color color,
    String label,
    String speed,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 8),
        Text(
          "$label",
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          speed,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
