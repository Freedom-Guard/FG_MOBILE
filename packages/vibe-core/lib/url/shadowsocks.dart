import 'dart:convert';

import 'package:flutter_v2ray/url/url.dart';

class ShadowSocksURL extends V2RayURL {
  ShadowSocksURL({required super.url}) {
    if (!url.startsWith('ss://')) {
      throw ArgumentError('url is invalid');
    }
    final temp = Uri.tryParse(url);
    if (temp == null) {
      throw ArgumentError('url is invalid');
    }
    uri = temp;
    if (uri.userInfo.isNotEmpty) {
      String raw = uri.userInfo;
      if (raw.length % 4 > 0) {
        raw += "=" * (4 - raw.length % 4);
      }
      try {
        final methodpass = utf8.decode(base64Decode(raw));
        method = methodpass.split(':')[0];
        password = methodpass.substring(method.length + 1);
      } catch (_) {}
    }

    if (uri.queryParameters.isNotEmpty) {
      var sni = super.populateTransportSettings(
        transport: uri.queryParameters['type'] ?? "tcp",
        headerType: uri.queryParameters['headerType'],
        host: uri.queryParameters["host"],
        path: uri.queryParameters["path"],
        seed: uri.queryParameters["seed"],
        quicSecurity: uri.queryParameters["quicSecurity"],
        key: uri.queryParameters["key"],
        mode: uri.queryParameters["mode"],
        serviceName: uri.queryParameters["serviceName"],
      );
      super.populateTlsSettings(
        streamSecurity: uri.queryParameters['security'] ?? '',
        allowInsecure: allowInsecure,
        sni: uri.queryParameters["sni"] ?? sni,
        fingerprint: streamSetting['tlsSettings']?['fingerprint'],
        alpns: uri.queryParameters['alpn'],
        publicKey: null,
        shortId: null,
        spiderX: null,
      );
    }
  }

  @override
  String get address => uri.host;

  @override
  int get port => uri.hasPort ? uri.port : super.port;

  @override
  String get remark => Uri.decodeFull(uri.fragment.replaceAll('+', '%20'));

  late final Uri uri;

  String method = "none";

  String password = "";

  @override
  Map<String, dynamic> get outbound1 => {
        "tag": "proxy",
        "protocol": "shadowsocks",
        "settings": {
          "vnext": null,
          "servers": [
            {
              "address": address,
              "method": method,
              "ota": false,
              "password": password,
              "port": port,
              "level": level,
              "email": null,
              "flow": null,
              "ivCheck": null,
              "users": null
            }
          ],
          "response": null,
          "network": null,
          "address": null,
          "port": null,
          "domainStrategy": null,
          "redirect": null,
          "userLevel": null,
          "inboundTag": null,
          "secretKey": null,
          "peers": null
        },
        "streamSettings": streamSetting,
        "proxySettings": null,
        "sendThrough": null,
        "mux": {"enabled": false, "concurrency": 8}
      };
}
