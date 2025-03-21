import 'dart:convert';
import 'package:Freedom_Guard/components/LOGLOG.dart';
import 'package:flutter/material.dart';
import 'package:flutter_v2ray/flutter_v2ray.dart';
import 'package:wireguard_flutter/wireguard_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

class Connect {
  final FlutterV2ray flutterV2ray = FlutterV2ray(onStatusChanged: (status) {});
  final wireguard = WireGuardFlutter.instance;

  void test() {}

  Future<void> disConnect() async {
    await flutterV2ray.initializeV2Ray();
    flutterV2ray.stopV2Ray();
    wireguard.stopVpn();
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
    } else {
      LogOverlay.showLog("Please Allow");
    }
  }

  Future<bool> ConnectWarp() async {
    try {
      await wireguard.initialize(interfaceName: 'wg0');
      const String conf = '''[Interface]
PrivateKey = 9yYN5X+bmODkpAv0nhSjA3GgpN6J/iCXYnXD50uVTz0=
Address = 172.16.0.2/32, 2606:4700:110:8b5e:1ee6:342f:58da:2b4b/128
DNS = 1.1.1.1, 1.0.0.1, 2606:4700:4700::1111, 2606:4700:4700::1001
MTU = 1280

[Peer]
PublicKey = bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=
AllowedIPs = 0.0.0.0/0, ::/0
Endpoint = engage.cloudflareclient.com:2408''';
      await wireguard.startVpn(
        serverAddress: "engage.cloudflareclient.com:2408",
        wgQuickConfig: conf,
        providerBundleIdentifier: 'com.freedom.guard',
      );
      LogOverlay.showLog(
        "Connected To warp",
        backgroundColor: Colors.greenAccent,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  // Fetches and processes configs from a URL
  Future<bool> ConnectAuto(String fgconfig, int timeout) async {
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
        List<String> publicServers = List<String>.from(data["MOBILE"] ?? []);
        var connStat = false;
        for (var config in publicServers) {
          if (config.split(",;,")[0] == "vibe") {
            config = config.split(",;,")[1].split("#")[0];
            LogOverlay.showLog(config);
            if (config.startsWith("http")) {
              var bestConfig = await getBestConfigFromSub(config);
              if (bestConfig != null) {
                LogOverlay.showLog(bestConfig);
                await ConnectVibe(bestConfig, "args");
                connStat = true;
                break;
              }
            } else {
              await ConnectVibe(config, "args");
            }
          } else if (config.split(",;,")[0] == "warp") {
            config = config.split(",;,")[1].split("#")[0];
            LogOverlay.showLog(config);
            if (await ConnectWarp()) {
              connStat = true;
              break;
            }
          }
          await Future.delayed(const Duration(milliseconds: 500));
        }
        LogOverlay.showLog('Config fetched successfully');
        return connStat;
      } else {
        LogOverlay.showLog('Failed to load config: ${response.statusCode}');
      }
    } catch (e) {
      LogOverlay.showLog('Error in ConnectAuto: $e');
    }
    return false;
  }

  Future<String?> getBestConfigFromSub(String sub) async {
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

      final stopwatch = Stopwatch()..start();
      final results = await Future.wait(
        configs.take(configs.length).map((config) async {
          try {
            final parser = FlutterV2ray.parseFromURL(config);
            final ping = await flutterV2ray
                .getServerDelay(config: parser.getFullConfiguration())
                .timeout(
                  const Duration(seconds: 10),
                  onTimeout: () {
                    return -1;
                  },
                );
            return ping > 0 ? {'config': config, 'ping': ping} : null;
          } catch ($e) {
            return null;
          }
        }),
      );

      stopwatch.stop();

      final validResults = results.whereType<Map<String, dynamic>>().toList();
      if (validResults.isEmpty) return null;
      validResults.sort((a, b) => a['ping'].compareTo(b['ping']));
      LogOverlay.showLog(validResults.first['config']);
      return validResults.first['config'] as String;
    } catch (_) {
      return null;
    }
  }
}
