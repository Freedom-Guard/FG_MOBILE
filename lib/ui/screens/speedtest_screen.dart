import 'dart:io';
import 'dart:typed_data';

import 'package:Freedom_Guard/components/local.dart';
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
    with SingleTickerProviderStateMixin {
  double downloadSpeed = 0.0;
  double uploadSpeed = 0.0;
  int ping = 0;
  bool isTesting = false;
  String status = 'Ready';
  double progress = 0.0;
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchPing() async {
    final stopwatch = Stopwatch()..start();
    try {
      await http
          .get(Uri.parse('https://www.google.com'))
          .timeout(const Duration(seconds: 5));
      stopwatch.stop();
      setState(() {
        ping = stopwatch.elapsedMilliseconds;
      });
    } catch (e) {
      setState(() => ping = 0);
    }
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
        setState(() {
          downloadSpeed = (bytes * 8 / timeInSeconds) / 1000000; // Mbps
        });
      } else {
        setState(() => downloadSpeed = 0);
      }
    } catch (e) {
      setState(() => downloadSpeed = 0);
    }
  }

  Future<void> _fetchUploadSpeed() async {
    final stopwatch = Stopwatch()..start();
    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity == ConnectivityResult.none) {
        setState(() => uploadSpeed = 0);
        return;
      }

      const payloadSize = 1000000;
      final payload = Uint8List(payloadSize);
      final response = await http.post(
        Uri.parse('https://speed.cloudflare.com/__up'),
        body: payload,
        headers: {'Content-Type': 'application/octet-stream'},
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        throw TimeoutException('Upload speed test timed out');
      });
      stopwatch.stop();
      final timeInSeconds = stopwatch.elapsedMilliseconds / 1000.0;
      if (response.statusCode == 200 || response.statusCode == 204) {
        if (timeInSeconds <= 0) {
          throw Exception('Invalid time measurement');
        }
        final speedMbps = (payloadSize * 8 / timeInSeconds) / 1000000;
        setState(() {
          uploadSpeed = double.parse(speedMbps.toStringAsFixed(2));
        });
      } else {
        setState(() => uploadSpeed = 0);
      }
    } on TimeoutException {
      setState(() => uploadSpeed = 0);
    } on SocketException {
      setState(() => uploadSpeed = 0);
    } catch (e) {
      setState(() => uploadSpeed = 0);
    } finally {
      stopwatch.reset();
    }
  }

  void startSpeedTest() async {
    setState(() {
      isTesting = true;
      downloadSpeed = 0.0;
      uploadSpeed = 0.0;
      ping = 0;
      status = 'Testing Download...';
      progress = 0.0;
    });
    _animationController.reset();
    _animationController.forward();

    await _fetchDownloadSpeed();
    setState(() {
      status = 'Testing Upload...';
      progress = 0.5;
    });

    await _fetchUploadSpeed();
    setState(() {
      status = 'Testing Ping...';
      progress = 0.75;
    });

    await _fetchPing();
    setState(() {
      status = 'Complete';
      progress = 1.0;
      isTesting = false;
    });
    _animationController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
        textDirection:
            getDir() == "rtl" ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(tr('speed-test')),
            elevation: 0,
          ),
          body: SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.grey[900]!, Colors.black],
                ),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 32),
                      if (status != "Complete") _buildStartButton(),
                      const SizedBox(height: 32),
                      _buildProgressIndicator(),
                      const SizedBox(height: 32),
                      _buildSpeedCards(),
                      const SizedBox(height: 52),
                      if (status == "Complete") _buildStartButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ));
  }

  Widget _buildHeader() {
    return SizedBox(
        width: double.infinity,
        child: Text(
          tr('speed-test-net'),
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ));
  }

  Widget _buildProgressIndicator() {
    return FadeTransition(
      opacity: _progressAnimation,
      child: Column(
        children: [
          CircularPercentIndicator(
            radius: 80.0,
            lineWidth: 12.0,
            percent: progress,
            center: Text(
              status,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            progressColor: Colors.blueAccent,
            backgroundColor: Colors.grey[800]!,
            circularStrokeCap: CircularStrokeCap.round,
            animation: true,
            animationDuration: 1000,
          ),
          const SizedBox(height: 16),
          Text(
            isTesting ? 'Running Test...' : 'Ready to Test',
            style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedCards() {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: [
        SpeedCard(
          title: 'Download',
          value: downloadSpeed,
          unit: 'Mbps',
          icon: Icons.download,
          color: Colors.blueAccent,
          animation: _progressAnimation,
        ),
        SpeedCard(
          title: 'Upload',
          value: uploadSpeed,
          unit: 'Mbps',
          icon: Icons.upload,
          color: Colors.greenAccent,
          animation: _progressAnimation,
        ),
        SpeedCard(
          title: 'Ping',
          value: ping.toDouble(),
          unit: 'ms',
          icon: Icons.network_ping,
          color: Colors.orangeAccent,
          animation: _progressAnimation,
        ),
      ],
    );
  }

  Widget _buildStartButton() {
    return GestureDetector(
      onTap: isTesting ? null : startSpeedTest,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isTesting
                ? [Colors.grey[700]!, Colors.grey[800]!]
                : [Colors.blueAccent, Colors.blue],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.blueAccent.withOpacity(isTesting ? 0.0 : 0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isTesting ? Icons.hourglass_empty : Icons.play_arrow,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              isTesting ? 'Testing...' : tr('start-test'),
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SpeedCard extends StatelessWidget {
  final String title;
  final double value;
  final String unit;
  final IconData icon;
  final Color color;
  final Animation<double> animation;

  const SpeedCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[850]!.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value.toStringAsFixed(1),
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              unit,
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }
}
