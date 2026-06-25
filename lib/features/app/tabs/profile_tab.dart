import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass.dart';
import '../../../data/models/analysis.dart';
import '../../../data/models/training_plan.dart';
import '../../../data/models/onboarding_enums.dart';
import '../../onboarding/providers/onboarding_provider.dart';
import '../providers/analysis_provider.dart';
import '../providers/plan_provider.dart';
import '../providers/units_controller.dart';
import '../screens/analysis_report_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/history_calendar_screen.dart';
import '../widgets/app_widgets.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final onb = context.watch<OnboardingProvider>();
    final p = onb.profile;
    final name = (p.name?.trim().isNotEmpty ?? false) ? p.name!.trim() : 'Athlete';
    final reports = context.watch<AnalysisProvider>().completed;
    final plan = context.watch<PlanProvider>();
    final units = context.watch<UnitsController>();
    final current = p.currentWeightKg ?? 90;
    final target = p.targetWeightKg ?? 70;

    final double? heightM = p.heightCm != null ? p.heightCm! / 100.0 : null;
    final double? bmi = (heightM != null && heightM > 0 && p.currentWeightKg != null)
        ? p.currentWeightKg! / (heightM * heightM)
        : null;


    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
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
          // Identity & Plan/Goals Card.
          DarkCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top section: Name & Avatar & Edit.
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surfaceElevated,
                      ),
                      child: Icon(Icons.person_rounded,
                          size: 32, color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: AppTextStyles.heading.copyWith(fontSize: 20)),
                          const SizedBox(height: 2),
                          Text(
                            [
                              if (p.gender != null) p.gender!.label,
                              if (p.heightCm != null) units.height(p.heightCm!),
                            ].join(' · '),
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _editProfile(context, onb),
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
                const SizedBox(height: 16),
                Container(
                  height: 1,
                  color: AppColors.surfaceHighlight.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Plan Column (Left)
                    Expanded(
                      child: plan.plan != null
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.auto_awesome_rounded,
                                    color: AppColors.accent, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Plan: ${plan.plan!.splitName}',
                                        style: AppTextStyles.label.copyWith(fontSize: 14),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${plan.sessionsThisWeek} sessions/wk · Wk ${plan.weekIndex + 1}',
                                        style: AppTextStyles.caption.copyWith(
                                            color: AppColors.textSecondary, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'PLAN',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textTertiary,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'No active plan',
                                  style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textTertiary, fontSize: 11),
                                ),
                              ],
                            ),
                    ),
                    // Vertical Divider
                    const SizedBox(width: 12),
                    Container(
                      width: 1,
                      height: 44,
                      color: AppColors.surfaceHighlight.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 12),
                    // Goals Column (Right)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'GOALS',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textTertiary,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 6),
                          p.goals.isNotEmpty
                              ? Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: [
                                    for (final g in p.goals)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.accentMuted.withValues(alpha: 0.5),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(g.icon, size: 11, color: AppColors.accent),
                                            const SizedBox(width: 3),
                                            Text(
                                              g.label,
                                              style: AppTextStyles.caption.copyWith(
                                                color: AppColors.accent,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                )
                              : Text(
                                  'No goals selected',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textTertiary,
                                    fontSize: 11,
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Stats row.
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  value: '${plan.completedThisWeek}',
                  labelText: 'WORKOUTS',
                  icon: Icons.fitness_center_rounded,
                  iconColor: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  value: '${reports.length}',
                  labelText: 'ANALYSES',
                  icon: Icons.analytics_rounded,
                  iconColor: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  value: '${plan.sessionsThisWeek}',
                  labelText: 'WEEKLY GOAL',
                  icon: Icons.flag_rounded,
                  iconColor: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Achievements box.
          GestureDetector(
            onTap: () => _showAchievementsBottomSheet(context),
            child: DarkCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.emoji_events_rounded, color: AppColors.warning, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Achievements', style: AppTextStyles.label.copyWith(fontSize: 15)),
                        const SizedBox(height: 2),
                        Text(
                          '3 Badges Unlocked · Tap to view upcoming',
                          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary, size: 24),
                ],
              ),
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
                    _wCol('Current', units.weight(current), AppColors.textPrimary),
                    const Spacer(),
                    _wCol('Goal', units.weight(target), AppColors.accent),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: target < current ? (target / current).clamp(0, 1) : 1,
                    minHeight: 10,
                    backgroundColor: AppColors.surfaceHighlight,
                    valueColor: AlwaysStoppedAnimation(AppColors.accent),
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
          if (bmi != null) ...[
            const SizedBox(height: 24),
            Text('Body Mass Index (BMI)', style: AppTextStyles.heading),
            const SizedBox(height: 12),
            DarkCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        bmi.toStringAsFixed(1),
                        style: AppTextStyles.statValue.copyWith(
                          fontSize: 48,
                          color: _getBmiColor(bmi),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getBmiCategory(bmi),
                              style: AppTextStyles.title.copyWith(
                                color: _getBmiColor(bmi),
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _getBmiRange(bmi),
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _bmiBar(bmi),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _legendDot(const Color(0xFF3B82FF), 'Under'),
                      _legendDot(const Color(0xFF1FB271), 'Healthy'),
                      _legendDot(const Color(0xFFF5872A), 'Over'),
                      _legendDot(const Color(0xFFE5484D), 'Obese'),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          _HistorySectionCard(
            startDate: plan.startDate,
            program: plan.program,
            reports: reports,
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

  void _editProfile(BuildContext context, OnboardingProvider onb) {
    final nameController = TextEditingController(text: onb.profile.name ?? '');
    final heightController = TextEditingController(text: onb.profile.heightCm?.toString() ?? '');
    final weightController = TextEditingController(text: onb.profile.currentWeightKg?.toString() ?? '');
    final targetWeightController = TextEditingController(text: onb.profile.targetWeightKg?.toString() ?? '');

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Edit Profile', style: AppTextStyles.title),
        content: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  textCapitalization: TextCapitalization.words,
                  cursorColor: AppColors.accent,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.accent),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.surfaceHighlight),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: heightController,
                  keyboardType: TextInputType.number,
                  cursorColor: AppColors.accent,
                  decoration: InputDecoration(
                    labelText: 'Height (cm)',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    suffixText: 'cm',
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.accent),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.surfaceHighlight),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: weightController,
                  keyboardType: TextInputType.number,
                  cursorColor: AppColors.accent,
                  decoration: InputDecoration(
                    labelText: 'Current Weight (kg)',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    suffixText: 'kg',
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.accent),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.surfaceHighlight),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: targetWeightController,
                  keyboardType: TextInputType.number,
                  cursorColor: AppColors.accent,
                  decoration: InputDecoration(
                    labelText: 'Target Weight (kg)',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    suffixText: 'kg',
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.accent),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.surfaceHighlight),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Edit Goals', style: AppTextStyles.label.copyWith(fontSize: 14)),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final goal in FitnessGoal.values)
                      FilterChip(
                        label: Text(
                          goal.label,
                          style: TextStyle(
                            fontSize: 11,
                            color: onb.isGoalSelected(goal) ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                        selected: onb.isGoalSelected(goal),
                        selectedColor: AppColors.accent,
                        backgroundColor: AppColors.surfaceHighlight,
                        checkmarkColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.transparent),
                        ),
                        onSelected: (bool selected) {
                          setState(() {
                            onb.toggleGoal(goal);
                          });
                        },
                      ),
                  ],
                ),
              ],
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
                final name = nameController.text.trim();
                final height = int.tryParse(heightController.text);
                final currentWeight = int.tryParse(weightController.text);
                final targetWeight = int.tryParse(targetWeightController.text);

                if (name.isNotEmpty) {
                  onb.setName(name);
                }
                if (height != null) {
                  onb.setHeight(height);
                }
                if (currentWeight != null) {
                  onb.setCurrentWeight(currentWeight);
                }
                if (targetWeight != null) {
                  onb.setTargetWeight(targetWeight);
                }
                onb.finish(); // Persist changes to local storage
                Navigator.of(ctx).pop();
              },
              child: Text('Save',
                  style: AppTextStyles.label.copyWith(color: AppColors.accent))),
        ],
      ),
    );
  }

  Color _getBmiColor(double bmi) {
    if (bmi < 18.5) return const Color(0xFF3B82FF); // Blue
    if (bmi < 25.0) return AppColors.success;      // Green
    if (bmi < 30.0) return AppColors.warning;      // Orange
    return AppColors.danger;                       // Red
  }

  String _getBmiCategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25.0) return 'Healthy Weight';
    if (bmi < 30.0) return 'Overweight';
    return 'Obese';
  }

  String _getBmiRange(double bmi) {
    if (bmi < 18.5) return 'BMI < 18.5';
    if (bmi < 25.0) return 'BMI 18.5 – 24.9';
    if (bmi < 30.0) return 'BMI 25.0 – 29.9';
    return 'BMI ≥ 30.0';
  }

  Widget _legendDot(Color c, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: c,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppTextStyles.caption.copyWith(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _bmiBar(double bmi) {
    int activeIndex = 0;
    if (bmi < 18.5) {
      activeIndex = 0;
    } else if (bmi < 25.0) {
      activeIndex = 1;
    } else if (bmi < 30.0) {
      activeIndex = 2;
    } else {
      activeIndex = 3;
    }

    final segments = [
      (const Color(0xFF3B82FF), 'Underweight'),
      (const Color(0xFF1FB271), 'Healthy'),
      (const Color(0xFFF5872A), 'Overweight'),
      (const Color(0xFFE5484D), 'Obese'),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (int i = 0; i < 4; i++)
          Expanded(
            child: Container(
              height: i == activeIndex ? 8 : 5,
              margin: EdgeInsets.only(right: i == 3 ? 0 : 4),
              decoration: BoxDecoration(
                color: i == activeIndex
                    ? segments[i].$1
                    : segments[i].$1.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
      ],
    );
  }

  void _showAchievementsBottomSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHighlight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Badges & Achievements',
                style: AppTextStyles.heading.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 20),
              Text(
                'EARNED BADGES',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 12),
              _badgeRow(
                title: 'First Workout',
                description: 'Completed your very first active workout session.',
                icon: Icons.flag_rounded,
                iconColor: AppColors.accent,
                unlocked: true,
              ),
              const SizedBox(height: 12),
              _badgeRow(
                title: '5-Day Streak',
                description: 'Maintained a 5-day training streak this week.',
                icon: Icons.local_fire_department_rounded,
                iconColor: AppColors.warning,
                unlocked: true,
              ),
              const SizedBox(height: 12),
              _badgeRow(
                title: 'Form Master',
                description: 'Achieved a score of 90%+ on form analyses.',
                icon: Icons.verified_rounded,
                iconColor: AppColors.success,
                unlocked: true,
              ),
              const SizedBox(height: 24),
              Text(
                'UPCOMING BADGES',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 12),
              _badgeRow(
                title: '10-Day Streak',
                description: 'Maintain a 10-day training streak.',
                icon: Icons.local_fire_department_rounded,
                iconColor: AppColors.textTertiary,
                unlocked: false,
              ),
              const SizedBox(height: 12),
              _badgeRow(
                title: 'Elite Athlete',
                description: 'Complete a total of 20 workout sessions.',
                icon: Icons.emoji_events_rounded,
                iconColor: AppColors.textTertiary,
                unlocked: false,
              ),
              const SizedBox(height: 12),
              _badgeRow(
                title: 'Analysis Pro',
                description: 'Perform a total of 10 form analyses.',
                icon: Icons.analytics_rounded,
                iconColor: AppColors.textTertiary,
                unlocked: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badgeRow({
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required bool unlocked,
  }) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: unlocked ? iconColor.withValues(alpha: 0.12) : AppColors.surfaceHighlight.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: unlocked ? null : Border.all(color: AppColors.surfaceHighlight, width: 1),
          ),
          child: Icon(
            icon,
            color: unlocked ? iconColor : AppColors.textTertiary.withValues(alpha: 0.5),
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: AppTextStyles.label.copyWith(
                      fontSize: 14,
                      color: unlocked ? AppColors.textPrimary : AppColors.textSecondary,
                    ),
                  ),
                  if (!unlocked) ...[
                    const SizedBox(width: 6),
                    Icon(Icons.lock_outline_rounded, size: 12, color: AppColors.textTertiary),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: AppTextStyles.caption.copyWith(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.value,
    required this.labelText,
    required this.icon,
    required this.iconColor,
  });

  final String value;
  final String labelText;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return DarkCard(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(value, 
                textAlign: TextAlign.center, 
                style: AppTextStyles.statValue.copyWith(fontSize: 32)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: iconColor),
                const SizedBox(width: 4),
                Text(
                  labelText,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ],
        ),
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
        child: GlassSurface(
          radius: 18,
          padding: const EdgeInsets.all(14),
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
      ),
    );
  }
}

