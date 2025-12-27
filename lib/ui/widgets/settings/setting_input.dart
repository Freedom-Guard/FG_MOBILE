import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      controller.text = prefs.getString(widget.prefKey) ?? '';
      setState(() {});
    }
  }

  Future<void> _save(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(widget.prefKey, value);
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
          border: Border.all(
            color: c.outlineVariant.withOpacity(0.3),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: c.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              onChanged: _save,
              keyboardType: TextInputType.number,
              style: TextStyle(
                color: c.onSurface,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: TextStyle(
                  color: c.onSurfaceVariant.withOpacity(0.6),
                ),
                filled: true,
                fillColor: c.onSurface.withOpacity(0.04),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
