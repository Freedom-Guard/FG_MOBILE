import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';

class PingWidget extends StatefulWidget {
  final String host;

  const PingWidget({Key? key, this.host = "8.8.8.8"}) : super(key: key);

  @override
  _PingWidgetState createState() => _PingWidgetState();
}

class _PingWidgetState extends State<PingWidget> {
  int? ping;
  bool isLoading = false;

  Future<void> _fetchPing() async {
    setState(() => isLoading = true);
    try {
      final stopwatch = Stopwatch()..start();
      await Process.run("ping", ["-c", "1", widget.host]);
      stopwatch.stop();
      setState(() => ping = stopwatch.elapsedMilliseconds);
    } catch (e) {
      setState(() => ping = null);
    }
    setState(() => isLoading = false);
  }

  @override
  void initState() {
    super.initState();
    _fetchPing();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20), // فاصله از بالا
      child: GestureDetector(
        onTap: _fetchPing,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              decoration: BoxDecoration(
                color:
                    ping == null
                        ? Colors.red.withOpacity(0.5)
                        : ping! < 50
                        ? Colors.green.withOpacity(0.5)
                        : ping! < 100
                        ? Colors.orange.withOpacity(0.5)
                        : Colors.red.withOpacity(0.5),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 3,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  isLoading
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : Icon(Icons.network_ping, color: Colors.white),
                  const SizedBox(width: 10),
                  Text(
                    isLoading
                        ? "در حال دریافت..."
                        : (ping != null ? "$ping ms" : "خطا"),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
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
