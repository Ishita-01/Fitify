import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/analysis.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../onboarding/providers/onboarding_provider.dart';
import '../providers/analysis_provider.dart';
import '../screens/analysis_report_screen.dart';
import '../screens/workout_detail_screen.dart';
import '../widgets/app_widgets.dart';
import '../widgets/charts.dart';
import '../widgets/workout_card.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<WorkoutRepository>();
    final name = context.watch<OnboardingProvider>().profile.name?.trim();
    final greeting = (name == null || name.isEmpty) ? 'Athlete' : name;
    final today = repo.featured;
    final recommended = repo.all().skip(1).take(3).toList();
    final reports = context.watch<AnalysisProvider>().completed;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hello, $greeting 👋',
                        style: AppTextStyles.display.copyWith(fontSize: 26)),
                    const SizedBox(height: 4),
                    Text("Let's crush today's session.",
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
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
                    Text('5',
                        style: AppTextStyles.label
                            .copyWith(color: AppColors.warning)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Today's workout (priority #1).
          GestureDetector(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => WorkoutDetailScreen(workout: today))),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82FF), Color(0xFF1B3A80)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("TODAY'S WORKOUT",
                      style: AppTextStyles.caption.copyWith(
                          color: Colors.white70,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6)),
                  const SizedBox(height: 8),
                  Text(today.title,
                      style: AppTextStyles.heading
                          .copyWith(color: Colors.white, fontSize: 24)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _wMeta(Icons.schedule_rounded, '${today.minutes} min'),
                      const SizedBox(width: 16),
                      _wMeta(Icons.local_fire_department_rounded,
                          '${today.calories} kcal'),
                      const SizedBox(width: 16),
                      _wMeta(Icons.format_list_numbered_rounded,
                          '${today.exerciseCount} moves'),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 11),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.play_arrow_rounded,
                            color: AppColors.accent, size: 20),
                        const SizedBox(width: 6),
                        Text('Quick Start',
                            style: AppTextStyles.button
                                .copyWith(color: AppColors.accent)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('This Week', style: AppTextStyles.heading),
          const SizedBox(height: 14),
          DarkCard(
            child: Row(
              children: [
                RingProgress(
                  value: 0.6,
                  size: 92,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('60%',
                          style: AppTextStyles.statValue.copyWith(fontSize: 20)),
                      Text('done',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textTertiary)),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    children: const [
                      _ProgressStat(
                          icon: Icons.check_circle_rounded,
                          label: 'Workouts',
                          value: '3 / 5',
                          color: AppColors.accent),
                      SizedBox(height: 12),
                      _ProgressStat(
                          icon: Icons.local_fire_department_rounded,
                          label: 'Calories burned',
                          value: '540 kcal',
                          color: AppColors.warning),
                      SizedBox(height: 12),
                      _ProgressStat(
                          icon: Icons.timer_rounded,
                          label: 'Active time',
                          value: '72 min',
                          color: AppColors.success),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SectionHeader(
            title: 'Recent Analysis',
            trailing: Text('View all',
                style: AppTextStyles.label.copyWith(color: AppColors.accent)),
          ),
          const SizedBox(height: 14),
          if (reports.isEmpty)
            DarkCard(
              child: Row(
                children: [
                  const Icon(Icons.insights_rounded,
                      color: AppColors.accent, size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'No reports yet. Upload a workout video in Analyze for a form breakdown.',
                      style: AppTextStyles.body.copyWith(
                          color: AppColors.textSecondary, fontSize: 14),
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 132,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: reports.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, i) => _ReportMini(report: reports[i]),
              ),
            ),
          const SizedBox(height: 24),
          Text('Recommended for You', style: AppTextStyles.heading),
          const SizedBox(height: 14),
          for (final w in recommended) WorkoutCard(workout: w),
        ],
      ),
    );
  }

  Widget _wMeta(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 15, color: Colors.white70),
        const SizedBox(width: 4),
        Text(label,
            style: AppTextStyles.caption.copyWith(color: Colors.white)),
      ],
    );
  }
}

class _ProgressStat extends StatelessWidget {
  const _ProgressStat(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
            child: Text(label,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary))),
        Text(value, style: AppTextStyles.label),
      ],
    );
  }
}

class _ReportMini extends StatelessWidget {
  const _ReportMini({required this.report});
  final AnalysisReport report;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => AnalysisReportScreen(report: report))),
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(report.exercise.icon, size: 18, color: AppColors.accent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(report.exercise.label,
                      style: AppTextStyles.label.copyWith(fontSize: 13),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            const Spacer(),
            Text('${report.overallScore}',
                style: AppTextStyles.display.copyWith(
                    fontSize: 34,
                    color: _scoreColor(report.overallScore))),
            Text('Overall score',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textTertiary, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

Color _scoreColor(int s) {
  if (s >= 85) return AppColors.success;
  if (s >= 70) return AppColors.warning;
  return AppColors.danger;
}
