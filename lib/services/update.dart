import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:Freedom_Guard/components/connect.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_filex/open_filex.dart';
import 'package:Freedom_Guard/core/network/network_service.dart';
import 'package:Freedom_Guard/constants/app_info.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:url_launcher/url_launcher.dart';

bool isNewerVersion(String latest, String current) {
  List<int> latestParts = latest.split('.').map(int.parse).toList();
  List<int> currentParts = current.split('.').map(int.parse).toList();

  for (int i = 0; i < latestParts.length; i++) {
    if (latestParts[i] > currentParts[i]) return true;
    if (latestParts[i] < currentParts[i]) return false;
  }
  return false;
}

Future<void> checkForUpdate(BuildContext context) async {
  try {
    print("[Updater] Checking for updates...");
    final response = await NetworkService.get(
      'https://raw.githubusercontent.com/Freedom-Guard/Freedom-Guard/main/config/mobile.json',
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final latestVersion = data['version'];
      const currentVersion = AppInfo.version;

      print("[Updater] Latest: $latestVersion, Current: $currentVersion");

      if (isNewerVersion(latestVersion, currentVersion)) {
        print("[Updater] New version available!");
        showDialog(
          context: context,
          barrierDismissible: !(data['forceUpdate'] ?? false),
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24.0)),
            backgroundColor: Colors.transparent,
            child: _UpdateDialogContent(data: data),
          ),
        );
      }
    }
  } catch (e) {
    print("[Updater] Update check failed: $e");
  }
}

class _UpdateDialogContent extends StatefulWidget {
  final Map<String, dynamic> data;
  const _UpdateDialogContent({required this.data});

  @override
  State<_UpdateDialogContent> createState() => _UpdateDialogContentState();
}

class _UpdateDialogContentState extends State<_UpdateDialogContent> {
  double progress = 0.0;
  bool downloading = false;

  Future<File?> downloadApk(String url) async {
    try {
      print("[Downloader] Starting download: $url");
      Directory dir = Platform.isAndroid
          ? (await getExternalStorageDirectory())!
          : await getApplicationDocumentsDirectory();

      final apkDir = Directory("${dir.path}/FreedomGuard");
      if (!apkDir.existsSync()) apkDir.createSync(recursive: true);
      final filePath = "${apkDir.path}/FreedomGuard.apk";

      final dio = Dio();
      await dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              progress = received / total;
            });
          }
        },
      );
      print("[Downloader] Download completed: $filePath");
      return File(filePath);
    } catch (e) {
      print("[Downloader] Download failed: $e");
      return null;
    }
  }

  Future<bool> checkInstallPermission() async {
    if (await Permission.requestInstallPackages.isGranted) return true;
    final status = await Permission.requestInstallPackages.request();
    return status.isGranted;
  }

  Future<void> startUpdate(String apkUrl) async {
    final hasPermission = await checkInstallPermission();
    if (!hasPermission) {
      print("[Updater] Install permission denied");
      return;
    }

    setState(() => downloading = true);
    final apkFile = await downloadApk(apkUrl);

    if (apkFile != null) {
      print("[Updater] Opening APK...");
      await OpenFilex.open(apkFile.path);
    }

    if (mounted) {
      setState(() {
        downloading = false;
        progress = 0.0;
      });
    }
  }

  Future<void> _launchWebsite(String? url) async {
    final targetUrl = url ?? "https://github.com/Freedom-Guard/Freedom-Guard/releases";
    final uri = Uri.parse(targetUrl);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        print("[Updater] Could not launch website");
      }
    } catch (e) {
      print("[Updater] Error launching website: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.system_update,
                    color: Colors.blueAccent, size: 32),
              ),
              const SizedBox(height: 16),
              const Text(
                'نسخه جدید موجود است',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                widget.data['messText'] ?? 'تغییرات جدید در دسترس است.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14, color: Colors.white70, height: 1.5),
              ),
              const SizedBox(height: 24),
              if (downloading) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("در حال دانلود...",
                        style:
                            TextStyle(color: Colors.blueAccent, fontSize: 12)),
                    Text("${(progress * 100).toInt()}%",
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.white10,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                  ),
                ),
              ] else
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _launchWebsite(widget.data['website_url']),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.blueAccent,
                              side: const BorderSide(color: Colors.blueAccent),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('وب‌سایت'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => startUpdate(widget.data['apk_url']),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('دانلود مستقیم'),
                          ),
                        ),
                      ],
                    ),
                    if (!(widget.data['forceUpdate'] ?? false)) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('انصراف',
                            style: TextStyle(color: Colors.white54)),
                      ),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<bool> checkForVPN() async {
  try {
    final result = await Connectivity().checkConnectivity();
    if (result == ConnectivityResult.vpn) return true;
    if (v2rayStatus.value.state == "CONNECTED") return true;
    return false;
  } catch (e) {
    print("[Network] VPN check error: $e");
    return false;
  }
}