import 'dart:convert';
import 'package:vibe_core/vibe_core.dart';

String getNameByConfig(String config) {
  try {
    if (config.startsWith("http") ||
        config.startsWith("freedom-guard") ||
        config.startsWith("mode=") ||
        config.split("#")[0].trim().replaceAll("vibe,;,", "") == "") {
      final name = config.split("#").last.trim().isNotEmpty
          ? config.split("#").last.trim()
          : config.split("/").last.trim();
      return Uri.decodeComponent(name);
    }

    final decodedConfig = VibeCore.parseFromURL(
        config.startsWith("vmess") ? config.split("#")[0] : config);
    try {
      return Uri.decodeComponent(
          decodedConfig.remark == "" ? "Unnamed Server" : decodedConfig.remark);
    } catch (_) {
      return decodedConfig.remark == ""
          ? "Unnamed Server"
          : decodedConfig.remark;
    }
  } catch (_) {
    try {
      final decoded = jsonDecode(config);
      if (decoded is Map) {
        if (decoded.containsKey("remarks")) {
          return Uri.decodeComponent(decoded["remarks"].toString());
        }
        if (decoded.containsKey("ps")) {
          return Uri.decodeComponent(decoded["ps"].toString());
        }
      }
    } catch (_) {}
    return "Unnamed Server";
  }
}
