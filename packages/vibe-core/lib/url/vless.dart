import 'dart:convert';
import 'package:vibe_core/url/url.dart';

class VlessURL extends V2RayURL {
  VlessURL({required super.url}) {
    if (!url.startsWith('vless://')) {
      throw ArgumentError('url is invalid');
    }
    final temp = Uri.tryParse(url);
    if (temp == null) {
      throw ArgumentError('url is invalid');
    }
    uri = temp;
    final sni = super.populateTransportSettings(
      transport: uri.queryParameters['type'] ?? 'tcp',
      headerType: uri.queryParameters['headerType'],
      host: uri.queryParameters['host'],
      path: uri.queryParameters['path'],
      seed: uri.queryParameters['seed'],
      quicSecurity: uri.queryParameters['quicSecurity'],
      key: uri.queryParameters['key'],
      mode: uri.queryParameters['mode'],
      serviceName: uri.queryParameters['serviceName'],
    );
    super.populateTlsSettings(
      streamSecurity: uri.queryParameters['security'] ?? '',
      allowInsecure: allowInsecure,
      sni: uri.queryParameters['sni'] ?? sni,
      fingerprint: uri.queryParameters['fp'] ??
          streamSetting['tlsSettings']?['fingerprint'],
      alpns: uri.queryParameters['alpn'],
      publicKey: uri.queryParameters['pbk'] ?? '',
      shortId: uri.queryParameters['sid'] ?? '',
      spiderX: uri.queryParameters['spx'] ?? '',
    );

    _populateXhttpSettings();
  }

  late final Uri uri;

  @override
  String get address => uri.host;

  @override
  int get port => uri.hasPort ? uri.port : super.port;

  @override
  String get remark => Uri.decodeFull(uri.fragment.replaceAll('+', '%20'));

  void _populateXhttpSettings() {
    final transport = uri.queryParameters['type'] ?? 'tcp';
    if (transport == 'xhttp') {
      final extraParam = uri.queryParameters['extra'];
      Map<String, dynamic>? extraSettings;

      if (extraParam != null) {
        try {
          final decodedExtra = Uri.decodeComponent(extraParam);
          extraSettings = jsonDecode(decodedExtra);
        } catch (e) {
          print('Failed to parse xhttp extra settings: $e');
        }
      }

      final xhttpSettings = <String, dynamic>{
        'host': uri.queryParameters['host'] ?? '',
        'path': uri.queryParameters['path'] ?? '/',
        'mode': uri.queryParameters['mode'] ?? 'auto',
      };

      if (extraSettings != null) {
        xhttpSettings['extra'] = extraSettings;
      }

      streamSetting['xhttpSettings'] = xhttpSettings;
    }
  }

  @override
  Map<String, dynamic> get outbound1 => {
        'tag': 'proxy',
        'protocol': 'vless',
        'settings': {
          'vnext': [
            {
              'address': address,
              'port': port,
              'users': [
                {
                  'id': uri.userInfo,
                  'alterId': null,
                  'security': security,
                  'level': level,
                  'encryption': uri.queryParameters['encryption'] ?? 'none',
                  'flow': uri.queryParameters['flow'] ?? '',
                }
              ]
            }
          ],
          'servers': null,
          'response': null,
          'network': null,
          'address': null,
          'port': null,
          'domainStrategy': null,
          'redirect': null,
          'userLevel': null,
          'inboundTag': null,
          'secretKey': null,
          'peers': null
        },
        'streamSettings': streamSetting,
        'proxySettings': null,
        'sendThrough': null,
        'mux': {
          'enabled': false,
          'concurrency': 8,
        },
      };
}
