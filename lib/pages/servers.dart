import 'dart:convert';
import 'dart:io';
import 'package:Freedom_Guard/components/LOGLOG.dart';
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
  late ServersM serversManage;
  late Settings settings;
  final TextEditingController serverController = TextEditingController();
  final Map<String, int?> serverPingTimes = {};
  bool isPingingAll = false;
  bool sortByPing = false;

  @override
  void initState() {
    super.initState();
    settings = Settings();
    serversManage = Provider.of<ServersM>(context, listen: false);
    Future.microtask(_loadServersAndInit);
  }

  @override
  void dispose() {
    serverController.dispose();
    super.dispose();
  }

  Future<void> _loadServersAndInit() async {
    try {
      await serversManage.getSelectedServer();
      await _restoreServers();
      await _restorePingTimes();
      await _restoreSelectedServer();
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
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

  Future<void> _restoreServers() async {
    final prefs = await SharedPreferences.getInstance();
    final serverList = prefs.getStringList('servers') ?? [];
    if (serverList.isEmpty) {
      await _setDefaultServers();
    } else {
      if (mounted) setState(() => servers = serverList);
    }
  }

  Future<void> _setDefaultServers() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final oldServers = await serversManage.oldServers();
      await prefs.setStringList('servers', oldServers);
      if (mounted) setState(() => servers = oldServers);
    } catch (_) {
      if (mounted) setState(() => servers = []);
    }
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
    var decoded = "";
    try {
      decoded = utf8.decode(Uri.decodeFull(config).runes.toList());
    } catch (_) {
      decoded = config;
    }
    return decoded.contains('#') ? decoded.split('#').last : decoded;
  }

  void _addServer(String serverName) {
    if (serverName.isNotEmpty && !servers.contains(serverName)) {
      setState(() {
        servers.insert(0, serverName);
      });
      serversManage.selectServer(serverName);
      _saveServers();
      serverController.clear();
      if (mounted) setState(() {});
      LogOverlay.showLog('Server added successfully.');
    }
  }

  void _removeServer(int index) {
    if (index >= 0 && index < servers.length) {
      final removedServer = servers[index];
      setState(() {
        servers.removeAt(index);
        serverPingTimes.remove(removedServer);
      });
      if (serversManage.selectedServer == removedServer) {
        serversManage.selectServer('');
      }
      _saveServers();
    }
  }

  void _shareServer(String server) {
    Share.share(server);
  }

  void _editServer(int index) {
    if (index < 0 || index >= servers.length) return;
    final controller = TextEditingController(text: servers[index]);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Server'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'New server name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  servers[index] = controller.text;
                });
                _saveServers();
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _pingServer(String server) async {
    if (server.startsWith('http')) {
      if (mounted) {
        setState(() {
          serverPingTimes[server] = null;
        });
        await _savePingTimes();
      }
      return;
    }
    try {
      final pingResult = await serversManage.pingC(server);
      if (mounted) {
        setState(() {
          serverPingTimes[server] = pingResult;
        });
        await _savePingTimes();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          serverPingTimes[server] = -1;
        });
        await _savePingTimes();
      }
    }
  }

  Future<void> _pingAllServers() async {
    setState(() => isPingingAll = true);
    final batchSize = 3;
    for (var i = 0; i < servers.length; i += batchSize) {
      final batch =
          servers.sublist(i, (i + batchSize).clamp(0, servers.length));
      await Future.wait(batch.map((server) => _pingServer(server)));
    }
    if (mounted) {
      setState(() => isPingingAll = false);
    }
  }

  void _toggleSortByPing() {
    setState(() {
      sortByPing = !sortByPing;
      if (sortByPing) {
        servers.sort((a, b) {
          final pingA =
              serverPingTimes[a] == -1 ? 9999 : serverPingTimes[a] ?? 9999;
          final pingB =
              serverPingTimes[b] == -1 ? 9999 : serverPingTimes[b] ?? 9999;
          return pingA.compareTo(pingB);
        });
      } else {
        _restoreServers();
      }
    });
  }

  void _showAddServerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Server'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: serverController,
              decoration:
                  const InputDecoration(hintText: 'Enter server config'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _addFromClipboard();
                  },
                  icon: const Icon(
                    Icons.content_paste,
                    size: 32,
                  ),
                  label: const Text(''),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    iconColor: Colors.white,
                    textStyle: const TextStyle(fontSize: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _importConfigFromFile();
                  },
                  icon: const Icon(
                    Icons.folder_open,
                    size: 32,
                  ),
                  label: const Text(''),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    iconColor: Colors.white,
                    textStyle: const TextStyle(fontSize: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _addServer(serverController.text);
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _importConfigFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result == null || result.files.single.path == null) return;

      final file = File(result.files.single.path!);
      final extension = path.extension(file.path).toLowerCase();

      if (extension == '.txt') {
        final content = await file.readAsString();
        final serversFromFile = content
            .split('\n')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        for (final server in serversFromFile) {
          _addServer(server);
        }
        LogOverlay.showLog('File imported successfully.');
      } else if (extension == '.conf') {
        final content = await file.readAsString();
        _addServer('wire:::\n$content');
        LogOverlay.showLog('File imported successfully.');
      } else {
        _showSnackBar('Invalid file format.');
      }
    } catch (_) {
      _showSnackBar('Error importing file.');
    }
  }

  void _addFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData == null ||
          clipboardData.text == null ||
          clipboardData.text!.isEmpty) {
        _showSnackBar('Clipboard is empty.');
        return;
      }

      final text = clipboardData.text!.trim();
      if (text.startsWith('[Interface]')) {
        _addServer('wire:::\n$text');
      } else if (['vless', 'vmess', 'ss', 'trojan'].any(text.startsWith)) {
        final serverList = text
            .split('\n')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        for (final server in serverList) {
          _addServer(server);
        }
      } else {
        _addServer(text);
      }
    } catch (_) {
      _showSnackBar('Error reading clipboard.');
    }
  }

  void _removeAllServers() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove All Servers'),
        content: const Text('Are you sure you want to delete all servers?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                servers.clear();
                serverPingTimes.clear();
              });
              serversManage.selectServer('');
              _saveServers();
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showQRCode(String text) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QR Code'),
        content: QrImageView(
          data: text,
          version: QrVersions.auto,
          size: 200,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.lightBlueAccent,
      ),
    );
  }

  void _showServerOptions(String server, int index) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                _editServer(index);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(context);
                _shareServer(server);
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code),
              title: const Text('Show QR Code'),
              onTap: () {
                Navigator.pop(context);
                _showQRCode(server);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _removeServer(index);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: getDir() == 'rtl' ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr("")),
          backgroundColor: Colors.black,
          actions: [
            IconButton(
              icon: Icon(
                Icons.vpn_key_rounded,
                color: Colors.redAccent,
              ),
              onPressed: () => {showEncryptDecryptDialog(context)},
            ),
            IconButton(
              icon: isPingingAll
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white70,
                        strokeWidth: 1.5,
                        strokeCap: StrokeCap.round,
                      ),
                    )
                  : const Icon(Icons.network_check),
              onPressed: isPingingAll ? null : _pingAllServers,
            ),
            IconButton(
              icon: Icon(
                Icons.sort,
                color: sortByPing ? Colors.blueAccent : Colors.white,
              ),
              onPressed: _toggleSortByPing,
            ),
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
              onPressed: _removeAllServers,
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () async {
                await serversManage.loadServers();
                await _restoreServers();
              },
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showAddServerDialog(context),
            ),
          ],
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : servers.isEmpty
                ? const Center(
                    child: Text(
                      'No servers added yet!',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: servers.length,
                    itemBuilder: (context, index) {
                      final server = servers[index];
                      final isSelected = serversManage.selectedServer == server;
                      final ping = serverPingTimes[server];
                      return Card(
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 16),
                        color: const Color(0xFF1C1C1E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isSelected
                                ? Colors.blueAccent
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: InkWell(
                          onTap: () async {
                            await serversManage.selectServer(server);
                            if (mounted) setState(() {});
                          },
                          borderRadius: BorderRadius.circular(16),
                          splashColor: Colors.blueAccent.withOpacity(0.3),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        getNameByConfig(server),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected
                                              ? Colors.blueAccent
                                              : Colors.white,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.signal_cellular_alt,
                                            size: 16,
                                            color: ping == null
                                                ? Colors.grey
                                                : ping == -1
                                                    ? Colors.red
                                                    : ping < 100
                                                        ? Colors.green
                                                        : Colors.orange,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            ping == null
                                                ? servers[index]
                                                        .startsWith('http')
                                                    ? 'SUB'
                                                    : 'Not tested'
                                                : ping == -1
                                                    ? 'Unreachable'
                                                    : '${ping}ms',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade400,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.network_check,
                                      color: Colors.green),
                                  onPressed: () => _pingServer(server),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.more_vert,
                                      color: Colors.white),
                                  onPressed: () =>
                                      _showServerOptions(server, index),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
