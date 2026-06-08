import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/workout.dart';
import '../widgets/app_widgets.dart';
import 'workout_session_screen.dart';

/// Overview of a workout: hero, meta chips, description and the exercise list,
/// with a pinned "Start Workout" CTA into the guided session (no camera).
class WorkoutDetailScreen extends StatelessWidget {
  const WorkoutDetailScreen({super.key, required this.workout});
  final Workout workout;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  Row(
                    children: [
                      _CircleButton(
                          icon: Icons.arrow_back_ios_new_rounded,
                          onTap: () => Navigator.of(context).pop()),
                      const Spacer(),
                      _CircleButton(
                          icon: Icons.favorite_border_rounded, onTap: () {}),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 180,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82FF), Color(0xFF1B3A80)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Center(
                      child: Icon(workout.category.icon,
                          color: Colors.white, size: 64),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(workout.title,
                      style: AppTextStyles.display.copyWith(fontSize: 26)),
                  const SizedBox(height: 6),
                  Text(workout.category.label,
                      style: AppTextStyles.label
                          .copyWith(color: AppColors.accent)),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _MetaChip(icon: Icons.schedule_rounded, label: '${workout.minutes} min'),
                      _MetaChip(icon: Icons.bolt_rounded, label: workout.difficulty.label),
                      _MetaChip(icon: Icons.local_fire_department_rounded, label: '${workout.calories} kcal'),
                      _MetaChip(icon: Icons.format_list_numbered_rounded, label: '${workout.exerciseCount} moves'),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text('Overview', style: AppTextStyles.title),
                  const SizedBox(height: 8),
                  Text(
                    'A guided ${workout.difficulty.label.toLowerCase()} ${workout.category.label.toLowerCase()} '
                    'session. Follow the on-screen coach through each move at your own pace — '
                    'record a set anytime and upload it in Analyze for a detailed form report.',
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.textSecondary, fontSize: 14.5),
                  ),
                  const SizedBox(height: 22),
                  Text('Exercises', style: AppTextStyles.title),
                  const SizedBox(height: 12),
                  for (var i = 0; i < workout.exercises.length; i++) ...[
                    _ExerciseRow(index: i + 1, exercise: workout.exercises[i]),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: GradientButton(
                label: 'Start Workout',
                icon: Icons.play_arrow_rounded,
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => WorkoutSessionScreen(workout: workout))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.accent),
          const SizedBox(width: 6),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({required this.index, required this.exercise});
  final int index;
  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    return DarkCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      radius: 16,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.accentMuted,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(exercise.icon, color: AppColors.accent, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(exercise.name,
                style: AppTextStyles.title.copyWith(fontSize: 15.5)),
          ),
          Text(exercise.metaLabel,
              style: AppTextStyles.label.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 18, color: AppColors.textPrimary),
      ),
    );
  }
}
