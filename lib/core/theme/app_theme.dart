import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Shared design tokens.
class AppRadius {
  AppRadius._();
  static const double card = 20;
  static const double button = 16;
  static const double chip = 14;
  static const double sheet = 28;
}

class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double screenH = 24;
}

class AppTheme {
  AppTheme._();

  /// The active theme, resolved against [AppColors.isDark]. Rebuilt by
  /// `MaterialApp` whenever `ThemeController` toggles the mode.
  static ThemeData get current {
    final dark = AppColors.isDark;
    final base =
        (dark ? ThemeData.dark(useMaterial3: true) : ThemeData.light(useMaterial3: true));
    final scheme = (dark ? const ColorScheme.dark() : const ColorScheme.light()).copyWith(
      surface: AppColors.background,
      primary: AppColors.accent,
      secondary: AppColors.accent,
      error: AppColors.danger,
      onPrimary: Colors.white,
      onSurface: AppColors.textPrimary,
    );
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: scheme,
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),
      dividerTheme: DividerThemeData(color: AppColors.border, thickness: 1),
    );
  }
}
