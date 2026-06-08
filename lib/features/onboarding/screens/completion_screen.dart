import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/page_transitions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/primary_button.dart';
import '../../app/main_shell.dart';
import '../providers/onboarding_provider.dart';

/// Terminal onboarding screen shown after the profile is saved, then the user
/// enters the dark main app.
class CompletionScreen extends StatelessWidget {
  const CompletionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final name = context.watch<OnboardingProvider>().profile.name?.trim();
    final greeting = (name == null || name.isEmpty) ? 'You' : name;
    return Scaffold(
      backgroundColor: AppColors.onbBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.onbCardSelected,
                ),
                child: const Icon(Icons.check_rounded,
                    color: AppColors.onbPrimary, size: 72),
              ),
              const SizedBox(height: 32),
              Text(
                "You're all set, $greeting!",
                textAlign: TextAlign.center,
                style: AppTextStyles.display
                    .copyWith(fontSize: 30, color: AppColors.onbTextDark),
              ),
              const SizedBox(height: 16),
              Text(
                'Your personalized fitness plan is ready. Your AI coach will guide every workout from here.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body
                    .copyWith(color: AppColors.onbTextGrey, fontSize: 15.5),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Start Training',
                dark: true,
                icon: Icons.arrow_forward_rounded,
                onPressed: () => Navigator.of(context)
                    .pushReplacement(fadeRoute(const MainShell())),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
