import 'workout.dart';

/// A single scheduled training day produced by the [PlanEngine].
class PlannedSession {
  final String id;
  final String title;
  final String focus; // e.g. "Full Body", "Push", "Legs & Core"
  final List<Exercise> exercises;
  final int restSeconds;
  final Difficulty difficulty;

  /// 1 = Monday … 7 = Sunday. Drives "today's session" selection.
  final int weekday;

  const PlannedSession({
    required this.id,
    required this.title,
    required this.focus,
    required this.exercises,
    required this.restSeconds,
    required this.difficulty,
    required this.weekday,
  });

  int get exerciseCount => exercises.length;

  /// Rough duration: per-exercise work + rest between moves.
  int get estMinutes {
    var seconds = 0;
    for (final e in exercises) {
      seconds += e.isTimed ? e.durationSec! : (e.reps ?? 12) * 3;
      seconds += restSeconds;
    }
    return (seconds / 60).ceil().clamp(5, 90);
  }

  /// Rough calorie estimate (~8 kcal/min bodyweight average).
  int get estCalories => (estMinutes * 8).round();

  WorkoutCategory get category => switch (focus) {
        'Push' || 'Pull' || 'Upper Body' => WorkoutCategory.muscleGain,
        'Legs' || 'Lower Body' => WorkoutCategory.strength,
        'Core & Cardio' => WorkoutCategory.cardio,
        _ => WorkoutCategory.fullBody,
      };

  /// Adapt to the [Workout] shape so existing detail/session screens render it
  /// unchanged.
  Workout asWorkout() => Workout(
        id: id,
        title: title,
        category: category,
        difficulty: difficulty,
        minutes: estMinutes,
        calories: estCalories,
        exercises: exercises,
      );
}

/// A week of personalised training. Deterministically derived from the user's
/// profile, so it can be regenerated rather than fully persisted.
class TrainingPlan {
  final int weekIndex; // 0-based weeks since the plan started
  final String splitName; // "Full Body", "Upper / Lower", "Push · Pull · Legs"
  final List<PlannedSession> sessions;

  const TrainingPlan({
    required this.weekIndex,
    required this.splitName,
    required this.sessions,
  });

  int get sessionsPerWeek => sessions.length;

  /// The session scheduled for [weekday] (1–7), or null on a rest day.
  PlannedSession? sessionForWeekday(int weekday) {
    for (final s in sessions) {
      if (s.weekday == weekday) return s;
    }
    return null;
  }

  /// Today's session if scheduled, else the next upcoming one this week, else
  /// the first session (so the UI always has something to show).
  PlannedSession sessionForToday(DateTime now) {
    final today = sessionForWeekday(now.weekday);
    if (today != null) return today;
    for (var d = now.weekday + 1; d <= 7; d++) {
      final s = sessionForWeekday(d);
      if (s != null) return s;
    }
    return sessions.first;
  }

  bool isTrainingDay(int weekday) => sessionForWeekday(weekday) != null;
}

/// Where a program day sits relative to today.
enum DayStatus { done, active, upcoming }

/// One day in the multi-week program timeline shown on Home (Day 1 … Day 28).
class ProgramDay {
  final int day; // 1-based day number across the whole program
  final PlannedSession session;
  final DayStatus status;

  const ProgramDay({
    required this.day,
    required this.session,
    required this.status,
  });
}

/// A block of program days (e.g. "Stage 1: Muscle Awakening — 7 days").
class ProgramStage {
  final int index; // 0-based
  final String name;
  final List<ProgramDay> days;

  const ProgramStage({
    required this.index,
    required this.name,
    required this.days,
  });

  int get total => days.length;
  int get doneCount => days.where((d) => d.status == DayStatus.done).length;
}
