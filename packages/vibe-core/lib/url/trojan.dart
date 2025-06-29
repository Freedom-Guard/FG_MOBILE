import 'package:flutter_v2ray/url/url.dart';

class TrojanURL extends V2RayURL {
  TrojanURL({required super.url}) {
    if (!url.startsWith('trojan://')) {
      throw ArgumentError('url is invalid');
    }
    final temp = Uri.tryParse(url);
    if (temp == null) {
      throw ArgumentError('url is invalid');
    }
    uri = temp;
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
        streamSecurity: uri.queryParameters['security'] ?? 'tls',
        allowInsecure: allowInsecure,
        sni: uri.queryParameters["sni"] ?? sni,
        fingerprint:
            streamSetting['tlsSettings']?['fingerprint'] ?? "randomized",
        alpns: uri.queryParameters['alpn'],
        publicKey: null,
        shortId: null,
        spiderX: null,
      );
      flow = uri.queryParameters["flow"] ?? "";
    } else {
      super.populateTlsSettings(
        streamSecurity: 'tls',
        allowInsecure: allowInsecure,
        sni: '',
        fingerprint:
            streamSetting['tlsSettings']?['fingerprint'] ?? "randomized",
        alpns: null,
        publicKey: null,
        shortId: null,
        spiderX: null,
      );
    }
  }
  String flow = "";

  @override
  String get address => uri.host;

  @override
  int get port => uri.hasPort ? uri.port : super.port;

  @override
  String get remark => Uri.decodeFull(uri.fragment.replaceAll('+', '%20'));

  late final Uri uri;

  @override
  Map<String, dynamic> get outbound1 => {
        "tag": "proxy",
        "protocol": "trojan",
        "settings": {
          "vnext": null,
          "servers": [
            {
              "address": address,
              "method": "chacha20-poly1305",
              "ota": false,
              "password": uri.userInfo,
              "port": port,
              "level": level,
              "email": null,
              "flow": flow,
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
