import 'package:flutter/material.dart';
import 'dart:async';
import '/components/LOGLOG.dart';

class LogPage extends StatefulWidget {
  const LogPage({super.key});

  @override
  State<LogPage> createState() => _LogPageState();
}

class _LogPageState extends State<LogPage> {
  List<String> logs = [];
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadLogs();
    _refreshLogs();
  }
  @override
  void dispose(){
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadLogs() async {
    final loadedLogs = await LogOverlay.loadLogs();
    setState(() {
      logs = loadedLogs as List<String>;
    });
  }

  void _refreshLogs() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _loadLogs();
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logs'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Text(logs.join('\n')),
    );
  }
}

