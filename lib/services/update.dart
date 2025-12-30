import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_filex/open_filex.dart';
import 'package:Freedom_Guard/core/network/network_service.dart';
import 'package:Freedom_Guard/constants/app_info.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:Freedom_Guard/components/connect.dart';

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
  final response = await NetworkService.get(
    'https://raw.githubusercontent.com/Freedom-Guard/Freedom-Guard/main/config/mobile.json',
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final latestVersion = data['version'];
    const currentVersion = AppInfo.version;

    if (isNewerVersion(latestVersion, currentVersion)) {
      showDialog(
        context: context,
        barrierDismissible: !(data['forceUpdate'] ?? false),
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          backgroundColor: Colors.transparent,
          child: _UpdateDialogContent(data: data),
        ),
      );
    }
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

  Future<File> downloadApk(String url) async {
    final dir = await getExternalStorageDirectory();
    final filePath = '${dir!.path}/FreedomGuard.apk';
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
    return File(filePath);
  }

  Future<bool> checkInstallPermission() async {
    if (await Permission.requestInstallPackages.isGranted) {
      return true;
    }
    final status = await Permission.requestInstallPackages.request();
    return status.isGranted;
  }

  Future<void> startUpdate(String apkUrl) async {
    final hasPermission = await checkInstallPermission();
    if (!hasPermission) return;

    setState(() {
      downloading = true;
    });

    final apkFile = await downloadApk(apkUrl);
    setState(() {
      downloading = false;
      progress = 0.0;
    });

    await OpenFilex.open(apkFile.path);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'نسخه جدید موجود است',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.data['messText'],
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          if (downloading)
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[800],
              color: Colors.blue,
              minHeight: 6,
            ),
          if (!downloading)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!(widget.data['forceUpdate'] ?? false))
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    child: const Text(
                      'انصراف',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () async {
                    await startUpdate(widget.data['apk_url']);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                  child: const Text(
                    'بروزرسانی',
                    style: TextStyle(fontSize: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

Future<bool> checkForVPN() async {
  final connectivityResult = await Connectivity().checkConnectivity();
  if (connectivityResult == ConnectivityResult.vpn) {
    return true;
  } else {
    if (v2rayStatus.value.state == "CONNECTED") {
      return true;
    } else {
      return false;
    }
  }
}
