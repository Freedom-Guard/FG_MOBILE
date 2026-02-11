import 'package:Freedom_Guard/core/global.dart';
import 'package:Freedom_Guard/core/local.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/LOGLOG.dart';

class LogPage extends StatefulWidget {
  @override
  State<LogPage> createState() => _LogPageState();
}

class _LogPageState extends State<LogPage> with SingleTickerProviderStateMixin {
  List<String> appLogs = [];
  List<String> coreLogs = [];
  List<String> filteredLogs = [];
  Timer? _refreshTimer;
  final TextEditingController searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late TabController _tabController;
  bool _isSearching = false;
  bool _autoScroll = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_applyFilter);
    searchController.addListener(_handleSearch);
    _loadLogs();
    _startRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tabController.dispose();
    _scrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLogs() async {
    String result = await LogOverlay.loadLogs();
    List<String> app =
        result.split("\n").where((e) => e.trim().isNotEmpty).toList();
    List<String> core = [];
    try {
      core = await connect.vibeCoreMain.getLogs();
    } catch (_) {}
    setState(() {
      appLogs = app;
      coreLogs = core;
    });
    _applyFilter();
    if (_autoScroll) _scrollToBottom();
  }

  void _startRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(Duration(seconds: 1), (_) => _loadLogs());
  }

  void _pauseRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  void _handleSearch() {
    final query = searchController.text;
    _isSearching = query.isNotEmpty;
    if (_isSearching) {
      _pauseRefresh();
    } else {
      _startRefresh();
    }
    _applyFilter();
  }

  void _applyFilter() {
    final query = searchController.text.toLowerCase();
    final current = _tabController.index == 0 ? appLogs : coreLogs;
    setState(() {
      filteredLogs = query.isEmpty
          ? current
          : current.where((log) => log.toLowerCase().contains(query)).toList();
    });
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  Future<void> _copySingle(String log) async {
    await Clipboard.setData(ClipboardData(text: log));
    LogOverlay.showLog("Copied", type: "success");
  }

  void _copyAll() {
    final text = filteredLogs.join("\n");
    Clipboard.setData(ClipboardData(text: text));
    LogOverlay.showLog(text.isEmpty ? "Empty!" : "All Copied",
        type: text.isEmpty ? "error" : "success");
  }

  Future<void> _clearLogs() async {
    if (_tabController.index == 0) {
      LogOverlay.clearLogs();
      appLogs = [];
    } else {
      await connect.vibeCoreMain.clearLogs();
      coreLogs = [];
    }
    _applyFilter();
    LogOverlay.showLog("Cleared!", type: "success");
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Directionality(
      textDirection: getDir() == "rtl" ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          title: Text("Logs",
              style: GoogleFonts.sourceCodePro(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.greenAccent)),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.greenAccent,
            labelColor: Colors.greenAccent,
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(text: "App"),
              Tab(text: "Core"),
            ],
          ),
        ),
        body: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: filteredLogs.isEmpty ? _emptyState() : _buildTerminal(),
            ),
            _buildBottomBar(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.all(12),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.greenAccent.withOpacity(0.4)),
        ),
        child: TextField(
          controller: searchController,
          style: GoogleFonts.sourceCodePro(color: Colors.greenAccent),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: "Search...",
            hintStyle: TextStyle(color: Colors.greenAccent.withOpacity(0.4)),
            icon: Icon(Icons.search, color: Colors.greenAccent),
            suffixIcon: _isSearching
                ? IconButton(
                    icon: Icon(Icons.clear, color: Colors.greenAccent),
                    onPressed: () {
                      searchController.clear();
                      _handleSearch();
                    },
                  )
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildTerminal() {
    return Container(
      padding: EdgeInsets.all(12),
      color: Colors.black,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: filteredLogs.length,
        itemBuilder: (context, index) {
          final log = filteredLogs[index];
          return GestureDetector(
            onLongPress: () => _copySingle(log),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 2),
              child: Text(
                log,
                style: GoogleFonts.sourceCodePro(
                    color: Colors.greenAccent, fontSize: 13, height: 1.4),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Text("No logs available",
          style:
              GoogleFonts.sourceCodePro(color: Colors.white38, fontSize: 16)),
    );
  }

  Widget _buildBottomBar(ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        border:
            Border(top: BorderSide(color: Colors.greenAccent.withOpacity(0.3))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _actionButton(Icons.copy_all, "Copy", _copyAll),
              SizedBox(width: 12),
              _actionButton(Icons.delete, "Clear", _clearLogs),
            ],
          ),
          Row(
            children: [
              Text("AutoScroll",
                  style: GoogleFonts.sourceCodePro(color: Colors.greenAccent)),
              Switch(
                value: _autoScroll,
                activeColor: Colors.greenAccent,
                onChanged: (v) {
                  setState(() => _autoScroll = v);
                  if (v) _scrollToBottom();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.greenAccent.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.greenAccent),
            SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.sourceCodePro(color: Colors.greenAccent)),
          ],
        ),
      ),
    );
  }
}
