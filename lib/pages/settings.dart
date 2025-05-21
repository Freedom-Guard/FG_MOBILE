import 'package:Freedom_Guard/components/LOGLOG.dart';
import 'package:Freedom_Guard/components/local.dart';
import 'package:Freedom_Guard/components/settings.dart';
import 'package:Freedom_Guard/pages/f-link.dart';
import 'package:Freedom_Guard/pages/split.dart';
import 'package:Freedom_Guard/widgets/about.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isSettingEnabled = false;
  bool isLoading = false;
  Settings settings = new Settings();
  Map settingsJson = {};

  _initSettingJson() async {
    settingsJson["f_link"] = await settings.getValue("f_link");
    settingsJson["fast_connect"] = await settings.getValue("fast_connect");
    settingsJson["block_ads_trackers"] = await settings.getValue(
      "block_ads_trackers",
    );
    settingsJson["bypass_lan"] = await settings.getValue("bypass_lan");
    settingsJson["guard_mode"] = await settings.getValue("guard_mode");
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _initSettingJson();
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isSettingEnabled = prefs.getBool('setting_key') ?? false;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
        textDirection:
            getDir() == "rtl" ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              tr("settings"),
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.volunteer_activism, color: Colors.red),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PremiumDonateConfigPage(),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.merge_type_sharp, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SplitPage()),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AboutDialogWidget();
                    },
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [],
                  ),
                  SettingSwitch(
                    title: tr("freedom-link"),
                    value: bool.tryParse(settingsJson["f_link"].toString()) ??
                        false,
                    onChanged: (bool value) {
                      setState(() {
                        settingsJson["f_link"] = value.toString();
                      });
                      settings.setValue("f_link", value.toString());
                    },
                    icon: Icons.link,
                  ),
                  SettingSwitch(
                    title: tr("block-ads-trackers"),
                    value: bool.tryParse(
                          settingsJson["block_ads_trackers"].toString(),
                        ) ??
                        false,
                    onChanged: (bool value) {
                      setState(() {
                        settingsJson["block_ads_trackers"] = value.toString();
                      });
                      settings.setValue("block_ads_trackers", value.toString());
                    },
                    icon: Icons.block,
                  ),
                  SettingSwitch(
                    title: tr("bypass-lan"),
                    value:
                        bool.tryParse(settingsJson["bypass_lan"].toString()) ??
                            false,
                    onChanged: (bool value) {
                      setState(() {
                        settingsJson["bypass_lan"] = value.toString();
                      });
                      settings.setValue("bypass_lan", value.toString());
                    },
                    icon: Icons.lan,
                  ),
                  SettingSwitch(
                    title: tr("guard-mode"),
                    value:
                        bool.tryParse(settingsJson["guard_mode"].toString()) ??
                            false,
                    onChanged: (bool value) {
                      setState(() {
                        settingsJson["guard_mode"] = value.toString();
                      });
                      settings.setValue("guard_mode", value.toString());
                    },
                    icon: Icons.shield_sharp,
                  ),
                  SettingSwitch(
                    title: tr("quick-connect-sub"),
                    value: bool.tryParse(
                            settingsJson["fast_connect"].toString()) ??
                        false,
                    onChanged: (bool value) {
                      setState(() {
                        settingsJson["fast_connect"] = value.toString();
                      });
                      settings.setValue("fast_connect", value.toString());
                    },
                    icon: Icons.speed_sharp,
                  ),
                  SettingSelector(
                    title: tr("language"),
                    prefKey: "lang",
                    options: ["en", "fa"],
                  ),
                  SettingSwitch(
                    title: "Manual mode",
                    value: _isSettingEnabled,
                    onChanged: (bool value) {
                      setState(() => _isSettingEnabled = value);
                      _saveSetting("setting_key", value);
                    },
                  ),
                  if (_isSettingEnabled)
                    Column(
                      children: [
                        const SettingInput(
                          title: "Auto Mode Timeout",
                          prefKey: "timeout_auto",
                          hintText: "110000",
                        ),
                        const SettingInput(
                          title: "تعداد درخواست\u200cهای هم\u200cزمان",
                          prefKey: "batch_size",
                          hintText: "15",
                        ),
                        SettingSelector(
                          title: "CORE VPN",
                          prefKey: "core_vpn",
                          options: ["auto", "vibe", "warp"],
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ));
  }
}

class SettingSwitch extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData? icon;

  const SettingSwitch({
    required this.title,
    required this.value,
    required this.onChanged,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surface.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: SwitchListTile(
          title: Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  ),
                  child: Icon(
                    icon,
                    size: 24,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Roboto',
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          value: value,
          onChanged: onChanged,
          activeColor: Theme.of(context).colorScheme.primary,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          hoverColor: Theme.of(context).colorScheme.primary.withOpacity(0.05),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}

class SettingSelector extends StatefulWidget {
  final String title;
  final String prefKey;
  final List<String> options;

  const SettingSelector({
    required this.title,
    required this.prefKey,
    required this.options,
  });

  @override
  State<SettingSelector> createState() => _SettingSelectorState();
}

class _SettingSelectorState extends State<SettingSelector> {
  late String _selectedValue;

  @override
  void initState() {
    super.initState();
    _loadValue();
  }

  Future<void> _loadValue() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedValue = prefs.getString(widget.prefKey) ?? widget.options[0];
    });
  }

  Future<void> _saveValue(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(widget.prefKey, value);
    if (widget.prefKey == "lang") {
      LogOverlay.showLog(tr('change-language'));
      await initTranslations();
      Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Text(widget.title),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedValue,
                items: widget.options.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() => _selectedValue = newValue!);
                  _saveValue(newValue!);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingInput extends StatefulWidget {
  final String title;
  final String prefKey;
  final String hintText;

  const SettingInput({
    required this.title,
    required this.prefKey,
    required this.hintText,
  });

  @override
  State<SettingInput> createState() => _SettingInputState();
}

class _SettingInputState extends State<SettingInput> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadValue();
  }

  Future<void> _loadValue() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _controller.text = prefs.getString(widget.prefKey) ?? "";
    });
  }

  Future<void> _saveValue(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(widget.prefKey, value);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  border: InputBorder.none,
                ),
                onChanged: _saveValue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
