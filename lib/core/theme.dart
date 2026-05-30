import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF004D40); // Deep Emerald
  static const Color secondaryColor = Color(0xFFC5A059); // Gold
  static const Color scaffoldBackgroundColor = Color(0xFFF5F5F0); // Off-White
  static const Color accentColor = Color(0xFF00796B);
  static const Color darkScaffoldBackgroundColor = Color(0xFF07110F);
  static const Color darkSurfaceColor = Color(0xFF101C19);
  static const Color darkElevatedSurfaceColor = Color(0xFF172622);

  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color surfaceColor(BuildContext context) {
    return isDark(context) ? darkSurfaceColor : Colors.white;
  }

  static Color elevatedSurfaceColor(BuildContext context) {
    return isDark(context) ? darkElevatedSurfaceColor : Colors.white;
  }

  static Color subtleSurfaceColor(BuildContext context) {
    return isDark(context) ? const Color(0xFF20312D) : const Color(0xFFF0F3EF);
  }

  static Color primaryTextColor(BuildContext context) {
    return isDark(context) ? const Color(0xFFF7FAF7) : Colors.black87;
  }

  static Color mutedTextColor(BuildContext context) {
    return isDark(context) ? const Color(0xFFB5C3BF) : Colors.grey.shade600;
  }

  static Color softBorderColor(BuildContext context) {
    return isDark(context) ? const Color(0xFF29433D) : const Color(0xFFE2E6DF);
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      textTheme: GoogleFonts.outfitTextTheme().copyWith(
        displayLarge: GoogleFonts.tajawal(
          color: primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 32,
        ),
        titleLarge: GoogleFonts.tajawal(
          color: primaryColor,
          fontWeight: FontWeight.w600,
          fontSize: 22,
        ),
        bodyLarge: GoogleFonts.tajawal(
          color: Colors.black87,
          fontSize: 16,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: Colors.white,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
      dividerTheme: const DividerThemeData(color: Color(0xFFE2E6DF)),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey.shade500,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        primary: primaryColor,
        secondary: secondaryColor,
        surface: darkSurfaceColor,
        onSurface: const Color(0xFFF7FAF7),
      ),
      scaffoldBackgroundColor: darkScaffoldBackgroundColor,
      textTheme: GoogleFonts.outfitTextTheme(
        ThemeData.dark().textTheme,
      ).copyWith(
        displayLarge: GoogleFonts.tajawal(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 32,
        ),
        titleLarge: GoogleFonts.tajawal(
          color: secondaryColor,
          fontWeight: FontWeight.w600,
          fontSize: 22,
        ),
        bodyLarge: GoogleFonts.tajawal(
          color: const Color(0xFFF7FAF7),
          fontSize: 16,
        ),
        bodyMedium: GoogleFonts.tajawal(color: const Color(0xFFE6EEEA)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkScaffoldBackgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: darkSurfaceColor,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkSurfaceColor,
        surfaceTintColor: darkSurfaceColor,
      ),
      dialogTheme: const DialogThemeData(backgroundColor: darkSurfaceColor),
      dividerTheme: const DividerThemeData(color: Color(0xFF29433D)),
      listTileTheme: const ListTileThemeData(
        textColor: Color(0xFFF7FAF7),
        iconColor: secondaryColor,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkElevatedSurfaceColor,
        hintStyle: const TextStyle(color: Color(0xFF9AA9A5)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFF29433D)),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkSurfaceColor,
        selectedItemColor: secondaryColor,
        unselectedItemColor: Color(0xFF9AA9A5),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}
