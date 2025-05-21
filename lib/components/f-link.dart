import 'package:Freedom_Guard/components/LOGLOG.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_v2ray/flutter_v2ray.dart';
import 'package:Freedom_Guard/components/connect.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

Future<String> getDeviceId() async {
  final prefs = await SharedPreferences.getInstance();
  const key = 'unique_device_id';
  var uuid = Uuid();

  try {
    String? id = prefs.getString(key);
    if (id != null) return id;
  } catch (_) {}

  final newId = uuid.v4();
  await prefs.setString(key, newId);
  return newId;
}

final FlutterV2ray flutterV2ray = FlutterV2ray(
  onStatusChanged: (status) async {
    if (status.toString() == "V2RayStatusState.connected") {
      LogOverlay.showLog("Connected To VIBE",
          backgroundColor: Colors.greenAccent);
    }
  },
);

String hashConfig(String config) {
  final trimmed = config.trim();
  return sha256.convert(utf8.encode(trimmed)).toString();
}

Future<void> saveFailedUpdate(String docId, int increment) async {
  final prefs = await SharedPreferences.getInstance();
  List<String> failedUpdates = prefs.getStringList('failedUpdates') ?? [];
  failedUpdates.add(jsonEncode({
    'docId': docId,
    'increment': increment,
    'timestamp': DateTime.now().toIso8601String()
  }));
  await prefs.setStringList('failedUpdates', failedUpdates);
}

Future<void> processFailedUpdates() async {
  final prefs = await SharedPreferences.getInstance();
  List<String> failedUpdates = prefs.getStringList('failedUpdates') ?? [];
  List<String> remainingUpdates = [];

  for (var update in failedUpdates) {
    try {
      final data = jsonDecode(update);
      final docId = data['docId'];
      final increment = data['increment'];
      await FirebaseFirestore.instance
          .collection('configs')
          .doc(docId)
          .update({'connected': FieldValue.increment(increment)}).timeout(
              Duration(seconds: 10), onTimeout: () {
        throw "";
      });
    } catch (e) {
      remainingUpdates.add(update);
    }
  }

  await prefs.setStringList('failedUpdates', remainingUpdates);
}

bool isValidTelegramLink(String input) {
  final uriPattern = RegExp(r"^https:\/\/t\.me\/[a-zA-Z0-9_]{5,32}$");
  final usernamePattern = RegExp(r"^@[a-zA-Z0-9_]{5,32}$");

  if (input.trim().isEmpty) {
    LogOverlay.showLog("لینک یا آیدی وارد نشده!",
        backgroundColor: Colors.redAccent);
    return false;
  }

  if (uriPattern.hasMatch(input) || usernamePattern.hasMatch(input)) {
    return true;
  }

  LogOverlay.showLog("لینک یا آیدی تلگرام نامعتبر است!",
      backgroundColor: Colors.redAccent);
  return false;
}

Future<bool> donateCONFIG(String config,
    {String core = "", String message = "", String telegramLink = ""}) async {
  try {
    if (!isValidTelegramLink(telegramLink)) {
      return false;
    }

    final text = config.trim();
    LogOverlay.showLog("Donating...", backgroundColor: Colors.blueAccent);
    if (text.isEmpty) {
      LogOverlay.showLog("Invalid config", backgroundColor: Colors.redAccent);
      return false;
    }

    final deviceID = await getDeviceId();

    final ipId = '$deviceID';
    final statsRef =
        FirebaseFirestore.instance.collection('usageStats').doc(ipId);
    final statsSnap =
        await statsRef.get().timeout(Duration(seconds: 7), onTimeout: () {
      throw "";
    });
    final today = DateTime.now().toIso8601String().substring(0, 10);

    if (!statsSnap.exists || statsSnap.data()?['lastUpdate'] != today) {
      await statsRef
          .set({'createdToday': 1, 'listedToday': 0, 'lastUpdate': today});
    } else {
      final created = statsSnap.data()?['createdToday'] ?? 0;
      if (created >= 50) {
        LogOverlay.showLog("Daily submission limit reached",
            backgroundColor: Colors.orange);
        return false;
      }
      await statsRef.update({'createdToday': FieldValue.increment(1)});
    }

    final docId = hashConfig(text);
    final existing = await FirebaseFirestore.instance
        .collection('configs')
        .doc(docId)
        .get()
        .timeout(Duration(seconds: 7), onTimeout: () {
      throw "";
    });
    if (existing.exists) {
      LogOverlay.showLog("This config is already submitted",
          backgroundColor: Colors.orangeAccent);
      return false;
    }

    if (utf8.encode(text).length > 10000) {
      LogOverlay.showLog("The config is too large",
          backgroundColor: Colors.redAccent);
      return false;
    }

    final ping = await testConfig(text);

    await FirebaseFirestore.instance.collection('configs').doc(docId).set({
      'config': text,
      'addedAt': DateTime.now().toIso8601String(),
      'isActive': true,
      'connected': 1,
      'ping': ping.toString(),
      'message': message.trim(),
      'core': core,
      'telegramLink': telegramLink.trim(),
    }).timeout(Duration(seconds: 10), onTimeout: () {
      throw "";
    });

    return true;
  } catch (e) {
    LogOverlay.showLog("Error saving config: please turn on vpn",
        backgroundColor: Colors.redAccent);
    return false;
  }
}

