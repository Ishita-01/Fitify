import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Pale-blue "coach tip" box with the robot mascot and a faint quote mark,
/// matching the onboarding screenshots.
class RobotTip extends StatelessWidget {
  const RobotTip({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.onbTip.withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(18),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.75), width: 1),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -6,
            right: 0,
            child: Text(
              '"',
              style: AppTextStyles.display.copyWith(
                fontSize: 40,
                color: AppColors.onbPrimary.withValues(alpha: 0.18),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: AppColors.onbPrimary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.smart_toy_rounded,
                    size: 22, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2, right: 12),
                  child: Text(
                    text,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.onbTextGrey,
                      fontSize: 14.5,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
