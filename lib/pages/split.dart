import 'package:Freedom_Guard/components/LOGLOG.dart';
import 'package:Freedom_Guard/components/settings.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SplitPage extends StatefulWidget {
  const SplitPage({super.key});

  @override
  State<SplitPage> createState() => _SplitPageState();
}

class _SplitPageState extends State<SplitPage> {
  List<String> installedApps = [];
  List<String> selectedApps = [];
  bool showSystemApps = false;
  Settings settings = new Settings();
  @override
  void initState() {
    super.initState();
    _loadSelectedApps();
    _getInstalledApps();
  }

  Future<void> _getInstalledApps() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      installedApps = [packageInfo.packageName];
    });
  }

  Future<void> _loadSelectedApps() async {
    String? selectedAppsString = await settings.getValue("split_app");
    if (selectedAppsString.isNotEmpty) {
      String cleanedString = selectedAppsString.substring(1, selectedAppsString.length - 1);
      List<String> loadedApps = cleanedString.split(', ');
      setState(() {
          selectedApps = loadedApps;
      });
      
    };
  }

  void _toggleAppSelection(String packageName) {
    setState(() {
      if (selectedApps.contains(packageName)) {
        selectedApps.remove(packageName);
      } else {
        selectedApps.add(packageName);
      }
    });
  }

  void _applySettings() {
    settings.setValue(
      "split_app",
      (selectedApps == [] ? "" : selectedApps.toString()),
    );
    LogOverlay.showLog("لیست برنامه‌های انتخاب‌شده: $selectedApps");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Split Tunneling"),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _applySettings),
        ],
      ),
      body: Column(
        children: [
          SwitchListTile(
            title: const Text("نمایش برنامه‌های سیستمی"),
            value: showSystemApps,
            onChanged: (value) {
              setState(() {
                showSystemApps = value;
              });
            },
          ),
          Text("برنامه های زیر از فیلترشکن عبور نمیکنند"),
          Expanded(
            child: ListView.builder(
              itemCount: installedApps.length,
              itemBuilder: (context, index) {
                String packageName = installedApps[index];
                return ListTile(
                  leading: const Icon(Icons.apps),
                  title: Text(packageName),
                  trailing: Switch(
                    value: selectedApps.contains(packageName),
                    onChanged: (value) => _toggleAppSelection(packageName),
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
