import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/page_transitions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_scaffold.dart';
import 'completion_screen.dart';

class NameScreen extends StatefulWidget {
  const NameScreen({super.key});

  @override
  State<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends State<NameScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: context.read<OnboardingProvider>().profile.name ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<OnboardingProvider>();
    final name = p.profile.name?.trim() ?? '';
    return OnboardingScaffold(
      step: 11,
      totalSteps: 11,
      title: 'What should we call you?',
      subtitle: 'Last step — let’s personalize your experience.',
      buttonLabel: 'Create My Plan',
      canProceed: name.isNotEmpty,
      onNext: () async {
        await context.read<OnboardingProvider>().finish();
        if (!context.mounted) return;
        Navigator.of(context)
            .pushReplacement(fadeRoute(const CompletionScreen()));
      },
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: TextField(
          controller: _controller,
          onChanged: (v) => context.read<OnboardingProvider>().setName(v),
          textCapitalization: TextCapitalization.words,
          style: AppTextStyles.title.copyWith(color: AppColors.onbTextDark),
          cursorColor: AppColors.onbPrimary,
          decoration: InputDecoration(
            hintText: 'Your name',
            hintStyle:
                AppTextStyles.body.copyWith(color: AppColors.onbTextGrey),
            filled: true,
            fillColor: AppColors.onbCard,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.card),
              borderSide: const BorderSide(color: AppColors.onbBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.card),
              borderSide: const BorderSide(color: AppColors.onbBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.card),
              borderSide: const BorderSide(color: AppColors.onbPrimary, width: 2),
            ),
          ),
        ),
      ),
    );
  }
}
