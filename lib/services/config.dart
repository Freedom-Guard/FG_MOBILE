import 'dart:convert';

String extractNameFromConfig(String config) {
  try {
    if (config.trim().isEmpty) return 'Unnamed Server';
    final decoded = Uri.decodeFull(config);
    final hashIndex = decoded.lastIndexOf('#');
    if (hashIndex != -1 && hashIndex < decoded.length - 1) {
      final name = decoded.substring(hashIndex + 1).trim();
      return name.isNotEmpty ? name : 'Unnamed Server';
    }
  } catch (_) {}
  return 'Unnamed Server';
}

String getNameByConfig(String config) {
  try {
    final decodedConfig = Uri.decodeFull(config);
    final utf8Decoded = utf8.decode(decodedConfig.runes.toList());
    final decoded = jsonDecode(utf8Decoded);
    return decoded['remarks']?.toString() ?? extractNameFromConfig(config);
  } catch (_) {
    return extractNameFromConfig(config);
  }
}
