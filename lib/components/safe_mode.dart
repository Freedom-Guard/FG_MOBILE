import 'dart:convert';
import 'package:Freedom_Guard/components/LOGLOG.dart';
import 'package:flutter/material.dart';

class SafeMode {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  init() {
    Future.microtask(() async {});
  }

  Future<bool> checkXrayAndConfirm(String xrayConfigJson,
      {int minSecurityScore = 70}) async {
    final context = LogOverlay.navigatorKey.currentContext;
    if (context == null) {
      print("context unavailable");
      return false;
    }

    try {
      final Map<String, dynamic> config = jsonDecode(xrayConfigJson);
      int securityScore = 100;
      List<String> issues = [];

      final Map<String, dynamic> outbound =
          ((config['outbounds'] is List && config['outbounds'].isNotEmpty)
              ? config['outbounds'][0]
              : config) as Map<String, dynamic>;

      final String protocol =
          (outbound['protocol'] ?? '').toString().toLowerCase();

      final Map streamSettings = (outbound['streamSettings'] ?? {}) as Map;

      final String transportSecurity =
          (streamSettings['security'] ?? 'none').toString().toLowerCase();

      final Map tlsSettings = (streamSettings['tlsSettings'] ?? {}) as Map;
      final bool allowInsecure =
          (tlsSettings['allowInsecure'] ?? false) as bool;

      final Map realitySettings =
          (streamSettings['realitySettings'] ?? {}) as Map;

      final Map settings = (outbound['settings'] ?? {}) as Map;

      if (transportSecurity != 'tls' && transportSecurity != 'reality') {
        securityScore -= 50;
        issues.add('امنیت حمل و نقل ضعیف است (TLS یا Reality الزامی است)');
      } else if (transportSecurity == 'tls') {
        if (allowInsecure) {
          securityScore -= 40;
          issues.add(
              'ویژگی allowInsecure فعال است که اجازه اتصال ناامن به سرور را می‌دهد و ممکن است دسترسی غیرمجاز به داده‌ها را ممکن سازد.');
        }
        if (tlsSettings['serverName'] == null ||
            tlsSettings['serverName'].isEmpty) {
          securityScore -= 20;
          issues.add('نام سرور (SNI) مشخص نشده است');
        }
      } else if (transportSecurity == 'reality') {
        if (realitySettings['serverName'] == null ||
            realitySettings['serverName'].isEmpty) {
          securityScore -= 15;
          issues.add('نام سرور برای Reality مشخص نشده است');
        }
      }

      if (protocol == 'vmess') {
        final List<dynamic> vnext = settings['vnext'] ?? [];
        if (vnext.isNotEmpty) {
          final List<dynamic> users = vnext[0]['users'] ?? [];
          if (users.isNotEmpty) {
            final String userSecurity =
                users[0]['security']?.toLowerCase() ?? 'auto';
            if (userSecurity == 'none') {
              securityScore -= 40;
              issues.add('رمزنگاری VMess غیرفعال است و سرور می‌تواند بخواند');
            } else if (userSecurity == 'aes-128-gcm' ||
                userSecurity == 'chacha20-poly1305') {
            } else {
              securityScore -= 20;
              issues.add('رمزنگاری VMess متوسط است و ممکن است ضعیف باشد');
            }
          }
        }
      } else if (protocol == 'vless') {
        if (transportSecurity == 'none') {
          securityScore -= 40;
          issues.add('VLESS بدون امنیت حمل و نقل اجازه دسترسی سرور می‌دهد');
        }
      } else if (protocol == 'trojan') {
        if (transportSecurity != 'tls') {
          securityScore -= 45;
          issues.add('Trojan بدون TLS اجازه خواندن اطلاعات توسط سرور می‌دهد');
        }
      } else if (protocol == 'shadowsocks') {
        final List<dynamic> servers = settings['servers'] ?? [];
        if (servers.isNotEmpty) {
          final String method = servers[0]['method']?.toLowerCase() ?? '';
          List<String> strongMethods = [
            'aes-256-gcm',
            'aes-128-gcm',
            'chacha20-ietf-poly1305'
          ];
          List<String> weakMethods = ['aes-256-cfb', 'aes-128-cfb', 'rc4-md5'];
          if (weakMethods.contains(method)) {
            securityScore -= 35;
            issues.add(
                'روش رمزنگاری Shadowsocks ضعیف است و سرور می‌تواند بخواند');
          } else if (!strongMethods.contains(method)) {
            securityScore -= 20;
            issues.add('روش رمزنگاری Shadowsocks متوسط است');
          }
        }
      } else {
        securityScore -= 30;
        issues.add('پروتکل ناشناخته یا پشتیبانی‌نشده ممکن است ناامن باشد');
      }

      final String network = streamSettings['network']?.toLowerCase() ?? 'tcp';
      if (network == 'tcp' && transportSecurity == 'none') {
        securityScore -= 25;
        issues.add('شبکه TCP بدون امنیت اجازه دسترسی سرور می‌دهد');
      }

      if (config.containsKey('certificateValid') &&
          !config['certificateValid']) {
        securityScore -= 30;
        issues.add('گواهی SSL معتبر نیست و امنیت را کاهش می‌دهد');
      }
      if (config.containsKey('certificateExpiry')) {
        DateTime expiry = DateTime.parse(config['certificateExpiry']);
        if (expiry.isBefore(DateTime.now().add(Duration(days: 30)))) {
          securityScore -= 20;
          issues.add('گواهی به زودی منقضی می‌شود و ممکن است ناامن شود');
        }
      }

      Map<String, bool> headers = config['securityHeaders'] ?? {};
      headers.forEach((key, value) {
        if (!value) {
          securityScore -= 10;
          issues.add('Header امنیتی $key وجود ندارد و امنیت را کاهش می‌دهد');
        }
      });

      if (securityScore < 0) securityScore = 0;

      if (securityScore < minSecurityScore) {
        bool userConfirmed = await showDialog(
            context: context,
            builder: (ctx) => Directionality(
                  textDirection: TextDirection.rtl,
                  child: AlertDialog(
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    title: Row(
                      children: [
                        Icon(Icons.shield, color: Colors.redAccent),
                        SizedBox(width: 8),
                        Text('امنیت پایین',
                            style: TextStyle(
                                color:
                                    Theme.of(context).colorScheme.onSurface)),
                      ],
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'سطح امنیت این کانفیگ $securityScore% است. جزئیات:',
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant),
                        ),
                        SizedBox(height: 8),
                        ...issues.map((issue) => Row(
                              children: [
                                Icon(Icons.warning,
                                    size: 16, color: Colors.orange),
                                SizedBox(width: 6),
                                Expanded(
                                    child: Text(issue,
                                        style: TextStyle(
                                            color: Colors.orangeAccent))),
                              ],
                            )),
                        SizedBox(height: 12),
                        Text('آیا اجازه اتصال به این کانفیگ را می‌دهید؟',
                            style: TextStyle(
                                color:
                                    Theme.of(context).colorScheme.onSurface)),
                      ],
                    ),
                    actions: [
                      TextButton(
                        style: TextButton.styleFrom(
                            foregroundColor:
                                Theme.of(context).colorScheme.primary),
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: Text('لغو'),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                            foregroundColor:
                                Theme.of(context).colorScheme.primary),
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: Text('اجازه میدم'),
                      ),
                    ],
                  ),
                ));
        return userConfirmed ?? false;
      }
      LogOverlay.showToast(
          "🔒 Configuration secured! Security Score: $securityScore%");
      LogOverlay.addLog(issues.toString());
      return true;
    } catch (e) {
      LogOverlay.addLog("error safe mode:" + e.toString());
      return false;
    }
  }
}
