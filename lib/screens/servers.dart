import 'dart:convert';
import 'dart:io';
import 'package:Freedom_Guard/components/f-link.dart';
import 'package:Freedom_Guard/components/local.dart';
import 'package:Freedom_Guard/components/servers.dart';
import 'package:Freedom_Guard/components/settings.dart';
import 'package:Freedom_Guard/widgets/encrypt.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:qr_flutter/qr_flutter.dart';

class ServersPage extends StatefulWidget {
  @override
  State<ServersPage> createState() => _ServersPageState();
}

class _ServersPageState extends State<ServersPage> {
  bool isLoading = true;
  List<String> servers = [];
  List<String> filteredServers = [];
  late ServersM serversManage;
  late Settings settings;
  final TextEditingController serverController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  final Map<String, int?> serverPingTimes = {};
  bool isPingingAll = false;
  bool sortByPing = false;

  @override
  void initState() {
    super.initState();
    settings = Settings();
    serversManage = Provider.of<ServersM>(context, listen: false);
    searchController.addListener(_applyFiltersAndSort);
    Future.microtask(_loadServersAndInit);
  }

  @override
  void dispose() {
    serverController.dispose();
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadServersAndInit() async {
    try {
      await serversManage.getSelectedServer();
      await _restoreServers(initialLoad: true);
      await _restorePingTimes();
      await _restoreSelectedServer();
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
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

  String getNameByConfig(String config) {
    try {
      final decodedConfig = Uri.decodeFull(config);
      final utf8Decoded = utf8.decode(decodedConfig.runes.toList());
      final decoded = jsonDecode(utf8Decoded);
      return decoded['remarks']?.toString() ?? _extractNameFromConfig(config);
    } catch (_) {
      return _extractNameFromConfig(config);
    }
  }

  String _extractNameFromConfig(String config) {
    try {
      final uriDecoded = Uri.decodeFull(config);
      final hashIndex = uriDecoded.lastIndexOf('#');
      if (hashIndex != -1 && hashIndex < uriDecoded.length - 1) {
        final name = uriDecoded.substring(hashIndex + 1);
        return name.trim().isNotEmpty ? name.trim() : 'Unnamed Server';
      }
      return 'Unnamed Server';
    } catch (_) {
      return 'Unnamed Server';
    }
  }

  void _addServer(String serverName) {
    if (serverName.isNotEmpty && !servers.contains(serverName)) {
      setState(() {
        servers.insert(0, serverName);
      });
      serversManage.selectServer(serverName);
      _saveServers();
      serverController.clear();
    }
  }

  void _confirmRemoveServer(String serverToRemove) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('delete-server')),
        content: Text(tr('are-you-sure-you-want-to-delete-this-server')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('cancel')),
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
      builder: (context) => AlertDialog(
        title: Text(tr('edit-server')),
        content: TextField(
          controller: controller,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          decoration: const InputDecoration(
            hintText: 'Enter server configuration',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('cancel')),
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
            child: Text(tr('save')),
          ),
        ],
      ),
    );
  }

  Future<void> _pingServer(String server) async {
    if (server.startsWith('http')) {
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
      builder: (context) => AlertDialog(
        title: Text(tr('add-server')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: serverController,
              decoration: InputDecoration(hintText: tr('enter-server-config')),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.content_paste),
                  tooltip: 'Paste from clipboard',
                  onPressed: () {
                    Navigator.pop(context);
                    _addFromClipboard();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.folder_open),
                  tooltip: 'Import from file',
                  onPressed: () {
                    Navigator.pop(context);
                    _importConfigFromFile();
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('cancel')),
          ),
          TextButton(
            onPressed: () {
              _addServer(serverController.text);
              Navigator.pop(context);
            },
            child: Text(tr('add')),
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
      _showSnackBar('File imported successfully.');
    } catch (_) {
      _showSnackBar('Error importing file.');
    }
  }

  void _addFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      final text = clipboardData?.text?.trim();
      if (text == null || text.isEmpty) {
        _showSnackBar('Clipboard is empty.');
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
      _showSnackBar('Error reading clipboard.');
    }
  }

  void _removeAllServers() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('remove-all-servers')),
        content: Text(tr('are-you-sure-you-want-to-delete-all-servers')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(tr('cancel'))),
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

  void _showQRCode(String text) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: SizedBox(
          width: 250,
          height: 250,
          child: Center(
            child: QrImageView(
              data: text,
              version: QrVersions.auto,
              size: 200,
              backgroundColor: Colors.white,
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'))
        ],
      ),
    );
  }

  void _showAppBarOptions(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Refresh'),
              onTap: () {
                Navigator.pop(context);
                _refreshSubscriptions();
              },
            ),
            ListTile(
              leading: Icon(Icons.vpn_key_rounded,
                  color: theme.colorScheme.secondary),
              title: const Text('Encrypt/Decrypt'),
              onTap: () {
                Navigator.pop(context);
                showEncryptDecryptDialog(context);
              },
            ),
            ListTile(
              leading:
                  Icon(Icons.delete_forever, color: theme.colorScheme.error),
              title: Text('Delete All Servers',
                  style: TextStyle(color: theme.colorScheme.error)),
              onTap: () {
                Navigator.pop(context);
                _removeAllServers();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showServerOptions(BuildContext context, String server) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
          child: Directionality(
        textDirection:
            getDir() == 'rtl' ? TextDirection.rtl : TextDirection.ltr,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
                leading: const Icon(Icons.edit),
                title: Text(tr('edit')),
                onTap: () {
                  Navigator.pop(context);
                  _editServer(server);
                }),
            ListTile(
                leading: const Icon(Icons.share),
                title: Text(tr('share')),
                onTap: () {
                  Navigator.pop(context);
                  _shareServer(server);
                }),
            ListTile(
                leading: const Icon(Icons.qr_code),
                title: Text(tr('qr-code')),
                onTap: () {
                  Navigator.pop(context);
                  _showQRCode(server);
                }),
            ListTile(
                leading: const Icon(Icons.volunteer_activism),
                title: Text(tr('donate')),
                onTap: () {
                  Navigator.pop(context);
                  donateCONFIG(server);
                }),
            ListTile(
              leading: Icon(Icons.delete, color: theme.colorScheme.error),
              title: Text(tr('delete'),
                  style: TextStyle(color: theme.colorScheme.error)),
              onTap: () {
                Navigator.pop(context);
                _confirmRemoveServer(server);
              },
            ),
          ],
        ),
      )),
    );
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildPingIndicator(int? ping, BuildContext context, String Server) {
    final theme = Theme.of(context);
    if (ping == null)
      return Text(Server.startsWith("http") ? 'SUB' : 'Not tested',
          style: TextStyle(
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.7)));
    if (ping == -1)
      return Text('Unreachable',
          style: TextStyle(color: theme.colorScheme.error));

    Color color;
    if (ping < 200) {
      color = Colors.green;
    } else if (ping < 500) {
      color = Colors.orange;
    } else {
      color = Colors.red;
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
        Text('${ping}ms',
            textDirection:
                getDir() == 'rtl' ? TextDirection.rtl : TextDirection.ltr,
            style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Directionality(
      textDirection: getDir() == 'rtl' ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr('manage-servers-page')),
          actions: [
            IconButton(
              icon: isPingingAll
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: theme.colorScheme.onPrimary))
                  : const Icon(Icons.network_check),
              tooltip: 'Ping All',
              onPressed: isPingingAll ? null : _pingAllServers,
            ),
            IconButton(
              icon: Icon(Icons.sort,
                  color: sortByPing
                      ? theme.colorScheme.secondary
                      : theme.colorScheme.onPrimary),
              tooltip: 'Sort by Ping',
              onPressed: _toggleSortByPing,
            ),
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Add Server',
              onPressed: () => _showAddServerDialog(context),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert),
              tooltip: 'More Options',
              onPressed: () => _showAppBarOptions(context),
            ),
          ],
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: tr('search-servers'),
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none),
                        filled: true,
                        fillColor:
                            theme.colorScheme.surfaceVariant.withOpacity(0.5),
                      ),
                    ),
                  ),
                  Expanded(
                    child: filteredServers.isEmpty
                        ? Center(
                            child: Text('No servers found!',
                                style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.6))),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 80),
                            itemCount: filteredServers.length,
                            itemBuilder: (context, index) {
                              final server = filteredServers[index];
                              final isSelected =
                                  serversManage.selectedServer == server;
                              final ping = serverPingTimes[server];

                              return Card(
                                clipBehavior: Clip.antiAlias,
                                elevation: isSelected ? 4 : 2,
                                margin: const EdgeInsets.symmetric(
                                    vertical: 6, horizontal: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                      color: isSelected
                                          ? theme.colorScheme.primary
                                          : Colors.transparent,
                                      width: 1.5),
                                ),
                                child: InkWell(
                                  onTap: () async {
                                    await serversManage.selectServer(server);
                                    if (mounted) setState(() {});
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 12),
                                    child: Row(
                                      children: [
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                getNameByConfig(server),
                                                style: theme
                                                    .textTheme.titleMedium
                                                    ?.copyWith(
                                                        fontWeight: isSelected
                                                            ? FontWeight.bold
                                                            : FontWeight
                                                                .normal),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              _buildPingIndicator(
                                                  ping, context, server),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                            icon:
                                                const Icon(Icons.network_check),
                                            tooltip: 'Ping Server',
                                            onPressed: () =>
                                                _pingServer(server)),
                                        IconButton(
                                          icon: const Icon(Icons.more_vert),
                                          tooltip: 'Options',
                                          onPressed: () => _showServerOptions(
                                              context, server),
                                        ),
                                      ],
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
    );
  }
}
