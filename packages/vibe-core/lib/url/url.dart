import 'dart:convert';

abstract class V2RayURL {
  V2RayURL({required this.url});

  final String url;

  bool get allowInsecure => true;

  String get security => 'auto';

  int get level => 8;

  int get port => 443;

  String get network => 'tcp';

  String get address => '';

  String get remark => '';

  Map<String, dynamic> inbound = {
    'tag': 'in_proxy',
    'port': 1080,
    'protocol': 'socks',
    'listen': '127.0.0.1',
    'settings': {
      'auth': 'noauth',
      'udp': true,
      'userLevel': 8,
      'address': null,
      'port': null,
      'network': null
    },
    'sniffing': {'enabled': false, 'destOverride': null, 'metadataOnly': null},
    'streamSettings': null,
    'allocate': null
  };

  Map<String, dynamic> log = {
    'access': '',
    'error': '',
    'loglevel': 'error',
    'dnsLog': false,
  };

  Map<String, dynamic> get outbound1;

  Map<String, dynamic> outbound2 = {
    'tag': 'direct',
    'protocol': 'freedom',
    'settings': {
      'vnext': null,
      'servers': null,
      'response': null,
      'network': null,
      'address': null,
      'port': null,
      'domainStrategy': 'UseIp',
      'redirect': null,
      'userLevel': null,
      'inboundTag': null,
      'secretKey': null,
      'peers': null
    },
    'streamSettings': null,
    'proxySettings': null,
    'sendThrough': null,
    'mux': null
  };

