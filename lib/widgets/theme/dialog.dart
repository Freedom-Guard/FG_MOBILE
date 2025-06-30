import 'package:Freedom_Guard/components/local.dart';
import 'package:Freedom_Guard/widgets/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ThemeDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final currentTheme = themeNotifier.currentTheme;

    final themes = [
      {
        'name': '🟣 Default Dark',
        'theme': defaultDarkTheme,
        'nameB': 'Default Dark',
        'color': const Color(0xFF9A66FF),
        'gradient': const LinearGradient(
          colors: [Color(0xFF9A66FF), Color(0xFF6B48FF), Color(0xFF00C2FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.5, 1.0],
        ),
      },
      {
        'name': '💻 Programmer',
        'theme': hackerTheme,
        'nameB': 'Programmer',
        'color': const Color(0xFF00FF88),
        'gradient': const LinearGradient(
          colors: [Color(0xFF00FF88), Color(0xFF00CC66), Color(0xFF111111)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.5, 1.0],
        ),
      },
      {
        'name': '🧬 Matrix',
        'theme': matrixTheme,
        'nameB': 'Matrix',
        'color': const Color(0xFF00FF00),
        'gradient': const LinearGradient(
          colors: [Color(0xFF00FF00), Color(0xFF00CC66), Color(0xFF121212)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.5, 1.0],
        ),
      },
      {
        'name': '⚡ Neon Dev',
        'theme': neonDevTheme,
        'nameB': 'Neon Dev',
        'color': const Color(0xFFFF00FF),
        'gradient': const LinearGradient(
          colors: [Color(0xFFFF00FF), Color(0xFFCC00CC), Color(0xFF00FFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.5, 1.0],
        ),
      },
      {
        'name': '🌌 Cyber Pulse',
        'theme': cyberPulseTheme,
        'nameB': 'Cyber Pulse',
        'color': const Color(0xFFEF2D56),
        'gradient': const LinearGradient(
          colors: [Color(0xFFEF2D56), Color(0xFFCC1E4A), Color(0xFF00F5D4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.5, 1.0],
        ),
      },
      {
        'name': '🌑 Cosmic Void',
        'theme': cosmicVoidTheme,
        'nameB': 'Cosmic Void',
        'color': const Color(0xFF3B28CC),
        'gradient': const LinearGradient(
          colors: [Color(0xFF3B28CC), Color(0xFF2A1E99), Color(0xFF0A0A14)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.5, 1.0],
        ),
      },
      {
        'name': '🌃 Neon Abyss',
        'theme': neonAbyssTheme,
        'nameB': 'Neon Abyss',
        'color': const Color(0xFFFF007F),
        'gradient': const LinearGradient(
          colors: [Color(0xFFFF007F), Color(0xFFCC0066), Color(0xFF00FFFF)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          stops: [0.0, 0.5, 1.0],
        ),
      },
      {
        'name': '🌟 Galactic Glow',
        'theme': galacticGlowTheme,
        'nameB': 'Galactic Glow',
        'color': const Color(0xFFFF6B6B),
        'gradient': const LinearGradient(
          colors: [Color(0xFFFF6B6B), Color(0xFFCC5555), Color(0xFF4ECDC4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.5, 1.0],
        ),
      },
      {
        'name': '⚡️ Quantum Spark',
        'theme': quantumSparkTheme,
        'nameB': 'Quantum Spark',
        'color': const Color(0xFF7B2CBF),
        'gradient': const LinearGradient(
          colors: [Color(0xFF7B2CBF), Color(0xFF5E2099), Color(0xFF56CFE1)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.5, 1.0],
        ),
      },
      {
        'name': '🔄 Reset',
        'theme': defaultDarkTheme,
        'nameB': 'Reset',
        'color': const Color(0xFF9A66FF),
        'gradient': null,
      },
    ];

    return AlertDialog(
      backgroundColor: Theme.of(context).dialogBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        tr('choose-theme'),
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.2,
          ),
          itemCount: themes.length,
          itemBuilder: (context, index) {
            final item = themes[index];
            final isSelected = item['theme'] == currentTheme;
            return GestureDetector(
              onTap: () async {
                await themeNotifier.setTheme(
                    item['theme'] as ThemeData, item['nameB'] as String);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: AnimatedScale(
                scale: isSelected ? 1.05 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Card(
                  elevation: isSelected ? 8 : 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: isSelected
                        ? BorderSide(color: item['color'] as Color, width: 2)
                        : BorderSide.none,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: item['gradient'] as LinearGradient?,
                      color: item['gradient'] == null
                          ? item['color'] as Color
                          : null,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              item['name'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                shadows: [
                                  Shadow(
                                    blurRadius: 4,
                                    color: Colors.black54,
                                    offset: Offset(1, 1),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Icon(
                              Icons.check_circle,
                              color: item['color'] as Color,
                              size: 24,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child:  Text(
            tr('close'),
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
  }
}
