import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';

/// A tappable option row for onboarding (light theme). White card; when
/// selected it gets a blue border, pale-blue fill, blue label, and a filled
/// check circle on the right. Unselected shows a hollow grey circle.
class SelectableCard extends StatelessWidget {
  const SelectableCard({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.subtitle,
    this.trailingCheck = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final String? subtitle;

  /// Kept for API compatibility; the light card always shows a trailing marker.
  final bool trailingCheck;

  @override
  Widget build(BuildContext context) {
    final labelColor =
        selected ? AppColors.onbPrimary : AppColors.onbTextDark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.onbCardSelected.withValues(alpha: 0.80)
              : Colors.white.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: selected
                ? AppColors.onbPrimary
                : Colors.white.withValues(alpha: 0.75),
            width: selected ? 2 : 1.2,
          ),
          boxShadow: selected
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFF1B2559).withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 7),
                  ),
                ],
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 24,
                  color: selected
                      ? AppColors.onbPrimary
                      : AppColors.onbTextDark),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: AppTextStyles.title
                          .copyWith(fontSize: 16, color: labelColor)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(subtitle!,
                        style: AppTextStyles.caption.copyWith(
                          color: selected
                              ? AppColors.onbPrimary.withValues(alpha: 0.8)
                              : AppColors.onbTextGrey,
                        )),
                  ],
                ],
              ),
            ),
            _Marker(selected: selected),
          ],
        ),
      ),
    );
  }
}

class _Marker extends StatelessWidget {
  const _Marker({required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColors.onbPrimary : const Color(0xFFEDEFF5),
      ),
      child: selected
          ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
          : null,
    );
  }
}
