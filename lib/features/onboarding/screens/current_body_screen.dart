import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/page_transitions.dart';
import '../../../core/widgets/selectable_card.dart';
import '../../../data/models/onboarding_enums.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_scaffold.dart';
import 'desired_body_screen.dart';

class CurrentBodyScreen extends StatelessWidget {
  const CurrentBodyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<OnboardingProvider>();
    return OnboardingScaffold(
      step: 3,
      totalSteps: 11,
      title: "What's your current body shape?",
      highlight: 'current',
      canProceed: p.profile.currentBodyShape != null,
      onNext: () =>
          Navigator.of(context).push(slideFadeRoute(const DesiredBodyScreen())),
      child: Column(
        children: [
          for (final shape in BodyShape.values) ...[
            SelectableCard(
              label: shape.label,
              icon: shape.icon,
              selected: p.profile.currentBodyShape == shape,
              onTap: () =>
                  context.read<OnboardingProvider>().setCurrentBodyShape(shape),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
