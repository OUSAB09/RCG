import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Apex Rush visual identity — neon arcade racing aesthetic.
class AppColors {
  static const Color bg = Color(0xFF0B0B16);
  static const Color bgElevated = Color(0xFF15152A);
  static const Color card = Color(0xFF1C1C36);
  static const Color cardHi = Color(0xFF26264A);

  static const Color neonCyan = Color(0xFF22E0FF);
  static const Color neonMagenta = Color(0xFFFF2D9B);
  static const Color neonPurple = Color(0xFF8A5BFF);
  static const Color neonGreen = Color(0xFF3DFF8A);
  static const Color neonYellow = Color(0xFFFFD23D);
  static const Color neonOrange = Color(0xFFFF7A3D);

  static const Color textPrimary = Color(0xFFF2F2FA);
  static const Color textSecondary = Color(0xFF9A9AB8);
  static const Color textDim = Color(0xFF63637E);

  static const LinearGradient brandGradient = LinearGradient(
    colors: [neonMagenta, neonPurple, neonCyan],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient bgGradient = LinearGradient(
    colors: [Color(0xFF0B0B16), Color(0xFF131326)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

class AppTheme {
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.neonCyan,
        secondary: AppColors.neonMagenta,
        surface: AppColors.card,
      ),
      textTheme: GoogleFonts.rajdhaniTextTheme(base.textTheme).apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.card,
        elevation: 0,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }

  static TextStyle display(double size,
          {Color color = AppColors.textPrimary, FontWeight weight = FontWeight.w700}) =>
      GoogleFonts.orbitron(fontSize: size, color: color, fontWeight: weight, letterSpacing: 1.0);

  static TextStyle body(double size,
          {Color color = AppColors.textPrimary, FontWeight weight = FontWeight.w500}) =>
      GoogleFonts.rajdhani(fontSize: size, color: color, fontWeight: weight, letterSpacing: 0.4);
}
