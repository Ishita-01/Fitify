import 'package:flutter/material.dart';

import '../../../core/navigation/page_transitions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/primary_button.dart';
import 'gender_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.onbBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 3),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('👏', style: AppTextStyles.display.copyWith(fontSize: 34)),
                        const SizedBox(height: 8),
                        Text(
                          'Hello!',
                          style: AppTextStyles.display.copyWith(
                            fontSize: 56,
                            color: AppColors.onbTextDark,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const _CoachAvatar(),
                ],
              ),
              const SizedBox(height: 24),
              RichText(
                text: TextSpan(
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontSize: 18,
                    height: 1.5,
                    color: AppColors.onbTextDark,
                    fontWeight: FontWeight.w500,
                  ),
                  children: [
                    const TextSpan(
                        text:
                            "I'm your personal coach.\nHere are some questions to tailor a "),
                    TextSpan(
                        text: 'personalized plan',
                        style: TextStyle(color: AppColors.onbPrimary)),
                    const TextSpan(text: ' for you.'),
                  ],
                ),
              ),
              const Spacer(flex: 4),
              PrimaryButton(
                label: "I'M READY",
                dark: true,
                onPressed: () => Navigator.of(context)
                    .push(slideFadeRoute(const GenderScreen())),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// Coach avatar — circular tinted disc with a coach icon (no photo asset yet).
class _CoachAvatar extends StatelessWidget {
  const _CoachAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      height: 110,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFE6E8F0),
      ),
      child: const Icon(Icons.sports_gymnastics_rounded,
          size: 64, color: AppColors.onbTextDark),
    );
  }
}
