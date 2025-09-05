import 'dart:convert';
import 'dart:ui';
import 'dart:io';
import 'package:Freedom_Guard/ui/widgets/dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;

import 'package:Freedom_Guard/utils/LOGLOG.dart';
import 'package:Freedom_Guard/components/f-link.dart';
import 'package:Freedom_Guard/core/local.dart';
import 'package:Freedom_Guard/components/servers.dart';
import 'package:Freedom_Guard/components/settings.dart';
import 'package:Freedom_Guard/main.dart';
import 'package:Freedom_Guard/ui/screens/cfg_screen.dart';
import 'package:Freedom_Guard/services/config.dart';
import 'package:Freedom_Guard/ui/widgets/encrypt.dart';
import 'package:Freedom_Guard/ui/widgets/enter_config.dart';
import 'package:Freedom_Guard/ui/widgets/qr_code.dart';

class ServersPage extends StatefulWidget {
  const ServersPage({super.key});

  @override
  State<ServersPage> createState() => _ServersPageState();
}

class _ServersPageState extends State<ServersPage> with RouteAware {
  bool isLoading = true;
  List<String> servers = [];
  List<String> filteredServers = [];
  late ServersM serversManage;
  late SettingsApp settings;
  final TextEditingController serverController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  final Map<String, int?> serverPingTimes = {};
  bool isPingingAll = false;
  bool sortByPing = false;

