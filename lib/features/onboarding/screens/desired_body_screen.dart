import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/page_transitions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/selectable_card.dart';
import '../../../data/models/onboarding_enums.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_scaffold.dart';
import 'height_screen.dart';

class DesiredBodyScreen extends StatelessWidget {
  const DesiredBodyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<OnboardingProvider>();
    return OnboardingScaffold(
      step: 4,
      totalSteps: 11,
      title: "What's your desired body shape?",
      highlight: 'desired',
      highlightColor: AppColors.onbGreen,
      canProceed: p.profile.desiredBodyShape != null,
      onNext: () =>
          Navigator.of(context).push(slideFadeRoute(const HeightScreen())),
      child: Column(
        children: [
          for (final shape in DesiredShape.values) ...[
            SelectableCard(
              label: shape.label,
              icon: shape.icon,
              selected: p.profile.desiredBodyShape == shape,
              onTap: () =>
                  context.read<OnboardingProvider>().setDesiredBodyShape(shape),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
