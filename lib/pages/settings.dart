// Suggested code may be subject to a license. Learn more: ~LicenseLog:2037767261.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:2747140428.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:2660053640.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:289404504.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:3782545339.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:3975634792.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:854757502.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:1548449028.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:3010143163.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:1618272542.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:3367225911.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:933345598.
import 'package:Freedom_Guard/components/settings.dart';
import 'package:Freedom_Guard/pages/f-link.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isSettingEnabled = false;
  Settings settings = new Settings();
  Map settingsJson = {};

  _initSettingJson() async {
    settingsJson["f_link"] = await settings.getValue("f_link");
    settingsJson["fast_connect"] = await settings.getValue("fast_connect");
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "تنظیمات",
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
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return const AboutDialogWidget();
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
              SettingSwitch(
                title: "Freedom LINK",
                value:
                    bool.tryParse(settingsJson["f_link"].toString()) ?? false,
                onChanged: (bool value) {
                  setState(() {
                    settingsJson["f_link"] = value.toString();
                  });
                  settings.setValue("f_link", value.toString());
                },
              ),
              SettingSwitch(
                title: "Quick Connect",
                value:
                    bool.tryParse(settingsJson["fast_connect"].toString()) ??
                    false,
                onChanged: (bool value) {
                  setState(() {
                    settingsJson["fast_connect"] = value.toString();
                  });
                  settings.setValue("fast_connect", value.toString());
                },
              ),
              SettingSelector(
                title: "YOUR ISP",
                prefKey: "user_isp",
                options: ["MCI", "IRANCELL", "PISHGAMAN", "OTHER"],
              ),
              SettingSwitch(
                title: "حالت دستی",
                value: _isSettingEnabled,
                onChanged: (bool value) {
                  setState(() => _isSettingEnabled = value);
                  _saveSetting("setting_key", value);
                },
              ),
              if (_isSettingEnabled)
                Column(
                  children: [
                    SettingInput(
                      title: "تایم اوت حالت خودکار",
                      prefKey: "timeout_auto",
                      hintText: "110000",
                    ),
                    SettingInput(
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
    );
  }
}

class SettingSwitch extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingSwitch({
    required this.title,
    required this.value,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SwitchListTile(
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: Colors.green,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}

class SettingSelector extends StatefulWidget {
  final String title;
  final String prefKey;
  final List<String> options;

  const SettingSelector({
    super.key,
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
                items:
                    widget.options.map((String value) {
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
    super.key,
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

class AboutDialogWidget extends StatelessWidget {
  const AboutDialogWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).dialogBackgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset("assets/icon/ico.png", width: 100, height: 100),
            const SizedBox(height: 10),
            const Text(
              "گارد آزادی",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SelectableText(
              "گارد آزادی یک ابزار متن‌باز برای دور زدن سانسور اینترنت است",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            Text(
              "نسخه: 3.2",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              spacing: 10,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                LinkWidget(
                  url: "https://github.com/Freedom-Guard/FG_MOBILE",
                  text: "GitHub",
                  icon: Icons.receipt_long_outlined,
                ),
                LinkWidget(
                  url: "https://t.me/Freedom_Guard_Net",
                  text: "Telegram",
                  icon: Icons.link,
                ),
                LinkWidget(
                  url: "https://x.com/Freedom_Guard_N",
                  text: "X",
                  icon: Icons.link,
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 32,
                ),
              ),
              child: const Text(
                "بستن",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LinkWidget extends StatelessWidget {
  final String url;
  final String text;
  final IconData icon;

  const LinkWidget({
    super.key,
    required this.url,
    required this.text,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("امکان باز کردن لینک وجود ندارد."),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.blueAccent),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              color: Colors.blueAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