  @override
  void initState() {
    super.initState();
    settings = SettingsApp();
    serversManage = Provider.of<ServersM>(context, listen: false);
    searchController.addListener(_applyFiltersAndSort);
    Future.microtask(_loadServersAndInit);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    serverController.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void didPopNext() {
    _restoreServers();
  }

  Future<void> _loadServersAndInit() async {
    try {
      await serversManage.getSelectedServer();
      await _restoreServers(initialLoad: true);
      await _restorePingTimes();
      await _restoreSelectedServer();
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _applyFiltersAndSort() {
    final query = searchController.text.toLowerCase();
    List<String> tempFilteredServers;

    if (query.isEmpty) {
      tempFilteredServers = List.from(servers);
    } else {
      tempFilteredServers = servers.where((server) {
        final serverName = getNameByConfig(server).toLowerCase();
        return serverName.contains(query);
      }).toList();
    }

    if (sortByPing) {
      tempFilteredServers.sort((a, b) {
        final pingA =
            serverPingTimes[a] == -1 ? 9999 : serverPingTimes[a] ?? 9999;
        final pingB =
            serverPingTimes[b] == -1 ? 9999 : serverPingTimes[b] ?? 9999;
        return pingA.compareTo(pingB);
      });
    }

    setState(() {
      filteredServers = tempFilteredServers;
    });
  }

  Future<void> _savePingTimes() async {
    final prefs = await SharedPreferences.getInstance();
    final pingMap = serverPingTimes
        .map((key, value) => MapEntry(key, value?.toString() ?? 'null'));
    await prefs.setString('pingTimes', jsonEncode(pingMap));
  }

  Future<void> _restorePingTimes() async {
    final prefs = await SharedPreferences.getInstance();
    final pingData = prefs.getString('pingTimes');
    if (pingData != null) {
      final pingMap = jsonDecode(pingData) as Map<String, dynamic>;
      pingMap.forEach((key, value) {
        serverPingTimes[key] = value == 'null' ? null : int.tryParse(value);
      });
    }
  }

  Future<void> _restoreServers({bool initialLoad = false}) async {
    final prefs = await SharedPreferences.getInstance();
    var serverList = prefs.getStringList('servers') ?? [];

    if (initialLoad && serverList.isEmpty) {
      await _refreshSubscriptions();
      serverList = prefs.getStringList('servers') ?? [];
    }

    if (mounted) {
      setState(() {
        servers = serverList;
      });
      _applyFiltersAndSort();
    }
  }

  Future<void> _refreshSubscriptions() async {
    await serversManage.loadServers();
    await _restoreServers();
  }

  Future<void> _restoreSelectedServer() async {
    final prefs = await SharedPreferences.getInstance();
    final selectedServer = prefs.getString('selectedServer');
    if (selectedServer != null && servers.contains(selectedServer)) {
      await serversManage.selectServer(selectedServer);
    }
  }

  Future<void> _saveServers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('servers', servers);
    _applyFiltersAndSort();
  }

  void _addServer(String serverName) {
    if (serverName.isNotEmpty && !servers.contains(serverName)) {
      setState(() {
        servers.insert(0, serverName);
      });
      serversManage.selectServer(serverName);
      _saveServers();
      serverController.clear();
    } else {
      serversManage.selectServer(serverName);
    }
  }

  void _confirmRemoveServer(String serverToRemove) {
    showDialog(
      context: context,
      builder: (context) => AppDialogs.buildDialog(
        context: context,
        title: tr('delete-server'),
        content: tr('are-you-sure-you-want-to-delete-this-server'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('cancel'),
                style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _removeServer(serverToRemove);
            },
            child: Text(tr('delete'),
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }

  void _removeServer(String serverToRemove) {
    setState(() {
      servers.remove(serverToRemove);
      serverPingTimes.remove(serverToRemove);
      if (serversManage.selectedServer == serverToRemove) {
        serversManage.selectServer("#Auto Server");
      }
    });
    _saveServers();
  }

  void _shareServer(String server) {
    Share.share(server);
  }

  void _editServer(String serverToEdit) {
    final originalIndex = servers.indexOf(serverToEdit);
    if (originalIndex == -1) return;

    final controller = TextEditingController(text: servers[originalIndex]);

    showDialog(
      context: context,
      builder: (context) => AppDialogs.buildDialog(
        context: context,
        title: tr('edit-server'),
        contentWidget: TextField(
          controller: controller,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          decoration: InputDecoration(
            hintText: 'Enter server configuration',
            border: InputBorder.none,
            hintStyle: TextStyle(
                color:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
          ),
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('cancel'),
                style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  servers[originalIndex] = controller.text;
                });
                _saveServers();
              }
              Navigator.pop(context);
            },
            child: Text(tr('save'),
                style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          ),
        ],
      ),
    );
  }

  Future<void> _pingServer(String server) async {
    if (server.startsWith('http') || server.startsWith('freedom-guard')) {
      if (mounted) {
        setState(() => serverPingTimes[server] = null);
        await _savePingTimes();
      }
      return;
    }
    setState(() => serverPingTimes[server] = null);
    try {
      final pingResult = await serversManage.pingC(server);
      if (mounted) {
        setState(() => serverPingTimes[server] = pingResult);
        await _savePingTimes();
      }
    } catch (e) {
      if (mounted) {
        setState(() => serverPingTimes[server] = -1);
        await _savePingTimes();
      }
    }
  }

  Future<void> _pingAllServers() async {
    setState(() => isPingingAll = true);
    final batchSize = 5;
    try {
      for (var i = 0; i < servers.length; i += batchSize) {
        final end =
            (i + batchSize < servers.length) ? i + batchSize : servers.length;
        final batch = servers.sublist(i, end);
        await Future.wait(batch.map((server) => _pingServer(server)));
      }
    } finally {
      if (mounted) {
        setState(() => isPingingAll = false);
      }
    }
  }

  void _toggleSortByPing() {
    setState(() {
      sortByPing = !sortByPing;
    });
    _applyFiltersAndSort();
  }

  void _showAddServerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AppDialogs.buildDialog(
        context: context,
        title: tr('add-server'),
        contentWidget: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: serverController,
              decoration: InputDecoration(
                hintText: tr('enter-server-config'),
                border: InputBorder.none,
                hintStyle: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.5)),
              ),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _buildIconButton(
                  icon: Icons.content_paste,
                  tooltip: 'Paste from clipboard',
                  onPressed: () {
                    Navigator.pop(context);
                    _addFromClipboard();
                  },
                ),
                _buildIconButton(
                  icon: Icons.folder_open,
                  tooltip: 'Import from file',
                  onPressed: () {
                    Navigator.pop(context);
                    _importConfigFromFile();
                  },
                ),
                _buildIconButton(
                  icon: Icons.build_rounded,
                  tooltip: 'Add Manual Config',
                  onPressed: () async {
                    final config = await showManualConfigDialog(context);
                    if (config != null) {
                      _addServer(config);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('cancel'),
                style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          ),
          TextButton(
            onPressed: () {
              _addServer(serverController.text);
              Navigator.pop(context);
            },
            child: Text(tr('add'),
                style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          ),
        ],
      ),
    );
  }

