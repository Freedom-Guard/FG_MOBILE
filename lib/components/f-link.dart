import 'dart:convert';
import 'package:Freedom_Guard/components/LOGLOG.dart';
import 'package:Freedom_Guard/components/settings.dart';
import 'package:http/http.dart' as http;

Future<void> donateCONFIG(String config, {String core = ""}) async {
  Settings settings = new Settings();
  final url = Uri.parse(
    "https://freedom-link.freedomguard.workers.dev/api/submit-config",
  );

  final Map<String, dynamic> body = {
    "key": "donated-config",
    "config": {
      "config": config,
      "isp": (await settings.getValue("user_isp").toString()),
      "device": "mobile",
      "ping": (await getIP_Ping())["ping"].toString(),
      "core":
          core == "" ? await settings.getValue("core_vpn").toString() : core,
      "timestamp": DateTime.now().millisecondsSinceEpoch,
    },
  };

  try {
    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer IRAN",
      },
      body: jsonEncode(body),
    );

    LogOverlay.showLog("✅ کانفیگ با موفقیت اهدا شد");
  } catch (error) {
    LogOverlay.showLog("❌ کانفیگ اهدا نشد: $error");
  }
}

Future<Map<String, dynamic>> getIP_Ping() async {
  Map<String, dynamic> responseFunc = {
    "ip": "",
    "ping": "",
    "country": "unknown",
    "filternet": true,
  };

  try {
    final int startTime = DateTime.now().millisecondsSinceEpoch;
    final http.Response response = await http
        .get(Uri.parse("https://api.ipify.org?format=json"))
        .timeout(Duration(seconds: 3));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      responseFunc["ip"] = data["ip"];
      responseFunc["ping"] = DateTime.now().millisecondsSinceEpoch - startTime;

      responseFunc["country"] = "unknown";

      try {
        responseFunc["filternet"] = false;
      } catch (err) {}
    }
  } catch (error) {}

  return responseFunc;
}
