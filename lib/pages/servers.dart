import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../components/servers.dart';

class ServersPage extends StatefulWidget {
  const ServersPage({super.key});

  @override
  State<ServersPage> createState() => _ServersPageState();
}

class _ServersPageState extends State<ServersPage> {
  List<String> servers = [];
  serversM serversManage = serversM();

  @override
  void initState() {
    super.initState();
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
      Map<String, dynamic> oldServersMap = await serversManage.oldServers();
      final oldServers = oldServersMap.keys.toList();
      await prefs.setStringList('servers', oldServers);
      await _loadServers();
    } catch (e) {
      await _loadServers();
    }
  }

  Future<void> _restoreSelectedServer() async {
    final prefs = await SharedPreferences.getInstance();
    String? selectedServer = prefs.getString('selectedServer');
    if (selectedServer != null) {
      serversManage.selectServer(selectedServer);
    }
  }

  Future<void> _loadServers() async {
    final prefs = await SharedPreferences.getInstance();
    final serverList = prefs.getStringList('servers') ?? [];
    setState(() => servers = serverList);
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
      setState(() {
        servers.add(serverName);
        _saveServers();
      });
    }
  }

  void _removeServer(int index) {
    setState(() {
      servers.removeAt(index);
      _saveServers();
    });
  }

  @override
  Widget build(BuildContext context) {
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
                      labelStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
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
                return Card(
                  child: ListTile(
                    onTap: () {
                      serversManage.selectServer(servers[index]);
                    },
                    title: Text(
                      servers[index] +
                          (servers[index] == (serversManage.getSelectedServer())
                              ? ' (selected)'
                              : ''),
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
