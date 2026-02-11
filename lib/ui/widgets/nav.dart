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
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: const BoxDecoration(
            color: Colors.transparent,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildNavItem(Icons.settings_rounded, 0, context),
              _buildNavItem(Icons.shield_rounded, 1, context),
              _buildNavItem(Icons.dns_rounded, 2, context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index, BuildContext context) {
    final isActive = index == currentIndex;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        if (!isActive) {
          HapticFeedback.mediumImpact();
          onTap(index);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        margin: EdgeInsets.symmetric(horizontal: 8),
        padding: EdgeInsets.only(bottom: isActive ? 30 : 0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: isActive
                ? LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isActive ? null : theme.colorScheme.surface.withOpacity(0.2),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : [],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (isActive)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 500),
                  builder: (context, value, child) => Container(
                    width: 56 * value,
                    height: 56 * value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.4),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              Icon(
                icon,
                size: isActive ? 32 : 28,
                color: isActive ? Colors.white : theme.colorScheme.onSurface,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
