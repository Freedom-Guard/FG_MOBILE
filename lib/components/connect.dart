import 'dart:convert';
import 'package:Freedom_Guard/components/LOGLOG.dart';
import 'package:Freedom_Guard/components/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_v2ray/flutter_v2ray.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

ValueNotifier<V2RayStatus> v2rayStatus =
    ValueNotifier<V2RayStatus>(V2RayStatus());

class Connect extends Tools {
  Future<void> connected() async {
    isConnected = true;
  }

  Future<bool> connectedQ() async {
    return isConnected;
  }

  // Test Internet
  Future<bool> test() async {
    try {
      final response = await http
          .get(Uri.parse('https://www.google.com'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        LogOverlay.showLog("Connected To internet", type: "success");
        return true;
      }
    } catch (_) {}
    LogOverlay.showLog("No internet", type: "error");
    return false;
  }

  // Diconnect VPN
  Future<void> disConnect() async {
    try {
      await flutterV2ray.initializeV2Ray();
      flutterV2ray.stopV2Ray();
    } catch (_) {
      LogOverlay.addLog("Failed to disconnect");
    }
  }

  // Add Fragment, Mux, ...
  Future<String> addOptionsToVibe(dynamic parsedJson) async {
    String mux = await settings.getValue("mux");
    String fragment = await settings.getValue("fragment");
    String BypassIran = await settings.getValue("bypass_iran");
    bool childLock = await settings.getBool("child_lock_enabled");
    String blockTADS = await settings.getValue("block_ads_trackers");
    LogOverlay.addLog("fragment: " + jsonEncode(fragment).toString());
    LogOverlay.addLog("mux: " + mux.toString());

    if (parsedJson is Map<String, dynamic>) {
      parsedJson["outbounds"] ??= [];
      parsedJson["routing"] ??= {};
      parsedJson["routing"]["rules"] ??= [];
      parsedJson["outbounds"].add({
        "protocol": "blackhole",
        "tag": "blockedrule",
        "settings": {
          "response": {"type": "http"},
        },
      });
      if (BypassIran == "true") {
        parsedJson["routing"] ??= {};
        parsedJson["routing"]["rules"] ??= [];
        (parsedJson["routing"]["rules"] as List).add({
          "type": "field",
          "ip": ["geoip:ir"],
          "outboundTag": "direct",
        });
      }
      if (childLock) {
        parsedJson["routing"]["rules"].add({
          "type": "field",
          "domain": ["pornhub.com"],
          "outboundTag": "blockedrule",
        });
      }
      if (blockTADS == "true") {
        parsedJson["routing"] ??= {};
        parsedJson["routing"]["rules"] ??= [];

        (parsedJson["routing"]["rules"] as List).addAll([
          {
            "outboundTag": "blockedrule",
            "domain": [
              "geosite:category-ads-all",
              "geosite:category-public-tracker",
            ],
            "type": "field",
          },
        ]);
      }
      if (mux.trim().isNotEmpty) {
        final muxJson = json.decode(mux);
        if (muxJson is Map && muxJson["enabled"] == true) {
          bool updated = false;
          if (parsedJson["outbounds"] is List) {
            for (var outbound in parsedJson["outbounds"]) {
              if (outbound is Map && outbound.containsKey("mux")) {
                outbound["mux"] = muxJson;
                updated = true;
                break;
              }
            }
            if (!updated &&
                parsedJson["outbounds"].isNotEmpty &&
                parsedJson["outbounds"][0] is Map) {
              var counter = 0;
              for (var i in parsedJson["outbounds"]) {
                parsedJson["outbounds"][counter]["mux"] = muxJson;
                counter++;
              }
            }
          }
        }
      }

      if (fragment.trim().isNotEmpty) {
        final fragJson = json.decode(fragment);
        if (fragJson is Map && fragJson["enabled"] == true) {
          var counter = 0;
          for (var i in parsedJson["outbounds"]) {
            if (parsedJson["outbounds"][counter]["protocol"] == 'freedom') {
              parsedJson["outbounds"][counter]["settings"]["fragment"] =
                  fragJson;
            }
            counter++;
          }
        }
      }
    }
    return jsonEncode(parsedJson).toString();
  }

  // Connects to a single V2Ray config
  Future<bool> ConnectVibe(String config, dynamic args) async {
    await disConnect();
    final stopwatch = Stopwatch()..start();
    LogOverlay.showLog(
      "Connecting To VIBE...",
      backgroundColor: Colors.blueAccent,
    );

    try {
      await flutterV2ray.initializeV2Ray();
    } catch (_) {
      LogOverlay.showLog("Failed to initialize VIBE", type: "error");
      return false;
    }

    try {
      String parser = "";
      if (await flutterV2ray.requestPermission()) {
        try {
          var parsedConfig = FlutterV2ray.parseFromURL(config);
          parser = parsedConfig != null
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
          LogOverlay.addLog('Ping connecting $ping ms');
        }
        String parsedJson = await addOptionsToVibe(jsonDecode(parser));
        LogOverlay.addLog(parsedJson);
        flutterV2ray.startV2Ray(
          remark: "Freedom Guard",
          config: parsedJson,
          blockedApps: (await settings.getValue("split_app"))
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
            type: "error");
      }
    } catch (e, stackTrace) {
      LogOverlay.showLog(
          "Failed to connect to VIBE \n ${e.toString()}\nStackTrace: ${stackTrace.toString()}",
          type: "error");
      return false;
    } finally {
      stopwatch.stop();
      debugPrint('Connection took ${stopwatch.elapsed.inMilliseconds} ms');
    }

    isConnected = false;
    return false;
  }

  Future<bool> ConnectSub(String config, String type) async {
    await disConnect();
    List configs = [];

    try {
      final response = await http.get(Uri.parse(config));
      if (response.statusCode == 200) {
        String raw = response.body.trim();
        String decoded;
        try {
          decoded = utf8.decode(base64Decode(raw));
          LogOverlay.addLog("Base64 decoded successfully");
        } catch (e) {
          decoded = raw;
          LogOverlay.addLog("Base64 decode failed, using raw text");
        }
        configs =
            type == "sub" ? decoded.split('\n') : jsonDecode(decoded)["MOBILE"];
      }
    } catch (e) {
      LogOverlay.showLog("config error \n $e", type: "error");
    }

    configs.shuffle();

    for (String cfg in configs) {
      if (cfg.startsWith("warp")) {
        continue;
      } else if (cfg.startsWith("http")) {
        return await ConnectSub(cfg, "sub");
      } else if (await testConfig(cfg.replaceAll("vibe,;,", "")) != -1) {
        if (await ConnectVibe(cfg, [])) {
          return true;
        }
      }
    }

    return false;
  }

  // Fetches and processes configs from a URL
  Future<bool> ConnectFG(String fgconfig, int timeout) async {
    try {
      final uri = Uri.parse(fgconfig);
      final response = await http.get(uri).timeout(
            Duration(milliseconds: timeout),
            onTimeout: () => throw TimeoutException(
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
            if (config.startsWith("http") ||
                config.startsWith("freedom-guard")) {
              connStat = await ConnectSub(
                  config.replaceAll("freedom-guard://", ""),
                  config.startsWith("freedom-guard") ? "fgAuto" : "sub");
              if (connStat == true) break;
            } else {
              if (await testConfig(config) != -1) {
                connStat = true;
                await ConnectVibe(config, []);
                if (connStat == true) break;
              }
            }
          } else if (config.split(",;,")[0] == "warp") {}
          await Future.delayed(const Duration(milliseconds: 500));
        }
        return connStat;
      } else {
        LogOverlay.showLog('Failed to load config: ${response.statusCode}',
            type: "error");
        return false;
      }
    } catch (e, stackTrace) {
      LogOverlay.addLog('Error in ConnectAuto: $e\nStackTrace: $stackTrace');
      return false;
    }
  }
}

