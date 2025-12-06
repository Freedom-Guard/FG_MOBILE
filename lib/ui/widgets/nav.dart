import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter/services.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(35),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                height: 80,
                width: MediaQuery.of(context).size.width * 0.7,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(35),
                  color: isDark
                      ? Colors.black.withOpacity(0.4)
                      : Colors.white.withOpacity(0.6),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.white.withOpacity(0.6),
                    width: 1.5,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItem(
                        context,
                        index: 0,
                        icon: Icons.settings_rounded,
                        label: 'تنظیمات',
                      ),
                      _buildNavItem(
                        context,
                        index: 1,
                        icon: Icons.shield_rounded,
                        label: 'اتصال',
                      ),
                      _buildNavItem(
                        context,
                        index: 2,
                        icon: Icons.cloud_sync,
                        label: 'سرورها',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = index == currentIndex;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final activeColor =
        isDark ? theme.colorScheme.primary : const Color(0xFF2563EB);
    final inactiveColor = isDark ? Colors.white38 : Colors.black38;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutQuint,
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color:
              isSelected ? activeColor.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: -5,
                  )
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(
                  begin: 0.0,
                  end: 1.0,
                ),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, -2 * value),
                    child: Transform.scale(
                      scale: 1.0 + (value * 0.1),
                      child: ShaderMask(
                        shaderCallback: (bounds) {
                          return LinearGradient(
                            colors: isSelected
                                ? [
                                    activeColor,
                                    isDark ? Colors.white : Colors.blueAccent,
                                  ]
                                : [inactiveColor, inactiveColor],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds);
                        },
                        blendMode: BlendMode.srcIn,
                        child: Icon(
                          icon,
                          size: 32,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
