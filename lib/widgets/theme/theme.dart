import 'package:Freedom_Guard/components/settings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

final defaultDarkTheme = ThemeData(
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF9A66FF),
    secondary: Color(0xFF00C2FF),
    surface: Color(0xFF1C1C2D),
    background: Color(0xFF12121A),
    error: Color(0xFFFF4C5B),
    onPrimary: Color(0xFFFFFFFF),
    onSecondary: Color(0xFF001F2F),
    onSurface: Color(0xFFD0D2E0),
    onBackground: Color(0xFFE0E0F0),
    onError: Color(0xFFFFFFFF),
  ),
  scaffoldBackgroundColor: Color(0xFF12121A),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF9A66FF),
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  cardColor: Color(0xFF2A2B3A),
  dividerColor: Color(0xFF3A3B4D),
  dialogBackgroundColor: Color(0xFF1C1C2D),
  splashColor: Colors.transparent,
  highlightColor: Colors.transparent,
  hoverColor: Colors.transparent,
);

final hackerTheme = ThemeData(
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF00FF88),
    secondary: Color(0xFF00FF88),
    surface: Color(0xFF111111),
    background: Color(0xFF0A0A0A),
    error: Color(0xFFFF4C5B),
    onPrimary: Colors.black,
    onSecondary: Colors.black,
    onSurface: Color(0xFF00FF88),
    onBackground: Color(0xFF00FF88),
    onError: Colors.white,
  ),
  scaffoldBackgroundColor: Color(0xFF0A0A0A),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF00FF88),
    foregroundColor: Colors.black,
    elevation: 0,
  ),
  cardColor: Color(0xFF1A1A1A),
  dividerColor: Color(0xFF333333),
  dialogBackgroundColor: Color(0xFF111111),
  splashColor: Colors.transparent,
  highlightColor: Colors.transparent,
  hoverColor: Colors.transparent,
);

final matrixTheme = ThemeData(
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF00FF00),
    secondary: Color(0xFF00CC66),
    surface: Color(0xFF101010),
    background: Color(0xFF000000),
    error: Color(0xFFFF4C5B),
    onPrimary: Colors.black,
    onSecondary: Colors.black,
    onSurface: Color(0xFF00FF00),
    onBackground: Color(0xFF00FF00),
    onError: Colors.white,
  ),
  scaffoldBackgroundColor: Color(0xFF000000),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF00FF00),
    foregroundColor: Colors.black,
    elevation: 0,
  ),
  cardColor: Color(0xFF121212),
  dividerColor: Color(0xFF2A2A2A),
  dialogBackgroundColor: Color(0xFF101010),
  splashColor: Colors.transparent,
  highlightColor: Colors.transparent,
  hoverColor: Colors.transparent,
);

final neonDevTheme = ThemeData(
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFFFF00FF),
    secondary: Color(0xFF00FFFF),
    surface: Color(0xFF1B1B2F),
    background: Color(0xFF121212),
    error: Color(0xFFFF4C5B),
    onPrimary: Colors.black,
    onSecondary: Colors.black,
    onSurface: Color(0xFFF0F0F0),
    onBackground: Color(0xFFE0E0E0),
    onError: Colors.white,
  ),
  scaffoldBackgroundColor: Color(0xFF121212),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFFF00FF),
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  cardColor: Color(0xFF2E2E3E),
  dividerColor: Color(0xFF444456),
  dialogBackgroundColor: Color(0xFF1B1B2F),
  splashColor: Colors.transparent,
  highlightColor: Colors.transparent,
  hoverColor: Colors.transparent,
);

final cyberPulseTheme = ThemeData(
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFFEF2D56),
    secondary: Color(0xFF00F5D4),
    surface: Color(0xFF1B1B2F),
    background: Color(0xFF0F0F1A),
    error: Color(0xFFFF4C5B),
    onPrimary: Colors.white,
    onSecondary: Colors.black,
    onSurface: Color(0xFFE0E0F0),
    onBackground: Color(0xFFD0D2E0),
    onError: Colors.white,
  ),
  scaffoldBackgroundColor: Color(0xFF0F0F1A),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFEF2D56),
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  cardColor: Color(0xFF2A2A3E),
  dividerColor: Color(0xFF3A3B4D),
  dialogBackgroundColor: Color(0xFF1B1B2F),
  splashColor: Colors.transparent,
  highlightColor: Colors.transparent,
  hoverColor: Colors.transparent,
);

final cosmicVoidTheme = ThemeData(
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF3B28CC),
    secondary: Color(0xFF00DDEB),
    surface: Color(0xFF0F172A),
    background: Color(0xFF0A0A14),
    error: Color(0xFFFF4C5B),
    onPrimary: Colors.white,
    onSecondary: Colors.black,
    onSurface: Color(0xFFD1D5DB),
    onBackground: Color(0xFFE5E7EB),
    onError: Colors.white,
  ),
  scaffoldBackgroundColor: Color(0xFF0A0A14),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF3B28CC),
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  cardColor: Color(0xFF1E293B),
  dividerColor: Color(0xFF334155),
  dialogBackgroundColor: Color(0xFF0F172A),
  splashColor: Colors.transparent,
  highlightColor: Colors.transparent,
  hoverColor: Colors.transparent,
);

