import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Freedom_Guard/utils/LOGLOG.dart';
import 'package:Freedom_Guard/core/local.dart';

class LanguageSelector extends StatefulWidget {
  final String title;
  final String prefKey;
  final Map<String, String> languages;

  const LanguageSelector({
    super.key,
    required this.title,
    required this.prefKey,
    required this.languages,
  });

  @override
  State<LanguageSelector> createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends State<LanguageSelector> {
  String? current;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      current = prefs.getString(widget.prefKey) ?? widget.languages.keys.first;
    });
  }

  Future<void> _select(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(widget.prefKey, value);
    LogOverlay.showLog(tr('change-language'));
    await initTranslations();
    Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: c.surfaceContainerHighest.withOpacity(0.55),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: c.outlineVariant.withOpacity(0.3),
              ),
            ),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: c.onSurface,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: widget.languages.entries.map((e) {
                    final selected = e.key == current;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => _select(e.key),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: selected
                                ? c.primary.withOpacity(0.2)
                                : c.onSurface.withOpacity(0.06),
                            border: Border.all(
                              color: selected ? c.primary : Colors.transparent,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                e.value,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color:
                                      selected ? c.primary : c.onSurfaceVariant,
                                ),
                              ),
                              if (selected)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Icon(
                                    Icons.check_circle,
                                    size: 18,
                                    color: c.primary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
