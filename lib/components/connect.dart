import 'dart:convert';
import 'package:Freedom_Guard/components/LOGLOG.dart';
import 'package:Freedom_Guard/components/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_v2ray/flutter_v2ray.dart';
import 'package:wireguard_flutter/wireguard_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

class Connect {
  bool isConnected = false;
  Settings settings = new Settings();
  final FlutterV2ray flutterV2ray = FlutterV2ray(
    onStatusChanged: (status) async {
      if (status.toString() == "V2RayStatusState.connected") {
        LogOverlay.showLog(
          "Connected To VIBE",
          backgroundColor: Colors.greenAccent,
        );
      }
    },
  );
  final wireguard = WireGuardFlutter.instance;

  Future<void> connected() async {
    isConnected = true;
  }

  Future<bool> connectedQ() async {
    return flutterV2ray.getConnectedServerDelay() != -1 ? true : false;
  }

  Future<bool> test() async {
    try {
      final response = await http
          .get(Uri.parse('https://www.google.com'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        LogOverlay.showLog(
          "Connected To internet",
          backgroundColor: Colors.greenAccent,
        );
        return true;
      }
    } catch (_) {}
    LogOverlay.showLog("No internet");
    return false;
  }

  Future<void> disConnect() async {
    await flutterV2ray.initializeV2Ray();
    flutterV2ray.stopV2Ray();
    wireguard.stopVpn();
  }

  // Connects to a single V2Ray config
  Future<bool> ConnectVibe(String config, dynamic args) async {
    try {
      await flutterV2ray.initializeV2Ray();
    } catch (_) {
      LogOverlay.showLog("Failed initialize VIBE");
    }
    try {
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
        return true;
      } else {
        LogOverlay.showLog(
          "Permission Denied: Please grant necessary permissions to establish a connection.",
          backgroundColor: Colors.redAccent,
        );
      }
    } catch (e) {
      LogOverlay.showLog(
        "Failed to connect to VIBE \n " + e.toString(),
        backgroundColor: Colors.redAccent,
      );
    }
    return false;
  }

  Future<Map<String, String>?> parseWireGuardLink(String link) async {
    try {
      final uri = Uri.parse(link);
      if (uri.scheme != 'wireguard') return null;

      final params = uri.queryParameters.map(
        (key, value) => MapEntry(key, Uri.decodeComponent(value)),
      );

      final privateKey = Uri.decodeComponent(uri.userInfo);
      if (privateKey.isEmpty) return null;

      final publicKey = params['publickey'];
      final address = params['address'];
      final mtu = params['mtu'];
      final endpoint = '${uri.host}:${uri.port}';
      if (publicKey == null || address == null || mtu == null) return null;

      final config = '''
[Interface]
PrivateKey = $privateKey
Address = $address
${_optionalField("DNS", params['dns'])}
MTU = $mtu

[Peer]
PublicKey = $publicKey
AllowedIPs = ${params['allowedips'] ?? '0.0.0.0/0, ::/0'}
Endpoint = $endpoint
${_optionalField("PresharedKey", params['presharedkey'])}
${_optionalField("PersistentKeepalive", params['keepalive'])}
''';

      return {'config': config, 'serverAddress': endpoint};
    } catch (e) {
      return null;
    }
  }

  String _optionalField(String key, String? value) {
    return value != null && value.isNotEmpty ? "$key = $value\n" : "";
  }

