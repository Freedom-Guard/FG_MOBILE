import 'package:Freedom_Guard/components/local.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/LOGLOG.dart';

class LogPage extends StatefulWidget {
  @override
  State<LogPage> createState() => _LogPageState();
}

class _LogPageState extends State<LogPage> with SingleTickerProviderStateMixin {
  List<String> logs = [];
  Timer? _refreshTimer;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadLogs();
    _refreshLogs();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
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
      logs = loadedLogs
          .split("\n")
          .where((log) => log.trim().isNotEmpty)
          .toList()
          .reversed
          .toList();
    });
  }

  void _refreshLogs() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _loadLogs();
    });
  }

  void _copyLogs() {
    LogOverlay.copyLogs().then((success) {
      LogOverlay.showLog(
          (success ? 'Logs copied to clipboard!' : 'No logs to copy!'),
          type: (success ? "success" : "error"));
    });
  }

  Future<void> _clearLogs() async {
    LogOverlay.clearLogs();
    setState(() => logs = []);

    LogOverlay.showLog('Logs cleared successfully!', type: "success");
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
        textDirection:
            getDir() == "rtl" ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
              title: Text(
                tr('logs'),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
              ),
              elevation: 0),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.grey[900]!, Colors.black],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Directionality(
                      textDirection: TextDirection.ltr,
                      child: Expanded(
                        child:
                            logs.isEmpty ? _buildEmptyState() : _buildLogList(),
                      )),
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ));
  }

  Widget _buildEmptyState() {
    return Center(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline, color: Colors.grey[600], size: 48),
            const SizedBox(height: 16),
            Text(
              'No logs available',
              style: GoogleFonts.inter(
                color: Colors.grey[500],
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        return FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Interval(0.1 * index, 1.0, curve: Curves.easeOut),
            ),
          ),
          child: _buildLogCard(logs[index], index),
        );
      },
    );
  }

  Widget _buildLogCard(String log, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850]!.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        log,
        style: GoogleFonts.sourceCodePro(
          color: Colors.white70,
          fontSize: 13,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        border: Border(top: BorderSide(color: Colors.grey[800]!, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            icon: Icons.copy,
            label: tr('copy'),
            color: Colors.blueAccent,
            onTap: _copyLogs,
          ),
          _buildActionButton(
            icon: Icons.delete,
            label: tr('clear'),
            color: Colors.redAccent,
            onTap: _clearLogs,
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
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
