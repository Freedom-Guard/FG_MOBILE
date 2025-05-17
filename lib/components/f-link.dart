import 'package:Freedom_Guard/components/LOGLOG.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_v2ray/flutter_v2ray.dart';
import 'package:Freedom_Guard/components/connect.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

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
      LogOverlay.showLog("کانفیگ نامعتبر است",
          backgroundColor: Colors.redAccent);
      return false;
    }

    final docId = hashConfig(text);

    final existing =
        await FirebaseFirestore.instance.collection('configs').doc(docId).get();

    if (existing.exists) {
      LogOverlay.showLog("این کانفیگ قبلاً ثبت شده",
          backgroundColor: Colors.orangeAccent);
      return false;
    }

    if (utf8.encode(text).length > 10000) {
      LogOverlay.showLog("کانفیگ بیش از حد بزرگ است",
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
    LogOverlay.showLog("خطا در ذخیره کانفیگ: $e",
        backgroundColor: Colors.redAccent);
    return false;
  }
}

Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
    getRandomConfigs() async {
  final snapshot = await FirebaseFirestore.instance
      .collection('configs')
      .where('isActive', isEqualTo: true)
      .orderBy('connected', descending: true)
      .orderBy('addedAt', descending: true)
      .limit(15)
      .get();
  return snapshot.docs;
}

Future<int> testConfig(String config) async {
  try {
    await flutterV2ray.initializeV2Ray();
    var parser;
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
  Connect conn = Connect();
  final docRef = FirebaseFirestore.instance.collection('configs').doc(docId);
  final docSnapshot = await docRef.get();
  final message = docSnapshot.data()?['message'] as String? ?? '';

  if (resPing > 1) {
    final success = await conn.ConnectVibe(config, []);
    if (success) {
      await docRef.update({'connected': FieldValue.increment(1)});
      if (message.isNotEmpty) {
        LogOverlay.showModal(message);
      }
      return true;
    }
  }
  await docRef.update({'connected': FieldValue.increment(-1)});
  return false;
}

Future<bool> connectFL() async {
  final configs = await getRandomConfigs();
  for (var config in configs) {
    final configStr = config.data()['config'] as String;
    final docId = config.id;
    final success = await tryConnect(configStr, docId);
    if (success) {
      return true;
    }
  }
  LogOverlay.showLog("اتصال ناموفق بود", backgroundColor: Colors.redAccent);
  return false;
}
