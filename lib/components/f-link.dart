import 'package:Freedom_Guard/core/async_runner.dart';
import 'package:Freedom_Guard/utils/LOGLOG.dart';
import 'package:Freedom_Guard/core/global.dart';
import 'package:Freedom_Guard/components/settings.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:Freedom_Guard/components/fsecure.dart';
import 'dart:async';
import 'dart:isolate';

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
              Duration(seconds: 7), onTimeout: () {
        throw "";
      });
    } catch (e) {
      remainingUpdates.add(update);
    }
  }

  await prefs.setStringList('failedUpdates', remainingUpdates);
}

bool isValidTelegramLink(String input) {
  if (input.startsWith("https://t.me/")) {
    return true;
  } else if (input.startsWith("@")) {
    return true;
  } else if (input == "") {
    return true;
  } else {
    return false;
  }
}

Future<String> getUserISP({type = "normal"}) async {
  try {
    final response = await http
        .get(Uri.parse("http://ip-api.com/json/"))
        .timeout(Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      type != "normal"
          ? data["org"] = (await SettingsApp().getValue("isp"))
          : SettingsApp().setValue("isp", data['org'] ?? "Unknown ISP");
      return data['org'] ?? "Unknown ISP";
    }
  } catch (e) {
    print("Error getting ISP: $e");
  }
  return "Unknown ISP";
}

Future<bool> donateCONFIG(String config,
    {String core = "", String message = "", String telegramLink = ""}) async {
  try {
    if (await isValidTelegramLink(telegramLink)) {
      if (telegramLink.startsWith("@")) {
        telegramLink = "https://t.me/" + telegramLink.split("@")[1];
      }
    } else {
      LogOverlay.showLog("لینک کانال تلگرام نامعتبر است", type: "error");
      return false;
    }

    final text = config.trim();
    LogOverlay.showLog("Donating...");
    if (text.isEmpty) {
      LogOverlay.addLog("Invalid config | Empty config");
      return false;
    }

    final deviceID = await getDeviceId();

    final ipId = '$deviceID';
    final statsRef =
        FirebaseFirestore.instance.collection('usageStats').doc(ipId);
    final statsSnap =
        await statsRef.get().timeout(Duration(seconds: 3), onTimeout: () {
      throw "";
    });
    final today = DateTime.now().toIso8601String().substring(0, 10);

    if (!statsSnap.exists || statsSnap.data()?['lastUpdate'] != today) {
      await statsRef
          .set({'createdToday': 1, 'listedToday': 0, 'lastUpdate': today});
    } else {
      final created = statsSnap.data()?['createdToday'] ?? 0;
      if (created >= 50) {
        LogOverlay.showLog("Daily submission limit reached", type: "error");
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
      LogOverlay.showLog("This config is already submitted", type: "error");
      return false;
    }

    if (utf8.encode(text).length > 10000) {
      LogOverlay.showLog("The config is too large", type: "error");
      return false;
    }
    final ping = await connect.testConfig(text, type: "f_link");

    await FirebaseFirestore.instance.collection('configs').doc(docId).set({
      'config': text,
      'addedAt': DateTime.now().toIso8601String(),
      'isActive': true,
      'connected': 1,
      'ping': ping.toString(),
      'message': message.trim(),
      'core': core,
      'secretKey': md5.convert(utf8.encode(FSecure.getKey())).toString(),
      'telegramLink': telegramLink.trim(),
    }).timeout(Duration(seconds: 10), onTimeout: () {
      throw "";
    });
    await FirebaseFirestore.instance
        .collection('configs')
        .doc(docId)
        .update({'secretKey': ""});
    LogOverlay.showLog("Config submitted successfully", type: "success");
    return true;
  } catch (e) {
    LogOverlay.addLog("Error saving config: $e \n please turn on vpn");
    return false;
  }
}

Future<List> getConfigsByISP({type = "normal"}) async {
  try {
    final userISP = await getUserISP(type: type);

    var query = FirebaseFirestore.instance
        .collection('configs')
        .where('isActive', isEqualTo: true)
        .where('ispList', arrayContains: userISP)
        .orderBy('connected', descending: true)
        .orderBy('addedAt', descending: true)
        .limit(15);

    var snapshot = await query.get();

    if (snapshot.docs.isEmpty) {
      snapshot = await FirebaseFirestore.instance
          .collection('configs')
          .where('isActive', isEqualTo: true)
          .orderBy('connected', descending: true)
          .orderBy('addedAt', descending: true)
          .limit(15)
          .get();
    }

    List<Map<String, dynamic>> listConfigs =
        snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();

    listConfigs.shuffle();
    await saveConfigs(listConfigs);
    return listConfigs;
  } catch (e) {
    List listConfigs = await restoreConfigs();
    listConfigs.shuffle();
    return listConfigs;
  }
}

Future<void> saveConfigs(List docs) async {
  final prefs = await SharedPreferences.getInstance();
  final configsJson = jsonEncode(docs);
  await prefs.setString('cachedConfigs', configsJson);
  LogOverlay.addLog("Configs cached successfully");
}

Future<List> restoreConfigs() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final configsJson = prefs.getString('cachedConfigs');
    if (configsJson != null) {
      final configs = jsonDecode(configsJson);
      LogOverlay.addLog("Configs restored from cache");
      return configs;
    }
  } catch (e) {
    LogOverlay.showLog("Error restoring configs: $e", type: "error");
  }
  return [];
}

