import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Re:ttle Design System Colors (matching CSS variables)
  static const Color primaryColor = Color(0xFF22C55E); // Green
  static const Color primaryDark = Color(0xFF0B3D2E); // Dark Forest Green
  static const Color accentLime = Color(0xFFD8F36A); // Lime Green
  static const Color mintColor = Color(0xFFF3FBF5); // Light Mint background
  static const Color cardBgLight = Colors.white;

  static const Color textDark = Color(0xFF132F23);
  static const Color textMuted = Color(0xFF7A9788);
  static const Color borderLight = Color(0xFFE6EFEA);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color destructiveColor = Color(0xFFDC2626);

  // Dark Mode colors
  static const Color bgDark = Color(0xFF131D18);
  static const Color cardBgDark = Color(0xFF1B2822);
  static const Color textLight = Color(0xFFF0F5F2);
  static const Color borderDark = Color(0x14FFFFFF);

  // Gradients
  static const LinearGradient gradientPrimary = LinearGradient(
    colors: [primaryColor, Color(0xFF66E091)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientHero = LinearGradient(
    colors: [primaryColor, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Shadows
  static final List<BoxShadow> shadowCard = [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.03),
      blurRadius: 3,
      offset: const Offset(0, 1),
    ),
  ];

  static final List<BoxShadow> shadowFab = [
    BoxShadow(
      color: primaryColor.withOpacity(0.35),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];

  // Font setup
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: mintColor,
      cardColor: cardBgLight,
      dividerColor: borderLight,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: primaryDark,
        tertiary: accentLime,
        surface: cardBgLight,
        error: destructiveColor,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme().copyWith(
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(fontSize: 14, color: textDark),
        bodyMedium: GoogleFonts.plusJakartaSans(fontSize: 13, color: textDark),
        bodySmall: GoogleFonts.plusJakartaSans(fontSize: 11, color: textMuted),
        labelLarge: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: primaryDark,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardBgLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: borderLight, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: borderLight.withOpacity(0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        hintStyle: const TextStyle(color: textMuted, fontSize: 13),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: bgDark,
      cardColor: cardBgDark,
      dividerColor: borderDark,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: accentLime,
        tertiary: primaryDark,
        surface: cardBgDark,
        error: destructiveColor,
      ),
      textTheme:
          GoogleFonts.plusJakartaSansTextTheme(
            ThemeData.dark().textTheme,
          ).copyWith(
            titleLarge: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textLight,
            ),
            titleMedium: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textLight,
            ),
            bodyLarge: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: textLight,
            ),
            bodyMedium: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: textLight,
            ),
            bodySmall: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: Colors.white60,
            ),
            labelLarge: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: accentLime,
            ),
          ),
      cardTheme: CardThemeData(
        color: cardBgDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: borderDark, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardBgDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
      ),
    );
  }
}
