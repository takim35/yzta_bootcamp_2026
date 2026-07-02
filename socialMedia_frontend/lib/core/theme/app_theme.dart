import 'package:flutter/material.dart';

class AppTheme {
  // Colors
  static const Color primaryDark = Color(0xFF0D0D1A);
  static const Color surfaceDark = Color(0xFF1A1A2E);
  static const Color cardDark = Color(0xFF16213E);
  static const Color accentViolet = Color(0xFF8A2BE2);
  static const Color accentPurple = Color(0xFF9370DB);
  static const Color accentPink = Color(0xFFFF69B4);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;
  static const Color textMuted = Colors.white54;
  static const Color dividerColor = Colors.white12;
  static const Color errorColor = Colors.redAccent;
  static const Color successColor = Colors.greenAccent;

  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 40.0;

  // Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 24.0;
  static const double radiusRound = 100.0;

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [accentViolet, accentPink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Decorations
  static BoxDecoration glassDecoration({double opacity = 0.1}) {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(radiusMedium),
      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
    );
  }

  static BoxDecoration gradientButtonDecoration() {
    return BoxDecoration(
      gradient: primaryGradient,
      borderRadius: BorderRadius.circular(radiusRound),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: accentViolet,
      scaffoldBackgroundColor: primaryDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryDark,
        elevation: 0,
      ),
    );
  }
}
