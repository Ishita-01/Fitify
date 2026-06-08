import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/workout.dart';
import '../../../data/repositories/workout_repository.dart';
import '../widgets/workout_card.dart';

class WorkoutsTab extends StatefulWidget {
  const WorkoutsTab({super.key});

  @override
  State<WorkoutsTab> createState() => _WorkoutsTabState();
}

class _WorkoutsTabState extends State<WorkoutsTab> {
  WorkoutCategory? _category; // null = All

  @override
  Widget build(BuildContext context) {
    final repo = context.read<WorkoutRepository>();
    final workouts =
        _category == null ? repo.all() : repo.byCategory(_category!);

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
                  Text('Workouts', style: AppTextStyles.display.copyWith(fontSize: 28)),
                  const SizedBox(height: 4),
                  Text('Guided training for every goal.',
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  const _SearchBar(),
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
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
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
            color: selected ? AppColors.accent : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: selected ? AppColors.accent : AppColors.border),
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
  const _SearchBar();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: AppColors.textTertiary),
          const SizedBox(width: 10),
          Text('Search workouts…',
              style: AppTextStyles.body.copyWith(color: AppColors.textTertiary)),
        ],
      ),
    );
  }
}
