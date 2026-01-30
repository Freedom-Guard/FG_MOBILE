import 'dart:async';
import 'package:Freedom_Guard/components/settings.dart';
import 'package:Freedom_Guard/utils/LOGLOG.dart';
import 'package:http/http.dart' as http;

class NetworkService {
  static int maxRetries = 3;
  static Duration timeout = const Duration(seconds: 8);

  static Future<String> _redirectBase() async {
    final v = await SettingsApp().getValue("redirectBase");
    return v.isEmpty ? "https://req.freedomguard.workers.dev/" : v;
  }

  static Map<String, String> _browserHeaders(String url) {
    return {
      "User-Agent":
          "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
              "(KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36",
      "Accept":
          "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
      "Accept-Language": "en-US,en;q=0.9",
      "Accept-Encoding": "gzip, deflate, br",
      "Connection": "keep-alive",
      "Referer": url,
      "Cache-Control": "no-cache",
      "Pragma": "no-cache",
    };
  }

  static Future<http.Response> get(String url) async {
    LogOverlay.addLog("Request started: $url");
    int attempt = 0;

    while (attempt < maxRetries) {
      try {
        final res = await http
            .get(Uri.parse(url), headers: _browserHeaders(url))
            .timeout(timeout);

        if (res.statusCode >= 200 && res.statusCode < 400) {
          LogOverlay.addLog("Request success: $url");
          return res;
        }
      } catch (_) {}

      attempt++;
      await Future.delayed(Duration(milliseconds: 300 * attempt));
      LogOverlay.addLog("Retry $attempt for $url");
    }

    final redirectBase = await _redirectBase();
    final redirectUrl = "$redirectBase$url";
    LogOverlay.addLog("Redirecting to: $redirectUrl");

    attempt = 0;
    while (attempt < maxRetries) {
      try {
        final res = await http
            .get(Uri.parse(redirectUrl), headers: _browserHeaders(redirectUrl))
            .timeout(timeout);

        if (res.statusCode >= 200 && res.statusCode < 400) {
          LogOverlay.addLog("Redirect success: $redirectUrl");
          return res;
        }
      } catch (_) {}

      attempt++;
      await Future.delayed(Duration(milliseconds: 400 * attempt));
    }

    LogOverlay.addLog("All requests failed");
    return http.Response("", 503);
  }
}