  Map<String, dynamic> outbound3 = {
    'tag': 'blackhole',
    'protocol': 'blackhole',
    'settings': {
      'vnext': null,
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
    'streamSettings': null,
    'proxySettings': null,
    'sendThrough': null,
    'mux': null
  };

  Map<String, dynamic> dns = {
    'servers': ['1.1.1.1', '1.0.0.1', '8.8.8.8', '8.8.4.4']
  };

  Map<String, dynamic> routing = {
    'domainStrategy': 'UseIp',
    'domainMatcher': null,
    'rules': [],
    'balancers': []
  };

  Map<String, dynamic> get fullConfiguration => {
        'log': log,
        'inbounds': [inbound],
        'outbounds': [outbound1, outbound2, outbound3],
        'dns': dns,
        'routing': routing,
      };

  String getFullConfiguration({int indent = 2}) {
    return JsonEncoder.withIndent(' ' * indent).convert(
      removeNulls(
        Map.from(fullConfiguration),
      ),
    );
  }

  late Map<String, dynamic> streamSetting = {
    'network': network,
    'security': '',
    'tcpSettings': null,
    'kcpSettings': null,
    'wsSettings': null,
    'httpSettings': null,
    'tlsSettings': null,
    'quicSettings': null,
    'realitySettings': null,
    'grpcSettings': null,
    'xhttpSettings': null,
    'httpupgradeSettings': null,
    'dsSettings': null,
    'sockopt': null
  };

  String populateTransportSettings({
    required String transport,
    required String? headerType,
    required String? host,
    required String? path,
    required String? seed,
    required String? quicSecurity,
    required String? key,
    required String? mode,
    required String? serviceName,
  }) {
    var sni = '';
    streamSetting['network'] = transport;
    if (transport == 'tcp') {
      streamSetting['tcpSettings'] = {
        'header': <String, dynamic>{'type': 'none', 'request': null},
        'acceptProxyProtocol': null
      };
      if (headerType == 'http') {
        streamSetting['tcpSettings']['header']['type'] = 'http';
        if (host != '' || path != '') {
          streamSetting['tcpSettings']['header']['request'] = {
            'path': path == null ? ['/'] : path.split(','),
            'headers': {
              'Host': host == null ? '' : host.split(','),
              'User-Agent': [
                'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/53.0.2785.143 Safari/537.36',
                'Mozilla/5.0 (iPhone; CPU iPhone OS 10_0_2 like Mac OS X) AppleWebKit/601.1 (KHTML, like Gecko) CriOS/53.0.2785.109 Mobile/14A456 Safari/601.1.46',
              ],
              'Accept-Encoding': [
                'gzip, deflate',
              ],
              'Connection': [
                'keep-alive',
              ],
              'Pragma': 'no-cache',
            },
            'version': '1.1',
            'method': 'GET',
          };
          sni = streamSetting['tcpSettings']['header']['request']['headers']
                          ['Host']
                      .length >
                  0
              ? streamSetting['tcpSettings']['header']['request']['headers']
                  ['Host'][0]
              : sni;
        }
      } else {
        streamSetting['tcpSettings']['header']['type'] = 'none';
        sni = host != '' ? host ?? '' : '';
      }
    } else if (transport == 'kcp') {
      streamSetting['kcpSettings'] = {
        'mtu': 1350,
        'tti': 50,
        'uplinkCapacity': 12,
        'downlinkCapacity': 100,
        'congestion': false,
        'readBufferSize': 1,
        'writeBufferSize': 1,
        'header': {
          'type': headerType ?? 'none',
        },
        'seed': (seed == null || seed == '') ? null : seed,
      };
    } else if (transport == 'ws') {
      streamSetting['wsSettings'] = {
        'path': path ?? ['/'],
        'headers': {'Host': host ?? ''},
        'maxEarlyData': null,
        'useBrowserForwarding': null,
        'acceptProxyProtocol': null,
      };
      sni = streamSetting['wsSettings']['headers']['Host'];
    } else if (transport == 'h2' || transport == 'http') {
      streamSetting['network'] = 'h2';
      streamSetting['h2Setting'] = {
        'host': host?.split(',') ?? '',
        'path': path ?? ['/'],
      };
      sni = streamSetting['h2Setting']['host'].length > 0
          ? streamSetting['h2Setting']['host'][0]
          : sni;
    } else if (transport == 'quic') {
      streamSetting['quicSettings'] = {
        'security': quicSecurity ?? 'none',
        'key': key ?? '',
        'header': {'type': headerType ?? 'none'},
      };
    } else if (transport == 'grpc') {
      streamSetting['grpcSettings'] = {
        'serviceName': serviceName ?? '',
        'multiMode': mode == 'multi',
      };
      sni = host ?? '';
    } else if (transport == 'xhttp') {
      // For xhttp, we'll set up the basic structure
      // The specific xhttp settings will be populated by the VLESS parser
      streamSetting['xhttpSettings'] = {
        'host': host ?? '',
        'path': path ?? '/',
        'mode': mode ?? 'auto',
      };
      sni = host ?? '';
    } else if (transport == 'httpupgrade') {
      // For httpupgrade, we'll set up the basic structure
      streamSetting['httpupgradeSettings'] = {
        'host': host ?? '',
        'path': path ?? '',
      };
      sni = host ?? '';
    }
    return sni;
  }

  /// Populates the TLS/reality settings for the connection.
  ///
  /// [streamSecurity] specifies the security method ('tls' or 'reality').
  /// [allowInsecure] whether to allow insecure connections.
  /// [sni] is the server name indicator.
  /// [fingerprint] is the fingerprint for TLS.
  /// [alpns] are the application layer protocol negotiation strings.
  /// [publicKey] is the public key for reality.
  /// [shortId] is the short ID for reality.
  /// [spiderX] is the spiderX for reality.
  void populateTlsSettings({
    required String? streamSecurity,
    required bool allowInsecure,
    required String? sni,
    required String? fingerprint,
    required String? alpns,
    required String? publicKey,
    required String? shortId,
    required String? spiderX,
  }) {
    streamSetting['security'] = streamSecurity;
    final tlsSetting = <String, dynamic>{
      'allowInsecure': allowInsecure,
      'serverName': sni,
      'alpn': alpns == '' ? null : alpns?.split(','),
      'minVersion': null,
      'maxVersion': null,
      'preferServerCipherSuites': null,
      'cipherSuites': null,
      'fingerprint': fingerprint,
      'certificates': null,
      'disableSystemRoot': null,
      'enableSessionResumption': null,
      'show': false,
      'publicKey': publicKey,
      'shortId': shortId,
      'spiderX': spiderX,
    };
    if (streamSecurity == 'tls') {
      streamSetting['realitySettings'] = null;
      streamSetting['tlsSettings'] = tlsSetting;
    } else if (streamSecurity == 'reality') {
      streamSetting['tlsSettings'] = null;
      streamSetting['realitySettings'] = tlsSetting;
    }
  }

  /// Recursively removes null values from a data structure.
  ///
  /// [params] is the input data structure (Map, List, or primitive).
  /// Returns a cleaned version of [params] with all null values removed.
  /// If the result is empty, returns null.
  dynamic removeNulls(dynamic params) {
    if (params is Map) {
      final map = {};
      params.forEach((key, value) {
        final value0 = removeNulls(value);
        if (value0 != null) {
          map[key] = value0;
        }
      });
      if (map.isNotEmpty) {
        return map;
      }
    } else if (params is List) {
      final list = [];
      for (final val in params) {
        final value = removeNulls(val);
        if (value != null) {
          list.add(value);
        }
      }
      if (list.isNotEmpty) return list;
    } else if (params != null) {
      return params;
    }
    return null;
  }
}
