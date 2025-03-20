import 'dart:convert';
import 'package:Freedom_Guard/components/LOGLOG.dart';
import 'package:flutter_v2ray/flutter_v2ray.dart';
import 'package:http/http.dart' as http;
import 'package:synchronized/extension.dart';
import 'dart:async';

class Connect {
  final FlutterV2ray flutterV2ray = FlutterV2ray(onStatusChanged: (status) {});

  void test() {}

  Future<void> disConnect() async {
    await flutterV2ray.initializeV2Ray();
    flutterV2ray.stopV2Ray();
  }

  // Connects to a single V2Ray config
  Future<void> ConnectVibe(String config, dynamic args) async {
    await flutterV2ray.initializeV2Ray();
    V2RayURL parser = FlutterV2ray.parseFromURL(config);
    LogOverlay.showLog(
      '${await flutterV2ray.getServerDelay(config: parser.getFullConfiguration())}ms',
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

  // Fetches and processes configs from a URL
  Future<void> ConnectAuto(String fgconfig, int timeout) async {
    try {
      final uri = Uri.parse(fgconfig);
      final response = await http
          .get(uri)
          .timeout(
            Duration(milliseconds: timeout),
            onTimeout:
                () =>
                    throw TimeoutException(
                      'Request timed out after $timeout ms',
                    ),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<String> publicServers = List<String>.from(data["PUBLIC"] ?? []);

        for (var config in publicServers) {
          if (config.split(",;,")[0] == "vibe") {
            config = config.split(",;,")[1];
            if (config.startsWith("http")) {
              String? bestConfig = await sortAndBestConfigFromSub(config);
              if (bestConfig != null) ConnectVibe(bestConfig, "args");
            } else {
              ConnectVibe(config, "args");
            }
          }
          await Future.delayed(const Duration(milliseconds: 500));
        }
        LogOverlay.showLog('Config fetched successfully');
      } else {
        LogOverlay.showLog('Failed to load config: ${response.statusCode}');
      }
    } catch (e) {
      LogOverlay.showLog('Error in ConnectAuto: $e');
    }
  }

  Future<String?> sortAndBestConfigFromSub(String sub) async {
    try {
      final uri = Uri.parse(sub);
      final response = await http.get(uri);
      if (response.statusCode != 200) return null;

      String data = response.body;
      if (sub.startsWith('http')) {
        try {
          data = utf8.decode(base64Decode(data));
        } catch (_) {}
      }

      final configs =
          data.split('\n').where((e) => e.trim().isNotEmpty).toList();
      if (configs.isEmpty) return null;

      await flutterV2ray.initializeV2Ray();
      final results = <Map<String, dynamic>>[];
      final stopwatch = Stopwatch()..start();

      final futures = configs.map((config) async {
        if (results.length >= 3 || stopwatch.elapsed.inSeconds >= 45)
          return null;
        try {
          final parser = FlutterV2ray.parseFromURL(config);
          final fullConfig = parser.getFullConfiguration();
          if (fullConfig.isEmpty) return null;

          final ping = await flutterV2ray
              .getServerDelay(config: fullConfig)
              .timeout(Duration(seconds: 3), onTimeout: () => -1);

          if (ping > 0 && ping < 2000) {
            results.add({'config': config, 'ping': ping});
          }
          return ping > 0 ? {'config': config, 'ping': ping} : null;
        } catch (_) {
          return null;
        }
      });

      await Future.wait(futures).timeout(Duration(seconds: 45));
      stopwatch.stop();

      if (results.isEmpty) return null;

      results.sort((a, b) => a['ping'].compareTo(b['ping']));
      return results.first['config'] as String;
    } catch (_) {
      return null;
    }
  }
}