class Tools {
  bool isConnected = false;
  Settings settings = new Settings();
  late final FlutterV2ray flutterV2ray = FlutterV2ray(
    onStatusChanged: (status) {
      v2rayStatus.value = status;
    },
  );

  bool isBase64(String str) {
    final base64RegExp = RegExp(r'^[A-Za-z0-9+/]+={0,2}$');
    str = str.replaceAll('\n', '').replaceAll('\r', '');
    return str.length % 4 == 0 && base64RegExp.hasMatch(str);
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

  Future<String?> getBestConfigFromSub(
    String sub, {
    int batchSize = 20,
    Duration batchTimeout = const Duration(seconds: 40),
    Duration requestTimeout = const Duration(seconds: 30),
    Duration pingTimeout = const Duration(seconds: 6),
  }) async {
    try {
      final fastConnectValue = await settings.getValue("fast_connect");
      final isQuick = fastConnectValue.isNotEmpty &&
          bool.tryParse(fastConnectValue) == true;

      if (isQuick) {
        final bestConfig = await settings.getValue("best_config_backup");
        final backupSub = await settings.getValue("backup_sub");

        if (sub == backupSub &&
            bestConfig.isNotEmpty &&
            await isConfigValid(bestConfig)) {
          LogOverlay.showLog("Quick connect activated", type: "success");
          return bestConfig;
        }
        LogOverlay.showLog("Quick connect failed, switching to normal mode",
            type: "warning");
      }

      await settings.setValue("backup_sub", sub.toString());
      final customBatchSize = int.tryParse(
        await settings.getValue("batch_size"),
      );
      final effectiveBatchSize = customBatchSize ?? batchSize;

      final uri = Uri.tryParse(sub);
      if (uri == null || !uri.hasScheme) {
        LogOverlay.showLog(
          "Invalid subscription URL",
          type: "error",
        );
        return null;
      }

      debugPrint('Fetching subscription from: $sub');
      final response = await http.get(uri).timeout(
            requestTimeout,
            onTimeout: () => throw TimeoutException('Request timed out'),
          );

      if (response.statusCode != 200) {
        LogOverlay.showLog("Server error: ${response.statusCode}",
            type: "error");
        return null;
      }

      String data = response.body;
      if (uri.scheme == 'http' || uri.scheme == 'https') {
        try {
          data = utf8.decode(base64Decode(data));
        } catch (e) {
          debugPrint('Error decoding data: $e');
        }
      }

      final configs =
          data.split('\n').where((e) => e.trim().isNotEmpty).toList();
      if (configs.isEmpty) {
        LogOverlay.showLog("No configs found in subscription", type: "error");
        return null;
      }

      try {
        await flutterV2ray.initializeV2Ray();
      } catch (e) {
        debugPrint('Failed to initialize V2Ray: $e');
        LogOverlay.showLog("VIBE initialization failed", type: "error");
        return null;
      }

      final List<Map<String, dynamic>> results = [];
      for (var i = 0; i < configs.length; i += effectiveBatchSize) {
        final batchEnd = (i + effectiveBatchSize > configs.length)
            ? configs.length
            : i + effectiveBatchSize;
        final batch = configs.sublist(i, batchEnd);

        final batchResults = await Future.wait(
          batch.map((config) async {
            try {
              final parser = FlutterV2ray.parseFromURL(config);
              final ping = await flutterV2ray
                  .getServerDelay(config: parser.getFullConfiguration())
                  .timeout(pingTimeout, onTimeout: () => -1);
              return ping > 0 ? {'config': config, 'ping': ping} : null;
            } catch (e) {
              debugPrint('Error testing config ping: $e');
              return null;
            }
          }),
        ).timeout(
          batchTimeout,
          onTimeout: () {
            debugPrint('Batch timeout for configs: $batch');
            return [];
          },
        ).then(
          (list) => list
              .where((e) => e != null)
              .cast<Map<String, dynamic>>()
              .toList(),
        );

        results.addAll(batchResults);
      }

      if (results.isEmpty) {
        LogOverlay.showLog("No valid configs found", type: "error");
        return null;
      }

      results.sort((a, b) => a['ping'].compareTo(b['ping']));
      final bestConfig = results.first['config'];

      LogOverlay.showLog(
        "Best config selected with ping ${results.first['ping']}ms",
      );
      await settings.setValue("best_config_backup", bestConfig);
      return bestConfig.toString();
    } catch (e) {
      debugPrint('Error in getBestConfigFromSub: $e');
      LogOverlay.showLog("Unexpected error: $e", type: "error");
      return null;
    }
  }
}
