import 'dart:typed_data';
import 'dart:ui';
import 'package:Freedom_Guard/core/local.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class SpeedTestPage extends StatefulWidget {
  @override
  State<SpeedTestPage> createState() => _SpeedTestPageState();
}

class _SpeedTestPageState extends State<SpeedTestPage>
    with TickerProviderStateMixin {
  double downloadSpeed = 0.0;
  double uploadSpeed = 0.0;
  int ping = 0;
  int jitter = 0;
  bool isTesting = false;
  String status = 'Ready';
  double progress = 0.0;
  String connectionType = "Checking...";
  List<Map<String, dynamic>> history = [];

  late AnimationController _gaugeController;
  late Animation<double> _gaugeAnimation;

  @override
  void initState() {
    super.initState();
    _gaugeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
    _gaugeAnimation = Tween<double>(begin: 0, end: 0).animate(
        CurvedAnimation(parent: _gaugeController, curve: Curves.elasticOut));
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    var result = await Connectivity().checkConnectivity();
    setState(() {
      connectionType = result.toString().split('.').last.toUpperCase();
    });
  }

  @override
  void dispose() {
    _gaugeController.dispose();
    super.dispose();
  }

  void _updateGauge(double value) {
    _gaugeAnimation = Tween<double>(
      begin: _gaugeAnimation.value,
      end: value > 100 ? 1.0 : value / 100,
    ).animate(
        CurvedAnimation(parent: _gaugeController, curve: Curves.easeOutCubic));
    _gaugeController.forward(from: 0);
  }

  Future<void> _runTest() async {
    setState(() {
      isTesting = true;
      downloadSpeed = 0;
      uploadSpeed = 0;
      ping = 0;
      jitter = 0;
      progress = 0.1;
      status = tr('Testing Ping...');
    });

    final pStopwatch = Stopwatch()..start();
    try {
      await http
          .get(Uri.parse('https://8.8.8.8'))
          .timeout(const Duration(seconds: 3));
      ping = pStopwatch.elapsedMilliseconds;
      jitter = (ping * 0.12).toInt();
    } catch (_) {}

    setState(() {
      status = tr('Downloading...');
      progress = 0.4;
    });

    final dStopwatch = Stopwatch()..start();
    try {
      final response = await http
          .get(Uri.parse('https://speed.cloudflare.com/__down?bytes=2000000'));
      double speed = (response.bodyBytes.length *
              8 /
              (dStopwatch.elapsedMilliseconds / 1000)) /
          1000000;
      downloadSpeed = double.parse(speed.toStringAsFixed(2));
      _updateGauge(downloadSpeed);
    } catch (_) {}

    setState(() {
      status = tr('Uploading...');
      progress = 0.7;
    });

    final uStopwatch = Stopwatch()..start();
    try {
      final payload = Uint8List(1000000);
      await http.post(Uri.parse('https://speed.cloudflare.com/__up'),
          body: payload);
      double speed =
          (1000000 * 8 / (uStopwatch.elapsedMilliseconds / 1000)) / 1000000;
      uploadSpeed = double.parse(speed.toStringAsFixed(2));
    } catch (_) {}

    setState(() {
      status = tr('Complete');
      progress = 1.0;
      isTesting = false;
      history.insert(0, {
        'down': downloadSpeed,
        'up': uploadSpeed,
        'ping': ping,
        'time': DateTime.now()
      });
    });
    _updateGauge(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: Container(
            padding: EdgeInsets.all(8),
            decoration:
                BoxDecoration(color: Colors.white10, shape: BoxShape.circle),
            child:
                Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(tr('Network Speed'),
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F172A),
                  Color(0xFF1E293B),
                  Color(0xFF020617)
                ],
              ),
            ),
          ),
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blueAccent.withOpacity(0.15)),
              child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                  child: Container()),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    SizedBox(height: 20),
                    _buildMainGauge(),
                    SizedBox(height: 40),
                    _buildQuickStats(),
                    SizedBox(height: 32),
                    _buildActionBtn(),
                    SizedBox(height: 40),
                    _buildHistorySection(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainGauge() {
    return Center(
      child: CircularPercentIndicator(
        radius: 120.0,
        lineWidth: 15.0,
        animation: true,
        animateFromLastPercent: true,
        percent: isTesting ? progress : 0.0,
        circularStrokeCap: CircularStrokeCap.round,
        progressColor: Colors.blueAccent,
        backgroundColor: Colors.white.withOpacity(0.05),
        center: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _gaugeAnimation,
              builder: (context, child) => Text(
                isTesting
                    ? (downloadSpeed > 0
                        ? downloadSpeed.toStringAsFixed(1)
                        : "...")
                    : "0.0",
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    color: Colors.white),
              ),
            ),
            Text("Mbps",
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 16, color: Colors.white54)),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(status,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _statItem("Download", downloadSpeed.toString(), "Mbps",
            Icons.south_rounded, Colors.blueAccent),
        _statItem("Upload", uploadSpeed.toString(), "Mbps", Icons.north_rounded,
            Colors.redAccent),
        _statItem("Ping", ping.toString(), "ms", Icons.sensors_rounded,
            Colors.orangeAccent),
      ],
    );
  }

  Widget _statItem(
      String label, String value, String unit, IconData icon, Color color) {
    return Container(
      width: (MediaQuery.of(context).size.width - 80) / 3,
      padding: EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 8),
          Text(value,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          Text(unit,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 10, color: Colors.white38)),
          SizedBox(height: 4),
          Text(label,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 11, color: Colors.white60)),
        ],
      ),
    );
  }

  Widget _buildActionBtn() {
    return GestureDetector(
      onTap: isTesting ? null : _runTest,
      child: Container(
        width: double.infinity,
        height: 65,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
                color: Colors.blueAccent.withOpacity(0.3),
                blurRadius: 20,
                offset: Offset(0, 10))
          ],
          gradient: LinearGradient(
              colors: isTesting
                  ? [Colors.grey, Colors.grey]
                  : [Color(0xFF4F46E5), Color(0xFF3B82F6)]),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Center(
          child: isTesting
              ? CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
              : Text(tr('START SPEED TEST'),
                  style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2)),
        ),
      ),
    );
  }

  Widget _buildHistorySection() {
    if (history.isEmpty) return Container();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr("Recent Tests"),
            style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: history.length > 3 ? 3 : history.length,
          separatorBuilder: (c, i) => SizedBox(height: 12),
          itemBuilder: (c, i) {
            final item = history[i];
            return Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: Colors.blueAccent.withOpacity(0.1),
                        shape: BoxShape.circle),
                    child:
                        Icon(Icons.history, color: Colors.blueAccent, size: 20),
                  ),
                  SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${item['down']} Mbps Download",
                          style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                      Text("${item['ping']} ms • ${connectionType}",
                          style: GoogleFonts.plusJakartaSans(
                              color: Colors.white38, fontSize: 12)),
                    ],
                  ),
                  Spacer(),
                  Icon(Icons.chevron_right, color: Colors.white24),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
