import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut, // انیمیشن ورود کشسانی و فوق مدرن
      builder: (context, anim, child) {
        return Transform.scale(
          scale: anim,
          child: child,
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: value
                  ? [c.primary.withOpacity(0.15), c.primary.withOpacity(0.05)]
                  : [
                      c.surfaceVariant.withOpacity(0.4),
                      c.surfaceVariant.withOpacity(0.1)
                    ],
            ),
            border: Border.all(
              color: value
                  ? c.primary.withOpacity(0.4)
                  : c.outline.withOpacity(0.1),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: value ? c.primary.withOpacity(0.1) : Colors.transparent,
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: () {
                HapticFeedback.lightImpact(); // لرزش ظریف هنگام لمس
                onChanged(!value);
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    if (icon != null)
                      _ModernIcon(icon: icon!, isActive: value, colorScheme: c),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: value ? c.primary : c.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    _CustomSwitch(value: value, colorScheme: c),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModernIcon extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final ColorScheme colorScheme;

  const _ModernIcon(
      {required this.icon, required this.isActive, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutBack,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? colorScheme.primary : colorScheme.surface,
        boxShadow: [
          if (isActive)
            BoxShadow(
              color: colorScheme.primary.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Icon(
        icon,
        size: 22,
        color: isActive ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _CustomSwitch extends StatelessWidget {
  final bool value;
  final ColorScheme colorScheme;

  const _CustomSwitch({required this.value, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 52,
      height: 30,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: value
            ? colorScheme.primary
            : colorScheme.onSurface.withOpacity(0.1),
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 300),
        curve: Curves.elasticOut,
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                  color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
            ],
          ),
        ),
      ),
    );
  }
}
