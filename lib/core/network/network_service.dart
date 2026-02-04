import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:Freedom_Guard/components/settings.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NetworkService {
  static const int maxRetries = 3;
  static const Duration timeout = Duration(seconds: 5);
  static const int maxCacheUses = 4;
  static const int maxCacheEntries = 20;
  static const Duration cacheMaxAge = Duration(days: 5);

  static const String _cachePrefix = 'http_cache_';
  static const String _cacheKeysKey = 'http_cache_keys';

  static Future<String> _redirectBase() async {
    final v = await SettingsApp().getValue("redirectBase");
    return v.isEmpty ? "https://req.freedomguard.workers.dev/" : v;
  }

  static Future<http.Response> get(String url) async {
    final cleanUrl = Uri.parse(url).toString();
    final prefs = await SharedPreferences.getInstance();

    final cached = await _getCached(prefs, cleanUrl);
    if (cached != null) {
      final now = DateTime.now();
      if (now.difference(cached.cachedAt) <= cacheMaxAge &&
          cached.uses < maxCacheUses) {
        cached.uses++;
        await _saveCached(prefs, cleanUrl, cached);
        return http.Response(cached.body, cached.statusCode);
      }
      if (now.difference(cached.cachedAt) > cacheMaxAge) {
        await _removeCached(prefs, cleanUrl);
      }
    }

    var res = await _tryGet(cleanUrl);
    if (res != null && _isGood(res.statusCode)) {
      await _putCache(prefs, cleanUrl, res);
      return res;
    }

    final base = await _redirectBase();
    final proxied = "$base$cleanUrl";

    res = await _tryGet(proxied);
    if (res != null && _isGood(res.statusCode)) {
      await _putCache(prefs, cleanUrl, res);
      return res;
    }

    if (cached != null) {
      return http.Response(cached.body, cached.statusCode);
    }

    return http.Response("", 503);
  }

  static bool _isGood(int code) => code >= 200 && code < 400;

  static Future<http.Response?> _tryGet(String url) async {
    int attempt = 0;
    while (attempt < maxRetries) {
      try {
        final res = await http.get(Uri.parse(url)).timeout(timeout);
        if (res.statusCode < 500) {
          return res;
        }
      } catch (_) {}

      attempt++;
      if (attempt < maxRetries) {
        final delayMs = 150 * (1 << attempt) + Random().nextInt(120);
        await Future.delayed(Duration(milliseconds: delayMs));
      }
    }
    return null;
  }

  static Future<_CachedResponse?> _getCached(
      SharedPreferences prefs, String url) async {
    final jsonStr = prefs.getString('$_cachePrefix$url');
    if (jsonStr == null) return null;

    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return _CachedResponse.fromMap(map);
    } catch (_) {
      return null;
    }
  }

  static Future<void> _saveCached(
      SharedPreferences prefs, String url, _CachedResponse cached) async {
    final jsonStr = jsonEncode(cached.toMap());
    await prefs.setString('$_cachePrefix$url', jsonStr);
  }

  static Future<void> _putCache(
      SharedPreferences prefs, String url, http.Response res) async {
    if (!_isGood(res.statusCode)) return;

    final entry = _CachedResponse(
      body: res.body,
      statusCode: res.statusCode,
      uses: 0,
      cachedAt: DateTime.now(),
    );

    final jsonStr = jsonEncode(entry.toMap());
    await prefs.setString('$_cachePrefix$url', jsonStr);

    List<String> keys = prefs.getStringList(_cacheKeysKey) ?? [];
    if (!keys.contains(url)) {
      keys.add(url);
      if (keys.length > maxCacheEntries) {
        final oldest = keys.removeAt(0);
        await prefs.remove('$_cachePrefix$oldest');
      }
      await prefs.setStringList(_cacheKeysKey, keys);
    }
  }

  static Future<void> _removeCached(SharedPreferences prefs, String url) async {
    await prefs.remove('$_cachePrefix$url');

    final keys = prefs.getStringList(_cacheKeysKey) ?? [];
    if (keys.contains(url)) {
      keys.remove(url);
      await prefs.setStringList(_cacheKeysKey, keys);
    }
  }
}

class _CachedResponse {
  final String body;
  final int statusCode;
  int uses;
  final DateTime cachedAt;

  _CachedResponse({
    required this.body,
    required this.statusCode,
    required this.uses,
    required this.cachedAt,
  });

  Map<String, dynamic> toMap() => {
        'body': body,
        'statusCode': statusCode,
        'uses': uses,
        'cachedAt': cachedAt.millisecondsSinceEpoch,
      };

  factory _CachedResponse.fromMap(Map<String, dynamic> map) {
    return _CachedResponse(
      body: map['body'] as String,
      statusCode: map['statusCode'] as int,
      uses: map['uses'] as int,
      cachedAt: DateTime.fromMillisecondsSinceEpoch(map['cachedAt'] as int),
    );
  }
}
