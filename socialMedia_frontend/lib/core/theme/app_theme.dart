import 'package:flutter/material.dart';

class AppTheme {
  // Pastel Disco Vibe Colors (Soft & Harmonized)
  static const Color primaryDark = Color(0xFF1E1A29); // Yumuşak koyu pastel mor/gri
  static const Color surfaceDark = Color(0xFF2A233A); // Daha açık yüzey
  static const Color cardDark = Color(0xFF362E49); // Kart arka planı
  
  // Pastel Disko Renkleri
  static const Color accentViolet = Color(0xFFDDB8F7); // Pastel Menekşe
  static const Color accentPurple = Color(0xFFCBA1EB); // Pastel Mor
  static const Color accentPink = Color(0xFFFFB3D9); // Pastel Disko Pembesi
  static const Color accentCyan = Color(0xFFA3FFF0); // Pastel Spot Turkuaz
  static const Color accentGold = Color(0xFFFFEBB3); // Pastel Spot Altın
  
  static const Color textPrimary = Color(0xFFF7F3FC); // Kırık beyaz pastel
  static const Color textSecondary = Color(0xFFD9D4E6);
  static const Color textMuted = Color(0xFFA5A0B5);
  static const Color dividerColor = Color(0x30FFFFFF);
  static const Color errorColor = Color(0xFFFF99AA); // Pastel kırmızı/pembe
  static const Color successColor = Color(0xFF99FFCC); // Pastel yeşil

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
