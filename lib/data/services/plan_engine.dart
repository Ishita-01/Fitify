import '../exercise_catalog.dart';
import '../models/onboarding_enums.dart';
import '../models/training_plan.dart';
import '../models/user_profile.dart';
import '../models/workout.dart';

/// Builds a structured, personalised weekly training plan from a [UserProfile].
///
/// Deterministic and offline — NO LLM. This is how real apps program training:
/// profile → frequency → split → exercise selection → goal-tuned volume →
/// weekly progression. Same inputs always yield the same plan.
class PlanEngine {
  const PlanEngine();

  TrainingPlan generate(UserProfile p, {int week = 0}) {
    final days = _sessionsPerWeek(p);
    final split = _split(days);
    final difficulty = _difficulty(p);
    final weekdays = _scheduleDays(days);

    final sessions = <PlannedSession>[];
    for (var i = 0; i < split.length; i++) {
      final focus = split[i];
      sessions.add(_buildSession(
        p: p,
        week: week,
        index: i,
        focus: focus,
        weekday: weekdays[i],
        difficulty: difficulty,
      ));
    }

    return TrainingPlan(
      weekIndex: week,
      splitName: _splitName(days),
      sessions: sessions,
    );
  }

  // ---- Frequency: how many sessions a week ----
  int _sessionsPerWeek(UserProfile p) {
    var base = switch (p.intensity) {
      WorkoutIntensity.easyStart => 3,
      WorkoutIntensity.breakSweat => 4,
      WorkoutIntensity.challenging => 5,
      WorkoutIntensity.pushLimits => 6,
      null => 3,
    };
    // Ease in detrained users regardless of ambition.
    switch (p.lastWorkout) {
      case WorkoutRecency.never:
      case WorkoutRecency.moreThanSixMonths:
        base = base.clamp(3, 4);
      case WorkoutRecency.threeToSixMonths:
        base = base.clamp(3, 5);
      default:
        break;
    }
    return base.clamp(3, 6);
  }

  // ---- Split: focus per session, scaled to frequency ----
  List<String> _split(int days) {
    switch (days) {
      case 3:
        return const ['Full Body', 'Full Body', 'Full Body'];
      case 4:
        return const ['Upper Body', 'Lower Body', 'Upper Body', 'Lower Body'];
      case 5:
        return const ['Push', 'Pull', 'Legs', 'Full Body', 'Core & Cardio'];
      default: // 6
        return const ['Push', 'Pull', 'Legs', 'Push', 'Pull', 'Legs'];
    }
  }

  String _splitName(int days) => switch (days) {
        3 => 'Full Body',
        4 => 'Upper / Lower',
        5 => 'Push · Pull · Legs +',
        _ => 'Push · Pull · Legs',
      };

  /// Spread N sessions across the week (1=Mon … 7=Sun) with rest gaps.
  List<int> _scheduleDays(int days) => switch (days) {
        3 => const [1, 3, 5],
        4 => const [1, 2, 4, 5],
        5 => const [1, 2, 3, 5, 6],
        _ => const [1, 2, 3, 4, 5, 6],
      };

  Difficulty _difficulty(UserProfile p) {
    final detrained = p.lastWorkout == WorkoutRecency.never ||
        p.lastWorkout == WorkoutRecency.moreThanSixMonths;
    if (detrained) return Difficulty.beginner;
    if (p.intensity == WorkoutIntensity.pushLimits ||
        p.intensity == WorkoutIntensity.challenging) {
      return Difficulty.advanced;
    }
    return Difficulty.intermediate;
  }

  // ---- Build one session ----
  PlannedSession _buildSession({
    required UserProfile p,
    required int week,
    required int index,
    required String focus,
    required int weekday,
    required Difficulty difficulty,
  }) {
    final wantsFatLoss = p.goals.contains(FitnessGoal.loseWeight) ||
        p.goals.contains(FitnessGoal.improveFitness);
    final wantsMuscle = p.goals.contains(FitnessGoal.buildMuscle) ||
        p.desiredBodyShape == DesiredShape.muscular ||
        p.desiredBodyShape == DesiredShape.athletic;
    final likes = p.activities.map(_activityToModality).toSet();

    // Target regions for this session's focus.
    final regions = _regionsFor(focus);

    final picks = <Exercise>[];

    // 1) Warm-up — always one cardio/mobility opener.
    picks.add(_pickWarmup(likes));

    // 2) Main block — pull from the focus regions, biased by goal & preference.
    final mainCount = wantsMuscle ? 5 : 4;
    picks.addAll(_pickMain(
      regions: regions,
      count: mainCount,
      likes: likes,
      preferCardio: wantsFatLoss,
      rotate: week + index, // vary selection across weeks/sessions
    ));

    // 3) Finisher — a HIIT/cardio burst for fat-loss goals.
    if (wantsFatLoss) {
      picks.add(_pickFinisher(likes, week + index));
    }

    // 4) Cool-down — a stretch/mobility close.
    picks.add(_pickCooldown(likes, week + index));

    // De-dupe while preserving order, then tune volume.
    final unique = <Exercise>[];
    final seen = <String>{};
    for (final e in picks) {
      if (seen.add(e.name)) unique.add(e);
    }
    final tuned = unique
        .map((e) => _tune(e, wantsMuscle: wantsMuscle, week: week))
        .toList();

    return PlannedSession(
      id: 'w${week}_s$index',
      title: '$focus Session',
      focus: focus,
      exercises: tuned,
      restSeconds: wantsFatLoss ? 20 : (wantsMuscle ? 60 : 40),
      difficulty: difficulty,
      weekday: weekday,
    );
  }

