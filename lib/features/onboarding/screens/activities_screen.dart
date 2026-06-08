import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/page_transitions.dart';
import '../../../core/widgets/selectable_chip.dart';
import '../../../data/models/onboarding_enums.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_scaffold.dart';
import 'name_screen.dart';

class ActivitiesScreen extends StatelessWidget {
  const ActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<OnboardingProvider>();
    return OnboardingScaffold(
      step: 10,
      totalSteps: 11,
      title: 'What activities do you enjoy?',
      canProceed: p.profile.activities.isNotEmpty,
      onNext: () =>
          Navigator.of(context).push(slideFadeRoute(const NameScreen())),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final a in Activity.values)
            SelectableChip(
              label: a.label,
              selected: p.isActivitySelected(a),
              onTap: () =>
                  context.read<OnboardingProvider>().toggleActivity(a),
            ),
        ],
      ),
    );
  }
}
