import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/page_transitions.dart';
import '../../../core/widgets/value_wheel_picker.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_scaffold.dart';
import 'target_weight_screen.dart';

class CurrentWeightScreen extends StatelessWidget {
  const CurrentWeightScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<OnboardingProvider>();
    return OnboardingScaffold(
      step: 6,
      totalSteps: 11,
      title: "What's your current weight?",
      highlight: 'current',
      onNext: () =>
          Navigator.of(context).push(slideFadeRoute(const TargetWeightScreen())),
      child: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: ValueWheelPicker(
          min: 30,
          max: 200,
          value: p.profile.currentWeightKg ?? 70,
          unit: 'kg',
          onChanged: (v) =>
              context.read<OnboardingProvider>().setCurrentWeight(v),
        ),
      ),
    );
  }
}
