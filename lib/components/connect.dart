import 'dart:convert';
import 'package:Freedom_Guard/components/LOGLOG.dart';
import 'package:Freedom_Guard/components/settings.dart';
import 'package:flutter/material.dart';
import 'package:vibe_core/flutter_v2ray.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

ValueNotifier<V2RayStatus> v2rayStatus =
    ValueNotifier<V2RayStatus>(V2RayStatus());

class Connect extends Tools {
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
      flutterV2ray.stopV2Ray();
    } catch (_) {
      LogOverlay.addLog("Failed to disconnect");
    }
  }

  // Add Fragment, Mux, ...

  Future<String> addOptionsToVibe(dynamic parsedJson) async {
    final settingsValues = await Future.wait([
      settings.getValue("mux"),
      settings.getValue("fragment"),
      settings.getValue("bypass_iran"),
      settings.getBool("child_lock_enabled"),
      settings.getValue("block_ads_trackers"),
      settings.getList("preferred_dns"),
    ]);

    String mux = settingsValues[0] as String;
    String fragment = settingsValues[1] as String;
    String bypassIran = settingsValues[2] as String;
    bool childLock = settingsValues[3] as bool;
    String blockTADS = settingsValues[4] as String;
    List dnsServers = settingsValues[5] as List;

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

      if (dnsServers.isNotEmpty) {
        if (dnsServers != []) {
          parsedJson["dns"]["servers"] = dnsServers;
        }
      }

      if (bypassIran == "true") {
        (parsedJson["routing"]["rules"] as List).add({
          "type": "field",
          "ip": ["geoip:ir"],
          "outboundTag": "direct",
        });
      }

      if (childLock) {
        parsedJson["routing"]["rules"].add({
          "type": "field",
          "domain": ["geosite:category-adult"],
          "outboundTag": "blockedrule",
        });
      }

      if (blockTADS == "true") {
        (parsedJson["routing"]["rules"] as List).add({
          "type": "field",
          "domain": [
            "geosite:category-ads-all",
            "geosite:category-public-tracker",
          ],
          "outboundTag": "blockedrule",
        });
      }

      if (mux.trim().isNotEmpty) {
        try {
          final muxJson = json.decode(mux);
          if (muxJson is Map && muxJson["enabled"] == true) {
            for (var outbound in parsedJson["outbounds"]) {
              if (outbound is Map<String, dynamic>) {
                final protocol = outbound["protocol"];
                if (protocol != 'freedom' &&
                    protocol != 'blackhole' &&
                    protocol != 'direct') {
                  outbound["mux"] = muxJson;
                }
              }
            }
          }
        } catch (e) {}
      }

      if (fragment.trim().isNotEmpty) {
        try {
          final fragJson = json.decode(fragment);
          if (fragJson is Map && fragJson["enabled"] == true) {
            for (var outbound in parsedJson["outbounds"]) {
              if (outbound is Map<String, dynamic> &&
                  outbound["protocol"] == 'freedom') {
                outbound["settings"] ??= {};
                (outbound["settings"] as Map<String, dynamic>)["fragment"] =
                    fragJson;
              }
            }
          }
        } catch (e) {}
      }
    }
    return jsonEncode(parsedJson);
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
        if (!(args["type"] is String && args["type"] == "f_link")) {
          LogOverlay.addLog(parsedJson);
        }
        settings.setValue("config_backup", config);
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
          bypassSubnets: (await getSubNetforBypassVibe()),
          proxyOnly: (await settings.getBool("proxy_mode")),
          notificationDisconnectButtonName: "قطع اتصال",
        );
        int? proxyPort = jsonDecode(parsedJson)["inbounds"][0]['port'] as int?;
        await settings.getBool("proxy_mode") == true
            ? LogOverlay.showLog("Proxy mode enabled on port $proxyPort")
            : null;
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

    return false;
  }

  Future<bool> ConnectSub(String config, String type) async {
    await disConnect();
    List configs = [];
    const int maxRetries = 6;
    int attempt = 1;

    while (attempt <= maxRetries) {
      try {
        final response = await http.get(Uri.parse(config));
        if (response.statusCode == 200) {
          String raw = response.body.trim();
          String decoded;
          try {
            decoded = utf8.decode(base64Decode(raw));
            LogOverlay.addLog("Base64 decoded successfully, Attempt: $attempt");
          } catch (e) {
            decoded = raw;
            LogOverlay.addLog(
                "Base64 decode failed, using raw text, Attempt: $attempt");
          }
          configs = type == "sub"
              ? decoded.split('\n')
              : jsonDecode(decoded)["MOBILE"];
          break;
        } else {
          LogOverlay.addLog(
              "Request failed with status ${response.statusCode}, Attempt: $attempt");
          if (attempt == maxRetries) {
            LogOverlay.addLog("Max retries reached, giving up");
            return false;
          }
        }
      } catch (e) {
        LogOverlay.addLog("Config error on attempt $attempt: $e");
        if (attempt == maxRetries) {
          LogOverlay.addLog("Max retries reached, giving up");
          return false;
        }
      }
      int delaySeconds = 1 << (attempt - 1);
      LogOverlay.addLog("Retrying after $delaySeconds seconds...");
      await Future.delayed(Duration(seconds: delaySeconds));
      attempt++;
    }

    if (configs.isEmpty) {
      LogOverlay.addLog("No valid configs retrieved after retries");
      return false;
    }

    configs.shuffle();

    for (String cfg in configs) {
      cfg = cfg.replaceAll("vibe,;,", "");
      if (cfg.startsWith("warp")) {
        continue;
      } else if (cfg.startsWith("http")) {
        return await ConnectSub(cfg, "sub").timeout(Duration(seconds: 30),
            onTimeout: () {
          return false;
        });
      } else if (await testConfig(cfg) != -1) {
        if (await ConnectVibe(cfg, {})) {
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
                      config.startsWith("freedom-guard") ? "fgAuto" : "sub")
                  .timeout(Duration(seconds: 20), onTimeout: () {
                return false;
              });
              if (connStat == true) break;
            } else {
              if (await testConfig(config) != -1) {
                connStat = true;
                await ConnectVibe(config, {});
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
  bool _isConnected = false;
  bool get isConnected => _isConnected;
  Settings settings = new Settings();
  late final FlutterV2ray flutterV2ray;

  Tools() {
    flutterV2ray = FlutterV2ray(
      onStatusChanged: (status) {
        v2rayStatus.value = status;
        _isConnected = status.state == "CONNECTED";
      },
    );
    _initializeV2RayOnce();
  }
  Future<void> _initializeV2RayOnce() async {
    try {
      await flutterV2ray.initializeV2Ray();
    } catch (e, stackTrace) {
      _log("خطا در مقداردهی اولیه VIBE: $e\nStackTrace: $stackTrace",
          type: "add");
    }
  }

  void _log(
    dynamic message, {
    String type = "info",
  }) {
    if (type == "add") {
      LogOverlay.addLog(message.toString());
      return;
    }
    LogOverlay.showLog(message.toString(), type: type);
    debugPrint(message.toString());
  }

  bool isBase64(String str) {
    final base64RegExp = RegExp(r'^[A-Za-z0-9+/]+={0,2}$');
    str = str.replaceAll('\n', '').replaceAll('\r', '');
    return str.length % 4 == 0 && base64RegExp.hasMatch(str);
  }

  debugPrint(message) {
    LogOverlay.addLog(message);
  }

  Future<int> getConnectedDelay() async {
    return await flutterV2ray
        .getConnectedServerDelay()
        .timeout(Duration(seconds: 7), onTimeout: () {
      return -1;
    });
  }

  Future<int> testConfig(String config, {String type = "normal"}) async {
    try {
      final parser = FlutterV2ray.parseFromURL(config);

      final ping = await flutterV2ray
          .getServerDelay(config: parser.getFullConfiguration())
          .timeout(
        const Duration(seconds: 6),
        onTimeout: () {
          type != "f_link"
              ? debugPrint('Ping timeout for config: $config')
              : null;
          return -1;
        },
      );
      if (ping > 0) {
        return ping;
      } else {
        type != "f_link"
            ? debugPrint('Invalid ping ($ping) for config: $config')
            : null;
        return -1;
      }
    } catch (e) {
      type != "f_link"
          ? debugPrint(
              'Error for config: $config\nError: $e\nStackTrace: in parse config',
            )
          : null;
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
}
