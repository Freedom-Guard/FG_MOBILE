import 'dart:io';
import 'package:Freedom_Guard/components/LOGLOG.dart';
import 'package:Freedom_Guard/components/servers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:qr_flutter/qr_flutter.dart';

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
    await serversManage.selectServer(selectedServer!);
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
    Share.share(server);
  }

  void _editServer(int index) {
    TextEditingController controller = TextEditingController(
      text: servers[index],
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(title: const Text("Edit Server"),
          content: TextField(controller: controller,
            decoration: const InputDecoration(hintText: "New server name"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty)
                {

                  setState(() {
                    servers[index] = controller.text;
                    _saveServers();
                  });
                }
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _showAddServerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Server',
            style: TextStyle(fontWeight: FontWeight.bold),),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.text_fields, color: Colors.blue),
                title: const Text('Add from Text'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddServerFromTextDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(
                    Icons.paste_outlined, color: Colors.green),
                title: const Text('Add from Clipboard'),
                onTap: () {
                  Navigator.pop(context);
                  _addFromClipboard();
                },

              ),
              ListTile(
                leading: const Icon(Icons.folder_open, color: Colors.orange),
                title: const Text('Add From File'),
                onTap: () {
                  Navigator.pop(context);
                  _importConfigFromFile();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddServerFromTextDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Add Server from Text"),
          content: SizedBox(
            width: double.maxFinite,
            child: TextField(
              controller: serverController,
              maxLines: 10,
              decoration: const InputDecoration(hintText: "Config"),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Add"),
              onPressed: () {
                for (var server in serverController.text.split("\n")) {
                  _addServer(server);
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  String safeDecode(String text) {
    try {
      return Uri.decodeFull(text);
    } catch (e) {
      return text;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Servers"),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
            onPressed: () => _removeAllServers(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () async {
              await serversManage.loadServers();
              await _loadServers();
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddServerDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child:
                servers.isEmpty
                    ? const Center(
                      child: Text(
                        "No servers added yet!",
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
                            vertical: 8,
                            horizontal: 12,
                          ),
                          color:
                              isSelected
                                  ? const Color(0xFF64B5F6)
                                  : const Color(0xFF212121),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                  color:
                                      isSelected
                                          ? const Color(0xFF42A5F5)
                                          : Colors.transparent,
                                  width: 4,
                                ),
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: ListTile(
                                      onTap: () async {
                                        await serversManage.selectServer(
                                          server,
                                        );
                                        setState(() {});
                                      },
                                      title: Text(
                                        (server.split("#").length > 1
                                            ? safeDecode(server.split("#")[1])
                                            : server.split("#")[0].length > 10
                                            ? "${server.split("#")[0].substring(0, 10)}..."
                                            : server.split("#")[0]),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight:
                                              isSelected
                                                  ? FontWeight.w500
                                                  : FontWeight.w400,
                                          color:
                                              isSelected
                                                  ? Colors.white
                                                  : Colors.grey.shade100,
                                        ),
                                      ),
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                  PopupMenuButton<String>(
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
                                        case 'qr':
                                          _showQRCodeDialog(server);
                                          break;
                                      }
                                    },
                                    itemBuilder:
                                        (
                                          BuildContext context,
                                        ) => <PopupMenuEntry<String>>[
                                          PopupMenuItem<String>(
                                            value: 'edit',
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.edit,
                                                  size: 20,
                                                  color: Color(0xFF757575),
                                                ),
                                                const SizedBox(width: 8),
                                                const Text(
                                                  'ویرایش',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Color(0xFF212121),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem<String>(
                                            value: 'share',
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.share_outlined,
                                                  size: 20,
                                                  color: Color(0xFF757575),
                                                ),
                                                const SizedBox(width: 8),
                                                const Text(
                                                  'اشتراک',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Color(0xFF212121),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem<String>(
                                            value: 'qr',
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.qr_code_2_outlined,
                                                  size: 20,
                                                  color: Color(0xFF757575),
                                                ),
                                                const SizedBox(width: 8),
                                               const Text(
                                                  'کد qr',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Color(0xFF212121),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem<String>(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.delete,
                                                  size: 20,
                                                  color: Color(0xFFE57373),
                                                ),
                                                const SizedBox(width: 8),
                                                const Text(
                                                  'حذف',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Color(0xFF212121),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                    icon: Icon(
                                      Icons.more_vert,
                                      size: 20,
                                      color:
                                          isSelected
                                              ? Colors.white
                                              : Colors.grey.shade300,
                                    ),
                                    color: const Color(0xFFFFFFFF),
                                    elevation: 1,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
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
    );
  }

  void _importConfigFromFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      File file = File(result.files.single.path!);
      if (path.extension(file.path) == '.txt') {
        String fileContent = await file.readAsString();
        List<String> serversFromFile = fileContent.split('\n');
        serversFromFile.forEach((server) {
          if (server.trim().isNotEmpty) {
            _addServer(server.trim());
          }
        });
        LogOverlay.showLog('file imported successfully.');
      } else if (path.extension(file.path) == '.conf') {
        String fileContent = await file.readAsString();
        _addServer("wire:::\n" + fileContent);
        LogOverlay.showLog('فایل با موفقیت وارد شد.');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فایل انتخاب شده معتبر نمی باشد.')),
        );
      }
    }
  }

  void _addFromClipboard() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData == null || clipboardData.text == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'clipboard is empty.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.lightBlueAccent,
        ),
      );
      return;
    }
    if (clipboardData.text!.startsWith("[Interface]")) {
      _addServer("wire:::\n" + clipboardData.text!);
    }
    for (var server in clipboardData.text!.split("\n")) {
      _addServer(server);
    }
  }

  void _removeAllServers() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove all servers'),
          content: const Text('Are you sure you want to delete all servers?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                setState(() {
                  servers.clear();
                  _saveServers();
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showQRCodeDialog(String text) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          alignment: Alignment.center,
          title: const Text('QR Code'),
          content: QrImageView(
            data: text.toString(),
            version: QrVersions.auto,
            size: 200.0,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
