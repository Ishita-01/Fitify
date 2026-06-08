import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/page_transitions.dart';
import '../../../data/models/onboarding_enums.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_scaffold.dart';
import '../../../core/widgets/selectable_card.dart';
import 'goal_screen.dart';

class GenderScreen extends StatelessWidget {
  const GenderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<OnboardingProvider>();
    return OnboardingScaffold(
      step: 1,
      totalSteps: 11,
      title: "What's your gender?",
      subtitle: 'This helps us tailor your plan and calorie targets.',
      canProceed: p.profile.gender != null,
      onNext: () =>
          Navigator.of(context).push(slideFadeRoute(const GoalScreen())),
      child: Column(
        children: [
          for (final g in Gender.values) ...[
            SelectableCard(
              label: g.label,
              icon: g.icon,
              selected: p.profile.gender == g,
              onTap: () => context.read<OnboardingProvider>().setGender(g),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