Future<List> getRandomConfigs() async {
  try {
    final deviceID = await getDeviceId();
    final ipId = 'ip-$deviceID';
    final statsRef =
        FirebaseFirestore.instance.collection('usageStats').doc(ipId);
    final statsSnap = await statsRef.get();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (!statsSnap.exists || statsSnap.data()?['lastUpdate'] != today) {
      await statsRef
          .set({'createdToday': 0, 'listedToday': 1, 'lastUpdate': today});
    } else {
      final listed = statsSnap.data()?['listedToday'] ?? 0;
      if (listed >= 50) {
        LogOverlay.showLog("Daily receive limit reached",
            backgroundColor: Colors.orange);
        return [];
      }
      await statsRef.update({'listedToday': FieldValue.increment(1)});
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('configs')
        .where('isActive', isEqualTo: true)
        .orderBy('connected', descending: true)
        .orderBy('addedAt', descending: true)
        .limit(15)
        .get()
        .timeout(Duration(seconds: 10), onTimeout: () {
      LogOverlay.showLog("Firebase timeout", backgroundColor: Colors.redAccent);
      throw "timeout fb online";
    });

    await saveConfigs(
        snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
    List listConfigs =
        snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    listConfigs.shuffle();
    return listConfigs;
  } catch (_) {
    List listConfigs = await restoreConfigs();
    listConfigs.shuffle();
    return listConfigs;
  }
}

Future<void> saveConfigs(List docs) async {
  final prefs = await SharedPreferences.getInstance();
  final configsJson = jsonEncode(docs);
  await prefs.setString('cachedConfigs', configsJson);
  LogOverlay.showLog("Configs cached successfully");
}

Future<List> restoreConfigs() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final configsJson = prefs.getString('cachedConfigs');
    if (configsJson != null) {
      final configs = jsonDecode(configsJson);
      LogOverlay.showLog("Configs restored from cache");
      return configs;
    }
  } catch (e) {
    LogOverlay.showLog("Error restoring configs: $e",
        backgroundColor: Colors.redAccent);
  }
  return [];
}

Future<int> testConfig(String config) async {
  try {
    await flutterV2ray.initializeV2Ray();
    dynamic parser;
    try {
      parser = FlutterV2ray.parseFromURL(config).getFullConfiguration();
    } catch (_) {
      parser = (config);
    }
    final ping = await flutterV2ray
        .getServerDelay(config: parser)
        .timeout(const Duration(seconds: 4), onTimeout: () => -1);
    return ping > 0 ? ping : -1;
  } catch (e) {
    return -1;
  }
}

Future<bool> tryConnect(String config, String docId, String message_old,
    String telegramLink) async {
  final resPing = await testConfig(config);
  final conn = Connect();
  final docRef = FirebaseFirestore.instance.collection('configs').doc(docId);

  String message = message_old;

  if (resPing > 1) {
    final success = await conn.ConnectVibe(config, []);
    if (success) {
      try {
        await docRef.update({'connected': FieldValue.increment(1)}).timeout(
            Duration(seconds: 5), onTimeout: () {
          throw "";
        });
      } on FirebaseException catch (e) {
        await saveFailedUpdate(docId, 1);
        LogOverlay.addLog(
            "Firebase error incrementing connection counter: ${e.message}");
      } catch (e) {
        LogOverlay.addLog("Unknown error incrementing connection counter: $e");
      }

      if (message.isNotEmpty) {
        if (isValidTelegramLink(telegramLink)) {
          LogOverlay.showModal(message, telegramLink);
        }
      }
      return true;
    }
  }

  try {
    await docRef.update({'connected': FieldValue.increment(-1)});
  } on FirebaseException catch (e) {
    await saveFailedUpdate(docId, -1);
    LogOverlay.showLog(
        "Firebase error decrementing connection counter: ${e.message}",
        backgroundColor: Colors.redAccent);
  } catch (e) {
    await saveFailedUpdate(docId, -1);
    LogOverlay.showLog("Unknown error decrementing connection counter: $e",
        backgroundColor: Colors.orangeAccent);
  }

  return false;
}

Future<void> refreshCache() async {
  await Future.delayed(Duration(seconds: 3));
  await getRandomConfigs();
  await processFailedUpdates();
}

Future<bool> connectFL() async {
  try {
    final configs = await getRandomConfigs().timeout(Duration(seconds: 10),
        onTimeout: () async {
      LogOverlay.showLog("Connection FL timed out",
          backgroundColor: Colors.redAccent);
      return await restoreConfigs();
    });
    for (var config in configs) {
      final configStr = config['config'] as String;
      final message = config['message'] ?? "";
      final telegramLink = config['telegramLink'] ?? "";
      final docId = config['id'];
      final success = await tryConnect(configStr, docId, message, telegramLink);
      if (success) {
        return true;
      }
    }
  } catch (e) {
    LogOverlay.showLog("Error connecting FL: $e",
        backgroundColor: Colors.redAccent);
  }
  LogOverlay.showLog("Connection FL failed", backgroundColor: Colors.redAccent);
  return false;
}