  void _importConfigFromFile() async {
    try {
      final result = await FilePicker.platform
          .pickFiles(type: FileType.custom, allowedExtensions: ['txt', 'conf']);
      if (result == null || result.files.single.path == null) return;

      final file = File(result.files.single.path!);
      final content = await file.readAsString();

      if (path.extension(file.path).toLowerCase() == '.conf') {
        _addServer('wire:::\n$content');
      } else {
        final serversFromFile = content
            .split('\n')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        for (final server in serversFromFile) {
          _addServer(server);
        }
      }
      LogOverlay.showLog('File imported successfully.');
    } catch (_) {
      LogOverlay.showLog('Error importing file.');
    }
  }

  void _addFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      final text = clipboardData?.text?.trim();
      if (text == null || text.isEmpty) {
        LogOverlay.showLog('Clipboard is empty.');
        return;
      }

      if (text.startsWith('[Interface]')) {
        _addServer('wire:::\n$text');
      } else {
        final serverList = text
            .split('\n')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        for (final server in serverList) {
          _addServer(server);
        }
      }
    } catch (_) {
      LogOverlay.showLog('Error reading clipboard.');
    }
  }

  void _removeAllServers() {
    showDialog(
      context: context,
      builder: (context) => AppDialogs.buildDialog(
        context: context,
        title: tr('remove-all-servers'),
        content: tr('are-you-sure-you-want-to-delete-all-servers'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('cancel'),
                style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                servers.clear();
                serverPingTimes.clear();
                serversManage.selectServer("#Auto Server");
              });
              _saveServers();
              Navigator.pop(context);
            },
            child: Text(tr('delete'),
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }

  void _removeServersWithoutPing() {
    showDialog(
      context: context,
      builder: (context) => AppDialogs.buildDialog(
        context: context,
        title: tr('remove-servers-without-ping'),
        content: tr('are-you-sure-you-want-to-delete-servers-without-ping'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              tr('cancel'),
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                final serversToRemove = servers.where((server) {
                  final ping = serverPingTimes[server];

                  final isUnreachable = ping == -1;
                  final isHttp = server.startsWith("http://") ||
                      server.startsWith("https://");
                  final isFreedom = server.startsWith("freedom-guard://");
                  final isEmptyConfig = server.split("#")[0].isEmpty;

                  return isUnreachable &&
                      !isHttp &&
                      !isFreedom &&
                      !isEmptyConfig;
                }).toList();

                if (serversToRemove.isNotEmpty) {
                  servers.removeWhere((s) => serversToRemove.contains(s));
                  serverPingTimes
                      .removeWhere((key, _) => serversToRemove.contains(key));

                  if (!servers.contains(serversManage.oldServers())) {
                    serversManage.selectServer("#Auto Server");
                  }
                  _saveServers();
                }
              });
              Navigator.pop(context);
            },
            child: Text(
              tr('delete'),
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAppBarOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildBottomSheet(
        children: [
          ListTile(
            leading: Icon(Icons.refresh,
                color: Theme.of(context).colorScheme.primary),
            title: Text(tr('refresh'),
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            onTap: () {
              Navigator.pop(context);
              _refreshSubscriptions();
            },
          ),
          ListTile(
            leading: Icon(Icons.vpn_key_rounded,
                color: Theme.of(context).colorScheme.secondary),
            title: Text('Encrypt/Decrypt',
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            onTap: () {
              Navigator.pop(context);
              showEncryptDecryptDialog(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.signal_wifi_bad,
                color: Theme.of(context).colorScheme.error),
            title: Text(tr('remove-servers-without-ping'),
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
            onTap: () {
              Navigator.pop(context);
              _removeServersWithoutPing();
            },
          ),
          ListTile(
            leading: Icon(Icons.delete_forever,
                color: Theme.of(context).colorScheme.error),
            title: Text(tr('remove-all-servers'),
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
            onTap: () {
              Navigator.pop(context);
              _removeAllServers();
            },
          ),
        ],
      ),
    );
  }

  void _showServerOptions(BuildContext context, String server) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildBottomSheet(
        children: [
          ListTile(
            leading:
                Icon(Icons.edit, color: Theme.of(context).colorScheme.primary),
            title: Text(tr('edit'),
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            onTap: () {
              Navigator.pop(context);
              _editServer(server);
            },
          ),
          if (server.startsWith("freedom-guard://") ||
              server.startsWith("http"))
            ListTile(
              leading: Icon(Icons.rocket_launch,
                  color: Theme.of(context).colorScheme.primary),
              title: Text('CFG',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface)),
              onTap: () {
                Navigator.pop(context);
                settings.setValue("selectedSubLink", server);
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => CFGPage()));
              },
            ),
          ListTile(
            leading:
                Icon(Icons.share, color: Theme.of(context).colorScheme.primary),
            title: Text(tr('share'),
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            onTap: () {
              Navigator.pop(context);
              _shareServer(server);
            },
          ),
          ListTile(
            leading: Icon(Icons.qr_code,
                color: Theme.of(context).colorScheme.primary),
            title: Text(tr('qr-code'),
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            onTap: () {
              Navigator.pop(context);
              showQRCode(context, server);
            },
          ),
          ListTile(
            leading: Icon(Icons.volunteer_activism,
                color: Theme.of(context).colorScheme.primary),
            title: Text(tr('donate'),
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            onTap: () {
              Navigator.pop(context);
              donateCONFIG(server);
            },
          ),
          ListTile(
            leading:
                Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
            title: Text(tr('delete'),
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
            onTap: () {
              Navigator.pop(context);
              _confirmRemoveServer(server);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPingIndicator(int? ping, BuildContext context, String server) {
    final theme = Theme.of(context);
    String label;
    Color labelColor;
    if (server.startsWith("http")) {
      label = "SUB";
      labelColor = theme.colorScheme.secondary;
    } else if (server.startsWith("freedom-guard")) {
      label = "SUB (FG)";
      labelColor = theme.colorScheme.secondary;
    } else if (server.split("#")[0].isEmpty) {
      label = "Mode";
      labelColor = theme.colorScheme.primary;
    } else if (ping == null) {
      label = "Not Tested";
      labelColor = theme.colorScheme.onSurface.withOpacity(0.7);
    } else if (ping == -1) {
      label = "Unreachable";
      labelColor = theme.colorScheme.error;
    } else {
      Color color;
      if (ping < 200) {
        color = Colors.green;
      } else if (ping < 500) {
        color = Colors.orange;
      } else {
        color = Colors.red;
      }
      String protocol = "Unknown";
      if (server.contains("://")) {
        protocol = server.split("://")[0].toUpperCase();
      }
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            ping < 200
                ? Icons.signal_cellular_4_bar_outlined
                : (ping < 500
                    ? Icons.signal_cellular_alt_2_bar
                    : Icons.signal_cellular_alt_1_bar),
            color: color,
            size: 16,
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(
              '$protocol • ${ping}ms',
              textDirection:
                  getDir() == 'rtl' ? TextDirection.rtl : TextDirection.ltr,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: labelColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: labelColor.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: labelColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildBottomSheet({required List<Widget> children}) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withOpacity(0.2),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border.all(
                color:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.1)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: children,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(
      {required IconData icon,
      required String tooltip,
      required VoidCallback onPressed}) {
    return IconButton(
      icon: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        padding: const EdgeInsets.all(8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Directionality(
      textDirection: getDir() == 'rtl' ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        extendBody: true,
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          elevation: 0,
          title: Text(
            tr('manage-servers-page'),
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimary),
          ),
          actions: [
            IconButton(
              icon: isPingingAll
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: theme.colorScheme.onPrimary),
                    )
                  : Icon(Icons.network_check,
                      color: theme.colorScheme.onPrimary),
              tooltip: 'Ping All',
              onPressed: isPingingAll ? null : _pingAllServers,
            ),
            IconButton(
              icon: Icon(
                Icons.sort,
                color: sortByPing
                    ? theme.colorScheme.secondary
                    : theme.colorScheme.onPrimary,
              ),
              tooltip: 'Sort by Ping',
              onPressed: _toggleSortByPing,
            ),
            IconButton(
              icon: Icon(Icons.add, color: theme.colorScheme.onPrimary),
              tooltip: 'Add Server',
              onPressed: () => _showAddServerDialog(context),
            ),
            IconButton(
              icon: Icon(Icons.more_vert, color: theme.colorScheme.onPrimary),
              tooltip: 'More Options',
              onPressed: () => _showAppBarOptions(context),
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary.withOpacity(0.1),
                theme.colorScheme.secondary.withOpacity(0.1),
              ],
            ),
          ),
          child: isLoading
              ? Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.1)),
                        ),
                        child: CircularProgressIndicator(
                            color: theme.colorScheme.primary),
                      ),
                    ),
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.1)),
                            ),
                            child: TextField(
                              controller: searchController,
                              decoration: InputDecoration(
                                hintText: tr('search-servers'),
                                prefixIcon: Icon(Icons.search,
                                    color: theme.colorScheme.primary),
                                border: InputBorder.none,
                                hintStyle: TextStyle(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.5)),
                              ),
                              style:
                                  TextStyle(color: theme.colorScheme.onSurface),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: filteredServers.isEmpty
                          ? Center(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: BackdropFilter(
                                  filter:
                                      ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surface
                                          .withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                          color: theme.colorScheme.onSurface
                                              .withOpacity(0.1)),
                                    ),
                                    child: Text(
                                      'No servers found!',
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        color: theme.colorScheme.onSurface
                                            .withOpacity(0.6),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.only(
                                  bottom: 80, left: 16, right: 16),
                              itemCount: filteredServers.length,
                              itemBuilder: (context, index) {
                                final server = filteredServers[index];
                                final isSelected =
                                    serversManage.selectedServer == server;
                                final ping = serverPingTimes[server];

                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 6),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.surface
                                            .withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isSelected
                                              ? theme.colorScheme.primary
                                                  .withOpacity(0.3)
                                              : theme.colorScheme.onSurface
                                                  .withOpacity(0.1),
                                          width: 2,
                                        ),
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          splashColor: Colors.transparent,
                                          highlightColor: Colors.transparent,
                                          hoverColor: Colors.transparent,
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          onTap: () async {
                                            await serversManage
                                                .selectServer(server);
                                            if (mounted) setState(() {});
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 16),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        getNameByConfig(server),
                                                        style: theme.textTheme
                                                            .titleMedium
                                                            ?.copyWith(
                                                          fontWeight: isSelected
                                                              ? FontWeight.bold
                                                              : FontWeight
                                                                  .normal,
                                                          color: theme
                                                              .colorScheme
                                                              .onSurface,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                      const SizedBox(height: 4),
                                                      _buildPingIndicator(ping,
                                                          context, server),
                                                    ],
                                                  ),
                                                ),
                                                _buildIconButton(
                                                  icon: Icons.network_check,
                                                  tooltip: 'Ping Server',
                                                  onPressed: () =>
                                                      _pingServer(server),
                                                ),
                                                _buildIconButton(
                                                  icon: Icons.more_vert,
                                                  tooltip: 'Options',
                                                  onPressed: () =>
                                                      _showServerOptions(
                                                          context, server),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
