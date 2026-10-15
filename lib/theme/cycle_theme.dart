import 'package:flutter/material.dart';

class CycleColors {
  CycleColors._();

  static const primary = Color(0xFFBE185D); // Blush Rose
  static const primaryDark = Color(0xFFF472B6);
  static const secondary = Color(0xFFEC4899); // Soft Berry
  static const accent = Color(0xFF7C3AED); // Fertility Lavender
  static const backgroundLight = Color(0xFFFDF8FA);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const borderLight = Color(0xFFFCE7F0);

  static const backgroundDark = Color(0xFF160F1A);
  static const surfaceDark = Color(0xFF24182B);
  static const borderDark = Color(0xFF3B2844);

  // Cycle Phase Colors
  static const phaseMenstrual = Color(0xFFE11D48); // Rose red
  static const phaseFollicular = Color(0xFFFB7185); // Warm pink
  static const phaseOvulation = Color(0xFF7C3AED); // Deep lavender
  static const phaseLuteal = Color(0xFFF43F5E); // Soft coral
}

class CycleTheme {
  CycleTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: CycleColors.primary,
        secondary: CycleColors.secondary,
        surface: CycleColors.surfaceLight,
        error: Color(0xFFDC2626),
      ),
      scaffoldBackgroundColor: CycleColors.backgroundLight,
      cardTheme: CardThemeData(
        color: CycleColors.surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: CycleColors.borderLight),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: CycleColors.backgroundLight,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Color(0xFF0F172A)),
        titleTextStyle: TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFF472B6),
        secondary: Color(0xFFFB7185),
        surface: CycleColors.surfaceDark,
        error: Color(0xFFEF4444),
      ),
      scaffoldBackgroundColor: CycleColors.backgroundDark,
      cardTheme: CardThemeData(
        color: CycleColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: CycleColors.borderDark),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: CycleColors.backgroundDark,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
