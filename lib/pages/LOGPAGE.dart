import 'package:flutter/material.dart';
import 'dart:async';
import '/components/LOGLOG.dart';

class LogPage extends StatefulWidget {
  const LogPage({super.key});

  @override
  State<LogPage> createState() => _LogPageState();
}

class _LogPageState extends State<LogPage> with SingleTickerProviderStateMixin {
  List<String> logs = [];
  Timer? _refreshTimer;
  late AnimationController _animationController;
  late Animation<double> _buttonAnimation;

  @override
  void initState() {
    super.initState();
    _loadLogs();
    _refreshLogs();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _buttonAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadLogs() async {
    String loadedLogs = await LogOverlay.loadLogs();
    setState(() {
      logs =
          loadedLogs.split("\n").where((log) => log.trim().isNotEmpty).toList();
    });
  }

  void _refreshLogs() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _loadLogs();
    });
  }

  void _copyLogs() {
    LogOverlay.copyLogs().then((success) {
      _showSnackBar(
        success ? 'Logs copied to clipboard!' : 'No logs to copy!',
        success ? Colors.green : Colors.red,
      );
    });
  }

  Future<void> _clearLogs() async {
    await LogOverlay.clearLogs();
    setState(() => logs = []);
    _showSnackBar('Logs cleared successfully!', Colors.green);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: color.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16.0),
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.6),
        elevation: 0,
        title: const Text(
          'Logs',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: FadeTransition(
              opacity: _buttonAnimation,
              child: Row(
                children: [
                  _buildActionButton(
                    Icons.copy,
                    'Copy Logs',
                    Colors.blueAccent,
                    _copyLogs,
                  ),
                  _buildActionButton(
                    Icons.delete,
                    'Clear Logs',
                    Colors.redAccent,
                    _clearLogs,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child:
                logs.isEmpty
                    ? const Center(
                      child: Text(
                        'No logs available',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 18,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(8.0),
                      itemCount: logs.length,
                      itemBuilder: (BuildContext context, int index) {
                        return Card(
                          color: Colors.white.withOpacity(0.1),
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(
                            vertical: 0.0,
                            horizontal: 8.0,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(0.0),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(
                              logs[index],
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        alignment: Alignment.topLeft,
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(1),
              blurRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [Icon(icon, color: Colors.white, size: 24)],
        ),
      ),
    );
  }
}
