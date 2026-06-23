import 'package:flutter/material.dart';

/// Central palette for Fitify.
///
/// The MAIN APP supports a runtime light/dark toggle: the semantic colors below
/// are *getters* that resolve against [_dark]. Flip the mode with
/// [AppColors.setMode] (driven by `ThemeController`) and every widget that reads
/// `AppColors.background` etc. reskins on the next rebuild — no per-widget edits.
///
/// ONBOARDING stays pure light always, so its `onb*` colors are plain consts.
class AppColors {
  AppColors._();

  // ===================== MODE =====================
  static bool _dark = false;
  static bool get isDark => _dark;
  static void setMode(bool dark) => _dark = dark;

  static Color _pick(Color light, Color dark) => _dark ? dark : light;

  // ===================== MAIN APP (light ⇄ dark) =====================
  static Color get background => _pick(const Color(0xFFF4F5FA), const Color(0xFF0A0B0E));
  static Color get surface => _pick(const Color(0xFFFFFFFF), const Color(0xFF15171C));
  static Color get surfaceElevated => _pick(const Color(0xFFEEF1F8), const Color(0xFF1C1F26));
  static Color get surfaceHighlight => _pick(const Color(0xFFE2E7F2), const Color(0xFF262A33));

  static Color get accent => _pick(const Color(0xFF2563FF), const Color(0xFF3B82FF));
  static Color get accentSoft => _pick(const Color(0xFFDCE6FF), const Color(0xFF1B2A4A));
  static const Color accentMuted = Color(0x142563FF); // translucent — reads on both
  static const Color premium = Color(0xFFF5C518); // "Go Premium" yellow

  static Color get textPrimary => _pick(const Color(0xFF10131C), const Color(0xFFF3F5FA));
  static Color get textSecondary => _pick(const Color(0xFF5B6172), const Color(0xFFB2B9C8));
  static Color get textTertiary => _pick(const Color(0xFF9AA0AE), const Color(0xFF838B9B));

  static const Color success = Color(0xFF1FB271);
  static const Color warning = Color(0xFFF5872A);
  static const Color danger = Color(0xFFE5484D);
  static Color get border => _pick(const Color(0xFFE6E9F1), const Color(0xFF272B34));

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF3B82FF), Color(0xFF2563FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get cardGradient => LinearGradient(
        colors: _dark
            ? const [Color(0xFF1B1E25), Color(0xFF15171C)]
            : const [Color(0xFFFFFFFF), Color(0xFFF1F4FB)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  /// Dark "pill" gradient used on onboarding CTAs (black button).
  static const LinearGradient ctaDark = LinearGradient(
    colors: [Color(0xFF2C2C2E), Color(0xFF0A0A0A)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // ===================== ONBOARDING (always light) =====================
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
