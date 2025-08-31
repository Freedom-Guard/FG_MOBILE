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
    return Padding(
      padding: EdgeInsets.only(
        left: 42,
        right: 42,
        bottom: MediaQuery.of(context).padding.bottom + 8,
        top: 6,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.surface.withOpacity(0.25),
                  Theme.of(context).colorScheme.surface.withOpacity(0.15),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 12,
                  spreadRadius: 1,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(Icons.settings_rounded, 0, context),
                _buildNavItem(Icons.home_rounded, 1, context),
                _buildNavItem(Icons.cloud, 2, context),
              ],
            ),
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
        HapticFeedback.mediumImpact();
        onTap(index);
      },
      child: TweenAnimationBuilder<double>(
        duration: Duration(milliseconds: 250),
        curve: Curves.easeInOutCubicEmphasized,
        tween: Tween(begin: isActive ? 1.0 : 0.0, end: isActive ? 1.0 : 0.0),
        builder: (context, value, child) {
          return Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isActive
                  ? LinearGradient(
                      colors: [
                        theme.colorScheme.primary.withOpacity(0.95),
                        theme.colorScheme.secondary.withOpacity(0.85),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: [0.3, 1.0],
                    )
                  : null,
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.35),
                        blurRadius: 14,
                        spreadRadius: 2,
                        offset: Offset(0, 4),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        spreadRadius: 0,
                        offset: Offset(0, 2),
                      ),
                    ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isActive
                          ? Colors.white.withOpacity(0.4)
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                ),
                TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 250),
                  curve: Curves.easeInOutCubicEmphasized,
                  tween: Tween(
                      begin: isActive ? 1.2 : 1.0, end: isActive ? 1.2 : 1.0),
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: Icon(
                        icon,
                        size: isActive ? 32 : 28,
                        color: isActive
                            ? Colors.white
                            : theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    );
                  },
                ),
                AnimatedOpacity(
                  opacity: isActive ? 0.5 : 0.0,
                  duration: Duration(milliseconds: 250),
                  curve: Curves.easeInOutCubicEmphasized,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          theme.colorScheme.primary.withOpacity(0.5),
                          Colors.transparent,
                        ],
                        radius: 0.6,
                        center: Alignment.center,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
