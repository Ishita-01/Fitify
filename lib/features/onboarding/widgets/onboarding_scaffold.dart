import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/primary_button.dart';
import 'robot_tip.dart';

/// Shared layout for every onboarding question (light theme): segmented
/// progress + back chevron, big heading with an optional coloured keyword,
/// an optional robot "tip" box, scrollable content, and a pinned black CTA.
class OnboardingScaffold extends StatelessWidget {
  const OnboardingScaffold({
    super.key,
    required this.step,
    required this.totalSteps,
    required this.title,
    required this.child,
    required this.onNext,
    this.subtitle,
    this.highlight,
    this.highlightColor,
    this.buttonLabel = 'Next',
    this.canProceed = true,
    this.centerContent = false,
  });

  final int step; // 1-based
  final int totalSteps;
  final String title;

  /// When present, rendered as a robot "tip" box under the heading.
  final String? subtitle;

  /// A word/phrase inside [title] to colour with [highlightColor].
  final String? highlight;
  final Color? highlightColor;

  final Widget child;
  final VoidCallback onNext;
  final String buttonLabel;
  final bool canProceed;
  final bool centerContent;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      backgroundColor: AppColors.onbBackground,
      body: AmbientBackground(
        child: Stack(
        children: [
          const _SlashDecoration(),
          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (canPop)
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          behavior: HitTestBehavior.opaque,
                          child: const Padding(
                            padding: EdgeInsets.only(right: 16, top: 4, bottom: 4),
                            child: Icon(Icons.arrow_back_ios_new_rounded,
                                size: 22, color: AppColors.onbTextDark),
                          ),
                        )
                      else
                        const SizedBox(width: 8),
                      Expanded(child: _SegmentedProgress(value: step / totalSteps)),
                      const SizedBox(width: 8),
                    ],
                  ),
                  const SizedBox(height: 26),
                  _Heading(
                    title: title,
                    highlight: highlight,
                    highlightColor: highlightColor ?? AppColors.onbPrimary,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 18),
                    RobotTip(text: subtitle!),
                  ],
                  const SizedBox(height: 22),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: centerContent
                          ? Center(child: child)
                          : child,
                    ),
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: buttonLabel,
                    dark: true,
                    enabled: canProceed,
                    onPressed: canProceed ? onNext : null,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({
    required this.title,
    required this.highlight,
    required this.highlightColor,
  });
  final String title;
  final String? highlight;
  final Color highlightColor;

  @override
  Widget build(BuildContext context) {
    final base = AppTextStyles.display
        .copyWith(fontSize: 30, color: AppColors.onbTextDark, height: 1.18);
    if (highlight == null || !title.contains(highlight!)) {
      return Text(title, style: base);
    }
    final parts = title.split(highlight!);
    return RichText(
      text: TextSpan(
        style: base,
        children: [
          TextSpan(text: parts[0]),
          TextSpan(text: highlight, style: base.copyWith(color: highlightColor)),
          if (parts.length > 1) TextSpan(text: parts.sublist(1).join(highlight!)),
        ],
      ),
    );
  }
}

/// Three rounded segments that fill left-to-right with progress.
class _SegmentedProgress extends StatelessWidget {
  const _SegmentedProgress({required this.value});
  final double value;

  @override
  Widget build(BuildContext context) {
    const segments = 3;
    return Row(
      children: List.generate(segments, (i) {
        final fill = (value * segments - i).clamp(0.0, 1.0);
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == segments - 1 ? 0 : 6),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: fill),
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOut,
                builder: (context, v, _) => LinearProgressIndicator(
                  value: v,
                  minHeight: 5,
                  backgroundColor: AppColors.onbTrack,
                  valueColor:
                      const AlwaysStoppedAnimation(AppColors.onbPrimary),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// Faint diagonal "//" stripes in the top-left, behind the heading.
class _SlashDecoration extends StatelessWidget {
  const _SlashDecoration();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 70,
      left: -10,
      child: Transform.rotate(
        angle: 0.32,
        child: Row(
          children: List.generate(
            2,
            (i) => Container(
              width: 14,
              height: 150,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: AppColors.onbPrimary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
