import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SystemSettingsLink extends StatelessWidget {
  final String title;
  final IconData icon;

  const SystemSettingsLink({
    super.key,
    required this.title,
    required this.icon,
  });

  Future<void> _open() async {
    if (Platform.isAndroid) {
      await launchUrl(Uri.parse('android.settings.VPN_SETTINGS'));
    } else if (Platform.isIOS) {
      await launchUrl(Uri.parse('App-Prefs:root=General&path=VPN'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: _open,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            color: c.surfaceContainerHighest.withOpacity(0.6),
            border: Border.all(
              color: c.outlineVariant.withOpacity(0.3),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.primary.withOpacity(0.15),
                ),
                child: Icon(icon, color: c.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(Icons.open_in_new, color: c.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
