// Suggested code may be subject to a license. Learn more: ~LicenseLog:3623181278.
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
    _initServers();
  }

  Future<void> _initServers() async {
    final prefs = await SharedPreferences.getInstance();

    if (!prefs.containsKey('servers') ||
        prefs.getStringList('servers')!.isEmpty) {
      final oldServersMap = await serversManage.oldServers();
      final oldServers = oldServersMap.keys.toList();
      await prefs.setStringList('servers', oldServers);
    }

    _loadServers();
  }

  Future<void> _loadServers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      servers = (prefs.getStringList('servers') ?? []);
    });
  }

  Future<void> _saveServers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
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
                    decoration: const InputDecoration(
                      labelText: "لینک سرور",
                      border: OutlineInputBorder(),
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
                    onTap: () => serversManage.selectServer(servers[index]),
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
