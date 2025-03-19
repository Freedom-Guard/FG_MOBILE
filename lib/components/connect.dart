import 'dart:convert';
import 'dart:io';
import 'package:Freedom_Guard/components/LOGLOG.dart';
import 'package:flutter_v2ray/flutter_v2ray.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

class Connect {
  final FlutterV2ray flutterV2ray = FlutterV2ray(onStatusChanged: (status) {});

  void test() {}

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

  // Finds the best config from a subscription link based on ping
  Future<String?> sortAndBestConfigFromSub(String sub) async {
    try {
      final uri = Uri.parse(sub);
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        LogOverlay.showLog('Failed to fetch sub link: ${response.statusCode}');
        return null;
      }

      String data = response.body;
      List<String> configs = [];
      if (sub.startsWith('http')) {
        data = utf8.decode(base64Decode(data));
      }
      configs =
          data
              .split('\n')
              .where((element) => element.trim().isNotEmpty)
              .toList();

      if (configs.isEmpty) {
        LogOverlay.showLog('No configs found in sub link');
        return null;
      }

      await flutterV2ray.initializeV2Ray(); // Initialize before pinging
      List<Map<String, dynamic>> configPings = [];
      for (String config in configs) {
        try {
          V2RayURL parser = FlutterV2ray.parseFromURL(config);
          if (parser.getFullConfiguration().isEmpty) continue;
          final ping = await flutterV2ray.getServerDelay(
            config: parser.getFullConfiguration(),
          );
          if (ping > 0) {
            configPings.add({'config': config, 'ping': ping});
          }
        } catch (e) {
          LogOverlay.showLog('Error pinging config: $e');
        }
      }

      if (configPings.isEmpty) {
        LogOverlay.showLog('No valid configs found in sub link');
        return null;
      }

      configPings.sort((a, b) => a['ping'].compareTo(b['ping']));
      LogOverlay.showLog('Best config ping: ${configPings.first['ping']}ms');
      return configPings.first['config'] as String;
    } catch (e) {
      LogOverlay.showLog('Error in sortAndBestConfigFromSub: $e');
      return null;
    }
  }
}
