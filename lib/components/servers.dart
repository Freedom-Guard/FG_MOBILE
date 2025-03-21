import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ServersM extends ChangeNotifier {
  String? selectedServer;

  ServersM() {
    _loadSelectedServer();
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
