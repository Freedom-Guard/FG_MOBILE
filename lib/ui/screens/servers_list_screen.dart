import 'dart:ui';
import 'package:Freedom_Guard/components/connect.dart';
import 'package:Freedom_Guard/core/global.dart';
import 'package:Freedom_Guard/services/config.dart';
import 'package:flutter/material.dart';
import 'package:Freedom_Guard/utils/LOGLOG.dart';
import 'package:share_plus/share_plus.dart'; // برای لاگ

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
    _configsFuture = _loadData();
  }

  Future<List<ConfigPingResult>> _loadData() {
    return connect.loadConfigPings();
  }

  void _refreshData() {
    setState(() {
      _configsFuture = _loadData();
    });
  }

  String _getRemarkFromLink(String link) {
    link = getNameByConfig(link);
    return link.length > 40 ? link.substring(0, 40) + "..." : link;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: Icon(Icons.share_rounded),
            onPressed: () async {
              try {
                final configs = await _configsFuture;
                if (configs.isEmpty) {
                  LogOverlay.showLog("Nothing to share!", type: "error");
                  return;
                }

                final List<String> allLinks =
                    configs.map((c) => c.configLink).toList();

                final shareText = allLinks.join("\n\n");

                await Share.share(
                  shareText,
                  subject: "Freedom Guard - Exported Configs",
                );
              } catch (e) {
                LogOverlay.showLog("Share failed: $e", type: "error");
              }
            },
          )
        ],
        title: Text("Server List"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Optional: Add a blurred background image here for full effect
          // Container(
          //   decoration: BoxDecoration(
          //     image: DecorationImage(
          //       image: AssetImage('assets/your_background.png'),
          //       fit: BoxFit.cover,
          //     ),
          //   ),
          // ),

          RefreshIndicator(
            onRefresh: () async => _refreshData(),
            child: FutureBuilder<List<ConfigPingResult>>(
              future: _configsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                      child: Text("Error: ${snapshot.error}",
                          style: TextStyle(color: theme.colorScheme.error)));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                      child: Text("No servers found. Pull to refresh.",
                          style: TextStyle(
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.7))));
                }

                final configs = snapshot.data!;
                configs.sort((a, b) => a.ping.compareTo(b.ping));

                return ListView.builder(
                  padding: EdgeInsets.only(
                    top: kToolbarHeight +
                        MediaQuery.of(context).padding.top +
                        20,
                    left: 16,
                    right: 16,
                    bottom: 20,
                  ),
                  itemCount: configs.length + 1, // +1 for "Auto Server"
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildAutoServerTile(context);
                    }
                    final config = configs[index - 1];
                    return _buildServerTile(context, config);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassTile({
    required BuildContext context,
    required Widget child,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.surface.withOpacity(0.25),
                  theme.colorScheme.surface.withOpacity(0.15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20.0),
              border: Border.all(
                color: theme.colorScheme.onSurface.withOpacity(0.1),
                width: 1.0,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(20.0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 18.0),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAutoServerTile(BuildContext context) {
    final theme = Theme.of(context);
    return _buildGlassTile(
      context: context,
      onTap: () async {
        LogOverlay.showLog("Connecting to Auto Server...",
            backgroundColor: Colors.blueAccent);
        Navigator.of(context).pop();
        try {
          String subLink = await connect.settings.getValue("saved_sub");
          if (subLink.isEmpty) {
            LogOverlay.showLog("Subscription link not found!", type: "error");
            return;
          }
          await connect.ConnectSub(subLink, "sub");
        } catch (e) {
          LogOverlay.showLog("Auto connect failed: $e", type: "error");
        }
      },
      child: Row(
        children: [
          Icon(Icons.auto_awesome_rounded, color: theme.colorScheme.primary),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              "Auto Server",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurface.withOpacity(0.7)),
        ],
      ),
    );
  }

  Widget _buildServerTile(BuildContext context, ConfigPingResult config) {
    final theme = Theme.of(context);
    final String configName = _getRemarkFromLink(config.configLink);

    Color pingColor;
    if (config.ping < 200) {
      pingColor = Color(0xFF4CAF50); // Green
    } else if (config.ping < 500) {
      pingColor = Color(0xFFFF9800); // Orange
    } else {
      pingColor = Color(0xFFF44336); // Red
    }

    return _buildGlassTile(
      context: context,
      onTap: () async {
        LogOverlay.showLog("Connecting to selected server...",
            backgroundColor: Colors.blueAccent);
        Navigator.of(context).pop();
        try {
          await connect.ConnectVibe(
              config.configLink, {"type": "manual_select"});
        } catch (e) {
          LogOverlay.showLog("Connection failed: $e", type: "error");
        }
      },
      child: Row(
        children: [
          Icon(Icons.public_rounded,
              color: theme.colorScheme.onSurface.withOpacity(0.8)),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              configName,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurface),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          SizedBox(width: 16),
          Text(
            "${config.ping} ms",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: pingColor,
              fontWeight: FontWeight.bold,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
