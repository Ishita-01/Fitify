import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/page_transitions.dart';
import '../../../core/widgets/selectable_card.dart';
import '../../../data/models/onboarding_enums.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_scaffold.dart';
import 'intensity_screen.dart';

class WorkoutRecencyScreen extends StatelessWidget {
  const WorkoutRecencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<OnboardingProvider>();
    return OnboardingScaffold(
      step: 8,
      totalSteps: 11,
      title: 'When did you last work out?',
      canProceed: p.profile.lastWorkout != null,
      onNext: () =>
          Navigator.of(context).push(slideFadeRoute(const IntensityScreen())),
      child: Column(
        children: [
          for (final r in WorkoutRecency.values) ...[
            SelectableCard(
              label: r.label,
              icon: r.icon,
              selected: p.profile.lastWorkout == r,
              onTap: () => context.read<OnboardingProvider>().setLastWorkout(r),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
