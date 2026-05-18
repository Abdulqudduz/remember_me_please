import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color background = Color(0xFFFBF9F4);
  static const Color onBackground = Color(0xFF31332E);
  static const Color primary = Color(0xFF366190);
  static const Color onPrimary = Color(0xFFF7F9FF);
  static const Color primaryDim = Color(0xFF295583);
  static const Color primaryContainer = Color(0xFF92BCF0);
  static const Color onPrimaryContainer = Color(0xFF003863);
  static const Color tertiary = Color(0xFF914D00);
  static const Color tertiaryContainer = Color(0xFFFE932C);
  static const Color onTertiaryContainer = Color(0xFF4A2500);
  static const Color secondary = Color(0xFF406934);
  static const Color secondaryContainer = Color(0xFFC0F0AD);
  static const Color onSecondaryContainer = Color(0xFF335B28);
  static const Color surfaceContainerLowest = Color(0xFFF5F4ED);
  static const Color surfaceContainerLow = Color(0xFFF5F4ED);
  static const Color surfaceVariant = Color(0xFFE3E3DB);
  static const Color onSurface = Color(0xFF31332E);
  static const Color onSurfaceVariant = Color(0xFF5E6059);
  static const Color surfaceContainer = Color(0xFFEFEEE7);
  static const Color surfaceContainerHigh = Color(0xFFE9E8E1);
  static const Color surfaceContainerHighest = Color(0xFFE3E3DB);
  static const Color outlineVariant = Color(0xFFB2B2AB);
  static const Color surfaceTint = Color(0xFF366190);
  static const Color onTertiary = Color(0xFFFFF7F4);
  static const Color scaffoldBackground = Color(0xFFE3F2FD);

  // Dark Theme Colors
  static const Color darkSurface = Color(0xFF121212);
  static const Color darkOnSurface = Color(0xFFF7F9FF);
  static const Color darkSurfaceContainerLow = Color(0xFF1E1E1E);
  static const Color darkSurfaceContainerHighest = Color(0xFF2C2C2C);
  
  // Shared Utilities
  static const Color transparent = Color(0x00000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color white70 = Color(0xB3FFFFFF);
  static const Color white54 = Color(0x8AFFFFFF);
  static const Color white30 = Color(0x4DFFFFFF);
  static const Color white12 = Color(0x1FFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color black87 = Color(0xDD000000);
  static const Color black54 = Color(0x8A000000);
  static const Color black45 = Color(0x73000000);
  static const Color black38 = Color(0x62000000);
  static const Color black12 = Color(0x1F000000);
  static const Color grey = Color(0xFF8E8E93);
  static const Color greyLight = Color(0xFFE5E5EA);
  static const Color greyDark = Color(0xFF3A3A3C);
  static const Color red = Color(0xFFFF3B30);
  static const Color redAccent = Color(0xFFFF453A);
  static const Color green = Color(0xFF34C759);
  static const Color orange = Color(0xFFFF9500);
  static const Color blue = Color(0xFF007AFF);
  static const Color blueAccent = Color(0xFF0A84FF);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        surface: AppColors.background,
        onSurface: AppColors.onBackground,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onPrimary,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.onSecondaryContainer,
        tertiary: AppColors.tertiary,
        onTertiary: AppColors.background,
        tertiaryContainer: AppColors.tertiaryContainer,
        onTertiaryContainer: AppColors.onTertiaryContainer,
        surfaceContainerLow: AppColors.surfaceContainerLow,
        surfaceContainerHighest: AppColors.surfaceVariant,
        onSurfaceVariant: AppColors.onSurfaceVariant,
      ),
      appBarTheme: const AppBarTheme(surfaceTintColor: AppColors.transparent),
      textTheme: GoogleFonts.lexendTextTheme().copyWith(
        displayLarge: GoogleFonts.lexend(
          fontSize: 56,
          fontWeight: FontWeight.w500,
          color: AppColors.primary,
          letterSpacing: -1,
        ),
        titleLarge: GoogleFonts.lexend(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
        ),
        titleMedium: GoogleFonts.lexend(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
        ),
        bodyLarge: GoogleFonts.lexend(
          fontSize: 18,
          fontWeight: FontWeight.w400,
          color: AppColors.onSurface,
        ),
        bodyMedium: GoogleFonts.lexend(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.onSurfaceVariant,
        ),
        labelSmall: GoogleFonts.lexend(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
      scaffoldBackgroundColor: AppColors.scaffoldBackground,
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.scaffoldBackground,
        surfaceTintColor: AppColors.transparent,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkOnSurface,
        primary: AppColors.primaryContainer,
        onPrimary: AppColors.onPrimaryContainer,
        secondary: AppColors.secondaryContainer,
        onSecondary: AppColors.onSecondaryContainer,
        surfaceContainerLow: AppColors.darkSurfaceContainerLow,
        surfaceContainerHighest: AppColors.darkSurfaceContainerHighest,
        onSurfaceVariant: AppColors.surfaceVariant,
      ),
      appBarTheme: const AppBarTheme(
        surfaceTintColor: AppColors.transparent,
        backgroundColor: AppColors.transparent,
        iconTheme: IconThemeData(color: AppColors.darkOnSurface),
        titleTextStyle: TextStyle(color: AppColors.darkOnSurface),
      ),
      scaffoldBackgroundColor: AppColors.darkSurface,
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.darkSurfaceContainerLow,
        surfaceTintColor: AppColors.transparent,
      ),
      textTheme: GoogleFonts.lexendTextTheme().apply(
        bodyColor: AppColors.darkOnSurface,
        displayColor: AppColors.darkOnSurface,
      ).copyWith(
        titleLarge: GoogleFonts.lexend(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.darkOnSurface,
        ),
        titleMedium: GoogleFonts.lexend(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.darkOnSurface,
        ),
        bodyLarge: GoogleFonts.lexend(
          fontSize: 18,
          fontWeight: FontWeight.w400,
          color: AppColors.darkOnSurface,
        ),
        bodyMedium: GoogleFonts.lexend(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.surfaceVariant,
        ),
      ),
    );
  }
}
