import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

class serversM extends StatelessWidget {
  Future<bool> selectServer(String server) async {
    try {
      // Get the application's document directory
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String appDocPath = appDocDir.path;

      // Define the path to the settings.json file
      String settingsPath = '$appDocPath/settings.json';

      // Read the existing JSON data from the file
      File settingsFile = File(settingsPath);
      Map<String, dynamic> jsonData = {};
      if (settingsFile.existsSync()) {
        String content = await settingsFile.readAsString();
        jsonData = json.decode(content);
      }

      // Update the server field
      jsonData['server'] = server;
      await settingsFile.writeAsString(json.encode(jsonData));
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
        return json.decode(content);
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
        jsonData = json.decode(content);
      }
      jsonData['servers'] = servers;
      await settingsFile.writeAsString(json.encode(jsonData));
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<String> getSelectedServer() async {
    try {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String appDocPath = appDocDir.path;
      String settingsPath = '$appDocPath/settings.json';
      File settingsFile = File(settingsPath);
      if (settingsFile.existsSync()) {
        String content = await settingsFile.readAsString();
        return json.decode(content)["server"];
      }
      return "";
    } catch (e) {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
}
