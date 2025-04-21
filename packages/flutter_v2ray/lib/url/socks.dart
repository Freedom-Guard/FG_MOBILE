import 'dart:convert';

import 'package:flutter_v2ray/url/url.dart';

class SocksURL extends V2RayURL {
  SocksURL({required super.url}) {
    if (!url.startsWith('socks://')) {
      throw ArgumentError('url is invalid');
    }
    final temp = Uri.tryParse(url);
    if (temp == null) {
      throw ArgumentError('url is invalid');
    }
    uri = temp;
    if (uri.userInfo.isNotEmpty) {
      final String userpass = utf8.decode(base64Decode(uri.userInfo));
      username = userpass.split(':')[0];
      password = userpass.substring(username!.length + 1);
    } else {
      username = null;
      password = null;
    }
  }

  late final String? username;
  late final String? password;
  late final Uri uri;

  @override
  String get address => uri.host;

  @override
  int get port => uri.hasPort ? uri.port : super.port;

  @override
  String get remark => Uri.decodeFull(uri.fragment.replaceAll('+', '%20'));

  @override
  Map<String, dynamic> get outbound1 => {
        "protocol": "socks",
        "settings": {
          "servers": [
            {
              "address": address,
              "level": level,
              "method": "chacha20-poly1305",
              "ota": false,
              "password": "",
              "port": port,
              "users": [
                {"level": level, "user": username, "pass": password}
              ]
            }
          ]
        },
        "streamSettings": streamSetting,
        "tag": "proxy",
        "mux": {"concurrency": 8, "enabled": false},
      };
}
