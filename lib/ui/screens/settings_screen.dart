import 'dart:ui';
import 'package:Freedom_Guard/ui/screens/backup_screen.dart';
import 'package:Freedom_Guard/ui/widgets/settings/setting_input.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Freedom_Guard/core/local.dart';
import 'package:Freedom_Guard/components/settings.dart';
import 'package:Freedom_Guard/ui/screens/f-link_screen.dart';
import 'package:Freedom_Guard/ui/screens/split_screen.dart';
import 'package:Freedom_Guard/ui/widgets/about.dart';
import 'package:Freedom_Guard/ui/widgets/theme/dialog.dart';
import 'package:Freedom_Guard/ui/widgets/settings/setting_switch.dart';
import 'package:Freedom_Guard/ui/widgets/settings/setting_selector.dart';
import 'package:Freedom_Guard/ui/widgets/settings/language_selector.dart';
import 'package:Freedom_Guard/ui/widgets/settings/system_settings_link.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final SettingsApp settings = SettingsApp();
  final Map<String, dynamic> settingsJson = {};
  bool manualMode = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    settingsJson["f_link"] = await settings.getValue("f_link");
    settingsJson["fast_connect"] = await settings.getValue("fast_connect");
    settingsJson["block_ads_trackers"] =
        await settings.getValue("block_ads_trackers");
    settingsJson["bypass_lan"] = await settings.getValue("bypass_lan");
    settingsJson["guard_mode"] = await settings.getValue("guard_mode");
    settingsJson["proxy_mode"] = await settings.getBool("proxy_mode");
    settingsJson["safe_mode"] = await settings.getBool("safe_mode");

    final prefs = await SharedPreferences.getInstance();
    manualMode = prefs.getBool("setting_key") ?? false;

    if (mounted) setState(() {});
  }

  Future<void> _saveManual(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("setting_key", value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;

    return Directionality(
      textDirection: getDir() == "rtl" ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        extendBody: true,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: c.primary,
          title: Text(
            tr("settings"),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: c.onPrimary,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.backup, color: c.onPrimary),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => BackupPage(),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.color_lens, color: c.onPrimary),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => ThemeDialog(),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.volunteer_activism, color: c.onPrimary),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PremiumDonateConfigPage(),
                  ),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.merge_type, color: c.onPrimary),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SplitPage()),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.info_outline, color: c.onPrimary),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AboutDialogWidget(),
                );
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    c.primary.withOpacity(0.18),
                    c.secondary.withOpacity(0.18),
                  ],
                ),
              ),
            ),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(color: Colors.transparent),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SettingSwitch(
                    title: tr("freedom-link"),
                    value: bool.tryParse(
                            settingsJson["f_link"]?.toString() ?? "") ??
                        false,
                    icon: Icons.link,
                    onChanged: (v) {
                      setState(() => settingsJson["f_link"] = v.toString());
                      settings.setValue("f_link", v.toString());
                    },
                  ),
                  SettingSwitch(
                    title: tr("block-ads-trackers"),
                    value: bool.tryParse(
                            settingsJson["block_ads_trackers"]?.toString() ??
                                "") ??
                        false,
                    icon: Icons.block,
                    onChanged: (v) {
                      setState(() =>
                          settingsJson["block_ads_trackers"] = v.toString());
                      settings.setValue("block_ads_trackers", v.toString());
                    },
                  ),
                  SettingSwitch(
                    title: tr("safe-mode"),
                    value: settingsJson["safe_mode"] ?? false,
                    icon: Icons.lock,
                    onChanged: (v) {
                      setState(() => settingsJson["safe_mode"] = v);
                      settings.setBool("safe_mode", v);
                    },
                  ),
                  SettingSwitch(
                    title: tr("proxy-mode"),
                    value: settingsJson["proxy_mode"] ?? false,
                    icon: Icons.swap_horiz,
                    onChanged: (v) {
                      setState(() => settingsJson["proxy_mode"] = v);
                      settings.setBool("proxy_mode", v);
                    },
                  ),
                  SettingSwitch(
                    title: tr("bypass-lan"),
                    value: bool.tryParse(
                            settingsJson["bypass_lan"]?.toString() ?? "") ??
                        false,
                    icon: Icons.lan,
                    onChanged: (v) {
                      setState(() => settingsJson["bypass_lan"] = v.toString());
                      settings.setValue("bypass_lan", v.toString());
                    },
                  ),
                  SettingSwitch(
                    title: tr("guard-mode"),
                    value: bool.tryParse(
                            settingsJson["guard_mode"]?.toString() ?? "") ??
                        false,
                    icon: Icons.shield_outlined,
                    onChanged: (v) {
                      setState(() => settingsJson["guard_mode"] = v.toString());
                      settings.setValue("guard_mode", v.toString());
                    },
                  ),
                  SettingSwitch(
                    title: tr("quick-connect-sub"),
                    value: bool.tryParse(
                            settingsJson["fast_connect"]?.toString() ?? "") ??
                        false,
                    icon: Icons.speed,
                    onChanged: (v) {
                      setState(
                          () => settingsJson["fast_connect"] = v.toString());
                      settings.setValue("fast_connect", v.toString());
                    },
                  ),
                  LanguageSelector(
                    title: tr("language"),
                    prefKey: "lang",
                    languages: const {
                      "en": "English",
                      "fa": "فارسی",
                      "es": "Español",
                      "ru": "Русский",
                      "zh": "中文",
                    },
                  ),
                  SystemSettingsLink(
                    title: tr("kill-switch-settings"),
                    icon: Icons.security,
                  ),
                  SettingSwitch(
                    title: tr("manual-mode"),
                    value: manualMode,
                    onChanged: (v) {
                      setState(() => manualMode = v);
                      _saveManual(v);
                    },
                  ),
                  if (manualMode) ...[
                    SettingInput(
                      title: tr("auto-mode-timeout"),
                      prefKey: "timeout_auto",
                      hintText: "110000",
                    ),
                    SettingSelector(
                      title: tr("core-vpn"),
                      prefKey: "core_vpn",
                      options: const ["auto", "vibe"],
                    ),
                  ],
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
