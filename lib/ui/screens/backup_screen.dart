import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:Freedom_Guard/utils/LOGLOG.dart';

class BackupPage extends StatefulWidget {
  const BackupPage({super.key});

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  bool busy = false;

  Future<Map<String, String>> _exportPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, String> backup = {};
    for (final key in prefs.getKeys()) {
      final value = prefs.get(key);
      if (value != null) backup[key] = jsonEncode(value);
    }
    return backup;
  }

  Future<void> _handleCreateBackup() async {
    final choice = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Create Backup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.save_alt),
              label: const Text('Export to File'),
              onPressed: () => Navigator.pop(context, 'file'),
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50)),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.copy),
              label: const Text('Export as Text'),
              onPressed: () => Navigator.pop(context, 'text'),
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50)),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.share),
              label: const Text('Share Backup'),
              onPressed: () => Navigator.pop(context, 'share'),
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50)),
            ),
          ],
        ),
      ),
    );
    if (choice == null) return;

    setState(() => busy = true);
    try {
      final data = await _exportPrefs();
      if (choice == 'file') {
        final bytes = utf8.encode(jsonEncode(data));
        final selectedPath = await FilePicker.platform.saveFile(
          dialogTitle: 'Select Backup Location',
          fileName:
              'freedom_guard_backup_${DateTime.now().millisecondsSinceEpoch}.json',
          type: FileType.any,
          bytes: bytes,
          allowedExtensions: ['json'],
        );
        if (selectedPath == null) return;
        LogOverlay.showLog('Backup saved to file');
      } else if (choice == 'text') {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Backup as Text'),
            content: SingleChildScrollView(
              child: SelectableText(jsonEncode(data)),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close')),
              ElevatedButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: jsonEncode(data)));
                    LogOverlay.showLog('Copied to clipboard');
                    Navigator.pop(context);
                  },
                  child: const Text('Copy')),
            ],
          ),
        );
      } else if (choice == 'share') {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/freedom_guard_backup.json');
        await file.writeAsString(jsonEncode(data));
        await Share.shareXFiles([XFile(file.path)]);
      }
    } catch (e) {
      LogOverlay.showLog(e.toString());
    }
    setState(() => busy = false);
  }

  Future<void> importBackupFromFile() async {
    setState(() => busy = true);
    try {
      final result = await FilePicker.platform
          .pickFiles(type: FileType.custom, allowedExtensions: ['json']);
      if (result == null || result.files.single.path == null) return;
      final file = File(result.files.single.path!);
      final raw = jsonDecode(await file.readAsString());
      await _importData(raw);
    } catch (e) {
      LogOverlay.showLog(e.toString());
    }
    setState(() => busy = false);
  }

  Future<void> importBackupFromClipboard() async {
    setState(() => busy = true);
    try {
      final text = (await Clipboard.getData('text/plain'))?.text;
      if (text == null || text.isEmpty) throw 'Clipboard empty';
      final raw = jsonDecode(text);
      await _importData(raw);
    } catch (e) {
      LogOverlay.showLog(e.toString());
    }
    setState(() => busy = false);
  }

  Future<void> importBackupFromUrl() async {
    setState(() => busy = true);
    try {
      final urlController = TextEditingController();
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Load Backup from URL'),
          content: TextField(
            controller: urlController,
            decoration:
                const InputDecoration(hintText: 'Enter backup JSON URL'),
            autofocus: true,
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Load')),
          ],
        ),
      );
      if (ok != true || urlController.text.isEmpty) return;
      final res = await http.get(Uri.parse(urlController.text.trim()));
      if (res.statusCode != 200) throw 'Failed to download backup';
      final raw = jsonDecode(res.body);
      await _importData(raw);
    } catch (e) {
      LogOverlay.showLog(e.toString());
    }
    setState(() => busy = false);
  }

  Future<void> _importData(dynamic raw) async {
    if (raw is! Map) throw 'Invalid backup data';
    final prefs = await SharedPreferences.getInstance();
    for (final entry in raw.entries) {
      try {
        final value = jsonDecode(entry.value);
        if (value is bool)
          await prefs.setBool(entry.key, value);
        else if (value is int)
          await prefs.setInt(entry.key, value);
        else if (value is double)
          await prefs.setDouble(entry.key, value);
        else if (value is String)
          await prefs.setString(entry.key, value);
        else if (value is List)
          await prefs.setStringList(
              entry.key, value.map((e) => e.toString()).toList());
      } catch (_) {
        await prefs.setString(entry.key, entry.value.toString());
      }
    }
    LogOverlay.showLog('Settings imported successfully');
    Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
  }

  Future<void> _resetSettings() async {
    setState(() => busy = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      LogOverlay.showLog('Settings reset successfully');
    } catch (e) {
      LogOverlay.showLog(e.toString());
    }
    setState(() => busy = false);
    Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
  }

  Future<void> _showImportOptions() async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ListTile(
              leading: const Icon(Icons.upload_file),
              title: const Text('Import from File'),
              onTap: () {
                Navigator.pop(context);
                importBackupFromFile();
              },
            ),
            ListTile(
              leading: const Icon(Icons.paste),
              title: const Text('Paste from Clipboard'),
              onTap: () {
                Navigator.pop(context);
                importBackupFromClipboard();
              },
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Paste from URL'),
              onTap: () {
                Navigator.pop(context);
                importBackupFromUrl();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.save_alt, size: 28),
              label:
                  const Text('Create Backup', style: TextStyle(fontSize: 18)),
              onPressed: busy ? null : _handleCreateBackup,
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 60)),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.download, size: 28),
              label:
                  const Text('Import Backup', style: TextStyle(fontSize: 18)),
              onPressed: busy ? null : _showImportOptions,
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 60)),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh, size: 28),
              label:
                  const Text('Reset Settings', style: TextStyle(fontSize: 18)),
              onPressed: busy ? null : _resetSettings,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 60),
              ),
            ),
            const Spacer(),
            if (busy) const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}
