import 'package:Freedom_Guard/components/settings.dart';
import 'package:Freedom_Guard/utils/LOGLOG.dart';
import 'package:http/http.dart' as http;

class NetworkService {
  static int maxRetries = 2;
  static Duration timeout = const Duration(seconds: 6);

  static Future<String> _redirectBase() async {
    final v = await SettingsApp().getValue("redirectBase");
    return v.isEmpty ? "https://req.freedomguard.workers.dev/" : v;
  }

  static Future<http.Response> get(String url) async {
    LogOverlay.addLog("Request started: $url");

    final redirectBase = await _redirectBase();
    int attempts = 0;

    while (attempts <= maxRetries) {
      try {
        final res = await http.get(Uri.parse(url)).timeout(timeout);
        if (res.statusCode == 200) {
          LogOverlay.addLog("Request success: $url");
          return res;
        }
      } catch (_) {}

      attempts++;
      await Future.delayed(const Duration(milliseconds: 250));
      LogOverlay.addLog("Retry $attempts for $url");
    }

    final redirectUrl = "$redirectBase$url";
    LogOverlay.addLog("Redirecting to: $redirectUrl");

    try {
      final redirected =
          await http.get(Uri.parse(redirectUrl)).timeout(timeout);
      LogOverlay.addLog("Redirect complete: $redirectUrl");
      return redirected;
    } catch (_) {
      LogOverlay.addLog("Redirect failed, returning empty response");
      return http.Response("", 503);
    }
  }
}
