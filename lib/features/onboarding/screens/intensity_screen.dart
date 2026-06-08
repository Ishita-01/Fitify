import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/page_transitions.dart';
import '../../../core/widgets/selectable_card.dart';
import '../../../data/models/onboarding_enums.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_scaffold.dart';
import 'activities_screen.dart';

class IntensityScreen extends StatelessWidget {
  const IntensityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<OnboardingProvider>();
    return OnboardingScaffold(
      step: 9,
      totalSteps: 11,
      title: 'How hard do you want to push?',
      subtitle: 'You can change this any time.',
      canProceed: p.profile.intensity != null,
      onNext: () =>
          Navigator.of(context).push(slideFadeRoute(const ActivitiesScreen())),
      child: Column(
        children: [
          for (final i in WorkoutIntensity.values) ...[
            SelectableCard(
              label: i.label,
              subtitle: i.subtitle,
              icon: i.icon,
              selected: p.profile.intensity == i,
              onTap: () => context.read<OnboardingProvider>().setIntensity(i),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
