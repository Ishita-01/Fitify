import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/page_transitions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/value_wheel_picker.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_scaffold.dart';
import 'workout_recency_screen.dart';

class TargetWeightScreen extends StatelessWidget {
  const TargetWeightScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<OnboardingProvider>();
    return OnboardingScaffold(
      step: 7,
      totalSteps: 11,
      title: "What's your target weight?",
      highlight: 'target',
      highlightColor: AppColors.onbGreen,
      onNext: () => Navigator.of(context)
          .push(slideFadeRoute(const WorkoutRecencyScreen())),
      child: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: ValueWheelPicker(
          min: 30,
          max: 200,
          value: p.profile.targetWeightKg ?? 65,
          unit: 'kg',
          onChanged: (v) =>
              context.read<OnboardingProvider>().setTargetWeight(v),
        ),
      ),
    );
  }
}
