import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass.dart';
import '../../../data/models/training_plan.dart';
import '../../../data/services/coach_copy.dart';
import '../../onboarding/providers/onboarding_provider.dart';
import '../providers/plan_provider.dart';
import '../screens/workout_detail_screen.dart';

/// Deterministic thumbnail gradients so each day reads distinctly (we have no
/// photo assets — a tinted tile + the focus icon stands in for the reference's
/// gym photos).
const _dayGradients = <List<Color>>[
  [Color(0xFF3B82FF), Color(0xFF1B3A80)],
  [Color(0xFF8B5CF6), Color(0xFF4C1D95)],
  [Color(0xFF10B981), Color(0xFF065F46)],
  [Color(0xFFF59E0B), Color(0xFF92400E)],
  [Color(0xFFEF4444), Color(0xFF7F1D1D)],
  [Color(0xFF06B6D4), Color(0xFF0E7490)],
  [Color(0xFFEC4899), Color(0xFF831843)],
];

/// Home is now purely the personalised day-by-day program (Day 1 … Day 28).
/// Completed days collapse into a per-stage summary so the timeline opens on the
/// active day. Progress charts / Recent Analysis / Recommended moved to Discover.
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<OnboardingProvider>().profile;
    final name = (profile.name?.trim().isNotEmpty ?? false)
        ? profile.name!.trim()
        : 'Athlete';
    final plan = context.watch<PlanProvider>();

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
          // ---- Greeting + streak ----
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(CoachCopy.greetingTitle(name),
                        style: AppTextStyles.display.copyWith(fontSize: 26)),
                    const SizedBox(height: 4),
                    Text(CoachCopy.greetingSub(profile, plan.plan),
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 15)),
                    const SizedBox(width: 5),
                    Text('${plan.completedThisWeek}',
                        style: AppTextStyles.label
                            .copyWith(color: AppColors.warning)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // ---- Program timeline ----
          if (plan.program.isEmpty)
            _NoPlan()
          else ...[
            _ProgramHeader(
                title: plan.programTitle,
                subtitle: plan.plan?.splitName ?? 'Personalized plan'),
            const SizedBox(height: 18),
            for (final stage in plan.program) _StageBlock(stage: stage),
          ],
        ],
      ),
    );
  }
}

class _NoPlan extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Icon(Icons.event_note_rounded,
              size: 44, color: AppColors.textTertiary),
          const SizedBox(height: 12),
          Text('Your plan is being prepared',
              style: AppTextStyles.title, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

/// Big program title + a tune/settings glyph, like the reference header.
class _ProgramHeader extends StatelessWidget {
  const _ProgramHeader({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final parts = title.split(' ');
    final lead = parts.first; // "28-Day"
    final rest = parts.skip(1).join(' ').toUpperCase();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(lead.toUpperCase(),
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.textTertiary,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(rest,
                  style: AppTextStyles.display
                      .copyWith(fontSize: 26, height: 1.05)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.accent)),
            ],
          ),
        ),
        Icon(Icons.tune_rounded, color: AppColors.textSecondary, size: 24),
      ],
    );
  }
}

/// "Stage N: Name" header + its day tiles. Completed days collapse behind a
/// tappable "N days completed" summary so the active day sits near the top.
class _StageBlock extends StatefulWidget {
  const _StageBlock({required this.stage});
  final ProgramStage stage;

  @override
  State<_StageBlock> createState() => _StageBlockState();
}

class _StageBlockState extends State<_StageBlock> {
  bool _showDone = false;

  @override
  Widget build(BuildContext context) {
    final stage = widget.stage;
    final done = stage.days.where((d) => d.status == DayStatus.done).toList();
    final rest = stage.days.where((d) => d.status != DayStatus.done).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 14),
          child: Row(
            children: [
              Expanded(
                child: Text('Stage ${stage.index + 1}: ${stage.name}',
                    style: AppTextStyles.title.copyWith(fontSize: 17)),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${stage.doneCount}/${stage.total}',
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.accent, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
        if (done.isNotEmpty) ...[
          _CompletedToggle(
            count: done.length,
            expanded: _showDone,
            onTap: () => setState(() => _showDone = !_showDone),
          ),
          if (_showDone)
            for (final d in done) _DayRow(day: d),
        ],
        for (final d in rest) _DayRow(day: d),
        const SizedBox(height: 6),
      ],
    );
  }
}

