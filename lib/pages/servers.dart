import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../components/servers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ServersPage extends StatefulWidget {
  const ServersPage({super.key});

  @override
  State<ServersPage> createState() => _ServersPageState();
}

class _ServersPageState extends State<ServersPage> {
  List<String> servers = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final serversManage = Provider.of<ServersM>(context, listen: false);
      serversManage.getSelectedServer();
    });
    _loadServersAndInit();
  }

  Future<void> _loadServersAndInit() async {
    await _restoreServers();
    await _restoreSelectedServer();
  }

  Future<void> _restoreServers() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('servers') ||
        prefs.getStringList('servers')!.isEmpty) {
      await _setOldServers();
    } else {
      await _loadServers();
    }
  }

  Future<void> _setOldServers() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final serversManage = context.read<ServersM>();
      Map<String, dynamic> oldServersMap = await serversManage.oldServers();
      final oldServers = oldServersMap.keys.toList();
      await prefs.setStringList('servers', oldServers);
    } catch (_) {
    } finally {
      await _loadServers();
    }
  }

  Future<void> _restoreSelectedServer() async {
    final prefs = await SharedPreferences.getInstance();
    final serversManage = Provider.of<ServersM>(context, listen: false);
    String? selectedServer = prefs.getString('selectedServer');
    if (selectedServer != null) {
      await serversManage.selectServer(selectedServer);
    }
  }

  Future<void> _loadServers() async {
    final prefs = await SharedPreferences.getInstance();
    final serverList = prefs.getStringList('servers') ?? [];
    if (mounted) {
      setState(() => servers = serverList);
    } else {
      servers = serverList;
    }
  }

  Future<void> _saveServers() async {
    final prefs = await SharedPreferences.getInstance();
    if (servers.isEmpty) {
      await prefs.remove('servers');
      return;
    }
    await prefs.setStringList('servers', servers);
  }

  void _addServer(String serverName) {
    if (serverName.isNotEmpty) {
      if (mounted) {
        setState(() {
          servers.add(serverName);
          _saveServers();
        });
      }
    }
  }

  void _removeServer(int index) {
    if (mounted) {
      setState(() {
        servers.removeAt(index);
        _saveServers();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final serversManage = Provider.of<ServersM>(context);
    TextEditingController serverController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text("مدیریت سرورها")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: serverController,
                    decoration: InputDecoration(
                      labelText: "لینک سرور",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blue, width: 2),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                      prefixIcon: Icon(Icons.link, color: Colors.blue),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.blue),
                  onPressed: () {
                    _addServer(serverController.text);
                    serverController.clear();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: servers.length,
              itemBuilder: (context, index) {
                final server = servers[index];
                final isSelected = server == serversManage.selectedServer;
                return Card(
                  color: isSelected ? Colors.blue.shade100 : null,
                  child: ListTile(
                    onTap: () async {
                      await serversManage.selectServer(server);
                      if (mounted) {
                        setState(() {});
                      }
                    },
                    title: Text(
                      server + (isSelected ? ' (انتخاب شده)' : ''),
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.blue : Colors.black,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeServer(index),
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
}
