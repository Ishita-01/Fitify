import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass.dart';
import '../../../data/models/analysis.dart';
import '../../../data/models/workout.dart';
import '../../../data/repositories/workout_repository.dart';
import '../providers/analysis_provider.dart';
import '../providers/plan_provider.dart';
import '../screens/all_reports_screen.dart';
import '../screens/analysis_report_screen.dart';
import '../widgets/app_widgets.dart';
import '../widgets/charts.dart';
import '../widgets/workout_card.dart';

/// Discover: your progress, recent form analysis, recommendations, and the
/// browsable workout library. (Home is now purely the day-by-day plan.)
class WorkoutsTab extends StatefulWidget {
  const WorkoutsTab({super.key});

  @override
  State<WorkoutsTab> createState() => _WorkoutsTabState();
}

class _WorkoutsTabState extends State<WorkoutsTab> {
  WorkoutCategory? _category; // null = All
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<WorkoutRepository>();
    final plan = context.watch<PlanProvider>();
    final reports = context.watch<AnalysisProvider>().completed;
    final recommended = repo.all().skip(1).take(3).toList();

    final pct = (plan.weekProgress * 100).round();
    final todayIdx = DateTime.now().weekday - 1;
    final week = [
      for (var wd = 1; wd <= 7; wd++)
        (plan.plan?.isTrainingDay(wd) ?? false) ? 1.0 : 0.22
    ];

    var workouts = _category == null ? repo.all() : repo.byCategory(_category!);
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      workouts = workouts
          .where((w) =>
              w.title.toLowerCase().contains(q) ||
              w.category.label.toLowerCase().contains(q))
          .toList();
    }

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Discover',
                      style: AppTextStyles.display.copyWith(fontSize: 28)),
                  const SizedBox(height: 4),
                  Text('Your progress, insights and library.',
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 20),

                  // ---- This Week ----
                  Text('This Week', style: AppTextStyles.heading),
                  const SizedBox(height: 14),
                  LiquidPanel(
                    child: Row(
                      children: [
                        RingProgress(
                          value: plan.weekProgress.clamp(0.0, 1.0),
                          size: 92,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('$pct%',
                                  style: AppTextStyles.statValue
                                      .copyWith(fontSize: 22)),
                              Text('done',
                                  style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textTertiary)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            children: [
                              _ProgressStat(
                                  icon: Icons.check_circle_rounded,
                                  label: 'Workouts',
                                  value:
                                      '${plan.completedThisWeek} / ${plan.sessionsThisWeek}',
                                  color: AppColors.accent),
                              const SizedBox(height: 12),
                              _ProgressStat(
                                  icon: Icons.local_fire_department_rounded,
                                  label: 'Calories burned',
                                  value: '${plan.caloriesThisWeek} kcal',
                                  color: AppColors.warning),
                              const SizedBox(height: 12),
                              _ProgressStat(
                                  icon: Icons.timer_rounded,
                                  label: 'Active time',
                                  value: '${plan.activeMinutesThisWeek} min',
                                  color: AppColors.success),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  LiquidPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_today_rounded,
                                size: 16, color: AppColors.accent),
                            const SizedBox(width: 8),
                            Text('Weekly Activity',
                                style:
                                    AppTextStyles.title.copyWith(fontSize: 15)),
                            const Spacer(),
                            Text(
                                '${plan.completedThisWeek}/${plan.sessionsThisWeek} done',
                                style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textTertiary)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        WeeklyBars(values: week, todayIndex: todayIdx),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ---- Recent Analysis ----
                  SectionHeader(
                    title: 'Recent Analysis',
                    trailing: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const AllReportsScreen())),
                      child: Text('View all',
                          style: AppTextStyles.label
                              .copyWith(color: AppColors.accent)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (reports.isEmpty)
                    DarkCard(
                      child: Row(
                        children: [
                          Icon(Icons.insights_rounded,
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
                        itemBuilder: (context, i) =>
                            _ReportMini(report: reports[i]),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // ---- Recommended ----
                  Text('Recommended for You', style: AppTextStyles.heading),
                  const SizedBox(height: 14),
                  for (final w in recommended) WorkoutCard(workout: w),
                  const SizedBox(height: 12),

                  // ---- Library ----
                  Text('Explore Library', style: AppTextStyles.heading),
                  const SizedBox(height: 14),
                  _SearchBar(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _query = v),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 38,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _CatChip(
                            label: 'All',
                            icon: Icons.grid_view_rounded,
                            selected: _category == null,
                            onTap: () => setState(() => _category = null)),
                        for (final c in WorkoutCategory.values)
                          _CatChip(
                              label: c.label,
                              icon: c.icon,
                              selected: _category == c,
                              onTap: () => setState(() => _category = c)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                      '${workouts.length} ${workouts.length == 1 ? 'workout' : 'workouts'}',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textTertiary)),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          if (workouts.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                child: Column(
                  children: [
                    Icon(Icons.search_off_rounded,
                        size: 40, color: AppColors.textTertiary),
                    const SizedBox(height: 10),
                    Text('No workouts match your search',
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
              sliver: SliverList.builder(
                itemCount: workouts.length,
                itemBuilder: (context, i) => WorkoutCard(workout: workouts[i]),
              ),
            ),
        ],
      ),
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
      child: SizedBox(
        width: 150,
        child: GlassSurface(
          radius: 20,
          padding: const EdgeInsets.all(14),
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
                      fontSize: 34, color: _scoreColor(report.overallScore))),
              Text('Overall score',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textTertiary, fontSize: 11)),
            ],
          ),
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

class _CatChip extends StatelessWidget {
  const _CatChip(
      {required this.label,
      required this.icon,
      required this.selected,
      required this.onTap});
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.accent : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: selected ? AppColors.accent : AppColors.border),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.30),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Icon(icon,
                  size: 16,
                  color: selected ? Colors.white : AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(label,
                  style: AppTextStyles.label.copyWith(
                      color: selected ? Colors.white : AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      radius: 16,
      opacity: AppColors.isDark ? 0.12 : 0.45,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 46,
        child: Row(
          children: [
            Icon(Icons.search_rounded, color: AppColors.textTertiary),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
                cursorColor: AppColors.accent,
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: 'Search workouts…',
                  hintStyle: AppTextStyles.body
                      .copyWith(color: AppColors.textTertiary),
                ),
              ),
            ),
            if (controller.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  controller.clear();
                  onChanged('');
                },
                child: Icon(Icons.close_rounded,
                    size: 18, color: AppColors.textTertiary),
              ),
          ],
        ),
      ),
    );
  }
}
