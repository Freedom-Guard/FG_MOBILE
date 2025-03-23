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
    return isConnected;
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

  Future<String?> parseWireGuardLink(String link) async {
    try {
      final uri = Uri.parse(link);
      if (uri.scheme != 'wireguard') {
        return null;
      }
      final auth = uri.userInfo.split(':');
      if (auth.length != 2) {
        return null;
      }
      final privateKey = auth[0];
      final publicKey = uri.queryParameters['publickey'];
      final address = uri.queryParameters['address'];
      final dns = uri.queryParameters['dns'];
      final mtu = uri.queryParameters['mtu'];
      final allowedIps = uri.queryParameters['allowedips'];
      final endpoint = '${uri.host}:${uri.port}';
      final psk = uri.queryParameters['presharedkey'];

      if (publicKey == null ||
          address == null ||
          mtu == null) {
        return null;
      }

      final config = '''[Interface]
PrivateKey = $privateKey
Address = $address${dns != null ? '\nDNS = $dns' : ''}
MTU = $mtu

[Peer]
PublicKey = $publicKey
AllowedIPs = ${allowedIps ?? '0.0.0.0/0, ::/0'}
Endpoint = $endpoint${psk != null ? '\nPresharedKey = $psk' : ''}''';

      return config;
    } catch (_) {
      return null;
    }
  }

  Future<bool> ConnectWarp(config, args) async {
    try {
      String conf = await parseWireGuardLink(config) as String;
      await wireguard.initialize(interfaceName: 'wg0');
      // const String conf = '''[Interface]
      // PrivateKey =
      // Address = 172.16.0.2/32
      // DNS = 1.1.1.1, 1.0.0.1
      // MTU = 1280

      // [Peer]
      // PublicKey = bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=
      // AllowedIPs = 0.0.0.0/0, ::/0
      // Endpoint = engage.cloudflareclient.com:2408''';
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
      LogOverlay.showLog("Failed to connect to WARP");
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
        batchSize = 15;
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
        debugPrint('Failed to initialize V2Ray: $e\nStackTrace: $stackTrace');
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
      LogOverlay.showLog(results.first['config']);
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
