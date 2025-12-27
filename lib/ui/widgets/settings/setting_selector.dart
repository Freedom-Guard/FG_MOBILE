import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  String? value;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      value = prefs.getString(widget.prefKey) ?? widget.options.first;
    });
  }

  Future<void> _save(String v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(widget.prefKey, v);
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          color: c.surfaceContainerHighest.withOpacity(0.6),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            DropdownButton<String>(
              value: value,
              isExpanded: true,
              underline: const SizedBox(),
              dropdownColor: c.surface,
              items: widget.options
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() => value = v);
                  _save(v);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
