import 'package:flutter/material.dart';

import '../models/workout.dart';

/// Contract for fetching the workout library. Swap the in-memory impl for a
/// FastAPI/Firebase-backed one later without touching the UI.
abstract class WorkoutRepository {
  List<Workout> all();
  List<Workout> byCategory(WorkoutCategory category);
  Workout? byId(String id);
  Workout get featured;
}

class InMemoryWorkoutRepository implements WorkoutRepository {
  final List<Workout> _workouts = _seed();

  @override
  List<Workout> all() => _workouts;

  @override
  List<Workout> byCategory(WorkoutCategory category) =>
      _workouts.where((w) => w.category == category).toList();

  @override
  Workout? byId(String id) {
    for (final w in _workouts) {
      if (w.id == id) return w;
    }
    return null;
  }

  @override
  Workout get featured => _workouts.first;

  static List<Workout> _seed() {
    const ex = [
      Exercise(name: 'Jumping Jacks', description: 'Full-body cardio warm-up. Keep a steady rhythm.', durationSec: 30, icon: Icons.directions_run_rounded),
      Exercise(name: 'Bodyweight Squats', description: 'Sit back into your heels, chest up, knees tracking over toes.', reps: 15, icon: Icons.airline_seat_legroom_reduced_rounded),
      Exercise(name: 'Push-ups', description: 'Hands under shoulders, body in a straight line, lower with control.', reps: 12, icon: Icons.fitness_center_rounded),
      Exercise(name: 'Plank Hold', description: 'Forearms down, brace your core, keep a neutral spine.', durationSec: 45, icon: Icons.airline_seat_flat_rounded),
      Exercise(name: 'Lunges', description: 'Step forward, drop the back knee, push through the front heel.', reps: 20, icon: Icons.directions_walk_rounded),
      Exercise(name: 'Mountain Climbers', description: 'Drive knees to chest at pace, keep hips low.', durationSec: 30, icon: Icons.terrain_rounded),
      Exercise(name: 'Cool-down', description: 'Slow stretches to bring your heart rate down.', durationSec: 120, icon: Icons.self_improvement_rounded),
    ];

    Workout w(String id, String title, WorkoutCategory c, Difficulty d, int min, int kcal, List<Exercise> e) =>
        Workout(id: id, title: title, category: c, difficulty: d, minutes: min, calories: kcal, exercises: e);

    return [
      w('w1', 'Full Body Burn', WorkoutCategory.fullBody, Difficulty.intermediate, 20, 180, ex),
      w('w2', 'Fat Blast Cardio', WorkoutCategory.weightLoss, Difficulty.beginner, 15, 150, ex.sublist(0, 5)),
      w('w3', 'Lean Muscle Builder', WorkoutCategory.muscleGain, Difficulty.advanced, 30, 240, ex),
      w('w4', 'Core Strength', WorkoutCategory.strength, Difficulty.intermediate, 18, 160, ex.sublist(1, 6)),
      w('w5', 'Morning Mobility', WorkoutCategory.mobility, Difficulty.beginner, 12, 80, [ex.first, ex[3], ex.last]),
      w('w6', 'Deep Stretch', WorkoutCategory.stretching, Difficulty.beginner, 10, 60, [ex.first, ex.last]),
      w('w7', 'HIIT Cardio', WorkoutCategory.cardio, Difficulty.advanced, 22, 260, ex),
      w('w8', 'First Steps', WorkoutCategory.beginner, Difficulty.beginner, 12, 90, ex.sublist(0, 4)),
    ];
  }
}
