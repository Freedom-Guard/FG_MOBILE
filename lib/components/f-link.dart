import 'package:Freedom_Guard/components/LOGLOG.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_v2ray/flutter_v2ray.dart';
import 'package:Freedom_Guard/components/connect.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

Future<String?> getIp() async {
  try {
    final res = await http.get(Uri.parse('https://api.ipify.org'));
    if (res.statusCode == 200) {
      return res.body.trim();
    }
    return null;
  } catch (e) {
    LogOverlay.showLog("Failed to get IP address",
        backgroundColor: Colors.redAccent);
    return null;
  }
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

Future<bool> donateCONFIG(String config,
    {String core = "", String message = ""}) async {
  try {
    final text = config.trim();
    if (text.isEmpty) {
      LogOverlay.showLog("Invalid config", backgroundColor: Colors.redAccent);
      return false;
    }

    final ip = await getIp();
    if (ip == null) return false;

    final ipId = 'ip-$ip';
    final statsRef =
        FirebaseFirestore.instance.collection('usageStats').doc(ipId);
    final statsSnap = await statsRef.get();
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
    final existing =
        await FirebaseFirestore.instance.collection('configs').doc(docId).get();
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
    });

    return true;
  } catch (e) {
    LogOverlay.showLog("Error saving config: $e please turn on vpn",
        backgroundColor: Colors.redAccent);
    return false;
  }
}

Future<List> getRandomConfigs() async {
  try {
    final ip = await getIp();
    if (ip == null) return [];

    final ipId = 'ip-$ip';
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
        .get();

    await saveConfigs(snapshot.docs);
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  } catch (_) {
    return await restoreConfigs();
  }
}

Future<void> saveConfigs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) async {
  final prefs = await SharedPreferences.getInstance();
  final configsJson =
      jsonEncode(docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  await prefs.setString('cachedConfigs', configsJson);
  LogOverlay.showLog("Configs cached successfully");
}

Future<List<dynamic>> restoreConfigs() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final configsJson = prefs.getString('cachedConfigs');
    if (configsJson != null) {
      final List<dynamic> configs = jsonDecode(configsJson);
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
      parser = jsonDecode(config);
    }
    final ping = await flutterV2ray
        .getServerDelay(config: parser)
        .timeout(const Duration(seconds: 6), onTimeout: () => -1);
    return ping > 0 ? ping : -1;
  } catch (e) {
    return -1;
  }
}

Future<bool> tryConnect(String config, String docId) async {
  final resPing = await testConfig(config);
  final conn = Connect();
  final docRef = FirebaseFirestore.instance.collection('configs').doc(docId);

  String message = '';

  try {
    final docSnapshot = await docRef.get();
    message = docSnapshot.data()?['message'] as String? ?? '';
  } on FirebaseException catch (e) {
    LogOverlay.showLog("Firebase error getting message: ${e.message}",
        backgroundColor: Colors.redAccent);
  } catch (e) {
    LogOverlay.showLog("Unknown error getting message: $e",
        backgroundColor: Colors.orangeAccent);
  }

  if (resPing > 1) {
    final success = await conn.ConnectVibe(config, []);
    if (success) {
      try {
        await docRef.update({'connected': FieldValue.increment(1)});
      } on FirebaseException catch (e) {
        LogOverlay.showLog(
            "Firebase error incrementing connection counter: ${e.message}",
            backgroundColor: Colors.redAccent);
      } catch (e) {
        LogOverlay.showLog("Unknown error incrementing connection counter: $e",
            backgroundColor: Colors.orangeAccent);
      }

      if (message.isNotEmpty) {
        LogOverlay.showModal(message);
      }
      return true;
    }
  }

  try {
    await docRef.update({'connected': FieldValue.increment(-1)});
  } on FirebaseException catch (e) {
    LogOverlay.showLog(
        "Firebase error decrementing connection counter: ${e.message}",
        backgroundColor: Colors.redAccent);
  } catch (e) {
    LogOverlay.showLog("Unknown error decrementing connection counter: $e",
        backgroundColor: Colors.orangeAccent);
  }

  return false;
}

Future<void> refreshCache() async {
  await getRandomConfigs();
}

Future<bool> connectFL() async {
  try {
    final configs = await getRandomConfigs();
    for (var config in configs) {
      final configStr = config['config'] as String;
      final docId = config.id;
      final success = await tryConnect(configStr, docId);
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
