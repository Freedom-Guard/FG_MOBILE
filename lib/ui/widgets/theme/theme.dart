import 'package:Freedom_Guard/components/settings.dart';
import 'package:flutter/material.dart';

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

final guardTheme = ThemeData(
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF2D9CFF),
    secondary: Color(0xFF7A3BFF),
    surface: Color(0xFF111827),
    background: Color(0xFF0A0F1A),
    error: Color(0xFFFF4C5B),
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: Color(0xFFE8F1FF),
    onBackground: Color(0xFFD9E6FF),
    onError: Colors.white,
  ),
  scaffoldBackgroundColor: const Color(0xFF0A0F1A),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF2D9CFF),
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  cardColor: const Color(0x1FFFFFFF),
  dividerColor: const Color(0xFF233043),
  dialogBackgroundColor: const Color(0xFF111827),
  splashColor: Colors.transparent,
  highlightColor: Colors.transparent,
  hoverColor: Colors.transparent,
  cardTheme: CardThemeData(
    color: const Color(0x22FFFFFF),
    elevation: 8,
    shadowColor: Colors.black.withOpacity(0.3),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF2D9CFF),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    ),
  ),
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
    backgroundColor: Colors.black,
    foregroundColor: Color(0xFF00FF88),
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
    backgroundColor: Colors.black,
    foregroundColor: Color(0xFF00FF00),
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

final blackAndWhiteTheme = ThemeData(
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFFFFFFFF),
    secondary: Color(0xFF999999),
    surface: Color(0xFF000000),
    background: Color(0xFF1A1A1A),
    error: Color(0xFFFF4C5B),
    onPrimary: Color(0xFF000000),
    onSecondary: Color(0xFF000000),
    onSurface: Color(0xFFFFFFFF),
    onBackground: Color(0xFFFFFFFF),
    onError: Color(0xFF000000),
  ),
  scaffoldBackgroundColor: Color(0xFF1A1A1A),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF000000),
    foregroundColor: Color(0xFFFFFFFF),
    elevation: 0,
  ),
  cardColor: Color(0xFF2A2A2A),
  dividerColor: Color(0xFF666666),
  dialogBackgroundColor: Color(0xFF000000),
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

final twilightVibesTheme = ThemeData(
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF8B5CF6),
    secondary: Color(0xFF22D3EE),
    surface: Color(0xFF19192B),
    background: Color(0xFF0F0F1E),
    error: Color(0xFFFF4C5B),
    onPrimary: Colors.white,
    onSecondary: Colors.black,
    onSurface: Color(0xFFD4D4D8),
    onBackground: Color(0xFFE4E4E7),
    onError: Colors.white,
  ),
  scaffoldBackgroundColor: Color(0xFF0F0F1E),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF8B5CF6),
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  cardColor: Color(0xFF25253A),
  dividerColor: Color(0xFF3C3C50),
  dialogBackgroundColor: Color(0xFF19192B),
  splashColor: Colors.transparent,
  highlightColor: Colors.transparent,
  hoverColor: Colors.transparent,
);

final midnightBloomTheme = ThemeData(
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFFD946EF),
    secondary: Color(0xFF3B82F6),
    surface: Color(0xFF1C1C2E),
    background: Color(0xFF0C0C1B),
    error: Color(0xFFFF4C5B),
    onPrimary: Colors.white,
    onSecondary: Colors.black,
    onSurface: Color(0xFFD1D5DB),
    onBackground: Color(0xFFE5E7EB),
    onError: Colors.white,
  ),
  scaffoldBackgroundColor: Color(0xFF0C0C1B),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFD946EF),
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  cardColor: Color(0xFF27273B),
  dividerColor: Color(0xFF404055),
  dialogBackgroundColor: Color(0xFF1C1C2E),
  splashColor: Colors.transparent,
  highlightColor: Colors.transparent,
  hoverColor: Colors.transparent,
);

final auroraPulseTheme = ThemeData(
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF10B981),
    secondary: Color(0xFF60A5FA),
    surface: Color(0xFF1A202C),
    background: Color(0xFF0D1117),
    error: Color(0xFFFF4C5B),
    onPrimary: Colors.white,
    onSecondary: Colors.black,
    onSurface: Color(0xFFD1D5DB),
    onBackground: Color(0xFFE5E7EB),
    onError: Colors.white,
  ),
  scaffoldBackgroundColor: Color(0xFF0D1117),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF10B981),
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  cardColor: Color(0xFF2D3748),
  dividerColor: Color(0xFF4A5568),
  dialogBackgroundColor: Color(0xFF1A202C),
  splashColor: Colors.transparent,
  highlightColor: Colors.transparent,
  hoverColor: Colors.transparent,
);

