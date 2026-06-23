import 'package:flutter/foundation.dart';

import '../../../data/models/onboarding_enums.dart';
import '../../../data/models/training_plan.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/services/local_storage_service.dart';
import '../../../data/services/plan_engine.dart';

/// Owns the user's personalised [TrainingPlan]. The plan is regenerated
/// deterministically from the profile via [PlanEngine]; only progress
/// (start date + completed session ids) is persisted.
class PlanProvider extends ChangeNotifier {
  PlanProvider(this._storage, {PlanEngine engine = const PlanEngine()})
      : _engine = engine {
    _restore();
  }

  final LocalStorageService _storage;
  final PlanEngine _engine;

  UserProfile? _profile;
  TrainingPlan? _plan;
  DateTime _startDate = DateTime.now();
  final Set<String> _completedIds = {};
  bool _restored = false;

  TrainingPlan? get plan => _plan;
  bool get hasPlan => _plan != null;

  // ---- 28-day program timeline (Home) ----
  static const int kProgramDays = 28;
  static const int kDaysPerStage = 7;

  List<ProgramStage> _program = const [];
  List<ProgramStage> get program => _program;

  /// Today's day number in the program (1-based, clamped to the program length).
  int get currentDay {
    final elapsed = DateTime.now().difference(_startDate).inDays;
    return (elapsed + 1).clamp(1, kProgramDays);
  }

  /// e.g. "28-Day Muscle Gain" — driven by the user's primary goal.
  String get programTitle {
    final p = _profile;
    final goal = (p != null && p.goals.isNotEmpty)
        ? p.goals.first
        : FitnessGoal.improveFitness;
    final what = switch (goal) {
      FitnessGoal.loseWeight => 'Fat Burn',
      FitnessGoal.buildMuscle => 'Muscle Gain',
      FitnessGoal.improveFitness => 'Total Fitness',
      _ => 'Body Recomp',
    };
    return '$kProgramDays-Day $what';
  }

  /// The session for the active day (drives the Home "Start Now" button).
  PlannedSession? get activeDaySession {
    for (final st in _program) {
      for (final d in st.days) {
        if (d.status == DayStatus.active) return d.session;
      }
    }
    return todaySession;
  }

  /// 0-based number of whole weeks since the plan began (drives progression).
  int get weekIndex => DateTime.now().difference(_startDate).inDays ~/ 7;

  Future<void> _restore() async {
    final prog = await _storage.loadPlanProgress();
    if (prog != null) {
      final iso = prog['startDate'] as String?;
      _startDate = iso != null
          ? (DateTime.tryParse(iso) ?? DateTime.now())
          : DateTime.now();
      final ids = (prog['completedIds'] as List?)?.cast<String>() ?? const [];
      _completedIds
        ..clear()
        ..addAll(ids);
    } else {
      _startDate = DateTime.now();
      await _persist();
    }
    _restored = true;
    _regenerate();
  }

  /// Called when the profile changes (after onboarding or an edit). Generating
  /// a brand-new plan also (re)starts the progression clock.
  void updateProfile(UserProfile profile, {bool resetStart = false}) {
    _profile = profile;
    if (resetStart) {
      _startDate = DateTime.now();
      _completedIds.clear();
      _persist();
    }
    if (_restored) _regenerate();
  }

  void _regenerate() {
    final p = _profile;
    if (p == null) return;
    _plan = _engine.generate(p, week: weekIndex);
    _program = _buildProgram(p);
    notifyListeners();
  }

  /// Builds the Day 1 … Day 28 timeline by cycling the weekly split across the
  /// program and advancing the engine's week every 7 days (so volume ramps).
  /// Cached here — never recomputed on a widget rebuild.
  List<ProgramStage> _buildProgram(UserProfile p) {
    final cur = currentDay;
    final names = _stageNames(p);
    final days = <ProgramDay>[];
    for (var d = 1; d <= kProgramDays; d++) {
      final wkPlan = _engine.generate(p, week: (d - 1) ~/ 7);
      final session = wkPlan.sessions[(d - 1) % wkPlan.sessions.length];
      final status = d < cur
          ? DayStatus.done
          : (d == cur ? DayStatus.active : DayStatus.upcoming);
      days.add(ProgramDay(day: d, session: session, status: status));
    }
    final stages = <ProgramStage>[];
    final stageCount = kProgramDays ~/ kDaysPerStage;
    for (var st = 0; st < stageCount; st++) {
      stages.add(ProgramStage(
        index: st,
        name: names[st % names.length],
        days: days.sublist(st * kDaysPerStage, (st + 1) * kDaysPerStage),
      ));
    }
    return stages;
  }

  List<String> _stageNames(UserProfile p) {
    final goal = p.goals.isNotEmpty ? p.goals.first : FitnessGoal.improveFitness;
    return switch (goal) {
      FitnessGoal.buildMuscle => const [
          'Muscle Awakening',
          'Build the Base',
          'Widen Your Frame',
          'Bulk & Power Up',
        ],
      FitnessGoal.loseWeight => const [
          'Ignite',
          'Burn Steady',
          'Shred Mode',
          'Define & Tone',
        ],
      _ => const [
          'Foundation',
          'Build Momentum',
          'Level Up',
          'Peak Form',
        ],
    };
  }

  PlannedSession? get todaySession => _plan?.sessionForToday(DateTime.now());

  int get sessionsThisWeek => _plan?.sessionsPerWeek ?? 0;

  int get completedThisWeek =>
      _plan?.sessions.where(isComplete).length ?? 0;

  double get weekProgress =>
      sessionsThisWeek == 0 ? 0 : completedThisWeek / sessionsThisWeek;

  /// Calories / minutes banked from completed sessions this week.
  int get caloriesThisWeek => _plan == null
      ? 0
      : _plan!.sessions
          .where(isComplete)
          .fold(0, (sum, s) => sum + s.estCalories);

  int get activeMinutesThisWeek => _plan == null
      ? 0
      : _plan!.sessions
          .where(isComplete)
          .fold(0, (sum, s) => sum + s.estMinutes);

  bool isComplete(PlannedSession s) => _completedIds.contains(s.id);

  Future<void> markComplete(PlannedSession s) async {
    if (_completedIds.add(s.id)) {
      await _persist();
      notifyListeners();
    }
  }

  /// Marks a session done by id (used by the session screen, which only holds
  /// the adapted [Workout]). No-ops for library workouts not in the plan.
  Future<void> markCompleteById(String id) async {
    final inPlan = _plan?.sessions.any((s) => s.id == id) ?? false;
    if (inPlan && _completedIds.add(id)) {
      await _persist();
      notifyListeners();
    }
  }

  Future<void> _persist() => _storage.savePlanProgress({
        'startDate': _startDate.toIso8601String(),
        'completedIds': _completedIds.toList(),
      });
}
