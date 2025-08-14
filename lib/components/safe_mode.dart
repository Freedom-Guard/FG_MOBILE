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
      {int minSecurityScore = 50}) async {
    final context = LogOverlay.navigatorKey.currentContext;
    if (context == null) return false;

    try {
      final Map<String, dynamic> config = jsonDecode(xrayConfigJson);
      int securityScore = 100;
      List<String> issues = [];

      final String protocol = config['protocol']?.toLowerCase() ?? '';
      final Map<String, dynamic> streamSettings =
          config['streamSettings'] ?? {};
      final String transportSecurity =
          streamSettings['security']?.toLowerCase() ?? 'none';
      final Map<String, dynamic> tlsSettings =
          streamSettings['tlsSettings'] ?? {};
      final bool allowInsecure = tlsSettings['allowInsecure'] ?? false;
      final Map<String, dynamic> realitySettings =
          streamSettings['realitySettings'] ?? {};
      final Map<String, dynamic> settings = config['settings'] ?? {};

      if (transportSecurity != 'tls' && transportSecurity != 'reality') {
        securityScore -= 30;
        issues.add('امنیت حمل و نقل ضعیف است (TLS یا Reality توصیه می‌شود)');
      } else if (transportSecurity == 'tls') {
        if (allowInsecure) {
          securityScore -= 25;
          issues.add('اجازه اتصال ناامن فعال است');
        }
        if (tlsSettings['serverName'] == null ||
            tlsSettings['serverName'].isEmpty) {
          securityScore -= 15;
          issues.add('نام سرور (SNI) مشخص نشده است');
        }
      } else if (transportSecurity == 'reality') {
        if (realitySettings['serverName'] == null ||
            realitySettings['serverName'].isEmpty) {
          securityScore -= 10;
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
              securityScore -= 20;
              issues.add('رمزنگاری VMess غیرفعال است');
            } else if (userSecurity == 'aes-128-gcm' ||
                userSecurity == 'chacha20-poly1305') {
            } else {
              securityScore -= 10;
              issues.add('رمزنگاری VMess متوسط است');
            }
          }
        }
      } else if (protocol == 'vless') {
        if (transportSecurity == 'none') {
          securityScore -= 20;
          issues.add('VLESS بدون امنیت حمل و نقل ناامن است');
        }
      } else if (protocol == 'trojan') {
        if (transportSecurity != 'tls') {
          securityScore -= 25;
          issues.add('Trojan بدون TLS ناامن است');
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
            securityScore -= 20;
            issues.add('روش رمزنگاری Shadowsocks ضعیف است');
          } else if (!strongMethods.contains(method)) {
            securityScore -= 10;
            issues.add('روش رمزنگاری Shadowsocks متوسط است');
          }
        }
      } else {
        securityScore -= 15;
        issues.add('پروتکل ناشناخته یا پشتیبانی‌نشده');
      }

      final String network = streamSettings['network']?.toLowerCase() ?? 'tcp';
      if (network == 'tcp' && transportSecurity == 'none') {
        securityScore -= 15;
        issues.add('شبکه TCP بدون امنیت ناامن است');
      }

      if (config.containsKey('certificateValid') &&
          !config['certificateValid']) {
        securityScore -= 20;
        issues.add('گواهی SSL معتبر نیست');
      }
      if (config.containsKey('certificateExpiry')) {
        DateTime expiry = DateTime.parse(config['certificateExpiry']);
        if (expiry.isBefore(DateTime.now().add(Duration(days: 30)))) {
          securityScore -= 15;
          issues.add('گواهی به زودی منقضی می‌شود');
        }
      }

      Map<String, bool> headers = config['securityHeaders'] ?? {};
      headers.forEach((key, value) {
        if (!value) {
          securityScore -= 5;
          issues.add('Header امنیتی $key وجود ندارد');
        }
      });

      if (securityScore < 0) securityScore = 0;

      if (securityScore < minSecurityScore) {
        bool userConfirmed = await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(Icons.shield, color: Colors.redAccent),
                SizedBox(width: 8),
                Text('امنیت پایین',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'سطح امنیت این کانفیگ $securityScore% است. جزئیات:',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                SizedBox(height: 8),
                ...issues.map((issue) => Row(
                      children: [
                        Icon(Icons.warning, size: 16, color: Colors.orange),
                        SizedBox(width: 6),
                        Expanded(
                            child: Text(issue,
                                style: TextStyle(color: Colors.orangeAccent))),
                      ],
                    )),
                SizedBox(height: 12),
                Text('آیا می‌خواهید ادامه دهید؟',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface)),
              ],
            ),
            actions: [
              TextButton(
                style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary),
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text('لغو'),
              ),
              TextButton(
                style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text('ادامه'),
              ),
            ],
          ),
        );
        return userConfirmed ?? false;
      }
      LogOverlay.showToast(
          "🔒 Configuration secured! Security Score: $securityScore%");

      return true;
    } catch (e) {
      return false;
    }
  }
}
