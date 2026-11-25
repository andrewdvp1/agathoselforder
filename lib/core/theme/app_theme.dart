import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);
    final displayFont = GoogleFonts.plusJakartaSans();

    final textTheme = baseTextTheme.copyWith(
      displaySmall: displayFont.copyWith(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: AppColors.textPrimary,
      ),
      headlineMedium: displayFont.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.25,
        color: AppColors.textPrimary,
      ),
      headlineSmall: displayFont.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.25,
        color: AppColors.textPrimary,
      ),
      titleLarge: displayFont.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: AppColors.textPrimary,
      ),
      titleMedium: displayFont.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: AppColors.textPrimary,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.textPrimary,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: AppColors.textSecondary,
      ),
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: AppColors.textPrimary,
      ),
      labelMedium: baseTextTheme.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: AppColors.textPrimary,
      ),
      bodySmall: baseTextTheme.bodySmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.3,
        color: AppColors.textMuted,
      ),
    );

    const colorScheme = ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primaryTonal,
      onPrimaryContainer: AppColors.primaryOnTonal,
      secondary: AppColors.secondary,
      onSecondary: AppColors.secondaryOnTonal,
      secondaryContainer: AppColors.secondaryTonal,
      onSecondaryContainer: AppColors.secondaryOnTonal,
      tertiary: AppColors.tertiary,
      onTertiary: AppColors.neutral,
      tertiaryContainer: AppColors.tertiaryTonal,
      onTertiaryContainer: AppColors.tertiaryOnTonal,
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: AppColors.errorTonal,
      onErrorContainer: AppColors.errorOnTonal,
      surface: AppColors.surfaceBase,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.borderGlassSubtle,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgCanvas,
      colorScheme: colorScheme,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.textPrimary,
        titleTextStyle: textTheme.headlineSmall,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceInput,
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        labelStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        errorStyle: textTheme.bodySmall?.copyWith(color: AppColors.errorTonal),
        prefixIconColor: AppColors.textMuted,
        suffixIconColor: AppColors.textSecondary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderGlassInput),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderGlassInput),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceBase,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.borderGlassMedium),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderGlassSubtle,
        thickness: 1,
      ),
    );
  }
}
