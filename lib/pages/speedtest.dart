// Suggested code may be subject to a license. Learn more: ~LicenseLog:248488495.
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;

class SpeedTestPage extends StatefulWidget {
  const SpeedTestPage({super.key});

  @override
  State<SpeedTestPage> createState() => _SpeedTestPageState();
}

class _SpeedTestPageState extends State<SpeedTestPage> {
  double downloadSpeed = 0.0;
  double uploadSpeed = 0.0;
  bool isTesting = false;
  String status = 'Ready';
  double progress = 0.0;
  int ping = 0;

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
      final response = await http
          .post(
            Uri.parse('https://httpbin.org/post'),
            body: List.filled(1000000, 0),
            headers: {'Content-Type': 'application/octet-stream'},
          )
          .timeout(const Duration(seconds: 5));
      stopwatch.stop();
      if (response.statusCode == 200 || response.statusCode == 204) {
        final timeInSeconds = stopwatch.elapsedMilliseconds / 1000;
        setState(() {
          uploadSpeed = (1000000 * 8 / timeInSeconds) / 1000000; // Mbps
        });
      } else {
        setState(() => uploadSpeed = 0);
      }
    } catch (e) {
      setState(() => uploadSpeed = 0);
    }
  }

  void startSpeedTest() async {
    setState(() {
      isTesting = true;
      downloadSpeed = 0.0;
      uploadSpeed = 0.0;
      status = 'Testing Download...';
      progress = 0.0;
    });

    await _fetchDownloadSpeed();
    setState(() {
      status = 'Testing Upload...';
      progress = 0.5;
    });

    await _fetchUploadSpeed();
    await _fetchPing();
    setState(() {
      status = 'Complete';
      progress = 1.0;
      isTesting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Speed Test'),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.black, Color.fromARGB(255, 49, 48, 48)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Internet Speed Test',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      SpeedCard(
                        title: 'Download',
                        speed: downloadSpeed,
                        unit: 'Mbps',
                      ),
                      SpeedCard(
                        title: 'Upload',
                        speed: uploadSpeed,
                        unit: 'Mbps',
                      ),
                      SpeedCard(
                        title: 'Ping',
                        speed: ping.toDouble(),
                        unit: 'ms',
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: isTesting ? null : startSpeedTest,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 15,
                          ),
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          isTesting ? 'Testing...' : 'Start Test',
                          style: TextStyle(fontSize: 22, color: Colors.blue),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SpeedCard extends StatelessWidget {
  final String title;
  final double speed;
  final String unit;

  const SpeedCard({
    super.key,
    required this.title,
    required this.speed,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: Colors.black.withOpacity(0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Text(
              speed.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              unit,
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