  Future<bool> ConnectWarp(String config, List<String> args) async {
    try {
      final conf = await parseWireGuardLink(config);
      if (conf == null) return false;

      await wireguard.initialize(interfaceName: 'wg0');
      await wireguard.startVpn(
        serverAddress: conf["serverAddress"]!,
        wgQuickConfig: conf["config"]!,
        providerBundleIdentifier: 'com.freedom.guard',
      );

      LogOverlay.showLog(
        "Connected To WARP",
        backgroundColor: Colors.greenAccent,
      );
      return true;
    } catch (e) {
      LogOverlay.showLog(
        "Failed to connect to WARP \nError: $e",
        backgroundColor: Colors.redAccent,
      );
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
              connStat = true;
              break;
            }
          } else if (config.split(",;,")[0] == "warp") {
            // config = config.split(",;,")[1].split("#")[0];
            // LogOverlay.showLog(config);
            // await ConnectWarp();
            // if (await test()) {
            //   connStat = true;
            //   break;
            // } else {
            //   await disConnect();
            // }
          }
          await Future.delayed(const Duration(milliseconds: 500));
        }
        LogOverlay.showLog('Config fetched successfully');
        return connStat;
      } else {
        LogOverlay.showLog('Failed to load config: ${response.statusCode}');
        return false;
      }
    } catch (e, stackTrace) {
      LogOverlay.showLog('Error in ConnectAuto: $e\nStackTrace: $stackTrace');
      return false;
    }
  }

  debugPrint(message) {
    LogOverlay.addLog(message);
  }

  Future<String?> getBestConfigFromSub(
    String sub, {
    int batchSize = 15,
    Duration batchTimeout = const Duration(seconds: 15),
    Duration requestTimeout = const Duration(seconds: 10),
    Duration pingTimeout = const Duration(seconds: 5),
  }) async {
    try {
      if (settings.getValue("batch_size") as String == "") {
        batchSize = 7;
      } else {
        batchSize = int.parse(settings.getValue("batch_size").toString());
      }
    } catch (_) {}
    final stopwatch = Stopwatch()..start();
    try {
      final uri = Uri.parse(sub);
      debugPrint('Fetching subscription from: $sub');
      final response = await http
          .get(uri)
          .timeout(
            requestTimeout,
            onTimeout: () {
              debugPrint('HTTP request timed out for: $sub');
              throw TimeoutException('Failed to fetch subscription');
            },
          );
      if (response.statusCode != 200) {
        debugPrint('HTTP request failed with status: ${response.statusCode}');
        return null;
      }
      String data = response.body;
      if (sub.toLowerCase().startsWith('http')) {
        try {
          data = utf8.decode(base64Decode(data));
          debugPrint('Successfully decoded base64 data');
        } catch (_) {}
      }
      final configs =
          data.split('\n').where((e) => e.trim().isNotEmpty).toList();
      if (configs.isEmpty) {
        debugPrint('No valid configs found in subscription');
        return null;
      }
      try {
        await flutterV2ray.initializeV2Ray();
        debugPrint('Initialized VIBE successfully');
      } catch (e, stackTrace) {
        debugPrint('Failed to initialize VIBE: $e\nStackTrace: $stackTrace');
        return null;
      }
      final List<Map<String, dynamic>> results = [];
      Future<void> processBatch(List<String> batch) async {
        final batchResults = await Future.wait(
          batch.map((config) async {
            try {
              final parser = FlutterV2ray.parseFromURL(config);
              final ping = await flutterV2ray
                  .getServerDelay(config: parser.getFullConfiguration())
                  .timeout(
                    pingTimeout,
                    onTimeout: () {
                      debugPrint('Ping timeout for config: $config');
                      return -1;
                    },
                  );
              if (ping > 0) {
                return {'config': config, 'ping': ping};
              } else {
                debugPrint('Invalid ping ($ping) for config: $config');
                return null;
              }
            } catch (e) {
              debugPrint(
                'Error for config: $config\nError: $e\nStackTrace: in parse config',
              );
              return null;
            }
          }),
          cleanUp: (result) => null,
        );
        results.addAll(
          batchResults
              .where((result) => result != null)
              .cast<Map<String, dynamic>>(),
        );
      }

      for (var i = 0; i < configs.length; i += batchSize) {
        final batch = configs.sublist(
          i,
          i + batchSize > configs.length ? configs.length : i + batchSize,
        );
        try {
          await processBatch(batch).timeout(
            batchTimeout,
            onTimeout: () {
              debugPrint(
                'Batch processing timed out for batch starting at index $i',
              );
            },
          );
        } catch (e, stackTrace) {
          debugPrint('Batch error at index $i: $e\nStackTrace: $stackTrace');
        }
      }
      stopwatch.stop();
      debugPrint('Processing took ${stopwatch.elapsed.inSeconds} seconds');
      if (results.isEmpty) {
        debugPrint('No valid results found');
        return null;
      }
      results.sort((a, b) => a['ping'].compareTo(b['ping']));
      LogOverlay.showLog(
        "Selected config: ${results.first['config']}",
        backgroundColor: Colors.blueAccent,
      );
      debugPrint(
        'Best config: ${results.first['config']} with ping: ${results.first['ping']}',
      );
      return results.first['config'] as String;
    } catch (e, stackTrace) {
      debugPrint(
        'Unexpected error in getBestConfigFromSub: $e\nStackTrace: $stackTrace',
      );
      return null;
    }
  }
}
