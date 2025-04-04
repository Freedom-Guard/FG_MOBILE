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

  Timer? _configUpdateTimer;
  void startConfigUpdateTimer(String fgconfig, int timeout) {
    if (_configUpdateTimer != null && _configUpdateTimer!.isActive) {
      _configUpdateTimer!.cancel();
    }
    _configUpdateTimer = Timer.periodic(const Duration(minutes: 15), (
      timer,
    ) async {
      if (isConnected) {
        await disConnect();
        await ConnectAuto(fgconfig, timeout);
      }
    });
  }

  void stopConfigUpdateTimer() {
    if (_configUpdateTimer != null && _configUpdateTimer!.isActive) {
      _configUpdateTimer!.cancel();
      _configUpdateTimer = null;
    }
  }

  Future<String> addOptionsToVibe(dynamic parsedJson) async {
    String mux = await settings.getValue("mux");
    String fragment = await settings.getValue("fragment");
    String BypassIran = await settings.getValue("bypass_iran");
    String blockTADS = await settings.getValue("block_ads_trackers");
    LogOverlay.addLog("fragment: " + jsonEncode(fragment).toString());
    LogOverlay.addLog("mux: " + mux.toString());

    if (parsedJson is Map<String, dynamic>) {
      if (BypassIran == "true") {
        parsedJson["routing"] ??= {};
        parsedJson["routing"]["rules"] ??= [];
        (parsedJson["routing"]["rules"] as List).add({
          "type": "field",
          "ip": ["geoip:ir"],
          "outboundTag": "direct",
        });
      }
      if (blockTADS == "true") {
        parsedJson["routing"] ??= {};
        parsedJson["routing"]["rules"] ??= [];

        List<String> adDomains = [
          "adservice.google.com",
          "doubleclick.net",
          "ads.youtube.com",
        ];

        (parsedJson["routing"]["rules"] as List).addAll([
          {
            "outboundTag": "block",
            "domain": [
              "geosite:category-ads-all",
              "geosite:malware",
              "geosite:phishing",
              "geosite:cryptominers",
            ],
            "type": "field",
          },
          {
            "outboundTag": "block",
            "ip": ["geoip:malware", "geoip:phishing"],
            "type": "field",
          },
        ]);

        parsedJson["outbounds"] ??= [];
        (parsedJson["outbounds"] as List).add({
          "tag": "blocked",
          "protocol": "blackhole",
          "settings": {},
        });
      }

      if (mux != "" && json.decode(mux)["enabled"] == true) {
        parsedJson["mux"] = json.decode(mux);
      }
      if (fragment != "" && json.decode(fragment)["enabled"] == true) {
        parsedJson["fragment"] = json.decode(fragment);
      }
    } else if (parsedJson is List<dynamic>) {
      parsedJson.forEach((element) {
        if (mux != "") {
          element["mux"] = json.decode(mux);
        }
        if (fragment != "") {
          element["fragment"] = json.decode(fragment);
        }
      }); 
    }
    return jsonEncode(parsedJson).toString();
  }

  Future<dynamic> getSubNetforBypassVibe() async {
    if (await settings.getValue("bypass_lan") == "true") {
      LogOverlay.showLog("Bypass LAN Enabled");
      return [
        "0.0.0.0/5",
        "8.0.0.0/7",
        "11.0.0.0/8",
        "12.0.0.0/6",
        "16.0.0.0/4",
        "32.0.0.0/3",
        "64.0.0.0/2",
        "128.0.0.0/3",
        "160.0.0.0/5",
        "168.0.0.0/6",
        "172.0.0.0/12",
        "172.32.0.0/11",
        "172.64.0.0/10",
        "172.128.0.0/9",
        "173.0.0.0/8",
        "174.0.0.0/7",
        "176.0.0.0/4",
        "192.0.0.0/9",
        "192.128.0.0/11",
        "192.160.0.0/13",
        "192.169.0.0/16",
        "192.170.0.0/15",
        "192.172.0.0/14",
        "192.176.0.0/12",
        "192.192.0.0/10",
        "193.0.0.0/8",
        "194.0.0.0/7",
        "196.0.0.0/6",
        "200.0.0.0/5",
        "208.0.0.0/4",
        "240.0.0.0/4",
      ];
    } else
      return null;
  }

  // Connects to a single V2Ray config
  Future<bool> ConnectVibe(String config, dynamic args) async {
    final stopwatch = Stopwatch()..start();
    LogOverlay.showLog(
      "Connecting To VIBE...",
      backgroundColor: Colors.blueAccent,
    );

    try {
      await flutterV2ray.initializeV2Ray();
    } catch (_) {
      LogOverlay.showLog("Failed to initialize VIBE");
      return false;
    }

    try {
      String parser = "";
      if (await flutterV2ray.requestPermission()) {
        try {
          var parsedConfig = FlutterV2ray.parseFromURL(config);
          parser =
              parsedConfig != null
                  ? parsedConfig.getFullConfiguration()
                  : config;
        } catch (_) {
          parser = config;
        }

        int ping = -1;
        try {
          ping = await flutterV2ray
              .getServerDelay(config: parser)
              .timeout(Duration(seconds: 4), onTimeout: () => -1);
        } catch (_) {
          ping = -1;
        }

        if (ping != -1) {
          LogOverlay.showLog(
            'Ping connecting $ping ms',
            backgroundColor: Colors.blueAccent,
          );
        }
        String parsedJson = await addOptionsToVibe(jsonDecode(parser));
        LogOverlay.addLog(parsedJson);
        flutterV2ray.startV2Ray(
          remark: "Freedom Guard",
          config: parsedJson,
          blockedApps:
              (await settings.getValue("split_app"))
                  .toString()
                  .replaceAll("[", "")
                  .replaceAll("]", "")
                  .split(",")
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList(),
          bypassSubnets: await getSubNetforBypassVibe(),
          proxyOnly: false,
          notificationDisconnectButtonName: "قطع اتصال",
        );

        isConnected = true;
        return true;
      } else {
        LogOverlay.showLog(
          "Permission Denied: Please grant necessary permissions to establish a connection.",
          backgroundColor: Colors.redAccent,
        );
      }
    } catch (e, stackTrace) {
      LogOverlay.showLog(
        "Failed to connect to VIBE \n ${e.toString()}\nStackTrace: ${stackTrace.toString()}",
        backgroundColor: Colors.redAccent,
      );
      return false;
    } finally {
      stopwatch.stop();
      debugPrint('Connection took ${stopwatch.elapsed.inMilliseconds} ms');
    }

    isConnected = false;
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
      var conf = {};
      if (config.startsWith("wire:::")) {
        conf["config"] = config.split("wire:::\n")[1];
        conf["serverAddress"] = conf["config"].split("\n")[1];
      } else {
        conf = await parseWireGuardLink(config) as Map<String, String>;
      }
      if (conf == "") return false;

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
      isConnected = true;
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
        String userIsp = await settings.getValue("user_isp").toString();
        List<String> publicServers = List<String>.from(
          userIsp != "" && data.containsKey(userIsp)
              ? data[userIsp]
              : (data.containsKey("MOBILE") ? data["MOBILE"] : []),
        );
        var connStat = false;
        for (var config in publicServers) {
          if (config.split(",;,")[0] == "vibe") {
            config = config.split(",;,")[1].split("#")[0];
            if (config.startsWith("http")) {
              var bestConfig = await getBestConfigFromSub(config);
              if (bestConfig != null && await testConfig(bestConfig) != -1) {
                connStat = await ConnectVibe(bestConfig, []);
                if (connStat == true) break;
              }
            } else {
              if (await testConfig(config) != -1) {
                connStat = true;
                await ConnectVibe(config, []);
                if (connStat == true) break;
              }
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

  Future<int> testConfig(String config) async {
    try {
      await flutterV2ray.initializeV2Ray();
      final parser = FlutterV2ray.parseFromURL(config);

      final ping = await flutterV2ray
          .getServerDelay(config: parser.getFullConfiguration())
          .timeout(
            const Duration(seconds: 6),
            onTimeout: () {
              debugPrint('Ping timeout for config: $config');
              return -1;
            },
          );
      if (ping > 0) {
        return ping;
      } else {
        debugPrint('Invalid ping ($ping) for config: $config');
        return -1;
      }
    } catch (e) {
      debugPrint(
        'Error for config: $config\nError: $e\nStackTrace: in parse config',
      );
      return -1;
    }
  }

  Future<bool> isConfigValid(String config) async {
    return await testConfig(config) > 0;
  }

  Future<String?> getBestConfigFromSub(
    String sub, {
    int batchSize = 20,
    Duration batchTimeout = const Duration(seconds: 40),
    Duration requestTimeout = const Duration(seconds: 30),
    Duration pingTimeout = const Duration(seconds: 6),
  }) async {
    bool isQUICK = false;
    try {
      String fastConnectValue = await settings.getValue("fast_connect");
      isQUICK =
          fastConnectValue.isNotEmpty &&
          bool.tryParse(fastConnectValue) == true;
      if (isQUICK) {
        String bestConfig = await settings.getValue("best_config_backup");
        String backupSub = await settings.getValue("backup_sub");
        if (sub == backupSub &&
            bestConfig.isNotEmpty &&
            await isConfigValid(bestConfig)) {
          LogOverlay.showLog(
            "Quick connect mode...",
            backgroundColor: Colors.deepPurpleAccent,
          );
          return bestConfig;
        }
        LogOverlay.showLog(
          "Quick connect failed, switching to normal connect",
          backgroundColor: Colors.orangeAccent,
        );
      }
    } catch (_) {}

    settings.setValue("backup_sub", sub);
    batchSize =
        int.tryParse(await settings.getValue("batch_size")) ?? batchSize;

    final uri = Uri.parse(sub);
    debugPrint('Fetching subscription from: $sub');
    final response = await http
        .get(uri)
        .timeout(
          requestTimeout,
          onTimeout:
              () => throw TimeoutException('Failed to fetch subscription'),
        );
    if (response.statusCode != 200) return null;

    String data = response.body;
    if (sub.toLowerCase().startsWith('http')) {
      try {
        data = utf8.decode(base64Decode(data));
      } catch (_) {}
    }

    final configs = data.split('\n').where((e) => e.trim().isNotEmpty).toList();
    if (configs.isEmpty) return null;

    try {
      await flutterV2ray.initializeV2Ray();
    } catch (e) {
      debugPrint('Failed to initialize VIBE: $e');
      return null;
    }

    final List<Map<String, dynamic>> results = [];
    for (var i = 0; i < configs.length; i += batchSize) {
      final batch = configs.sublist(
        i,
        i + batchSize > configs.length ? configs.length : i + batchSize,
      );
      final batchResults = await Future.wait(
        batch.map((config) async {
          try {
            final parser = FlutterV2ray.parseFromURL(config);
            final ping = await flutterV2ray
                .getServerDelay(config: parser.getFullConfiguration())
                .timeout(pingTimeout, onTimeout: () => -1);
            return ping > 0 ? {'config': config, 'ping': ping} : null;
          } catch (_) {
            return null;
          }
        }),
      ).then((list) => list.whereType<Map<String, dynamic>>().toList());

      results.addAll(batchResults);
    }

    if (results.isEmpty) return null;
    results.sort((a, b) => a['ping'].compareTo(b['ping']));
    final bestConfig = results.first['config'];

    LogOverlay.showLog(
      "Selected config: $bestConfig",
      backgroundColor: Colors.blueAccent,
    );
    settings.setValue("best_config_backup", bestConfig);
    return bestConfig;
  }
}
