import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'color_tokens.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return FlexThemeData.dark(
      colors: const FlexSchemeColor(
        primary: ColorTokens.primary,
        primaryContainer: Color(0xFF2D2550),
        secondary: ColorTokens.secondary,
        secondaryContainer: Color(0xFF004D4A),
        tertiary: ColorTokens.accent,
        tertiaryContainer: Color(0xFF5A2040),
      ),
      surfaceMode: FlexSurfaceMode.highScaffoldLevelSurface,
      blendLevel: 15,
      subThemesData: const FlexSubThemesData(
        blendOnLevel: 20,
        blendOnColors: false,
        useM2StyleDividerInM3: true,
        inputDecoratorBorderType: FlexInputBorderType.outline,
        inputDecoratorRadius: 8.0,
        cardRadius: 12.0,
        dialogRadius: 16.0,
        tabBarIndicatorWeight: 3.0,
        bottomNavigationBarOpacity: 0.95,
      ),
      useMaterial3: true,
      fontFamily: GoogleFonts.inter().fontFamily,
    ).copyWith(
      scaffoldBackgroundColor: const Color(0xFF0D1117),
      cardColor: const Color(0xFF161B22),
      dividerColor: const Color(0xFF21262D),
      textTheme: _buildTextTheme(Brightness.dark),
      tooltipTheme: _tooltipTheme(Brightness.dark),
      snackBarTheme: _snackBarTheme(Brightness.dark),
    );
  }

  static ThemeData get lightTheme {
    return FlexThemeData.light(
      colors: const FlexSchemeColor(
        primary: ColorTokens.primary,
        primaryContainer: Color(0xFFE8E4FF),
        secondary: ColorTokens.secondary,
        secondaryContainer: Color(0xFFD1FAF0),
        tertiary: ColorTokens.accent,
        tertiaryContainer: Color(0xFFFFE0EB),
      ),
      surfaceMode: FlexSurfaceMode.highScaffoldLevelSurface,
      blendLevel: 7,
      subThemesData: const FlexSubThemesData(
        blendOnLevel: 10,
        blendOnColors: false,
        useM2StyleDividerInM3: true,
        inputDecoratorBorderType: FlexInputBorderType.outline,
        inputDecoratorRadius: 8.0,
        cardRadius: 12.0,
        dialogRadius: 16.0,
        tabBarIndicatorWeight: 3.0,
      ),
      useMaterial3: true,
      fontFamily: GoogleFonts.inter().fontFamily,
    ).copyWith(
      scaffoldBackgroundColor: const Color(0xFFF6F8FA),
      cardColor: Colors.white,
      dividerColor: const Color(0xFFD0D7DE),
      textTheme: _buildTextTheme(Brightness.light),
      tooltipTheme: _tooltipTheme(Brightness.light),
      snackBarTheme: _snackBarTheme(Brightness.light),
    );
  }

  static SnackBarThemeData _snackBarTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return SnackBarThemeData(
      backgroundColor: isDark ? const Color(0xFF2D333B) : const Color(0xFF1F2328),
      contentTextStyle: TextStyle(
        fontFamily: GoogleFonts.inter().fontFamily,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: isDark ? const Color(0xFFE6EDF3) : Colors.white,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      behavior: SnackBarBehavior.floating,
      elevation: 4,
    );
  }

  static TooltipThemeData _tooltipTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return TooltipThemeData(
      waitDuration: const Duration(milliseconds: 400),
      showDuration: const Duration(milliseconds: 1500),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D333B) : const Color(0xFF1F2328),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      textStyle: TextStyle(
        fontFamily: GoogleFonts.inter().fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: isDark ? const Color(0xFFE6EDF3) : Colors.white,
      ),
    );
  }

  static TextTheme _buildTextTheme(Brightness brightness) {
    final baseColor =
        brightness == Brightness.dark ? Colors.white : const Color(0xFF1F2328);
    final secondaryColor =
        brightness == Brightness.dark
            ? const Color(0xFF8B949E)
            : const Color(0xFF656D76);
    final fontFamily = GoogleFonts.inter().fontFamily;
    final monoFamily = GoogleFonts.jetBrainsMono().fontFamily;

    return TextTheme(
      headlineLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: baseColor,
      ),
      headlineMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),
      titleLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),
      titleMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: baseColor,
      ),
      titleSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: secondaryColor,
      ),
      bodyLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: baseColor,
      ),
      bodyMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: baseColor,
      ),
      bodySmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: secondaryColor,
      ),
      labelLarge: TextStyle(
        fontFamily: monoFamily,
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: baseColor,
      ),
      labelMedium: TextStyle(
        fontFamily: monoFamily,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: secondaryColor,
      ),
      labelSmall: TextStyle(
        fontFamily: monoFamily,
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: secondaryColor,
      ),
    );
  }
}
