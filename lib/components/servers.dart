import 'dart:convert';
import 'dart:io';
import 'package:Freedom_Guard/components/LOGLOG.dart';
import 'package:Freedom_Guard/components/settings.dart';
import 'package:Freedom_Guard/components/connect.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ServersM extends ChangeNotifier {
  String? selectedServer;
  Settings settings = new Settings();
  Connect connect = new Connect();
  ServersM() {
    _loadSelectedServer();
    loadServers();
  }

  Future<void> loadServers() async {
    bool success = await addServerFromUrl(
      "https://raw.githubusercontent.com/Freedom-Guard/Freedom-Guard/refs/heads/main/config/index.json",
    );
    if (success) {
      notifyListeners();
    }
  }

  Future<void> _loadSelectedServer() async {
    final prefs = await SharedPreferences.getInstance();
    selectedServer = prefs.getString('selectedServer') ?? "";
    notifyListeners();
  }

  Future<bool> selectServer(String server) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selectedServer', server);
      selectedServer = server;
      if (selectedServer!.split("#")[0] == "") {
        settings.setValue("core_vpn", "auto");
      } else if (selectedServer!.startsWith("wireguard")) {
        settings.setValue("core_vpn", "warp");
      } else {
        settings.setValue("core_vpn", "vibe");
      }
      notifyListeners();
      showPing(server);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> showPing(server) async {
    try {
      if (server.split("#")[0] == "") return;
      LogOverlay.showLog(
        "ping: " + (await connect.testConfig(server)).toString(),
        backgroundColor: Colors.blueAccent,
      );
    } catch (e) {}
  }

  Future<bool> addServerFromUrl(String url) async {
    try {
      final response = await HttpClient()
          .getUrl(Uri.parse(url))
          .then((req) => req.close())
          .then((res) => res.transform(utf8.decoder).join());

      final decoded = jsonDecode(response);
      if (decoded is! Map<String, dynamic> || decoded['MOBILE'] is! List) {
        return false;
      }

      List<String> newServers = List<String>.from(decoded['MOBILE'].toList());
      List oldData = await oldServers();
      List<String> currentServers = List<String>.from(oldData ?? []);

      bool isUpdated = false;

      for (String server in newServers) {
        server = server.split(",;,")[0] == "warp" ? '' : server.split(",;,")[1];
        if (!currentServers.contains(server) && server.split("#").length > 1) {
          currentServers.add(server);
          isUpdated = true;
          notifyListeners();
        }
      }

      if (isUpdated) {
        await saveServers(currentServers);
      }

      return isUpdated;
    } catch (e) {
      return false;
    }
  }

  Future<List<String>> oldServers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final serverList = prefs.getStringList('servers') ?? [];
      return serverList;
    } catch (e) {
      return [];
    }
  }

  Future<bool> saveServers(List<String> servers) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (servers.isEmpty) {
        await prefs.remove('servers');
        return true;
      }
      await prefs.setStringList('servers', servers);
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String appDocPath = appDocDir.path;
      String settingsPath = '$appDocPath/settings.json';
      File settingsFile = File(settingsPath);
      Map<String, dynamic> jsonData = {};
      if (settingsFile.existsSync()) {
        String content = await settingsFile.readAsString();
        jsonData = json.decode(content) as Map<String, dynamic>;
      }
      jsonData['servers'] = servers;
      await settingsFile.writeAsString(json.encode(jsonData));
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<String?> getSelectedServer() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('selectedServer') ?? "";
  }
}
