import 'dart:convert';

import 'package:flutter_v2ray/url/url.dart';

class VmessURL extends V2RayURL {
  VmessURL({required super.url}) {
    if (!url.startsWith('vmess://')) {
      throw ArgumentError('url is invalid');
    }
    String raw = url.substring(8);
    if (raw.length % 4 > 0) {
      raw += "=" * (4 - raw.length % 4);
    }
    try {
      rawConfig = jsonDecode(utf8.decode(base64Decode(raw)));
    } catch (_) {
      throw ArgumentError('url is invalid');
    }
    var sni = super.populateTransportSettings(
      transport: rawConfig['net'],
      headerType: rawConfig['type'],
      host: rawConfig['host'],
      path: rawConfig['path'],
      seed: rawConfig['path'],
      quicSecurity: rawConfig['host'],
      key: rawConfig['path'],
      mode: rawConfig['type'],
      serviceName: rawConfig['path'],
    );
    String? fingerprint = (rawConfig['fp'] != null && rawConfig['fp'] != '')
        ? rawConfig['fp']
        : streamSetting['tlsSettings']?['fingerprint'];
    super.populateTlsSettings(
      streamSecurity: rawConfig['tls'],
      allowInsecure: allowInsecure,
      sni: sni,
      fingerprint: fingerprint,
      alpns: rawConfig['alpn'],
      publicKey: null,
      shortId: null,
      spiderX: null,
    );
  }
  late final Map<String, dynamic> rawConfig;

  @override
  String get remark => rawConfig['ps'];

  @override
  String get address => rawConfig['add'] ?? '';

  @override
  int get port => int.tryParse(rawConfig['port'].toString()) ?? super.port;

  @override
  Map<String, dynamic> get outbound1 => {
        "tag": "proxy",
        "protocol": "vmess",
        "settings": {
          "vnext": [
            {
              "address": address,
              "port": port,
              "users": [
                {
                  "id": rawConfig['id'] ?? '',
                  "alterId": int.tryParse(rawConfig['aid'].toString()) ?? 0,
                  "security": (rawConfig['scy']?.isEmpty ?? true)
                      ? security
                      : rawConfig['scy'],
                  "level": level,
                  "encryption": "",
                  "flow": ""
                }
              ]
            }
          ],
          "servers": null,
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
        "mux": {
          "enabled": false,
          "concurrency": 8,
        }
      };
}