class _HistorySectionCard extends StatelessWidget {
  const _HistorySectionCard({
    required this.startDate,
    required this.program,
    required this.reports,
  });

  final DateTime startDate;
  final List<ProgramStage> program;
  final List<AnalysisReport> reports;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Sunday-first weekday offset calculation: Sunday (0) to Saturday (6)
    final sundayOffset = today.weekday % 7;
    final startOfWeek = today.subtract(Duration(days: sundayOffset));
    final weekDates = List.generate(7, (i) => startOfWeek.add(Duration(days: i)));

    final completedWorkoutDates = <DateTime>{};
    for (final stage in program) {
      for (final day in stage.days) {
        if (day.status == DayStatus.done) {
          final date = startDate.add(Duration(days: day.day - 1));
          completedWorkoutDates.add(DateTime(date.year, date.month, date.day));
        }
      }
    }

    final completedAnalysisDates = <DateTime>{};
    for (final r in reports) {
      completedAnalysisDates.add(DateTime(r.createdAt.year, r.createdAt.month, r.createdAt.day));
    }

    int streak = 0;
    DateTime checkDate = today;
    
    bool todayOrYesterdayComplete = completedWorkoutDates.contains(checkDate) || 
                                    completedAnalysisDates.contains(checkDate) ||
                                    completedWorkoutDates.contains(checkDate.subtract(const Duration(days: 1))) ||
                                    completedAnalysisDates.contains(checkDate.subtract(const Duration(days: 1)));
                                    
