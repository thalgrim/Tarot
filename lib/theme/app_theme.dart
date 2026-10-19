import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const background = Color(0xFF121A2F);
  static const surface = Color(0xFF1B2542);
  static const surfaceBorder = Color(0xFF263154);
  static const primary = Color(0xFFDE4B34);
  static const gold = Color(0xFFCBA23C);
  static const cream = Color(0xFFF2EAD9);
  static const textPrimary = Color(0xFFF5F6FA);
  static const textMuted = Color(0xFF8A8FA3);
  static const positive = Color(0xFF7ED9A6);
  static const negative = Color(0xFFE8897A);
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.gold,
      onSecondary: AppColors.background,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      error: AppColors.negative,
      onError: Colors.white,
    ),
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    ),
    dividerColor: AppColors.surfaceBorder,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.surfaceBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.surfaceBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      labelStyle: const TextStyle(color: AppColors.textMuted),
      hintStyle: const TextStyle(color: AppColors.textMuted),
    ),
    textSelectionTheme: const TextSelectionThemeData(cursorColor: AppColors.primary),
    sliderTheme: base.sliderTheme.copyWith(
      activeTrackColor: AppColors.gold,
      inactiveTrackColor: AppColors.surface,
      thumbColor: AppColors.textPrimary,
      overlayColor: AppColors.gold.withValues(alpha: 0.2),
      valueIndicatorColor: AppColors.gold,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: const WidgetStatePropertyAll(AppColors.textPrimary),
      trackColor: WidgetStatePropertyAll(AppColors.surface),
      trackOutlineColor: const WidgetStatePropertyAll(AppColors.surfaceBorder),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.surface,
      contentTextStyle: TextStyle(color: AppColors.textPrimary),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