final starlightGlowTheme = ThemeData(
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFFF472B6),
    secondary: Color(0xFF38BDF8),
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
    backgroundColor: Color(0xFFF472B6),
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

final voidNebulaTheme = ThemeData(
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF6366F1),
    secondary: Color(0xFFEC4899),
    surface: Color(0xFF1E1E2E),
    background: Color(0xFF0A0A14),
    error: Color(0xFFFF4C5B),
    onPrimary: Colors.white,
    onSecondary: Colors.black,
    onSurface: Color(0xFFD4D4D8),
    onBackground: Color(0xFFE4E4E7),
    onError: Colors.white,
  ),
  scaffoldBackgroundColor: Color(0xFF0A0A14),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF6366F1),
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  cardColor: Color(0xFF25253A),
  dividerColor: Color(0xFF3C3C50),
  dialogBackgroundColor: Color(0xFF1E1E2E),
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
    'Guard': guardTheme,
    'Programmer': hackerTheme,
    'Matrix': matrixTheme,
    'Neon Dev': neonDevTheme,
    'Cyber Pulse': cyberPulseTheme,
    'Cosmic Void': cosmicVoidTheme,
    'Neon Abyss': neonAbyssTheme,
    'Galactic Glow': galacticGlowTheme,
    'Quantum Spark': quantumSparkTheme,
    'Black and White': blackAndWhiteTheme,
    'Twilight Vibes': twilightVibesTheme,
    'Midnight Bloom': midnightBloomTheme,
    'Aurora Pulse': auroraPulseTheme,
    'Starlight Glow': starlightGlowTheme,
    'Void Nebula': voidNebulaTheme,
    'Reset': defaultDarkTheme,
  };

  static Future<ThemeNotifier> init() async {
    final themeName = await SettingsApp().getValue("theme");
    final themeData = _themes[themeName] ?? defaultDarkTheme;
    return ThemeNotifier(themeData, themeName);
  }

  Future<void> setTheme(ThemeData theme, String name) async {
    _currentTheme = theme;
    _currentThemeName = name;
    await SettingsApp().setValue('theme', name);
    notifyListeners();
  }

  List<Color>? getDisconnectedGradient() {
    switch (_currentThemeName) {
      case 'Default Dark':
        return [Color(0xAA3A2A6B), Color.fromARGB(170, 44, 8, 130)];
      case 'Programmer':
        return [Color(0xAA00533D), Color.fromARGB(170, 0, 143, 95)];
      case 'Matrix':
        return [Color(0xAA004729), Color.fromARGB(170, 0, 149, 139)];
      case 'Neon Dev':
        return [Color(0xAA660066), Color.fromARGB(170, 93, 0, 102)];
      case 'Cyber Pulse':
        return [Color(0xAA661428), Color.fromARGB(170, 150, 0, 37)];
      case 'Cosmic Void':
        return [Color(0xAA231A5C), Color.fromARGB(170, 0, 0, 140)];
      case 'Neon Abyss':
        return [Color(0xAA660033), Color.fromARGB(170, 153, 0, 77)];
      case 'Galactic Glow':
        return [Color(0xAA662828), Color.fromARGB(170, 102, 34, 14)];
      case 'Quantum Spark':
        return [Color(0xAA351A53), Color.fromARGB(170, 79, 0, 153)];
      case 'Twilight Vibes':
        return [Color(0xAA4B2E8A), Color.fromARGB(170, 14, 81, 94)];
      case 'Midnight Bloom':
        return [Color(0xAA7A2787), Color.fromARGB(170, 27, 46, 94)];
      case 'Aurora Pulse':
        return [Color(0xAA086A4B), Color.fromARGB(170, 36, 62, 94)];
      case 'Starlight Glow':
        return [Color(0xAA8A3F6A), Color.fromARGB(170, 20, 71, 94)];
      case 'Void Nebula':
        return [Color(0xAA372A87), Color.fromARGB(170, 83, 35, 94)];
      default:
        return null;
    }
  }
}
