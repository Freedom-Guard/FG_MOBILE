// Suggested code may be subject to a license. Learn more: ~LicenseLog:3911754807.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:1482143165.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../components/servers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ServersPage extends StatefulWidget {
  const ServersPage({super.key});

  @override
  State<ServersPage> createState() => _ServersPageState();
}

class _ServersPageState extends State<ServersPage> {
  List<String> servers = [];
  late ServersM serversManage;
  final TextEditingController serverController = TextEditingController();

  @override
  void initState() {
    super.initState();
    serversManage = Provider.of<ServersM>(context, listen: false);
    Future.microtask(() async {
      await serversManage.getSelectedServer();
      await _loadServersAndInit();
    });
  }

  Future<void> _loadServersAndInit() async {
    await _restoreServers();
    await _restoreSelectedServer();
  }

  Future<void> _restoreServers() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('servers') ||
        (prefs.getStringList('servers') ?? []).isEmpty) {
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
    } catch (_) {
    } finally {
      await _loadServers();
    }
  }

  Future<void> _restoreSelectedServer() async {
    final prefs = await SharedPreferences.getInstance();
    String? selectedServer = prefs.getString('selectedServer');
    if (selectedServer != null) {
      await serversManage.selectServer(selectedServer);
    }
  }

  Future<void> _loadServers() async {
    final prefs = await SharedPreferences.getInstance();
    final serverList = prefs.getStringList('servers') ?? [];
    if (mounted) setState(() => servers = serverList);
  }

  Future<void> _saveServers() async {
    final prefs = await SharedPreferences.getInstance();
    if (servers.isEmpty) {
      await prefs.remove('servers');
    } else {
      await prefs.setStringList('servers', servers);
    }
  }

  void _addServer(String serverName) {
    if (serverName.isNotEmpty && !servers.contains(serverName)) {
      setState(() {
        servers.add(serverName);
        _saveServers();
      });
      serverController.clear();
    }
  }

  void _removeServer(int index) {
    if (mounted) {
      serversManage.selectServer("");
      setState(() {
        servers.removeAt(index);
        _saveServers();
      });
    }
  }

  void _shareServer(String server) {
    Share.share('سرور من: $server');
  }

  void _editServer(int index) {
    TextEditingController controller = TextEditingController(
      text: servers[index],
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("ویرایش سرور"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: "نام جدید سرور"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("لغو"),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  setState(() {
                    servers[index] = controller.text;
                    _saveServers();
                  });
                }
                Navigator.pop(context);
              },
              child: const Text("ذخیره"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final serversManage = Provider.of<ServersM>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("مدیریت سرورها"),
        backgroundColor: Colors.black,
        centerTitle: true,
      ),
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
                        borderSide: const BorderSide(
                          color: Colors.blue,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                      prefixIcon: const Icon(Icons.link, color: Colors.blue),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.blue),
                  onPressed: () => _addServer(serverController.text),
                ),
              ],
            ),
          ),
          Expanded(
            child:
                servers.isEmpty
                    ? const Center(
                      child: Text(
                        "هیچ سروری اضافه نشده است!",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                    : ListView.builder(
                      itemCount: servers.length,
                      itemBuilder: (context, index) {
                        String server = servers[index];
                        bool isSelected =
                            serversManage.selectedServer == server;

                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 10,
                          ),
                          color:
                              isSelected
                                  ? const Color(0xFFB2DFDB)
                                  : const Color.fromARGB(106, 29, 13, 39),
                          child: ListTile(
                            onTap: () async {
                              await serversManage.selectServer(server);
                              setState(() {});
                            },
                            title: Text(
                              (server.split("#").length > 1
                                      ? server.split("#")[1]
                                      : server.split("#")[0]) +
                                  (isSelected ? ' (انتخاب شده)' : ''),
                              style: TextStyle(
                                fontWeight:
                                    isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                color: isSelected ? Colors.blue : Colors.white,
                              ),
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (String result) {
                                switch (result) {
                                  case 'edit':
                                    _editServer(index);
                                    break;
                                  case 'share':
                                    _shareServer(server);
                                    break;
                                  case 'delete':
                                    _removeServer(index);
                                    break;
                                }
                              },
                              itemBuilder:
                                  (BuildContext context) =>
                                      <PopupMenuEntry<String>>[
                                        const PopupMenuItem<String>(
                                          value: 'edit',
                                          child: Text('ویرایش'),
                                        ),
                                        const PopupMenuItem<String>(
                                          value: 'share',
                                          child: Text('اشتراک'),
                                        ),
                                        const PopupMenuItem<String>(
                                          value: 'delete',
                                          child: Text('حذف'),
                                        ),
                                      ],
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
