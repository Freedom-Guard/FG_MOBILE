import 'dart:convert';
import 'dart:io';
import 'package:Freedom_Guard/components/LOGLOG.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ServersM extends ChangeNotifier {
  String? selectedServer;

  ServersM() {
    _loadSelectedServer();
  }

  void initState() {
    addServerFromUrl(
      "https://raw.githubusercontent.com/Freedom-Guard/Freedom-Guard/refs/heads/main/config/index.json",
    );
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
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
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
      Map<String, dynamic> oldData = await oldServers();
      List<String> currentServers = List<String>.from(oldData['servers'] ?? []);

      Set<String> updatedServers = {...currentServers, ...newServers};

      await saveServers(updatedServers.toList());
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> oldServers() async {
    try {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String appDocPath = appDocDir.path;
      String settingsPath = '$appDocPath/settings.json';
      File settingsFile = File(settingsPath);
      if (settingsFile.existsSync()) {
        String content = await settingsFile.readAsString();
        return json.decode(content) as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  Future<bool> saveServers(List<String> servers) async {
    try {
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
