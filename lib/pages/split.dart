import 'package:Freedom_Guard/components/LOGLOG.dart';
import 'package:Freedom_Guard/components/settings.dart';
import 'package:flutter/material.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';

class SplitPage extends StatefulWidget {
  @override
  State<SplitPage> createState() => _SplitPageState();
}

class _SplitPageState extends State<SplitPage> {
  List<AppInfo> installedApps = [];
  List<String> selectedApps = [];
  bool showSystemApps = false;
  Settings settings = Settings();
  bool isSettingsLoading = true;
  bool isLoading = true;
  bool checkedAll = false;

  @override
  void initState() {
    super.initState();
    _loadSelectedApps();
    _getInstalledApps();
  }

  Future<void> _getInstalledApps() async {
    setState(() {
      isLoading = true;
    });
    try {
      List<AppInfo> apps = await InstalledApps.getInstalledApps(
        !showSystemApps,
        true,
      );
      setState(() {
        installedApps = apps;
        isLoading = false;
      });
      LogOverlay.showLog("Number of loaded apps: ${apps.length}");
    } catch (e) {
      setState(() {
        installedApps = [];
        isLoading = false;
      });
      LogOverlay.showLog("Error loading apps: $e");
    }
  }

  Future<void> _loadSelectedApps() async {
    try {
      String? selectedAppsString = await settings.getValue("split_app");
      if (selectedAppsString.isNotEmpty) {
        String cleanedString = selectedAppsString.replaceAll(
          RegExp(r'[\[\]]'),
          '',
        );
        List<String> loadedApps =
            cleanedString.split(', ').where((e) => e.isNotEmpty).toList();
        setState(() async {
          if (loadedApps.isEmpty) {
            String? selectedAppsString =
                await settings.getValue("split_app").toString();
            String cleanedString = selectedAppsString.replaceAll(
              RegExp(r'[\[\]]'),
              '',
            );
            List<String> loadedApps =
                cleanedString.split(', ').where((e) => e.isNotEmpty).toList();
            setState(() {
              selectedApps = loadedApps;
            });
            LogOverlay.showLog("Selected apps loaded: $loadedApps");
          }
          selectedApps = loadedApps;
        });
        LogOverlay.showLog("Selected apps loaded: $loadedApps");
      }
    } catch (e) {
      LogOverlay.showLog("Error loading selected apps: $e");
    }
  }

  void _toggleAppSelection(String packageName) {
    setState(() {
      checkedAll = false;
      if (selectedApps.contains(packageName)) {
        selectedApps.remove(packageName);
      } else {
        selectedApps.add(packageName);
      }
    });
  }

  void _applySettings() {
    isSettingsLoading = true;
    settings.setValue(
      "split_app",
      selectedApps.isEmpty ? "" : selectedApps.toString(),
    );
    LogOverlay.showLog("List of selected apps: $selectedApps");
  }

  void _selectAllApps() {
    setState(() {
      if (checkedAll) {
        selectedApps = [];
        checkedAll = false;
        LogOverlay.showLog("All apps deselected");
      } else {
        selectedApps = installedApps
            .map((app) => app.packageName)
            .where((name) => name.isNotEmpty)
            .toList();
        checkedAll = true;
        LogOverlay.showLog("All apps selected");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text(
          "Split Tunneling",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: checkedAll
                ? const Icon(Icons.check_box, color: Colors.white)
                : const Icon(Icons.check_box_outline_blank,
                    color: Colors.white),
            onPressed: _selectAllApps,
          ),
          IconButton(
            icon: const Icon(Icons.check, color: Colors.white),
            onPressed: _applySettings,
          ),
          IconButton(
            icon: const Icon(Icons.clear_sharp, color: Colors.white),
            onPressed: () async {
              setState(() {
                isSettingsLoading = true;
                selectedApps = [];
              });
              settings.setValue("split_app", "");
              await _loadSelectedApps();
              await _getInstalledApps();
              setState(() {
                isSettingsLoading = false;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).scaffoldBackgroundColor,
            child: SwitchListTile(
              activeColor: Colors.blueAccent,
              title: const Text(
                "Show system apps",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              value: showSystemApps,
              onChanged: (value) {
                setState(() {
                  showSystemApps = value;
                  _getInstalledApps();
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              "The following apps will not go through the filter",
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Colors.blueAccent,
                    ),
                  )
                : installedApps.isEmpty
                    ? const Center(
                        child: Text(
                          "No apps found!",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: installedApps.length,
                        itemBuilder: (context, index) {
                          AppInfo app = installedApps[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundImage: app.icon != null
                                    ? MemoryImage(app.icon!)
                                    : null,
                                child: app.icon == null
                                    ? const Icon(Icons.apps)
                                    : null,
                              ),
                              title: Text(
                                app.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                app.packageName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              trailing: Switch(
                                activeColor: Colors.blueAccent,
                                value: selectedApps.contains(app.packageName),
                                onChanged: (value) => _toggleAppSelection(
                                  app.packageName,
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
}