  List<MuscleGroup> _regionsFor(String focus) => switch (focus) {
        'Push' => const [MuscleGroup.chest, MuscleGroup.shoulders, MuscleGroup.arms],
        'Pull' => const [MuscleGroup.back, MuscleGroup.core],
        'Legs' => const [MuscleGroup.legs, MuscleGroup.glutes],
        'Upper Body' => const [
            MuscleGroup.chest,
            MuscleGroup.back,
            MuscleGroup.shoulders,
            MuscleGroup.arms,
          ],
        'Lower Body' => const [MuscleGroup.legs, MuscleGroup.glutes, MuscleGroup.core],
        'Core & Cardio' => const [MuscleGroup.core, MuscleGroup.cardio],
        _ => const [
            MuscleGroup.legs,
            MuscleGroup.chest,
            MuscleGroup.back,
            MuscleGroup.core,
          ],
      };

  ExerciseModality _activityToModality(Activity a) => switch (a) {
        Activity.homeFitness => ExerciseModality.strength,
        Activity.calisthenics => ExerciseModality.calisthenics,
        Activity.stretching => ExerciseModality.stretching,
        Activity.running => ExerciseModality.cardio,
        Activity.yoga => ExerciseModality.yoga,
        Activity.hiit => ExerciseModality.hiit,
        Activity.mobility => ExerciseModality.mobility,
      };

  Exercise _pickWarmup(Set<ExerciseModality> likes) {
    final cardio = ExerciseCatalog.byMuscle(MuscleGroup.cardio).toList();
    cardio.sort((a, b) => _affinity(b, likes).compareTo(_affinity(a, likes)));
    return cardio.first;
  }

  List<Exercise> _pickMain({
    required List<MuscleGroup> regions,
    required int count,
    required Set<ExerciseModality> likes,
    required bool preferCardio,
    required int rotate,
  }) {
    // Gather candidates region by region so the session stays balanced.
    final result = <Exercise>[];
    var r = 0;
    var guard = 0;
    while (result.length < count && guard < count * 4) {
      final region = regions[r % regions.length];
      final pool = ExerciseCatalog.byMuscle(region)
          .where((e) => e.modality != ExerciseModality.stretching)
          .toList();
      if (pool.isNotEmpty) {
        pool.sort((a, b) => _affinity(b, likes).compareTo(_affinity(a, likes)));
        // Rotate the entry point so weeks/sessions don't repeat identically.
        final pick = pool[(rotate + r) % pool.length];
        if (!result.any((e) => e.name == pick.name)) result.add(pick);
      }
      r++;
      guard++;
    }
    return result;
  }

  Exercise _pickFinisher(Set<ExerciseModality> likes, int rotate) {
    final pool = ExerciseCatalog.byModality(ExerciseModality.hiit).toList();
    if (pool.isEmpty) return ExerciseCatalog.byName('Mountain Climbers');
    return pool[rotate % pool.length];
  }

  Exercise _pickCooldown(Set<ExerciseModality> likes, int rotate) {
    final wantsYoga = likes.contains(ExerciseModality.yoga);
    final pool = ExerciseCatalog.all
        .where((e) =>
            e.modality == ExerciseModality.stretching ||
            (wantsYoga && e.modality == ExerciseModality.yoga))
        .toList();
    if (pool.isEmpty) return ExerciseCatalog.byName('Cool-down Breathing');
    return pool[rotate % pool.length];
  }

  /// Higher score = better fit for the user's preferred modalities.
  int _affinity(Exercise e, Set<ExerciseModality> likes) =>
      likes.contains(e.modality) ? 1 : 0;

  /// Scale reps/duration for the goal and progress over weeks.
  Exercise _tune(Exercise e, {required bool wantsMuscle, required int week}) {
    final progression = 1 + week * 0.1; // +10% volume per week
    if (e.isTimed) {
      final base = e.durationSec!;
      final scaled = (base * progression).round();
      return e.copyWith(durationSec: scaled.clamp(20, 120));
    }
    final base = e.reps ?? 12;
    // Hypertrophy stays in the 8–12 zone; endurance/fat-loss pushes reps up.
    final goalAdj = wantsMuscle ? 0.9 : 1.15;
    final scaled = (base * goalAdj * progression).round();
    return e.copyWith(reps: scaled.clamp(6, 30));
  }
}
