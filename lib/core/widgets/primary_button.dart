import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';

/// Full-width CTA. Two looks:
/// - default: blue gradient (used in the dark app)
/// - [dark] = true: black pill (used on onboarding screens)
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
    this.icon,
    this.dark = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool enabled;
  final IconData? icon;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final active = enabled && onPressed != null;
    final gradient = dark ? AppColors.ctaDark : AppColors.accentGradient;
    final glow = dark ? Colors.black : AppColors.accent;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: active ? 1 : 0.45,
      child: GestureDetector(
        onTap: active ? onPressed : null,
        child: Container(
          height: 58,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(dark ? 30 : AppRadius.button),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: glow.withValues(alpha: dark ? 0.28 : 0.32),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label,
                  style: AppTextStyles.button.copyWith(color: Colors.white)),
              if (icon != null) ...[
                const SizedBox(width: 8),
                Icon(icon, size: 20, color: Colors.white),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
