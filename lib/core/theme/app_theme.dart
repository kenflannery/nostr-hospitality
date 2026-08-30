import 'package:flutter/material.dart';

/// Modern Material 3 theme tailored to Hospitality Libre's Sage & Lavender brand identity.
class AppTheme {
  AppTheme._();

  // Brand Colors: Sage & Lavender
  static const Color primarySage = Color(0xFF537A65);
  static const Color secondaryLavender = Color(0xFF8675B3);
  static const Color tertiarySlate = Color(0xFF556877);

  static const Color positiveGreen = Color(0xFF388E3C);
  static const Color neutralGrey = Color(0xFF5F6368);
  static const Color negativeRed = Color(0xFFD93025);

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primarySage,
      primary: primarySage,
      secondary: secondaryLavender,
      tertiary: tertiarySlate,
      brightness: Brightness.light,
      surface: const Color(0xFFF9FAF9),
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: const Color(0xFFF1F4F2),
      surfaceContainer: const Color(0xFFE9ECE9),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        indicatorColor: primarySage.withValues(alpha: 0.15),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 1.5,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primarySage,
      primary: const Color(0xFF7CA38E),
      secondary: const Color(0xFFAFA0D6),
      tertiary: const Color(0xFF8CAADB),
      brightness: Brightness.dark,
      surface: const Color(0xFF141A17),
      surfaceContainerLowest: const Color(0xFF0D1210),
      surfaceContainerLow: const Color(0xFF1A211D),
      surfaceContainer: const Color(0xFF222B26),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.18),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 1.5,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
