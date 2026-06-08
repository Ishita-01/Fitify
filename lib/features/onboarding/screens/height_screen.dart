import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/page_transitions.dart';
import '../../../core/widgets/value_wheel_picker.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_scaffold.dart';
import 'current_weight_screen.dart';

class HeightScreen extends StatelessWidget {
  const HeightScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<OnboardingProvider>();
    return OnboardingScaffold(
      step: 5,
      totalSteps: 11,
      title: 'How tall are you?',
      subtitle: 'We use this to calculate your targets.',
      onNext: () =>
          Navigator.of(context).push(slideFadeRoute(const CurrentWeightScreen())),
      child: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: ValueWheelPicker(
          min: 120,
          max: 220,
          value: p.profile.heightCm ?? 170,
          unit: 'cm',
          onChanged: (v) => context.read<OnboardingProvider>().setHeight(v),
        ),
      ),
    );
  }
}
