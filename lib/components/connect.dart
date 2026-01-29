import 'dart:async';

import 'dart:convert';
import 'package:Freedom_Guard/core/global.dart';
import 'package:Freedom_Guard/core/network/network_service.dart';
import 'package:Freedom_Guard/utils/LOGLOG.dart';
import 'package:Freedom_Guard/components/safe_mode.dart';
import 'package:Freedom_Guard/components/settings.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_v2ray_client/flutter_v2ray.dart';
import 'package:http/http.dart' as http;

class ConfigPingResult {
  final String configLink;
  final int ping;

  ConfigPingResult({required this.configLink, required this.ping});

  Map<String, dynamic> toJson() => {'configLink': configLink, 'ping': ping};

  factory ConfigPingResult.fromJson(Map<String, dynamic> json) {
    return ConfigPingResult(configLink: json['configLink'], ping: json['ping']);
  }
}

ValueNotifier<V2RayStatus> v2rayStatus = ValueNotifier<V2RayStatus>(
  V2RayStatus(),
);

class Connect extends Tools {
  Timer? _guardModeTimer;
  bool _guardModeActive = false;
  final String _cachedConfigsKey = 'cached_config_pings';

  Future<void> _saveConfigPings(List<ConfigPingResult> configs) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> jsonList =
          configs.map((c) => jsonEncode(c.toJson())).toList();
      await prefs.setStringList(_cachedConfigsKey, jsonList);
      LogOverlay.addLog("Saved ${configs.length} configs with pings to cache.");
    } catch (e) {
      LogOverlay.addLog("Error saving config pings: $e");
    }
  }

  Future<List<ConfigPingResult>> loadConfigPings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String>? jsonList = prefs.getStringList(_cachedConfigsKey);
      if (jsonList == null || jsonList.isEmpty) {
        return [];
      }
      return jsonList
          .map((s) => ConfigPingResult.fromJson(jsonDecode(s)))
          .toList();
    } catch (e) {
      LogOverlay.addLog("Failed to load cached configs: $e");
      await _clearConfigPings();
      return [];
    }
  }

  Future<void> _clearConfigPings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cachedConfigsKey);
    LogOverlay.addLog("Cleared config ping cache.");
  }

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

  Future<void> disConnect({typeDis = "normal"}) async {
    try {
      vibeCoreMain.stopV2Ray();
      if (typeDis != "guard") {
        _stopGuardModeMonitoring();
      }
    } catch (_) {
      LogOverlay.addLog("Failed to disconnect");
    }
  }

  getJson(config) {
    return V2ray.parseFromURL(config);
  }

  Future<bool> ConnectVibe(
    String config,
    dynamic args, {
    typeDis = "normal",
  }) async {
    await disConnect(typeDis: typeDis);
    final stopwatch = Stopwatch()..start();
    GlobalFGB.connStatText.value = "Connecting to VIBE...";

    LogOverlay.addLog(
      "Connecting To VIBE...",
    );

    try {
      String parser = "";
      bool requestPermission =
          typeDis != "quick" ? await vibeCoreMain.requestPermission() : true;
      if (requestPermission) {
        try {
          var parsedConfig = V2ray.parseFromURL(config);
          parser = parsedConfig != null
              ? parsedConfig.getFullConfiguration()
              : config;
        } catch (_) {
          parser = config;
        }

        int ping = -1;
        try {
          ping = await vibeCoreMain
              .getServerDelay(config: parser)
              .timeout(Duration(seconds: 2), onTimeout: () => -1);
        } catch (_) {
          ping = -1;
        }

        if (ping != -1) {
          LogOverlay.addLog('Ping connecting $ping ms');
        }
        String parsedJson = await addOptionsToVibe(jsonDecode(parser));
        if ((await settings.getBool("safe_mode")) == true) {
          final safeStat = await SafeMode().checkXrayAndConfirm(parsedJson);
          LogOverlay.addLog("safe mode: " + safeStat.toString());
          if (!safeStat) {
            return false;
          }
        }
        if (!(args["type"] is String && args["type"] == "f_link")) {
          LogOverlay.addLog(parsedJson);
          SettingsApp().setValue("config_backup", config);
          LogOverlay.addLog("saved config_backup to " + config);
        } else {
          settings.setValue("config_backup", "");
        }

        vibeCoreMain.startV2Ray(
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
        _isConnected = true;
        GlobalFGB.connStatText.value = "Connected successfully ✅";
        return true;
      } else {
        LogOverlay.showLog(
          "Permission Denied: Please grant necessary permissions to establish a connection.",
          type: "error",
        );
      }
    } catch (e, stackTrace) {
      LogOverlay.showLog(
        "Failed to connect to VIBE \n ${e.toString()}\nStackTrace: ${stackTrace.toString()}",
        type: "error",
      );
      return false;
    } finally {
      stopwatch.stop();
      LogOverlay.addLog(
          'Connection took ${stopwatch.elapsed.inMilliseconds} ms');
    }

    return false;
  }

  Future<bool> ConnectSub(
    String config,
    String type, {
    String typeC = "normal",
  }) async {
    await disConnect();
    GlobalFGB.connStatText.value = "📡 Fetching subscription configurations…";
    LogOverlay.addLog("Trying cached configs first...");
    List<ConfigPingResult> cachedConfigs = await loadConfigPings();
    bool isCache = (await settings.getValue("selectedServer")) ==
        (await settings.getValue("saved_sub"));
    await settings.setValue("saved_sub", config);

    if (cachedConfigs.isNotEmpty && isCache) {
      cachedConfigs.sort((a, b) => a.ping.compareTo(b.ping));

      for (var cachedResult in cachedConfigs) {
        LogOverlay.addLog(
          "Testing cached config with ping: ${cachedResult.ping}ms",
        );
        int currentPing = await testConfig(
          cachedResult.configLink,
          type: typeC,
        );

        if (currentPing != -1) {
          if (await ConnectVibe(cachedResult.configLink, {
            "type": type,
            "link": config,
          })) {
            final guardModeEnabled =
                (await settings.getValue("guard_mode")) == "true";
            if (guardModeEnabled) {
              List<String> allConfigs =
                  cachedConfigs.map((c) => c.configLink).toList();
              _startGuardModeMonitoring(cachedResult.configLink, allConfigs);
            }
            LogOverlay.addLog(
              "Connected using cached config.",
            );
            return true;
          }
        } else {
          LogOverlay.addLog(
            "Cached config failed or ping is ($currentPing ms).",
          );
        }
      }
      LogOverlay.addLog("All cached configs failed. Fetching new list.");
    } else {
      _clearConfigPings();
      LogOverlay.addLog("No cached configs found. Fetching new list.");
    }

    List fetchedConfigs = [];
    const int maxRetries = 6;
    int attempt = 1;

    while (attempt <= maxRetries) {
      try {
        final response = await NetworkService.get(config);
        if (response.statusCode == 200) {
          String raw = response.body.trim();
          String decoded;
          try {
            decoded = utf8.decode(base64Decode(raw));
            LogOverlay.addLog("Base64 decoded successfully, Attempt: $attempt");
          } catch (e) {
            decoded = raw;
            LogOverlay.addLog(
              "Base64 decode failed, using raw text, Attempt: $attempt",
            );
          }
          fetchedConfigs = type == "sub" || type == "f_link"
              ? decoded.split('\n')
              : jsonDecode(decoded)["MOBILE"];
          break;
        } else {
          LogOverlay.addLog(
            "Request failed with status ${response.statusCode}, Attempt: $attempt",
          );
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

    if (fetchedConfigs.isEmpty) {
      LogOverlay.addLog("No valid configs retrieved after retries");
      return false;
    }

    LogOverlay.addLog(
      "Fetched ${fetchedConfigs.length} new configs. Clearing old cache and testing all sequentially...",
    );

    await _clearConfigPings();

    List<ConfigPingResult> newPingResults = [];
    List<String> httpSubConfigs = [];
    List<String> directConfigs = [];
    final guardModeEnabled = (await settings.getValue("guard_mode")) == "true";

    for (String cfg in fetchedConfigs) {
      cfg = cfg.replaceAll("vibe,;,", "").trim();
      if (cfg.isEmpty || cfg.startsWith("warp")) {
        continue;
      }

      if (cfg.startsWith("http")) {
        httpSubConfigs.add(cfg);
      } else {
        directConfigs.add(cfg);
      }
    }

    LogOverlay.addLog(
      "Starting sequential ping test on ${directConfigs.length} direct configs.",
    );

    directConfigs.shuffle();

    for (String cfg in directConfigs) {
      int ping = await testConfig(cfg, type: typeC);

      if (ping != -1) {
        LogOverlay.addLog("Ping Success: ${ping}ms for config: ${cfg}");
        newPingResults.add(ConfigPingResult(configLink: cfg, ping: ping));
        if (_isConnected == false)
          await ConnectVibe(cfg, {"type": type, "link": config});
        await _saveConfigPings(newPingResults);
      } else {
        LogOverlay.addLog("Ping Failed for config: ${cfg}");
      }
    }

    newPingResults.sort((a, b) => a.ping.compareTo(b.ping));

    await _saveConfigPings(newPingResults);

    List<String> allSortedConfigsForGuardMode =
        newPingResults.map((c) => c.configLink).toList();

    for (var result in newPingResults) {
      LogOverlay.addLog("Trying new config with ping: ${result.ping}ms");
      if (await ConnectVibe(result.configLink, {
        "type": type,
        "link": config,
      })) {
        if (guardModeEnabled) {
          _startGuardModeMonitoring(
            result.configLink,
            allSortedConfigsForGuardMode,
          );
        }
        LogOverlay.addLog("Connected to new config.");
        return true;
      }
    }

    LogOverlay.addLog(
      "All new direct configs failed. Trying http/sub configs...",
    );
    for (String httpCfg in httpSubConfigs) {
      if (await ConnectSub(
        httpCfg,
        "sub",
        typeC: typeC,
      ).timeout(Duration(seconds: 30), onTimeout: () => false)) {
        return true;
      } else {
        return _isConnected;
      }
    }

    LogOverlay.addLog("Failed to connect to any config from subscription.");
    return false;
  }

  void _startGuardModeMonitoring(
    String currentConfig,
    List<String> allSortedConfigs,
  ) {
    _guardModeActive = true;
    int retryCount = 0;
    const int maxRetries = 2;
    String activeConfig = currentConfig;

    _guardModeTimer?.cancel();
    LogOverlay.addLog("Smart Guard mode monitoring started.");

    Timer(const Duration(seconds: 10), () async {
      if (!_guardModeActive) return;
      await _performGuardCheck(
        allSortedConfigs: allSortedConfigs,
        activeConfig: activeConfig,
        retryCount: retryCount,
        maxRetries: maxRetries,
        onConfigSwitched: (newConfig) {
          activeConfig = newConfig;
          retryCount = 0;
        },
        onRetryIncrement: () => retryCount++,
        onRetryReset: () => retryCount = 0,
      );
    });

    _guardModeTimer =
        Timer.periodic(const Duration(seconds: 120), (timer) async {
      if (!_guardModeActive) {
        timer.cancel();
        return;
      }

      await _performGuardCheck(
        allSortedConfigs: allSortedConfigs,
        activeConfig: activeConfig,
        retryCount: retryCount,
        maxRetries: maxRetries,
        onConfigSwitched: (newConfig) {
          activeConfig = newConfig;
          retryCount = 0;
        },
        onRetryIncrement: () => retryCount++,
        onRetryReset: () => retryCount = 0,
      );
    });
  }

  Future<void> _performGuardCheck({
    required List<String> allSortedConfigs,
    required String activeConfig,
    required int retryCount,
    required int maxRetries,
    required void Function(String) onConfigSwitched,
    required VoidCallback onRetryIncrement,
    required VoidCallback onRetryReset,
  }) async {
    int ping = await getConnectedDelay();
    LogOverlay.addLog("Guard mode check - ping: $ping");

    if (ping == -1 || ping > 1000) {
      onRetryIncrement();
      LogOverlay.addLog(
          "Guard mode: bad connection, retry $retryCount/$maxRetries");

      if (retryCount >= maxRetries) {
        LogOverlay.addLog("Guard mode: attempting to find next best config.");
        bool connected = false;

        for (String nextCfg in allSortedConfigs) {
          if (nextCfg == activeConfig) continue;

          LogOverlay.addLog("Guard mode: testing next config...");
          int newPing = await testConfig(nextCfg);

          if (newPing != -1 && newPing < 1000) {
            LogOverlay.addLog(
                "Guard mode: trying better config with ping $newPing");
            bool result = await ConnectVibe(nextCfg, {}, typeDis: "guard");

            if (result) {
              onConfigSwitched(nextCfg);
              connected = true;
              LogOverlay.showLog("Guard mode: switched to new config",
                  type: "success");
              break;
            }
          }
        }

        if (!connected) {
          LogOverlay.addLog(
              "Guard mode: no better config found after checking all.");
        }
      }
    } else {
      onRetryReset();
      LogOverlay.addLog("Guard mode: connection healthy");
    }
  }

  void _stopGuardModeMonitoring() {
    _guardModeActive = false;
    _guardModeTimer?.cancel();
    _guardModeTimer = null;
  }

  Future<bool> ConnectFG(String fgconfig, int timeout) async {
    try {
      final uri = (fgconfig);
      http.Response? response;
      int attempt = 0;
      int delayMs = 800;
      bool usedCache = false;
      String? cachedData;

      while (attempt < 3) {
        try {
          response = await NetworkService.get(uri).timeout(
            Duration(milliseconds: timeout),
            onTimeout: () => throw TimeoutException('Request timed out'),
          );
          break;
        } catch (e) {
          attempt++;
          if (attempt >= 3) {
            final prefs = await SharedPreferences.getInstance();
            cachedData = prefs.getString('cached_fg_config');
            if (cachedData != null) {
              usedCache = true;
              LogOverlay.addLog('Using cached config due to failure: $e');
              break;
            } else {
              LogOverlay.addLog('No cached config found. Network error: $e');
              return false;
            }
          }
          await Future.delayed(Duration(milliseconds: delayMs));
          delayMs *= 2;
        }
      }

      dynamic data;
      if (usedCache) {
        data = jsonDecode(cachedData!);
      } else {
        if (response == null || response.statusCode != 200) {
          LogOverlay.showLog(
            'Failed to load config: ${response?.statusCode ?? "unknown"}',
            type: "error",
          );
          return false;
        }
        data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_fg_config', response.body);
      }

      List publicServers = data["MOBILE"];

      for (var entry in publicServers) {
        var parts = entry.split(",;,");
        if (parts[0] == "vibe") {
          var config = parts[1].split("#")[0];
          if (config.startsWith("http") || config.startsWith("freedom-guard")) {
            bool connStat = await ConnectSub(
              config.replaceAll("freedom-guard://", ""),
              config.startsWith("freedom-guard") ? "fgAuto" : "sub",
            ).timeout(Duration(seconds: 20), onTimeout: () {
              return isConnected;
            });
            if (!connStat && isConnected) return _isConnected;
            if (connStat) return true;
          } else {
            if (await testConfig(config) != -1) {
              await ConnectVibe(config, {});
              return true;
            }
          }
        } else if (parts[0] == "warp") {
          continue;
        }
        await Future.delayed(const Duration(milliseconds: 400));
      }

      return false;
    } catch (e, stack) {
      LogOverlay.addLog('Error in ConnectFG: $e\n$stack');
      return false;
    }
  }
}

class Tools {
  bool _isConnected = false;
  bool get isConnected => _isConnected;
  SettingsApp settings = new SettingsApp();
  late final V2ray vibeCoreMain;

  Tools() {
    vibeCoreMain = V2ray(
      onStatusChanged: (status) {
        v2rayStatus.value = status;
        _isConnected = status.state == "CONNECTED";
      },
    );
    _initializeV2RayOnce();
  }
  Future<void> _initializeV2RayOnce() async {
    try {
      await vibeCoreMain.initialize();
    } catch (e, stackTrace) {
      _log(
        "خطا در مقداردهی اولیه VIBE: $e\nStackTrace: $stackTrace",
        type: "add",
      );
    }
  }

  void _log(dynamic message, {String type = "info"}) {
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
    return await vibeCoreMain.getConnectedServerDelay().timeout(
      Duration(seconds: 7),
      onTimeout: () {
        return -1;
      },
    );
  }

  Future<String> addOptionsToVibe(dynamic parsedJson) async {
    final settingsValues = await Future.wait([
      settings.getValue("mux"),
      settings.getValue("fragment"),
      settings.getValue("bypass_iran"),
      settings.getBool("child_lock_enabled"),
      settings.getValue("block_ads_trackers"),
      settings.getList("preferred_dns"),
      settings.getValue("fakedns"),
      settings.getValue("sni"),
    ]);

    String mux = settingsValues[0] as String;
    String fragment = settingsValues[1] as String;
    String bypassIran = settingsValues[2] as String;
    bool childLock = settingsValues[3] as bool;
    String blockTADS = settingsValues[4] as String;
    List dnsServers = settingsValues[5] as List;
    String fakeDns = settingsValues[6] as String;
    String sni = settingsValues[7] as String;

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

      parsedJson["dns"] ??= {};
      parsedJson["dns"]["servers"] ??= [];

      if (dnsServers.isNotEmpty) {
        parsedJson["dns"]["servers"] = dnsServers;
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

      if (fakeDns.trim().isNotEmpty) {
        try {
          final fakeJson = json.decode(fakeDns);
          if (fakeJson is Map && fakeJson["enabled"] == true) {
            parsedJson["fakedns"] = [
              {"ipPool": fakeJson["ipPool"], "poolSize": fakeJson["lruSize"]},
            ];
            (parsedJson["dns"]["servers"] as List).insert(0, "fakedns");
          }
        } catch (e) {}
      }
      if (sni.trim().isNotEmpty) {
        try {
          final sniJson = jsonDecode(sni);
          if (sniJson is Map &&
              sniJson["enabled"] == true &&
              sniJson["serverName"] != null &&
              sniJson["serverName"].toString().isNotEmpty) {
            for (var outbound in parsedJson["outbounds"]) {
              if (outbound is Map<String, dynamic>) {
                final stream = outbound["streamSettings"];
                if (stream is Map<String, dynamic>) {
                  final security = stream["security"];

                  // TLS
                  if (security == "tls") {
                    stream["tlsSettings"] ??= {};
                    stream["tlsSettings"]["serverName"] = sniJson["serverName"];
                  }

                  // Reality
                  if (security == "reality") {
                    stream["realitySettings"] ??= {};
                    stream["realitySettings"]["serverName"] =
                        sniJson["serverName"];
                  }
                }
              }
            }
          }
        } catch (e) {
          LogOverlay.addLog("SNI apply failed: $e");
        }
      }
    }
    return jsonEncode(parsedJson);
  }

  Future<int> testConfig(String config, {String type = "normal"}) async {
    try {
      final parser = V2ray.parseFromURL(config);
      final ping = await vibeCoreMain
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
