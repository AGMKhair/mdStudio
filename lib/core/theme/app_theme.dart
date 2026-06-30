import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

class AppTheme {
  AppTheme._();

  // ─── LIGHT THEME ──────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.saira().fontFamily,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.cardBg,
        error: AppColors.error,
        onPrimary: AppColors.white,
        onSecondary: AppColors.white,
        onSurface: AppColors.grey900,
        onError: AppColors.white,
      ),
      scaffoldBackgroundColor: AppColors.scaffoldBg,
      textTheme: _buildTextTheme(Brightness.light),
      appBarTheme: _buildAppBarTheme(Brightness.light),
      elevatedButtonTheme: _buildElevatedButtonTheme(),
      outlinedButtonTheme: _buildOutlinedButtonTheme(),
      inputDecorationTheme: _buildInputDecorationTheme(),
      cardTheme: _buildCardTheme(),
      dividerTheme: const DividerThemeData(
        color: AppColors.grey200,
        thickness: 1,
      ),
    );
  }

  // ─── DARK THEME ───────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.saira().fontFamily,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.darkCardBg,
        error: AppColors.error,
        onPrimary: AppColors.white,
        onSecondary: AppColors.white,
        onSurface: AppColors.grey100,
        onError: AppColors.white,
      ),
      scaffoldBackgroundColor: AppColors.darkScaffoldBg,
      textTheme: _buildTextTheme(Brightness.dark),
      appBarTheme: _buildAppBarTheme(Brightness.dark),
      elevatedButtonTheme: _buildElevatedButtonTheme(),
      outlinedButtonTheme: _buildOutlinedButtonTheme(),
      inputDecorationTheme: _buildInputDecorationTheme(isDark: true),
      cardTheme: _buildCardTheme(isDark: true),
    );
  }

  // ─── TEXT THEME ───────────────────────────────────────────────
  static TextTheme _buildTextTheme(Brightness brightness) {
    final Color textColor = brightness == Brightness.light
        ? AppColors.grey900
        : AppColors.grey100;
    final Color subtleColor = brightness == Brightness.light
        ? AppColors.grey600
        : AppColors.grey400;

    return TextTheme(
      displayLarge: GoogleFonts.saira(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: textColor,
        height: 1.2,
      ),
      displayMedium: GoogleFonts.saira(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: textColor,
        height: 1.2,
      ),
      displaySmall: GoogleFonts.saira(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textColor,
        height: 1.3,
      ),
      headlineLarge: GoogleFonts.saira(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      headlineMedium: GoogleFonts.saira(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      headlineSmall: GoogleFonts.saira(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleLarge: GoogleFonts.saira(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleMedium: GoogleFonts.saira(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
      titleSmall: GoogleFonts.saira(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: subtleColor,
      ),
      bodyLarge: GoogleFonts.saira(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      bodyMedium: GoogleFonts.saira(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      bodySmall: GoogleFonts.saira(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: subtleColor,
      ),
      labelLarge: GoogleFonts.saira(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      labelMedium: GoogleFonts.saira(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
      labelSmall: GoogleFonts.saira(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: subtleColor,
      ),
    );
  }

  // ─── APP BAR ──────────────────────────────────────────────────
  static AppBarTheme _buildAppBarTheme(Brightness brightness) {
    final bool isLight = brightness == Brightness.light;
    return AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: isLight ? AppColors.white : AppColors.darkCardBg,
      foregroundColor: isLight ? AppColors.grey900 : AppColors.grey100,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: isLight
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
      titleTextStyle: GoogleFonts.saira(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: isLight ? AppColors.grey900 : AppColors.grey100,
      ),
    );
  }

  // ─── ELEVATED BUTTON ──────────────────────────────────────────
  static ElevatedButtonThemeData _buildElevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        minimumSize: const Size(double.infinity, AppDimensions.buttonHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
        ),
        textStyle: GoogleFonts.saira(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ─── OUTLINED BUTTON ──────────────────────────────────────────
  static OutlinedButtonThemeData _buildOutlinedButtonTheme() {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary, width: 1.5),
        minimumSize: const Size(double.infinity, AppDimensions.buttonHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
        ),
        textStyle: GoogleFonts.saira(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ─── INPUT DECORATION ─────────────────────────────────────────
  static InputDecorationTheme _buildInputDecorationTheme({
    bool isDark = false,
  }) {
    final Color borderColor = isDark ? AppColors.grey700 : AppColors.grey300;
    final Color fillColor = isDark ? AppColors.darkCardBg : AppColors.grey50;

    return InputDecorationTheme(
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingM,
        vertical: AppDimensions.paddingM,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.inputRadius),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.inputRadius),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.inputRadius),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.inputRadius),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      hintStyle: GoogleFonts.saira(
        color: isDark ? AppColors.grey500 : AppColors.grey400,
        fontSize: 14,
      ),
      labelStyle: GoogleFonts.saira(
        color: isDark ? AppColors.grey400 : AppColors.grey600,
        fontSize: 14,
      ),
    );
  }

  // ─── CARD ─────────────────────────────────────────────────────
  static CardThemeData _buildCardTheme({bool isDark = false}) {
    return CardThemeData(
      elevation: AppDimensions.cardElevation,
      color: isDark ? AppColors.darkCardBg : AppColors.cardBg,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      clipBehavior: Clip.antiAlias,
    );
  }
}
