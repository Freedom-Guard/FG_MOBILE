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
    if (loadedLogs.isEmpty) {
      setState(() {
        logs = [];
      });
      return;
    }
    setState(() {
      logs =
          loadedLogs.split("\n").where((log) => log.trim().isNotEmpty).toList();
      debugPrint('Loaded logs: ${logs.length} entries');
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
    setState(() {
      logs = [];
    });
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
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1F1F),
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
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: FadeTransition(
              opacity: _buttonAnimation,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: Icons.copy,
                    label: 'Copy Logs',
                    color: Colors.blueAccent,
                    onTap: _copyLogs,
                  ),
                  _buildActionButton(
                    icon: Icons.delete,
                    label: 'Clear Logs',
                    color: Colors.redAccent,
                    onTap: _clearLogs,
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
                          color: const Color(0xFF1F1F1F),
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(
                            vertical: 4.0,
                            horizontal: 8.0,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
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

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        transformAlignment: Alignment.center,
        transform: Matrix4.identity()..scale(onTap != null ? 1.0 : 0.95),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.6), color],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 12.0,
              spreadRadius: 2.0,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8.0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              shaderCallback:
                  (bounds) => LinearGradient(
                    colors: [Colors.white, color.withOpacity(0.8)],
                  ).createShader(bounds),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 10.0),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 0.5,
                shadows: [
                  Shadow(
                    color: Colors.black54,
                    offset: Offset(1, 1),
                    blurRadius: 3,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
