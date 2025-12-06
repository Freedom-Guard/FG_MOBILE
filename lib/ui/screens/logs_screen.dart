import 'package:Freedom_Guard/core/local.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/LOGLOG.dart';

class LogPage extends StatefulWidget {
  @override
  State<LogPage> createState() => _LogPageState();
}

class _LogPageState extends State<LogPage> with SingleTickerProviderStateMixin {
  List<String> logs = [];
  List<String> filteredLogs = [];
  Timer? _refreshTimer;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLogs();
    _startRefresh();
    _controller =
        AnimationController(vsync: this, duration: Duration(milliseconds: 600));
    _fadeAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();
    searchController.addListener(_filterLogs);
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _controller.dispose();
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLogs() async {
    String result = await LogOverlay.loadLogs();
    List<String> logList = result
        .split("\n")
        .where((e) => e.trim().isNotEmpty)
        .toList()
        .reversed
        .toList();
    setState(() {
      logs = logList;
      filteredLogs = logList;
    });
  }

  void _startRefresh() {
    _refreshTimer = Timer.periodic(Duration(seconds: 1), (_) => _loadLogs());
  }

  void _filterLogs() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredLogs =
          logs.where((log) => log.toLowerCase().contains(query)).toList();
    });
  }

  Future<void> _copySingle(String log) async {
    await Clipboard.setData(ClipboardData(text: log));
    LogOverlay.showLog("Log copied!", type: "success");
  }

  void _copyAll() {
    LogOverlay.copyLogs().then((success) {
      LogOverlay.showLog(success ? "All logs copied!" : "No logs to copy!",
          type: success ? "success" : "error");
    });
  }

  Future<void> _clearLogs() async {
    LogOverlay.clearLogs();
    setState(() => logs = filteredLogs = []);
    LogOverlay.showLog("Logs cleared!", type: "success");
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: getDir() == "rtl" ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          elevation: 0,
          title: Text(tr("logs"),
              style:
                  GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.bold)),
        ),
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black, Colors.grey.shade900],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Column(
              children: [
                SizedBox(
                    height: MediaQuery.of(context).padding.top +
                        kToolbarHeight +
                        12),
                _buildSearchBar(),
                Expanded(
                    child: filteredLogs.isEmpty ? _emptyState() : _buildList()),
                _buildBottomMenu(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: TextField(
              controller: searchController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: "Search logs...",
                hintStyle: TextStyle(color: Colors.white60),
                icon: Icon(Icons.search, color: Colors.white70),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline, size: 55, color: Colors.white38),
            SizedBox(height: 12),
            Text("No logs available",
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 18)),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: filteredLogs.length,
      itemBuilder: (context, index) => _logTile(filteredLogs[index], index),
    );
  }

  Widget _logTile(String log, int index) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _controller,
        curve: Interval(0.05 * index, 1, curve: Curves.easeOut),
      )),
      child: GestureDetector(
        onLongPress: () => _copySingle(log),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            margin: EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: Text(
              log,
              style: GoogleFonts.sourceCodePro(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 13,
                  height: 1.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomMenu() {
    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            border:
                Border(top: BorderSide(color: Colors.white.withOpacity(0.15))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _menuButton(Icons.copy, tr("copy"), Colors.blueAccent, _copyAll),
              _menuButton(
                  Icons.delete, tr("clear"), Colors.redAccent, _clearLogs),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuButton(
      IconData icon, String label, Color color, VoidCallback action) {
    return GestureDetector(
      onTap: action,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            SizedBox(width: 8),
            Text(label,
                style: GoogleFonts.inter(
                    color: color, fontSize: 15, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
