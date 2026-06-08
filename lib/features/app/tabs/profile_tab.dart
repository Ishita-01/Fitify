import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/analysis.dart';
import '../../onboarding/providers/onboarding_provider.dart';
import '../providers/analysis_provider.dart';
import '../screens/analysis_report_screen.dart';
import '../screens/settings_screen.dart';
import '../widgets/app_widgets.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final onb = context.watch<OnboardingProvider>();
    final p = onb.profile;
    final name = (p.name?.trim().isNotEmpty ?? false) ? p.name!.trim() : 'Athlete';
    final reports = context.watch<AnalysisProvider>().completed;
    final current = p.currentWeightKg ?? 90;
    final target = p.targetWeightKg ?? 70;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Row(
            children: [
              Text('Profile', style: AppTextStyles.display.copyWith(fontSize: 28)),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen())),
                child: const Icon(Icons.settings_outlined, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Identity card.
          DarkCard(
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: AppColors.surfaceElevated),
                  child: const Icon(Icons.person_rounded,
                      size: 36, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: AppTextStyles.heading.copyWith(fontSize: 20)),
                      const SizedBox(height: 2),
                      Text(
                          [
                            if (p.gender != null) p.gender!.label,
                            if (p.heightCm != null) '${p.heightCm} cm',
                          ].join(' · '),
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _editName(context, onb),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.accentMuted,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('Edit',
                        style: AppTextStyles.label
                            .copyWith(color: AppColors.accent)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Stats row.
          Row(
            children: [
              Expanded(child: _StatTile(value: '12', label: 'Workouts')),
              const SizedBox(width: 12),
              Expanded(child: _StatTile(value: '${reports.length}', label: 'Analyses')),
              const SizedBox(width: 12),
              Expanded(child: _StatTile(value: '5', label: 'Day streak')),
            ],
          ),
          const SizedBox(height: 24),
          Text('Fitness Goals', style: AppTextStyles.heading),
          const SizedBox(height: 12),
          DarkCard(
            child: p.goals.isEmpty
                ? Text('No goals set yet.',
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.textTertiary))
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final g in p.goals)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.accentMuted,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(g.icon, size: 15, color: AppColors.accent),
                              const SizedBox(width: 6),
                              Text(g.label,
                                  style: AppTextStyles.caption
                                      .copyWith(color: AppColors.accent)),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 24),
          Text('Weight Progress', style: AppTextStyles.heading),
          const SizedBox(height: 12),
          DarkCard(
            child: Column(
              children: [
                Row(
                  children: [
                    _wCol('Current', '$current kg', AppColors.textPrimary),
                    const Spacer(),
                    _wCol('Goal', '$target kg', AppColors.accent),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: target < current ? (target / current).clamp(0, 1) : 1,
                    minHeight: 10,
                    backgroundColor: AppColors.surfaceHighlight,
                    valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                      '${(current - target).abs()} kg to go',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Achievements', style: AppTextStyles.heading),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final a in const [
                ('First Workout', Icons.flag_rounded, AppColors.accent),
                ('5-Day Streak', Icons.local_fire_department_rounded, AppColors.warning),
                ('Form Master', Icons.verified_rounded, AppColors.success),
              ])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        Container(
                          height: 64,
                          decoration: BoxDecoration(
                            color: (a.$3).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(a.$2, color: a.$3, size: 30),
                        ),
                        const SizedBox(height: 6),
                        Text(a.$1,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.caption.copyWith(fontSize: 11)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Analysis History', style: AppTextStyles.heading),
          const SizedBox(height: 12),
          if (reports.isEmpty)
            DarkCard(
              child: Text('No analyses yet — upload a video in Analyze.',
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.textTertiary)),
            )
          else
            for (final r in reports) _HistoryRow(report: r),
        ],
      ),
    );
  }

  Widget _wCol(String label, String value, Color c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary)),
        Text(value, style: AppTextStyles.statValue.copyWith(color: c)),
      ],
    );
  }

  void _editName(BuildContext context, OnboardingProvider onb) {
    final controller = TextEditingController(text: onb.profile.name ?? '');
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Edit name', style: AppTextStyles.title),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          cursorColor: AppColors.accent,
          decoration: InputDecoration(
            hintText: 'Your name',
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.accent),
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Cancel',
                  style: AppTextStyles.label
                      .copyWith(color: AppColors.textSecondary))),
          TextButton(
              onPressed: () {
                onb.setName(controller.text.trim());
                Navigator.of(ctx).pop();
              },
              child: Text('Save',
                  style: AppTextStyles.label.copyWith(color: AppColors.accent))),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label});
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) {
    return DarkCard(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Text(value, style: AppTextStyles.statValue),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textTertiary, fontSize: 11)),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.report});
  final AnalysisReport report;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => AnalysisReportScreen(report: report))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.accentMuted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(report.exercise.icon, color: AppColors.accent),
            ),
            const SizedBox(width: 14),
            Expanded(
                child: Text(report.exercise.label,
                    style: AppTextStyles.title.copyWith(fontSize: 15.5))),
            Text('${report.overallScore}',
                style: AppTextStyles.statValue.copyWith(
                    color: report.overallScore >= 85
                        ? AppColors.success
                        : report.overallScore >= 70
                            ? AppColors.warning
                            : AppColors.danger)),
          ],
        ),
      ),
    );
  }
}
