import 'package:Freedom_Guard/core/local.dart';
import 'package:Freedom_Guard/ui/widgets/theme/theme.dart';
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
        'name': '⚪⚫ Black and White',
        'theme': blackAndWhiteTheme,
        'nameB': 'Black and White',
        'color': const Color(0xFF000000),
        'gradient': const LinearGradient(
          colors: [Color(0xFF000000), Color(0xFF666666), Color(0xFFF5F5F5)],
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
        'name': '🌄 Twilight Vibes',
        'theme': twilightVibesTheme,
        'nameB': 'Twilight Vibes',
        'color': const Color(0xFF8B5CF6),
        'gradient': const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9), Color(0xFF22D3EE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.5, 1.0],
        ),
      },
      {
        'name': '🌙 Midnight Bloom',
        'theme': midnightBloomTheme,
        'nameB': 'Midnight Bloom',
        'color': const Color(0xFFD946EF),
        'gradient': const LinearGradient(
          colors: [Color(0xFFD946EF), Color(0xFFA21CAF), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.5, 1.0],
        ),
      },
      {
        'name': '🌌 Aurora Pulse',
        'theme': auroraPulseTheme,
        'nameB': 'Aurora Pulse',
        'color': const Color(0xFF10B981),
        'gradient': const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF047857), Color(0xFF60A5FA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.5, 1.0],
        ),
      },
      {
        'name': '✨ Starlight Glow',
        'theme': starlightGlowTheme,
        'nameB': 'Starlight Glow',
        'color': const Color(0xFFF472B6),
        'gradient': const LinearGradient(
          colors: [Color(0xFFF472B6), Color(0xFFDB2777), Color(0xFF38BDF8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.5, 1.0],
        ),
      },
      {
        'name': '🌠 Void Nebula',
        'theme': voidNebulaTheme,
        'nameB': 'Void Nebula',
        'color': const Color(0xFF6366F1),
        'gradient': const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF4338CA), Color(0xFFEC4899)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).dialogBackgroundColor.withOpacity(0.95),
              Theme.of(context).dialogBackgroundColor.withOpacity(0.85),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Text(
                tr('choose-theme'),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            SizedBox(
              height: 400,
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.3,
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
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOutQuint,
                      transform: Matrix4.identity()
                        ..scale(isSelected ? 1.05 : 1.0),
                      child: Card(
                        elevation: isSelected ? 10 : 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: isSelected
                              ? BorderSide(
                                  color:
                                      (item['color'] as Color).withOpacity(0.8),
                                  width: 2,
                                )
                              : BorderSide.none,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: item['gradient'] as LinearGradient?,
                            color: item['gradient'] == null
                                ? item['color'] as Color
                                : null,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withOpacity(isSelected ? 0.3 : 0.1),
                                blurRadius: isSelected ? 12 : 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(
                                    item['name'] as String,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      shadows: [
                                        Shadow(
                                          blurRadius: 6,
                                          color: Colors.black.withOpacity(0.4),
                                          offset: const Offset(1, 1),
                                        ),
                                      ],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              AnimatedPositioned(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOutQuint,
                                top: isSelected ? 8 : 12,
                                right: isSelected ? 8 : 12,
                                child: AnimatedOpacity(
                                  opacity: isSelected ? 1.0 : 0.0,
                                  duration: const Duration(milliseconds: 300),
                                  child: Icon(
                                    Icons.check_circle,
                                    color: item['color'] as Color,
                                    size: 26,
                                  ),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  backgroundColor:
                      Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                  foregroundColor: Theme.of(context).colorScheme.secondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text(
                  tr('close'),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.secondary,
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
