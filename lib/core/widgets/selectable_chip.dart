import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// A pill-shaped multi-select chip for the onboarding "activities" grid.
/// Selected = blue border + pale-blue fill + blue text; otherwise white.
class SelectableChip extends StatelessWidget {
  const SelectableChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        decoration: BoxDecoration(
          color: selected ? AppColors.onbCardSelected : AppColors.onbCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.onbPrimary : AppColors.onbBorder,
            width: selected ? 1.6 : 1.4,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: selected ? AppColors.onbPrimary : AppColors.onbTextDark,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