/// Collapsed "✓ N days completed" strip on the timeline rail.
class _CompletedToggle extends StatelessWidget {
  const _CompletedToggle(
      {required this.count, required this.expanded, required this.onTap});
  final int count;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 22,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.center,
                    child: Container(width: 2, color: AppColors.border),
                  ),
                ),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: onTap,
                child: GlassSurface(
                  radius: 16,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded,
                          size: 18, color: AppColors.accent),
                      const SizedBox(width: 10),
                      Text('$count ${count == 1 ? 'day' : 'days'} completed',
                          style: AppTextStyles.label
                              .copyWith(color: AppColors.textSecondary)),
                      const Spacer(),
                      Icon(
                          expanded
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          color: AppColors.textTertiary),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One timeline row: a rail (dot + connecting line) on the left, day card right.
class _DayRow extends StatelessWidget {
  const _DayRow({required this.day});
  final ProgramDay day;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Rail(status: day.status),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _DayCard(day: day),
            ),
          ),
        ],
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({required this.status});
  final DayStatus status;

  @override
  Widget build(BuildContext context) {
    final active = status == DayStatus.active;
    final done = status == DayStatus.done;
    final dotColor = active || done
        ? AppColors.accent
        : AppColors.textTertiary.withValues(alpha: 0.5);
    return SizedBox(
      width: 22,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned.fill(
            child: Align(
              alignment: Alignment.center,
              child: Container(width: 2, color: AppColors.border),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 30),
            child: Container(
              width: active ? 18 : 14,
              height: active ? 18 : 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done || active ? dotColor : AppColors.background,
                border: Border.all(color: dotColor, width: 2),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.5),
                          blurRadius: 8,
                        )
                      ]
                    : null,
              ),
              child: done
                  ? const Icon(Icons.check, size: 9, color: Colors.white)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// The day card. Active = vivid accent card with Start Now; others = black
/// glass card with a thumbnail + duration/calories.
class _DayCard extends StatelessWidget {
  const _DayCard({required this.day});
  final ProgramDay day;

  @override
  Widget build(BuildContext context) {
    final s = day.session;
    final grad = _dayGradients[(day.day - 1) % _dayGradients.length];
    final active = day.status == DayStatus.active;
    final upcoming = day.status == DayStatus.upcoming;

    if (active) {
      return GestureDetector(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => WorkoutDetailScreen(workout: s.asWorkout()))),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xCC3B82FF), Color(0xE61B3A80)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            border:
                Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.32),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('TODAY',
                        style: AppTextStyles.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            fontSize: 10)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Day ${day.day}',
                  style: AppTextStyles.display
                      .copyWith(color: Colors.white, fontSize: 34)),
              Text(s.title,
                  style: AppTextStyles.body
                      .copyWith(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _chip(Icons.schedule_rounded, '${s.estMinutes} mins'),
                  const SizedBox(width: 8),
                  _chip(Icons.local_fire_department_rounded,
                      '${s.estCalories} kcal'),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_arrow_rounded,
                        color: AppColors.accent, size: 20),
                    const SizedBox(width: 6),
                    Text('Start Now',
                        style: AppTextStyles.button
                            .copyWith(color: AppColors.accent)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Done / upcoming compact row.
    return Opacity(
      opacity: upcoming ? 0.72 : 1,
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => WorkoutDetailScreen(workout: s.asWorkout()))),
        child: GlassSurface(
          radius: 18,
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Day ${day.day}',
                        style: AppTextStyles.heading.copyWith(fontSize: 22)),
                    const SizedBox(height: 4),
                    Text('${s.estMinutes} mins   |   ${s.estCalories} kcal',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 76,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: grad,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(s.category.icon, color: Colors.white, size: 26),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 5),
          Text(label,
              style: AppTextStyles.caption
                  .copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