Future<bool> _tryConnectInternal(
  String config,
  String docId,
  String message_old,
  String telegramLink,
) async {
  int resPing = 0;

  if (config.startsWith("http")) {
    resPing = (await connect.ConnectSub(config, "f_link", typeC: "f_link")
            .timeout(Duration(seconds: 25), onTimeout: () {
      return connect.isConnected;
    }))
        ? 999
        : -1;
  } else {
    resPing = await connect.testConfig(config, type: "f_link");
  }

  String message = message_old;
  var docRef;

  if (resPing > 1) {
    bool success = false;

    if (!config.startsWith("http")) {
      success = await connect.ConnectVibe(config, {"type": "f_link"});
    } else {
      success = true;
    }

    if (success) {
      try {
        docRef = FirebaseFirestore.instance.collection('configs').doc(docId);
        await docRef.update({'connected': FieldValue.increment(1)}).timeout(
          Duration(seconds: 3),
          onTimeout: () => throw "",
        );
      } catch (e) {
        await saveFailedUpdate(docId, 1);
      }

      return true;
    }
  }

  try {
    docRef = FirebaseFirestore.instance.collection('configs').doc(docId);
    await docRef.update({'connected': FieldValue.increment(-1)}).timeout(
      Duration(seconds: 3),
      onTimeout: () => throw "",
    );
  } catch (e) {
    await saveFailedUpdate(docId, -1);
  }

  return false;
}

Future<bool> tryConnect(
  String config,
  String docId,
  String message_old,
  String telegramLink,
) async {
  return ((_tryConnectInternal(
    config,
    docId,
    message_old,
    telegramLink,
  )));
}

Future<void> refreshCache() async {
  await Future.delayed(Duration(seconds: 3));
  await getConfigsByISP(type: "cache");
  await processFailedUpdates();
  await processFailedISPAdds();
}

Future<void> addISPToConfig(String docId, String isp) async {
  try {
    final docRef = FirebaseFirestore.instance.collection('configs').doc(docId);
    await docRef.update({
      'ispList': FieldValue.arrayUnion([isp])
    }).timeout(Duration(seconds: 3), onTimeout: () {
      throw "";
    });
    LogOverlay.addLog("ISP added to config: $isp");
  } catch (e) {
    LogOverlay.addLog("Error adding ISP to config: $e");
    await cacheFailedISP(docId, isp);
  }
}

Future<void> cacheFailedISP(String docId, String isp) async {
  final prefs = await SharedPreferences.getInstance();
  final failedListJson = prefs.getString('failedISPs');
  List failedList = failedListJson != null ? jsonDecode(failedListJson) : [];

  if (!failedList.any((item) => item['docId'] == docId && item['isp'] == isp)) {
    failedList.add({'docId': docId, 'isp': isp});
    await prefs.setString('failedISPs', jsonEncode(failedList));
    LogOverlay.addLog("Cached failed ISP update for later: $docId");
  }
}

Future<void> processFailedISPAdds() async {
  final prefs = await SharedPreferences.getInstance();
  final failedListJson = prefs.getString('failedISPs');
  if (failedListJson == null) return;

  List failedList = jsonDecode(failedListJson);
  List processed = [];

  for (var item in failedList) {
    try {
      final docRef =
          FirebaseFirestore.instance.collection('configs').doc(item['docId']);
      await docRef.update({
        'ispList': FieldValue.arrayUnion([item['isp']])
      });
      processed.add(item);
      LogOverlay.addLog("Retried ISP update: ${item['isp']}");
    } catch (e) {
      LogOverlay.addLog("Retry failed for ISP: ${item['isp']}");
    }
  }
  LogOverlay.addLog("Successful ISP updates: ${processed.length}");
  failedList.removeWhere((item) => processed.contains(item));
  await prefs.setString('failedISPs', jsonEncode(failedList));
}

Future<void> rating(String docID) async {
  await Future.delayed(Duration(seconds: 10));
  final rate = await showRatingModal("آیا این کانفیگ کار میکند؟", docID);
  if (rate > 3) {
    saveFailedUpdate(docID, rate);
  } else if (rate < 3) {
    saveFailedUpdate(docID, rate == 2 ? 2 : 5);
  }
}

Future<bool> connectFL() async {
  try {
    final configs = await restoreConfigs();
    for (var config in configs) {
      final configStr = config['config'] as String;
      final message = config['message'] ?? "";
      final telegramLink = config['telegramLink'] ?? "";
      final docId = config['id'];

      final success = await PromiseRunner.runWithTimeout(
        (SendPort sendPort) async {
          bool res = await tryConnect(configStr, docId, message, telegramLink);
          sendPort.send(IsolateMessage('result', res));
        },
        timeout: Duration(seconds: 100),
      );

      if (success) {
        if (message.isNotEmpty) {
          LogOverlay.showModal(
            message,
            isValidTelegramLink(telegramLink) ? telegramLink : "",
          );
        }
        rating(docId);
        final isp = await SettingsApp().getValue("isp");
        await addISPToConfig(docId, isp == "" ? await getUserISP() : isp);
        SettingsApp()
            .setValue("config_backup", "mode=f-link#Auto Server (FL Mode)");
        return true;
      }
    }
  } catch (e) {
    LogOverlay.addLog("Error connecting FL: $e");
  }
  LogOverlay.addLog("Connection FL failed");
  return false;
}
