import 'package:flutter/material.dart';

import 'models/workout.dart';

/// A curated catalogue of bodyweight moves with metadata. The [PlanEngine]
/// selects from this by [MuscleGroup] and [ExerciseModality]; reps/duration
/// here are sensible base values that the engine scales per goal & week.
///
/// Pure data, no I/O — keeps the engine deterministic and offline.
class ExerciseCatalog {
  ExerciseCatalog._();

  static const List<Exercise> all = [
    // ---------------- Warm-up / cardio ----------------
    Exercise(
      name: 'Jumping Jacks',
      description: 'Full-body cardio warm-up. Keep a steady, springy rhythm.',
      durationSec: 40,
      icon: Icons.directions_run_rounded,
      muscle: MuscleGroup.cardio,
      modality: ExerciseModality.cardio,
    ),
    Exercise(
      name: 'High Knees',
      description: 'Drive knees up to hip height at pace, stay light on the feet.',
      durationSec: 30,
      icon: Icons.directions_run_rounded,
      muscle: MuscleGroup.cardio,
      modality: ExerciseModality.cardio,
    ),
    Exercise(
      name: 'Mountain Climbers',
      description: 'Drive knees to chest at pace, keep hips low and core braced.',
      durationSec: 30,
      icon: Icons.terrain_rounded,
      muscle: MuscleGroup.cardio,
      modality: ExerciseModality.hiit,
    ),
    Exercise(
      name: 'Burpees',
      description: 'Squat, kick back to a plank, hop in and jump. Full-body burner.',
      reps: 10,
      icon: Icons.local_fire_department_rounded,
      muscle: MuscleGroup.cardio,
      modality: ExerciseModality.hiit,
    ),
    Exercise(
      name: 'Butt Kicks',
      description: 'Jog in place, flicking heels to your glutes.',
      durationSec: 30,
      icon: Icons.directions_run_rounded,
      muscle: MuscleGroup.cardio,
      modality: ExerciseModality.cardio,
    ),

    // ---------------- Legs / glutes ----------------
    Exercise(
      name: 'Bodyweight Squats',
      description: 'Sit back into your heels, chest up, knees tracking over toes.',
      reps: 15,
      icon: Icons.airline_seat_legroom_reduced_rounded,
      muscle: MuscleGroup.legs,
      modality: ExerciseModality.strength,
    ),
    Exercise(
      name: 'Reverse Lunges',
      description: 'Step back, drop the rear knee, push through the front heel.',
      reps: 20,
      icon: Icons.directions_walk_rounded,
      muscle: MuscleGroup.legs,
      modality: ExerciseModality.strength,
    ),
    Exercise(
      name: 'Glute Bridges',
      description: 'Drive hips to the ceiling, squeeze glutes at the top.',
      reps: 18,
      icon: Icons.airline_seat_flat_angled_rounded,
      muscle: MuscleGroup.glutes,
      modality: ExerciseModality.strength,
    ),
    Exercise(
      name: 'Wall Sit',
      description: 'Back flat on the wall, thighs parallel, hold and breathe.',
      durationSec: 45,
      icon: Icons.event_seat_rounded,
      muscle: MuscleGroup.legs,
      modality: ExerciseModality.strength,
    ),
    Exercise(
      name: 'Calf Raises',
      description: 'Rise onto the balls of your feet, pause, lower with control.',
      reps: 20,
      icon: Icons.height_rounded,
      muscle: MuscleGroup.legs,
      modality: ExerciseModality.strength,
    ),
    Exercise(
      name: 'Jump Squats',
      description: 'Squat then explode up; land soft and reset.',
      reps: 12,
      icon: Icons.bolt_rounded,
      muscle: MuscleGroup.legs,
      modality: ExerciseModality.hiit,
    ),

    // ---------------- Chest / arms / shoulders (push) ----------------
    Exercise(
      name: 'Push-ups',
      description: 'Hands under shoulders, body in a line, lower with control.',
      reps: 12,
      icon: Icons.fitness_center_rounded,
      muscle: MuscleGroup.chest,
      modality: ExerciseModality.calisthenics,
    ),
    Exercise(
      name: 'Incline Push-ups',
      description: 'Hands on a raised surface — easier path to full push-ups.',
      reps: 14,
      icon: Icons.fitness_center_rounded,
      muscle: MuscleGroup.chest,
      modality: ExerciseModality.calisthenics,
    ),
    Exercise(
      name: 'Pike Push-ups',
      description: 'Hips high, lower the crown of your head — shoulder focus.',
      reps: 10,
      icon: Icons.change_history_rounded,
      muscle: MuscleGroup.shoulders,
      modality: ExerciseModality.calisthenics,
    ),
    Exercise(
      name: 'Triceps Dips',
      description: 'Hands on a chair edge, lower the elbows, press back up.',
      reps: 12,
      icon: Icons.chair_alt_rounded,
      muscle: MuscleGroup.arms,
      modality: ExerciseModality.calisthenics,
    ),

    // ---------------- Back (pull) ----------------
    Exercise(
      name: 'Superman Hold',
      description: 'Lie face-down, lift chest and legs, squeeze the lower back.',
      durationSec: 30,
      icon: Icons.flight_rounded,
      muscle: MuscleGroup.back,
      modality: ExerciseModality.strength,
    ),
    Exercise(
      name: 'Bird Dog',
      description: 'On all fours, extend opposite arm and leg; stay square.',
      reps: 16,
      icon: Icons.pets_rounded,
      muscle: MuscleGroup.back,
      modality: ExerciseModality.strength,
    ),
    Exercise(
      name: 'Reverse Snow Angels',
      description: 'Face-down, sweep arms from hips to overhead, squeezing the upper back.',
      reps: 16,
      icon: Icons.ac_unit_rounded,
      muscle: MuscleGroup.back,
      modality: ExerciseModality.strength,
    ),

    // ---------------- Core ----------------
    Exercise(
      name: 'Plank Hold',
      description: 'Forearms down, brace your core, keep a neutral spine.',
      durationSec: 45,
      icon: Icons.airline_seat_flat_rounded,
      muscle: MuscleGroup.core,
      modality: ExerciseModality.calisthenics,
    ),
    Exercise(
      name: 'Bicycle Crunches',
      description: 'Opposite elbow to knee, rotate through the core, slow and controlled.',
      reps: 24,
      icon: Icons.directions_bike_rounded,
      muscle: MuscleGroup.core,
      modality: ExerciseModality.strength,
    ),
    Exercise(
      name: 'Leg Raises',
      description: 'Lower the legs slowly without arching the lower back.',
      reps: 14,
      icon: Icons.swap_vert_rounded,
      muscle: MuscleGroup.core,
      modality: ExerciseModality.strength,
    ),
    Exercise(
      name: 'Russian Twists',
      description: 'Lean back, rotate side to side, heels light off the floor.',
      reps: 24,
      icon: Icons.sync_alt_rounded,
      muscle: MuscleGroup.core,
      modality: ExerciseModality.strength,
    ),
    Exercise(
      name: 'Side Plank',
      description: 'Stack the hips, brace the obliques, hold tall on one forearm.',
      durationSec: 30,
      icon: Icons.align_horizontal_left_rounded,
      muscle: MuscleGroup.core,
      modality: ExerciseModality.calisthenics,
    ),

    // ---------------- Mobility / stretching / yoga ----------------
    Exercise(
      name: 'Cat–Cow Flow',
      description: 'Alternate arching and rounding the spine with your breath.',
      durationSec: 40,
      icon: Icons.self_improvement_rounded,
      muscle: MuscleGroup.mobility,
      modality: ExerciseModality.mobility,
    ),
    Exercise(
      name: 'World\'s Greatest Stretch',
      description: 'Lunge, rotate, and open the chest — a full-body mobility reset.',
      durationSec: 40,
      icon: Icons.accessibility_new_rounded,
      muscle: MuscleGroup.mobility,
      modality: ExerciseModality.mobility,
    ),
    Exercise(
      name: 'Downward Dog',
      description: 'Press the hips up and back, lengthen hamstrings and spine.',
      durationSec: 40,
      icon: Icons.change_history_rounded,
      muscle: MuscleGroup.mobility,
      modality: ExerciseModality.yoga,
    ),
    Exercise(
      name: 'Child\'s Pose',
      description: 'Sink the hips back, relax the shoulders, breathe slow.',
      durationSec: 45,
      icon: Icons.spa_rounded,
      muscle: MuscleGroup.mobility,
      modality: ExerciseModality.stretching,
    ),
    Exercise(
      name: 'Standing Hamstring Stretch',
      description: 'Hinge at the hips, soft knees, let the back lengthen.',
      durationSec: 30,
      icon: Icons.straighten_rounded,
      muscle: MuscleGroup.mobility,
      modality: ExerciseModality.stretching,
    ),
    Exercise(
      name: 'Cool-down Breathing',
      description: 'Slow nasal breaths to bring the heart rate down. Well done.',
      durationSec: 60,
      icon: Icons.self_improvement_rounded,
      muscle: MuscleGroup.mobility,
      modality: ExerciseModality.stretching,
    ),
  ];

  static Iterable<Exercise> byMuscle(MuscleGroup m) =>
      all.where((e) => e.muscle == m);

  static Iterable<Exercise> byModality(ExerciseModality mod) =>
      all.where((e) => e.modality == mod);

  static Exercise byName(String name) =>
      all.firstWhere((e) => e.name == name, orElse: () => all.first);
}
