import 'package:flutter/material.dart';

/// Central palette for Fitify. The app has two distinct skins:
/// - DARK for the main app (pure-black, blue accent, yellow premium)
/// - LIGHT for onboarding (pale lavender, white cards, blue primary, black CTAs)
class AppColors {
  AppColors._();

  // ===================== MAIN APP (LIGHT) =====================
  // Light-first: the whole app uses these. A dark variant becomes a Settings
  // toggle later (see [[fitify-build-state]]).
  static const Color background = Color(0xFFF4F5FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFEEF1F8);
  static const Color surfaceHighlight = Color(0xFFE2E7F2);

  static const Color accent = Color(0xFF2563FF); // primary blue
  static const Color accentSoft = Color(0xFFDCE6FF);
  static const Color accentMuted = Color(0x142563FF);
  static const Color premium = Color(0xFFF5C518); // "Go Premium" yellow

  static const Color textPrimary = Color(0xFF10131C);
  static const Color textSecondary = Color(0xFF5B6172);
  static const Color textTertiary = Color(0xFF9AA0AE);

  static const Color success = Color(0xFF1FB271);
  static const Color warning = Color(0xFFF5872A);
  static const Color danger = Color(0xFFE5484D);
  static const Color border = Color(0xFFE6E9F1);

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF3B82FF), Color(0xFF2563FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF1F4FB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Dark "pill" gradient used on onboarding CTAs (black button).
  static const LinearGradient ctaDark = LinearGradient(
    colors: [Color(0xFF2C2C2E), Color(0xFF0A0A0A)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // ===================== LIGHT (onboarding) =====================
  static const Color onbBackground = Color(0xFFF3F4F9);
  static const Color onbCard = Color(0xFFFFFFFF);
  static const Color onbCardSelected = Color(0xFFEAF1FF);
  static const Color onbPrimary = Color(0xFF2563FF);
  static const Color onbGreen = Color(0xFF1FB271);
  static const Color onbOrange = Color(0xFFF5872A);
  static const Color onbTextDark = Color(0xFF10131C);
  static const Color onbTextGrey = Color(0xFF6B7280);
  static const Color onbTip = Color(0xFFE9EFFE);
  static const Color onbBorder = Color(0xFFE4E7EF);
  static const Color onbTrack = Color(0xFFE2E6F0); // progress / slider track
}
