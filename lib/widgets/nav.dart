import 'dart:ui';
import 'package:flutter/material.dart';

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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.05),
                  Colors.black.withOpacity(0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(36),
              border: Border.all(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 6,
                  spreadRadius: 0.5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.settings_rounded, 0, context),
                _buildNavItem(Icons.home_rounded, 1, context),
                _buildNavItem(Icons.cloud_sync_rounded, 2, context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index, BuildContext context) {
    bool isActive = index == currentIndex;

    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 350),
        curve: Curves.easeInOutSine,
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: isActive
              ? LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.secondary.withOpacity(0.9),
                    Theme.of(context).colorScheme.primary.withOpacity(0.75),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Theme.of(context)
                        .colorScheme
                        .secondary
                        .withOpacity(0.25),
                    blurRadius: 8,
                    spreadRadius: 1.5,
                    offset: Offset(0, 1),
                  ),
                ]
              : [],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedScale(
              scale: isActive ? 1.15 : 1.0,
              duration: Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              child: AnimatedOpacity(
                opacity: isActive ? 1.0 : 0.7,
                duration: Duration(milliseconds: 350),
                child: Icon(
                  icon,
                  size: isActive ? 30 : 26,
                  color: isActive
                      ? Colors.white
                      : Colors.grey.shade200.withOpacity(0.75),
                  shadows: isActive
                      ? [
                          Shadow(
                            color: Theme.of(context)
                                .colorScheme
                                .secondary
                                .withOpacity(0.3),
                            blurRadius: 6,
                            offset: Offset(0, 1),
                          ),
                        ]
                      : [],
                ),
              ),
            ),
            AnimatedOpacity(
              opacity: isActive ? 0.3 : 0.0,
              duration: Duration(milliseconds: 500),
              curve: Curves.easeOutSine,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Theme.of(context).colorScheme.secondary.withOpacity(0.4),
                      Colors.transparent,
                    ],
                    radius: 0.65,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
