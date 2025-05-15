import 'package:Freedom_Guard/components/LOGLOG.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_v2ray/flutter_v2ray.dart';
import 'package:Freedom_Guard/components/connect.dart';

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
Future<void> donateCONFIG(String config, {String core = ""}) async {
  try {
    final text = config;
    if (text.isEmpty) return;

    await FirebaseFirestore.instance.collection('configs').add({
      'config': text,
      'addedAt': DateTime.now().toIso8601String(),
      'isActive': true,
      'ping': (await testConfig(text)).toString()
    });
  } catch (e) {
    LogOverlay.showLog("خطا در ذخیره کانفیگ: ${e.toString()}");
  }
}

Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
    getRandomConfigs() async {
  final snapshot = await FirebaseFirestore.instance
      .collection('configs')
      .where('isActive', isEqualTo: true)
      .orderBy('addedAt', descending: true)
      .limit(15)
      .get();

  return snapshot.docs;
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
        return -1;
      },
    );
    if (ping > 0) {
      return ping;
    } else {
      return -1;
    }
  } catch (e) {
    return -1;
  }
}

Future<bool> tryConnect(var config) async {
  int resPing = await testConfig(config);
  Connect conn = Connect();
  if (resPing > 1) {
    return (await conn.ConnectVibe(config, []));
  } else {
    return false;
  }
}

Future<bool> connectFL() async {
  final configs = await getRandomConfigs();
  for (var config in configs) {
    var configStr = config.data()['config'] as String;
    var res = await tryConnect(configStr);
    if (res) {
      return true;
    }
  }
  return false;
}
