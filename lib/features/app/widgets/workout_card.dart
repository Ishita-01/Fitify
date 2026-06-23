import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass.dart';
import '../../../data/models/workout.dart';
import '../screens/workout_detail_screen.dart';

/// Compact workout row used in Home (recommended) and the Workouts library.
class WorkoutCard extends StatelessWidget {
  const WorkoutCard({super.key, required this.workout});
  final Workout workout;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => WorkoutDetailScreen(workout: workout))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: GlassSurface(
          radius: 20,
          padding: const EdgeInsets.all(12),
          child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF3B82FF), Color(0xFF1B3A80)]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(workout.category.icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(workout.title,
                      style: AppTextStyles.title.copyWith(fontSize: 16)),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      _meta(Icons.schedule_rounded, '${workout.minutes} min'),
                      const SizedBox(width: 12),
                      _meta(Icons.bolt_rounded, workout.difficulty.label),
                      const SizedBox(width: 12),
                      _meta(Icons.local_fire_department_rounded,
                          '${workout.calories}'),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: AppColors.textTertiary),
          ],
          ),
        ),
      ),
    );
  }

  Widget _meta(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppColors.textTertiary),
        const SizedBox(width: 3),
        Text(label,
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textTertiary, fontSize: 12)),
      ],
    );
  }
}
