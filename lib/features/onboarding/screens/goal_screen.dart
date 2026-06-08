import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/page_transitions.dart';
import '../../../core/widgets/selectable_card.dart';
import '../../../data/models/onboarding_enums.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_scaffold.dart';
import 'current_body_screen.dart';

class GoalScreen extends StatelessWidget {
  const GoalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<OnboardingProvider>();
    return OnboardingScaffold(
      step: 2,
      totalSteps: 11,
      title: 'What do you want most?',
      canProceed: p.profile.goals.isNotEmpty,
      onNext: () =>
          Navigator.of(context).push(slideFadeRoute(const CurrentBodyScreen())),
      child: Column(
        children: [
          for (final goal in FitnessGoal.values) ...[
            SelectableCard(
              label: goal.label,
              icon: goal.icon,
              trailingCheck: true,
              selected: p.isGoalSelected(goal),
              onTap: () => context.read<OnboardingProvider>().toggleGoal(goal),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
