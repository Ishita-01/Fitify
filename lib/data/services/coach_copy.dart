import '../models/onboarding_enums.dart';
import '../models/training_plan.dart';
import '../models/user_profile.dart';

/// Hand-written, human-voiced microcopy — deliberately NOT LLM-generated, so it
/// never reads like AI slop. Lines are picked from curated pools and lightly
/// personalised from the profile/plan. Varied by a rotating seed so the app
/// feels alive without sounding random.
class CoachCopy {
  CoachCopy._();

  static String _pick(List<String> pool, int seed) => pool[seed % pool.length];

  static int _daySeed() {
    final now = DateTime.now();
    return now.year * 366 + now.day * 13 + now.hour;
  }

  /// Big greeting line on Home, e.g. "Morning, Vish."
  static String greetingTitle(String name) {
    final h = DateTime.now().hour;
    final part = h < 12
        ? 'Morning'
        : h < 17
            ? 'Afternoon'
            : 'Evening';
    return '$part, $name';
  }

  /// Sub-line under the greeting — reflects the day's plan & goal.
  static String greetingSub(UserProfile p, TrainingPlan? plan) {
    final today = plan?.sessionForToday(DateTime.now());
    final isTrainingToday =
        plan != null && plan.isTrainingDay(DateTime.now().weekday);

    if (!isTrainingToday && plan != null) {
      return _pick(const [
        'Rest day. Recovery is where the work pays off.',
        'Active recovery today — move easy, breathe deep.',
        'No session scheduled. Let the muscles rebuild.',
      ], _daySeed());
    }

    final focus = today?.focus.toLowerCase();
    final goalLine = switch (_primaryGoal(p)) {
      FitnessGoal.loseWeight => [
          'Lean work today. Keep the rests short.',
          'Let\'s shed a little more — $focus is on deck.',
        ],
      FitnessGoal.buildMuscle => [
          'Time to build. $focus, full effort.',
          'Slow the reps down, own every $focus set.',
        ],
      _ => [
          'Today is ${focus ?? 'movement'}. Let\'s move well.',
          'Show up for $focus — your future self says thanks.',
        ],
    };
    return _pick(goalLine, _daySeed());
  }

  /// One-line nudge for the "Today's workout" card CTA area.
  static String sessionTeaser(PlannedSession s) => _pick(const [
        'Quick start — you\'ll be done before the kettle boils.',
        'Lock in. Press play and follow along.',
        'No equipment, no excuses. Let\'s go.',
        'One session closer. Start when ready.',
      ], s.title.length + _daySeed());

  /// Encouragement shown between exercises during a session.
  static String betweenExercises(int index, int total) {
    if (index == 0) {
      return _pick(const ['Ease in — warm those muscles up.', 'Here we go.'],
          _daySeed());
    }
    if (index >= total - 1) {
      return _pick(
          const ['Last one — empty the tank.', 'Finish strong. This is yours.'],
          _daySeed());
    }
    final pools = [
      'Halfway thoughts later — stay with this rep.',
      'Breathe. Control the movement.',
      'Looking strong. Keep the form tight.',
      'You\'ve got more than you think.',
    ];
    return _pick(pools, index + _daySeed());
  }

  /// Celebration when a session finishes.
  static String sessionComplete(int streak) {
    if (streak >= 2) {
      return _pick([
        '$streak in a row. That\'s a habit forming.',
        'Streak alive: $streak. Proud of you.',
      ], streak + _daySeed());
    }
    return _pick(const [
      'Done. That counts — every single one does.',
      'Session banked. Recover well.',
      'That\'s a win. See you next one.',
    ], _daySeed());
  }

  /// A rotating "coach tip" for the onboarding robot box / home.
  static String tip(UserProfile p) {
    final base = switch (_primaryGoal(p)) {
      FitnessGoal.loseWeight => const [
          'Fat loss is mostly the kitchen — training protects your muscle while you lean out.',
          'Short rests keep the heart rate up. That\'s the fat-burning sweet spot.',
        ],
      FitnessGoal.buildMuscle => const [
          'Muscle grows on rest days. Sleep is your secret weapon.',
          'Push close to failure on the last set — that\'s where growth lives.',
        ],
      _ => const [
          'Consistency beats intensity. Three honest sessions a week changes everything.',
          'Form first, speed second. Quality reps build a body that lasts.',
        ],
    };
    return _pick(base, _daySeed());
  }

  static FitnessGoal _primaryGoal(UserProfile p) =>
      p.goals.isNotEmpty ? p.goals.first : FitnessGoal.improveFitness;

  /// A compact factual brief about the user, fed to the LLM coach as system
  /// context so replies reference the real plan/goals (not generic advice).
  static String assistantBrief(UserProfile p, TrainingPlan? plan) {
    final lines = <String>['User profile:'];
    if (p.name?.trim().isNotEmpty ?? false) lines.add('- Name: ${p.name!.trim()}');
    if (p.gender != null) lines.add('- Gender: ${p.gender!.label}');
    if (p.goals.isNotEmpty) {
      lines.add('- Goals: ${p.goals.map((g) => g.label).join(', ')}');
    }
    if (p.heightCm != null) lines.add('- Height: ${p.heightCm} cm');
    if (p.currentWeightKg != null) {
      lines.add(
          '- Weight: ${p.currentWeightKg} kg, target ${p.targetWeightKg ?? p.currentWeightKg} kg');
    }
    if (p.intensity != null) lines.add('- Preferred intensity: ${p.intensity!.label}');
    if (p.activities.isNotEmpty) {
      lines.add('- Enjoys: ${p.activities.map((a) => a.label).join(', ')}');
    }
    if (plan != null) {
      lines.add(
          'Current plan: ${plan.splitName}, ${plan.sessionsPerWeek} sessions/week (week ${plan.weekIndex + 1}).');
      final today = plan.sessionForToday(DateTime.now());
      lines.add(
          "Today's session: ${today.title} — ${today.exercises.map((e) => e.name).join(', ')}.");
    }
    return lines.join('\n');
  }
}
