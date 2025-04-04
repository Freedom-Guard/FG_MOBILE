import 'package:Freedom_Guard/components/LOGLOG.dart';
import 'package:Freedom_Guard/components/settings.dart';
import 'package:flutter/material.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';

class SplitPage extends StatefulWidget {
  const SplitPage({super.key});

  @override
  State<SplitPage> createState() => _SplitPageState();
}

class _SplitPageState extends State<SplitPage> {
  List<AppInfo> installedApps = [];
  List<String> selectedApps = [];
  bool showSystemApps = false;
  Settings settings = Settings();
  bool isLoading = true;

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
      LogOverlay.showLog("تعداد برنامه‌های بارگذاری‌شده: ${apps.length}");
    } catch (e) {
      setState(() {
        installedApps = [];
        isLoading = false;
      });
      LogOverlay.showLog("خطا در بارگذاری برنامه‌ها: $e");
    }
  }

  Future<void> _loadSelectedApps() async {
    try {
      String? selectedAppsString = await settings.getValue("split_app");
      if (selectedAppsString.isNotEmpty) {
        String cleanedString = selectedAppsString.substring(
          1,
          selectedAppsString.length - 1,
        );
        List<String> loadedApps =
            cleanedString.split(', ').where((e) => e.isNotEmpty).toList();
        setState(() {
          selectedApps = loadedApps;
        });
        LogOverlay.showLog("برنامه‌های انتخاب‌شده بارگذاری شدند: $loadedApps");
      }
    } catch (e) {
      LogOverlay.showLog("خطا در بارگذاری برنامه‌های انتخاب‌شده: $e");
    }
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
      selectedApps.isEmpty ? "" : selectedApps.toString(),
    );
    LogOverlay.showLog("لیست برنامه‌های انتخاب‌شده: $selectedApps");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text(
          "Split Tunneling (beta)",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.white),
            onPressed: _applySettings,
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
                "نمایش برنامه‌های سیستمی",
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
              "برنامه‌های زیر از فیلترشکن عبور نمی‌کنند",
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          Expanded(
            child:
                isLoading
                    ? const Center(
                      child: CircularProgressIndicator(
                        color: Colors.blueAccent,
                      ),
                    )
                    : installedApps.isEmpty
                    ? const Center(
                      child: Text(
                        "هیچ برنامه‌ای یافت نشد!",
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
                              backgroundImage:
                                  app.icon != null
                                      ? MemoryImage(app.icon!)
                                      : null,
                              child:
                                  app.icon == null
                                      ? const Icon(Icons.apps)
                                      : null,
                            ),
                            title: Text(
                              app.name ?? "بدون نام",
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              app.packageName ?? "بدون بسته",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            trailing: Switch(
                              activeColor: Colors.blueAccent,
                              value: selectedApps.contains(app.packageName),
                              onChanged:
                                  (value) => _toggleAppSelection(
                                    app.packageName ?? "",
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
