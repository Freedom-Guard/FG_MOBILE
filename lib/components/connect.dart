import 'dart:convert';
import 'package:flutter_v2ray/flutter_v2ray.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:Freedom_Guard/components/LOGLOG.dart'; // مسیر درست رو چک کنید

class Connect {
  void test() {}

  Future<void> ConnectVibe(String config, dynamic args) async {
    final FlutterV2ray flutterV2ray = FlutterV2ray(
      onStatusChanged: (status) {
        test();
      },
    );

    await flutterV2ray.initializeV2Ray();

    V2RayURL parser = FlutterV2ray.parseFromURL(config);

    // Get Server Delay
    LogOverlay.showLog(
      '${flutterV2ray.getServerDelay(config: parser.getFullConfiguration())}ms',
    );

    if (await flutterV2ray.requestPermission()) {
      flutterV2ray.startV2Ray(
        remark: parser.remark,
        config: parser.getFullConfiguration(),
        blockedApps: null,
        bypassSubnets: null,
        proxyOnly: false,
      );
    }
  }

  Future<void> ConnectAuto(String fgconfig, int timeout) async {
    try {
      final uri = Uri.parse(fgconfig);

      final response = await http
          .get(uri)
          .timeout(
            Duration(milliseconds: timeout),
            onTimeout: () {
              throw TimeoutException('Request timed out after $timeout ms');
            },
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<String> publicServers = List<String>.from(data["PUBLIC"] ?? []);

        for (var config in publicServers) {
          LogOverlay.showLog('Server: $config');
          await Future.delayed(
            const Duration(milliseconds: 500),
          ); // فاصله بین لاگ‌ها
        }

        LogOverlay.showLog('Config fetched successfully');
      } else {
        LogOverlay.showLog('Failed to load config: ${response.statusCode}');
      }
    } catch (e) {
      LogOverlay.showLog('Error in ConnectAuto: $e');
    }
  }
}