    if (todayOrYesterdayComplete) {
      if (!completedWorkoutDates.contains(checkDate) && !completedAnalysisDates.contains(checkDate)) {
        checkDate = checkDate.subtract(const Duration(days: 1));
      }
      while (completedWorkoutDates.contains(checkDate) || completedAnalysisDates.contains(checkDate)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      }
    }

    final weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'History',
              style: AppTextStyles.heading,
            ),
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => HistoryCalendarScreen(
                      startDate: startDate,
                      program: program,
                      reports: reports,
                    ),
                  ),
                );
              },
              child: Text(
                'All records',
                style: AppTextStyles.label.copyWith(
                  color: const Color(0xFF3B82FF),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DarkCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (index) {
                  final cellDate = weekDates[index];
                  final dayLabel = weekdays[index];
                  
                  final isToday = cellDate.year == today.year && cellDate.month == today.month && cellDate.day == today.day;
                  final isFuture = cellDate.isAfter(today);
                  final isWorkoutDone = completedWorkoutDates.contains(cellDate);
                  final isAnalysisDone = completedAnalysisDates.contains(cellDate);
                  final isDone = isWorkoutDone || isAnalysisDone;

                  Color textCol = AppColors.textPrimary;
                  Color? bg;
                  Border? border;

                  if (isDone) {
                    bg = isWorkoutDone ? AppColors.accent : AppColors.success;
                    textCol = Colors.white;
                  } else if (isToday) {
                    border = Border.all(color: AppColors.accent, width: 1.5);
                    textCol = AppColors.accent;
                  } else if (isFuture) {
                    textCol = AppColors.textTertiary.withValues(alpha: 0.5);
                  } else {
                    textCol = AppColors.textSecondary;
                  }

                  return Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          dayLabel,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textTertiary,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: bg,
                            border: border,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${cellDate.day}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isToday || isDone ? FontWeight.bold : FontWeight.normal,
                              color: textCol,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              Container(
                height: 1,
                color: AppColors.surfaceHighlight.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Day Streak',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 6),
                      Text(
                        '$streak',
                        style: AppTextStyles.statValue.copyWith(
                          fontSize: 18,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
