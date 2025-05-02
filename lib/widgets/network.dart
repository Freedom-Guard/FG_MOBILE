import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PingWidget extends StatefulWidget {
  const PingWidget({Key? key}) : super(key: key);

  @override
  _PingWidgetState createState() => _PingWidgetState();
}

class _PingWidgetState extends State<PingWidget> {
  int? ping;
  bool isPinging = false;
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchPing();
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
    setState(() {
      isPinging = true;
      ping = 0;
    });
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isPinging ? null : _fetchPing,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isPinging
                ? [Colors.amber.shade600, Colors.amber.shade800]
                : ping == null
                    ? [Colors.grey.shade700, Colors.grey.shade900]
                    : [
                        const Color.fromARGB(255, 36, 0, 121),
                        const Color.fromARGB(255, 77, 0, 45),
                      ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.0, 1.0],
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: isPinging
                  ? Colors.amberAccent.withOpacity(0.4)
                  : ping == null
                      ? Colors.grey.withOpacity(0.25)
                      : const Color.fromARGB(255, 159, 100, 255)
                          .withOpacity(0.35),
              blurRadius: 8,
              spreadRadius: 1,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: isPinging
                ? Colors.amberAccent.withOpacity(0.5)
                : ping == null
                    ? Colors.white.withOpacity(0.1)
                    : const Color.fromARGB(255, 159, 100, 255).withOpacity(0.3),
            width: 1.2,
          ),
          color: Colors.black.withOpacity(0.05),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: animation,
                child: child,
              ),
              child: Icon(
                isPinging ? Icons.sync : Icons.signal_wifi_4_bar,
                key: ValueKey(isPinging),
                color: isPinging
                    ? Colors.white
                    : ping == null
                        ? Colors.grey.shade400
                        : const Color.fromARGB(255, 167, 100, 255),
                size: 14,
              ),
            ),
            const SizedBox(width: 6),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                color: Colors.white.withOpacity(isPinging ? 0.9 : 1.0),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                fontFamily: 'Roboto',
                shadows: [
                  Shadow(
                    color: isPinging
                        ? Colors.amberAccent.withOpacity(0.3)
                        : ping == null
                            ? Colors.grey.withOpacity(0.2)
                            : const Color.fromARGB(255, 159, 100, 255)
                                .withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                isPinging
                    ? 'Pinging'
                    : ping != null
                        ? '$ping ms'
                        : '—',
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
  String countryFlag = "🌍";
  bool isLoading = false;
  bool isConnected = false;
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchNetworkSpeeds();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (!isLoading) _fetchNetworkSpeeds();
    });
  }

  Future<void> _fetchNetworkSpeeds() async {
    setState(() => isLoading = true);
    await Future.wait([
      _fetchDownloadSpeed(),
      _fetchUploadSpeed(),
      _fetchCountryFlag(),
    ]);
    setState(() {
      isLoading = false;
    });
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
    } catch (_) {
      setState(() => downloadSpeed = null);
    }
  }

  Future<void> _fetchUploadSpeed() async {
    final stopwatch = Stopwatch()..start();
    try {
      final response = await http.post(
        Uri.parse('https://speed.cloudflare.com/__up'),
        body: List.filled(1000000, 0),
        headers: {'Content-Type': 'application/octet-stream'},
      ).timeout(const Duration(seconds: 5));
      stopwatch.stop();
      if (response.statusCode == 200 || response.statusCode == 204) {
        final timeInSeconds = stopwatch.elapsedMilliseconds / 1000;
        setState(() => uploadSpeed = (1000000 * 8 ~/ timeInSeconds).toInt());
      } else {
        setState(() => uploadSpeed = null);
      }
    } catch (_) {
      setState(() => uploadSpeed = null);
    }
  }

  Future<void> _fetchCountryFlag() async {
    try {
      final response = await http.get(Uri.parse('http://ip-api.com/json'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final countryCode = data['countryCode'];
        setState(() => countryFlag = _getFlagEmoji(countryCode));
      }
    } catch (_) {
      setState(() => countryFlag = '🌍');
    }
  }

  String _getFlagEmoji(String countryCode) {
    return countryCode
        .toUpperCase()
        .runes
        .map((e) => String.fromCharCode(e + 127397))
        .join();
  }

  String _formatSpeed(int? speed) {
    if (speed == null) return "—";
    final mbps = speed / 1000000;
    return mbps >= 1
        ? "${mbps.toStringAsFixed(1)} Mbps"
        : "${(speed / 1000).toStringAsFixed(1)} Kbps";
  }

  @override
  Widget build(BuildContext context) {
    return isConnected
        ? _buildConnectedWidget(context)
        : _buildStatusWidget(context);
  }

  Widget _buildConnectedWidget(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.65,
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blueGrey.shade800, Colors.black87],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const PingWidget(),
          GestureDetector(
            onTap: isLoading ? null : _fetchNetworkSpeeds,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: isLoading
                      ? [Colors.grey.shade700, Colors.grey.shade800]
                      : [Colors.teal.shade700, Colors.teal.shade900],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.refresh,
                color: Colors.white.withOpacity(isLoading ? 0.6 : 1.0),
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusWidget(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.65,
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blueGrey.shade800, Colors.black87],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Network Status",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        fontFamily: 'Roboto',
                      ),
                    ),
                    const PingWidget(),
                  ],
                ),
                const SizedBox(height: 10),
                _buildStatusCard(),
              ],
            ),
          ),
          if (isLoading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.tealAccent,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          _buildStatusRow(
            icon: Icons.arrow_downward,
            color: downloadSpeed == null ? Colors.grey : Colors.blueAccent,
            label: "Download",
            value: _formatSpeed(downloadSpeed),
          ),
          const SizedBox(height: 6),
          _buildStatusRow(
            icon: Icons.arrow_upward,
            color: uploadSpeed == null ? Colors.grey : Colors.orangeAccent,
            label: "Upload",
            value: _formatSpeed(uploadSpeed),
          ),
          const SizedBox(height: 6),
          _buildStatusRow(
            icon: Icons.public,
            color: countryFlag == '🌍' ? Colors.grey : Colors.redAccent,
            label: "Location",
            value: countryFlag,
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: _buildRefreshButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildRefreshButton() {
    return GestureDetector(
      onTap: isLoading ? null : _fetchNetworkSpeeds,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: isLoading
                ? [Colors.grey.shade700, Colors.grey.shade800]
                : [Colors.teal.shade700, Colors.teal.shade900],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.refresh,
          color: Colors.white.withOpacity(isLoading ? 0.6 : 1.0),
          size: 16,
        ),
      ),
    );
  }

  Widget _buildStatusRow({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.15),
            Colors.transparent,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'Roboto',
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              fontFamily: 'Roboto',
            ),
          ),
        ],
      ),
    );
  }
}
