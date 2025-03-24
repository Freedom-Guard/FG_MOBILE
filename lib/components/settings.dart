import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class Settings {
  Future<String> getValue(String key) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(key) == null) {
      return "";
    } else {
      return prefs.getString(key).toString();
    }
  }

  Future<bool> setValue(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    bool result = await prefs.setString(key, value);
    if (result) {
      await saveToFile();
    }
    return result;
  }

  Future<void> saveToFile() async {
    final prefs = await SharedPreferences.getInstance();
    final settings = prefs.getKeys().fold<Map<String, String>>({}, (map, key) {
      final value = prefs.getString(key);
      if (value != null) map[key] = value;
      return map;
    });

    final file = await getSettingsFile();
    await file.writeAsString(json.encode(settings));
  }

  Future<Map<String, String>> loadSettings() async {
    final file = await getSettingsFile();
    if (await file.exists()) {
      try {
        final content = await file.readAsString();
        final data = json.decode(content) as Map<String, dynamic>;
        final prefs = await SharedPreferences.getInstance();
        data.forEach((key, value) => prefs.setString(key, value.toString()));
        return data.map((key, value) => MapEntry(key, value.toString()));
      } catch (_) {}
    }
    return {};
  }

  Future<File> getSettingsFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/settings.json');
  }
}
