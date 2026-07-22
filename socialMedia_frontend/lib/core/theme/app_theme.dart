import 'package:flutter/material.dart';

class AppTheme {
  // Wardrowbe-inspired Sleek Dark Theme Colors
  static const Color primaryDark = Color(0xFF000000); // Pure black background
  static const Color surfaceDark = Color(0xFF0F0F0F); // Very dark gray for app bars/nav
  static const Color cardDark = Color(0xFF141414); // Dark gray for cards
  
  // Accents (Keeping for compatibility, but maybe less saturated)
  static const Color accentViolet = Color(0xFFDDB8F7); 
  static const Color accentPurple = Color(0xFFCBA1EB); 
  static const Color accentPink = Color(0xFFFFB3D9); 
  static const Color accentCyan = Color(0xFFA3FFF0); 
  static const Color accentGold = Color(0xFFFFEBB3); 
  
  static const Color textPrimary = Color(0xFFF0F0F0); // Off-white
  static const Color textSecondary = Color(0xFFB0B0B0); // Gray
  static const Color textMuted = Color(0xFF707070); // Darker gray
  static const Color dividerColor = Color(0xFF262626); // Subtle border color
  static const Color errorColor = Color(0xFFFF6B6B); 
  static const Color successColor = Color(0xFF51CF66); 

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