final neonAbyssTheme = ThemeData(
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFFFF007F),
    secondary: Color(0xFF00FFFF),
    surface: Color(0xFF1C2526),
    background: Color(0xFF0B0F10),
    error: Color(0xFFFF4C5B),
    onPrimary: Colors.black,
    onSecondary: Colors.black,
    onSurface: Color(0xFFE0E0E0),
    onBackground: Color(0xFFD0D0D0),
    onError: Colors.white,
  ),
  scaffoldBackgroundColor: Color(0xFF0B0F10),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFFF007F),
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  cardColor: Color(0xFF2D3536),
  dividerColor: Color(0xFF3A4546),
  dialogBackgroundColor: Color(0xFF1C2526),
  splashColor: Colors.transparent,
  highlightColor: Colors.transparent,
  hoverColor: Colors.transparent,
);

final galacticGlowTheme = ThemeData(
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFFFF6B6B),
    secondary: Color(0xFF4ECDC4),
    surface: Color(0xFF1F1F2D),
    background: Color(0xFF0F0F1A),
    error: Color(0xFFFF4C5B),
    onPrimary: Colors.white,
    onSecondary: Colors.black,
    onSurface: Color(0xFFE0E0F0),
    onBackground: Color(0xFFD0D2E0),
    onError: Colors.white,
  ),
  scaffoldBackgroundColor: Color(0xFF0F0F1A),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFFF6B6B),
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  cardColor: Color(0xFF2A2A3E),
  dividerColor: Color(0xFF3A3B4D),
  dialogBackgroundColor: Color(0xFF1F1F2D),
  splashColor: Colors.transparent,
  highlightColor: Colors.transparent,
  hoverColor: Colors.transparent,
);

final quantumSparkTheme = ThemeData(
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF7B2CBF),
    secondary: Color(0xFF56CFE1),
    surface: Color(0xFF1E1E2A),
    background: Color(0xFF0D0D15),
    error: Color(0xFFFF4C5B),
    onPrimary: Colors.white,
    onSecondary: Colors.black,
    onSurface: Color(0xFFD0D2E0),
    onBackground: Color(0xFFE0E0F0),
    onError: Colors.white,
  ),
  scaffoldBackgroundColor: Color(0xFF0D0D15),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF7B2CBF),
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  cardColor: Color(0xFF2A2A3E),
  dividerColor: Color(0xFF3A3B4D),
  dialogBackgroundColor: Color(0xFF1E1E2A),
  splashColor: Colors.transparent,
  highlightColor: Colors.transparent,
  hoverColor: Colors.transparent,
);

class ThemeNotifier extends ChangeNotifier {
  ThemeData _currentTheme;
  String _currentThemeName;

  ThemeNotifier(this._currentTheme, this._currentThemeName);

  ThemeData get currentTheme => _currentTheme;
  String get currentThemeName => _currentThemeName;

  static final Map<String, ThemeData> _themes = {
    'Default Dark': defaultDarkTheme,
    'Programmer': hackerTheme,
    'Matrix': matrixTheme,
    'Neon Dev': neonDevTheme,
    'Cyber Pulse': cyberPulseTheme,
    'Cosmic Void': cosmicVoidTheme,
    'Neon Abyss': neonAbyssTheme,
    'Galactic Glow': galacticGlowTheme,
    'Quantum Spark': quantumSparkTheme,
    'Reset': defaultDarkTheme
  };

  static Future<ThemeNotifier> init() async {
    final themeName = await Settings().getValue("theme");
    final themeData = _themes[themeName] ?? defaultDarkTheme;
    return ThemeNotifier(themeData, themeName);
  }

  BoxDecoration? getGradientBackground() =>
      _getGradientBackground(_currentThemeName);

  Future<void> setTheme(ThemeData theme, String name) async {
    _currentTheme = theme;
    _currentThemeName = name;
    await Settings().setValue('theme', name);
    notifyListeners();
  }

  BoxDecoration? _getGradientBackground(String themeName) {
    switch (themeName) {
      case 'Default Dark':
        return const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF9A66FF), Color(0xFF00C2FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      case 'Programmer':
        return const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00FF88), Color(0xFF111111)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      case 'Matrix':
        return const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00FF00), Color(0xFF121212)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      case 'Neon Dev':
        return const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFF00FF), Color(0xFF00FFFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      case 'Cyber Pulse':
        return const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEF2D56), Color(0xFF00F5D4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      case 'Cosmic Void':
        return const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3B28CC), Color(0xFF0A0A14)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        );
      case 'Neon Abyss':
        return const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFF007F), Color(0xFF00FFFF)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        );
      case 'Galactic Glow':
        return const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFF6B6B), Color(0xFF4ECDC4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      case 'Quantum Spark':
        return const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF7B2CBF), Color(0xFF56CFE1)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        );
      default:
        return null;
    }
  }
}
