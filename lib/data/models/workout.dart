import 'package:flutter/material.dart';

/// Workout library domain models. Pure data — no UI, no I/O. A backend
/// (FastAPI/Firebase) can later serialise these without UI changes.

enum WorkoutCategory {
  fullBody('Full Body', Icons.accessibility_new_rounded),
  weightLoss('Weight Loss', Icons.local_fire_department_rounded),
  muscleGain('Muscle Gain', Icons.fitness_center_rounded),
  strength('Strength', Icons.sports_mma_rounded),
  cardio('Cardio', Icons.directions_run_rounded),
  mobility('Mobility', Icons.accessibility_rounded),
  stretching('Stretching', Icons.self_improvement_rounded),
  beginner('Beginner', Icons.eco_rounded),
  intermediate('Intermediate', Icons.trending_up_rounded),
  advanced('Advanced', Icons.bolt_rounded);

  const WorkoutCategory(this.label, this.icon);
  final String label;
  final IconData icon;
}

enum Difficulty {
  beginner('Beginner'),
  intermediate('Intermediate'),
  advanced('Advanced');

  const Difficulty(this.label);
  final String label;
}

/// The primary region an exercise trains — lets the plan engine assemble
/// balanced sessions and honour splits (push/pull/legs etc).
enum MuscleGroup {
  fullBody('Full Body'),
  chest('Chest'),
  back('Back'),
  legs('Legs'),
  glutes('Glutes'),
  core('Core'),
  shoulders('Shoulders'),
  arms('Arms'),
  cardio('Cardio'),
  mobility('Mobility');

  const MuscleGroup(this.label);
  final String label;
}

/// How an exercise is performed — maps onto the user's preferred [Activity]
/// choices so the engine can bias selection toward what they enjoy.
enum ExerciseModality { strength, cardio, hiit, mobility, stretching, yoga, calisthenics }

/// A single exercise within a workout. [durationSec] drives a timed move;
/// [reps] drives a counted move (one of the two is used). [muscle] and
/// [modality] are metadata the plan engine reads (library seeds use defaults).
class Exercise {
  final String name;
  final String description;
  final int? durationSec;
  final int? reps;
  final IconData icon;
  final MuscleGroup muscle;
  final ExerciseModality modality;

  const Exercise({
    required this.name,
    required this.description,
    this.durationSec,
    this.reps,
    this.icon = Icons.fitness_center_rounded,
    this.muscle = MuscleGroup.fullBody,
    this.modality = ExerciseModality.strength,
  });

  Exercise copyWith({int? durationSec, int? reps}) => Exercise(
        name: name,
        description: description,
        durationSec: durationSec ?? this.durationSec,
        reps: reps ?? this.reps,
        icon: icon,
        muscle: muscle,
        modality: modality,
      );

  bool get isTimed => durationSec != null;

  /// Short label like "00:30" or "x 12".
  String get metaLabel {
    if (isTimed) {
      final m = (durationSec! ~/ 60).toString().padLeft(2, '0');
      final s = (durationSec! % 60).toString().padLeft(2, '0');
      return '$m:$s';
    }
    return 'x $reps';
  }
}

class Workout {
  final String id;
  final String title;
  final WorkoutCategory category;
  final Difficulty difficulty;
  final int minutes;
  final int calories;
  final List<Exercise> exercises;

  const Workout({
    required this.id,
    required this.title,
    required this.category,
    required this.difficulty,
    required this.minutes,
    required this.calories,
    required this.exercises,
  });

  int get exerciseCount => exercises.length;
}
