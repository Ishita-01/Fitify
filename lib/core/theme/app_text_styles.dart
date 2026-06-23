import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typography for Fitify — an "athletic premium" pairing:
/// - **Space Grotesk** for display/headings/buttons (modern, sporty grotesk).
/// - **Inter** for body/UI text (the clean, SF-like workhorse).
/// - **Bebas Neue** for big stat numbers (condensed, scoreboard energy).
class AppTextStyles {
  AppTextStyles._();

  static TextStyle get display => GoogleFonts.spaceGrotesk(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.12,
        letterSpacing: -0.8,
        color: AppColors.textPrimary,
      );

  static TextStyle get headingLarge => GoogleFonts.spaceGrotesk(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        height: 1.18,
        letterSpacing: -0.5,
        color: AppColors.textPrimary,
      );

  static TextStyle get heading => GoogleFonts.spaceGrotesk(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 1.22,
        letterSpacing: -0.3,
        color: AppColors.textPrimary,
      );

  static TextStyle get title => GoogleFonts.spaceGrotesk(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: AppColors.textPrimary,
      );

  static TextStyle get body => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: AppColors.textSecondary,
      );

  static TextStyle get label => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      );

  static TextStyle get button => GoogleFonts.spaceGrotesk(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      );

  /// Big numeric display (streaks, percentages, scores, kcal). Bebas Neue is
  /// condensed and single-weight, so it's sized up vs the old Poppins value.
  static TextStyle get statValue => GoogleFonts.bebasNeue(
        fontSize: 30,
        fontWeight: FontWeight.w400,
        height: 1.0,
        letterSpacing: 0.5,
        color: AppColors.textPrimary,
      );
}
