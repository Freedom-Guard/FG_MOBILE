import 'package:flutter/material.dart';

class SettingSwitch extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData? icon;

  const SettingSwitch({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: () => onChanged(!value),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              color: c.surfaceContainerHighest.withOpacity(0.6),
              border: Border.all(
                color: value
                    ? c.primary.withOpacity(0.5)
                    : c.outlineVariant.withOpacity(0.3),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(
                children: [
                  if (icon != null)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: value
                            ? c.primary.withOpacity(0.18)
                            : c.onSurface.withOpacity(0.06),
                      ),
                      child: Icon(
                        icon,
                        color: value ? c.primary : c.onSurfaceVariant,
                      ),
                    ),
                  if (icon != null) const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: c.onSurface,
                      ),
                    ),
                  ),
                  Switch(
                    value: value,
                    onChanged: onChanged,
                    trackOutlineColor:
                        WidgetStateProperty.all(Colors.transparent),
                    inactiveTrackColor: c.onSurface.withOpacity(0.15),
                    activeTrackColor: c.primary.withOpacity(0.35),
                    activeColor: c.primary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
