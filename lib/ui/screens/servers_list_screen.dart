import 'dart:ui';
import 'package:Freedom_Guard/components/connect.dart';
import 'package:Freedom_Guard/core/global.dart';
import 'package:Freedom_Guard/services/config.dart';
import 'package:flutter/material.dart';
import 'package:Freedom_Guard/utils/LOGLOG.dart';
import 'package:share_plus/share_plus.dart';

class ServerListPage extends StatefulWidget {
  const ServerListPage({Key? key}) : super(key: key);

  @override
  _ServerListPageState createState() => _ServerListPageState();
}

class _ServerListPageState extends State<ServerListPage> {
  late Future<List<ConfigPingResult>> _configsFuture;

  @override
  void initState() {
    super.initState();
    _configsFuture = connect.loadConfigPings();
  }

  void _refreshData() {
    setState(() {
      _configsFuture = connect.loadConfigPings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Network Nodes",
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_rounded, size: 22),
            onPressed: _shareConfigs,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
        ),
        child: RefreshIndicator(
          backgroundColor: Colors.grey[900],
          color: theme.colorScheme.primary,
          onRefresh: () async => _refreshData(),
          child: FutureBuilder<List<ConfigPingResult>>(
            future: _configsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildEmptyState();
              }

              final configs = snapshot.data!;
              configs.sort((a, b) => a.ping.compareTo(b.ping));

              return ListView.builder(
                padding: EdgeInsets.only(
                  top: 20 + MediaQuery.of(context).padding.top,
                  left: 16,
                  right: 16,
                  bottom: 30,
                ),
                itemCount: configs.length + 2,
                itemBuilder: (context, index) {
                  if (index == 0) return ServerStateCard(configs: configs);
                  if (index == 1) return _buildAutoServerTile(context);

                  final config = configs[index - 2];
                  return TweenAnimationBuilder<double>(
                    duration: Duration(milliseconds: 400 + (index * 50)),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: _buildServerTile(context, config),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _shareConfigs() async {
    try {
      final configs = await _configsFuture;
      if (configs.isEmpty) return;
      final shareText = configs.map((c) => c.configLink).join("\n");
      await Share.share(shareText, subject: "Freedom Guard Configs");
    } catch (e) {
      LogOverlay.showLog("Share failed", type: "error");
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_rounded,
              size: 64, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 16),
          const Text("No Nodes Found", style: TextStyle(color: Colors.white38)),
        ],
      ),
    );
  }

  Widget _buildGlassContainer(
      {required Widget child,
      required VoidCallback onTap,
      Color? borderColor}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.06),
            Colors.white.withOpacity(0.02)
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border:
            Border.all(color: borderColor ?? Colors.white.withOpacity(0.08)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(padding: const EdgeInsets.all(18), child: child),
        ),
      ),
    );
  }

  Widget _buildAutoServerTile(BuildContext context) {
    final theme = Theme.of(context);
    return _buildGlassContainer(
      borderColor: theme.colorScheme.primary.withOpacity(0.3),
      onTap: () async {
        Navigator.pop(context);
        String subLink = await connect.settings.getValue("saved_sub");
        if (subLink.isNotEmpty) await connect.ConnectSub(subLink, "sub");
      },
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: theme.colorScheme.primary,
            child: Icon(Icons.bolt_rounded, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text("Smart Connect",
                style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
          ),
          Icon(Icons.arrow_forward_ios_rounded,
              size: 12, color: theme.colorScheme.primary.withOpacity(0.5)),
        ],
      ),
    );
  }

  Icon getPingIcon(int ping) {
    if (ping < 150) {
      return const Icon(
        Icons.signal_cellular_alt_rounded,
        color: Colors.green,
      );
    } else if (ping < 300) {
      return const Icon(
        Icons.signal_cellular_alt_2_bar,
        color: Colors.orange,
      );
    } else {
      return const Icon(
        Icons.signal_cellular_alt_1_bar,
        color: Colors.red,
      );
    }
  }

  Widget _buildServerTile(BuildContext context, ConfigPingResult config) {
    final String configName = getNameByConfig(config.configLink);
    final String protocol = config.configLink.split("://")[0].toUpperCase();

    Color pingColor = config.ping < 200
        ? Colors.greenAccent
        : (config.ping < 500 ? Colors.orangeAccent : Colors.redAccent);

    return _buildGlassContainer(
      onTap: () async {
        Navigator.pop(context);
        await connect.ConnectVibe(config.configLink, {"type": "manual_select"});
      },
      child: Row(
        children: [
          _protocolIcon(protocol),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(configName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(protocol,
                    style: TextStyle(
                        color: Colors.white24,
                        fontSize: 10,
                        fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text("${config.ping}ms",
                  style: TextStyle(
                      color: pingColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      fontFamily: 'monospace')),
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(bottom: 10, right: 10),
                child: getPingIcon(config.ping),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _protocolIcon(String protocol) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05), shape: BoxShape.circle),
      child: Icon(Icons.router_rounded,
          size: 18, color: Colors.white.withOpacity(0.5)),
    );
  }
}

class ServerStateCard extends StatelessWidget {
  final List<ConfigPingResult> configs;
  const ServerStateCard({super.key, required this.configs});

  @override
  Widget build(BuildContext context) {
    final pings = configs.map((e) => e.ping).toList();
    final avgPing = (pings.reduce((a, b) => a + b) / pings.length).round();
    final bestPing = pings.reduce((a, b) => a < b ? a : b);
    final healthy = configs.where((c) => c.ping < 800).length;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 10),
      margin: const EdgeInsets.only(bottom: 25),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _stat("Avg", "$avgPing", "ms"),
          _stat("Best", "$bestPing", "ms"),
          _stat("Alive", "$healthy", ""),
          _stat("Total", "${configs.length}", ""),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, String unit) {
    return Column(
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                  text: value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              if (unit.isNotEmpty)
                TextSpan(
                    text: unit,
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 10)),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(label.toUpperCase(),
            style: const TextStyle(
                color: Colors.white24,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5)),
      ],
    );
  }
}
