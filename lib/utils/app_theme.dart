import 'package:flutter/material.dart';
import '../services/theme_service.dart';

/// AppColors exposes theme-aware getters (not raw consts) so every screen
/// that already reads `AppColors.xxx` directly automatically follows the
/// live Light/Dark toggle without needing to be individually rewritten.
/// ThemeService.isDark is kept in sync synchronously whenever the user
/// toggles theme, so these getters always reflect the current mode even
/// though they're static (no BuildContext needed).
class AppColors {
  // ---------------- Dark palette (unchanged from original) ----------------
  static const Color _bgDark = Color(0xFF0A0E1A);
  static const Color _surfaceDark = Color(0xFF131A2B);
  static const Color _surfaceLightDark = Color(0xFF1C2438);
  static const Color _primaryBlueDark = Color(0xFF2B6CF6);
  static const Color _accentCyanDark = Color(0xFF4FC3F7);
  static const Color _textPrimaryDark = Color(0xFFEAF0FF);
  static const Color _textSecondaryDark = Color(0xFF8B96AD);
  static const Color _balanceGreenDark = Color(0xFF2ECC71);
  static const Color _balanceRedDark = Color(0xFFFF6B4A);
  static const Color _warningAmberDark = Color(0xFFFFB020);

  // ---------------- Light palette (new - warm paper/ink, own identity) ----------------
  static const Color _bgLight = Color(0xFFF4F0E6);
  static const Color _surfaceLight = Color(0xFFFFFFFF);
  static const Color _surfaceLightLight = Color(0xFFF6F2E9);
  static const Color _primaryBlueLight = Color(0xFF1E4FD6);
  static const Color _accentCyanLight = Color(0xFF0E7FA3);
  static const Color _textPrimaryLight = Color(0xFF20242C);
  static const Color _textSecondaryLight = Color(0xFF6B7280);
  static const Color _balanceGreenLight = Color(0xFF1F8A4C);
  static const Color _balanceRedLight = Color(0xFFC2410C);
  static const Color _warningAmberLight = Color(0xFFB45309);

  static bool get _dark => ThemeService.isDark;

  static Color get bgDark => _dark ? _bgDark : _bgLight;
  static Color get surface => _dark ? _surfaceDark : _surfaceLight;
  static Color get surfaceLight => _dark ? _surfaceLightDark : _surfaceLightLight;
  static Color get primaryBlue => _dark ? _primaryBlueDark : _primaryBlueLight;
  static Color get accentCyan => _dark ? _accentCyanDark : _accentCyanLight;
  static Color get textPrimary => _dark ? _textPrimaryDark : _textPrimaryLight;
  static Color get textSecondary => _dark ? _textSecondaryDark : _textSecondaryLight;
  static Color get balanceGreen => _dark ? _balanceGreenDark : _balanceGreenLight;
  static Color get balanceRed => _dark ? _balanceRedDark : _balanceRedLight;
  static Color get warningAmber => _dark ? _warningAmberDark : _warningAmberLight;

  static LinearGradient get primaryGradient => _dark
      ? const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A8A), Color(0xFF4FC3F7)],
        )
      : const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E4FD6), Color(0xFF0E7FA3)],
        );
}

class AppTheme {
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0A0E1A),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2B6CF6),
        brightness: Brightness.dark,
        primary: const Color(0xFF2B6CF6),
        surface: const Color(0xFF131A2B),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0A0E1A),
        elevation: 0,
        centerTitle: false,
        foregroundColor: Color(0xFFEAF0FF),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF131A2B),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1C2438),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2B6CF6),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Color(0xFFEAF0FF)),
        bodyMedium: TextStyle(color: Color(0xFFEAF0FF)),
      ).apply(
        bodyColor: const Color(0xFFEAF0FF),
        displayColor: const Color(0xFFEAF0FF),
      ),
    );
  }

  /// New warm paper/ink light theme - own identity (deep blue + teal accent
  /// on cream), same spirit as EasyQuote's light look without copying it.
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF4F0E6),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1E4FD6),
        brightness: Brightness.light,
        primary: const Color(0xFF1E4FD6),
        secondary: const Color(0xFF0E7FA3),
        surface: const Color(0xFFFFFFFF),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF4F0E6),
        elevation: 0,
        centerTitle: false,
        foregroundColor: Color(0xFF20242C),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFFFFFFFF),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE4DFD0)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF6F2E9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE4DFD0)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E4FD6),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Color(0xFF20242C)),
        bodyMedium: TextStyle(color: Color(0xFF20242C)),
      ).apply(
        bodyColor: const Color(0xFF20242C),
        displayColor: const Color(0xFF20242C),
      ),
    );
  }
}
