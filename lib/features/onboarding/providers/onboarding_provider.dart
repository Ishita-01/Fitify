import 'package:flutter/foundation.dart';

import '../../../data/models/onboarding_enums.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/services/local_storage_service.dart';

/// Holds the in-progress onboarding answers and persists them when complete.
class OnboardingProvider extends ChangeNotifier {
  OnboardingProvider(this._storage) {
    _hydrate();
  }

  final LocalStorageService _storage;

  UserProfile _profile = const UserProfile(
    heightCm: 170,
    currentWeightKg: 70,
    targetWeightKg: 65,
  );
  UserProfile get profile => _profile;

  /// Load a previously-saved profile at startup so a returning user (or a dev
  /// running with onboarding skipped) sees their real, personalised data.
  Future<void> _hydrate() async {
    final saved = await _storage.loadProfile();
    if (saved != null) {
      _profile = saved;
      notifyListeners();
    }
  }

  void _update(UserProfile next) {
    _profile = next;
    notifyListeners();
  }

  // ---- Single-value setters ----
  void setGender(Gender v) => _update(_profile.copyWith(gender: v));
  void setCurrentBodyShape(BodyShape v) =>
      _update(_profile.copyWith(currentBodyShape: v));
  void setDesiredBodyShape(DesiredShape v) =>
      _update(_profile.copyWith(desiredBodyShape: v));
  void setHeight(int cm) => _update(_profile.copyWith(heightCm: cm));
  void setCurrentWeight(int kg) =>
      _update(_profile.copyWith(currentWeightKg: kg));
  void setTargetWeight(int kg) => _update(_profile.copyWith(targetWeightKg: kg));
  void setLastWorkout(WorkoutRecency v) =>
      _update(_profile.copyWith(lastWorkout: v));
  void setIntensity(WorkoutIntensity v) =>
      _update(_profile.copyWith(intensity: v));
  void setName(String v) => _update(_profile.copyWith(name: v));

  // ---- Multi-select toggles ----
  void toggleGoal(FitnessGoal goal) {
    final goals = List<FitnessGoal>.from(_profile.goals);
    goals.contains(goal) ? goals.remove(goal) : goals.add(goal);
    _update(_profile.copyWith(goals: goals));
  }

  void toggleActivity(Activity activity) {
    final acts = List<Activity>.from(_profile.activities);
    acts.contains(activity) ? acts.remove(activity) : acts.add(activity);
    _update(_profile.copyWith(activities: acts));
  }

  bool isGoalSelected(FitnessGoal g) => _profile.goals.contains(g);
  bool isActivitySelected(Activity a) => _profile.activities.contains(a);

  /// Persist the completed profile locally.
  Future<void> finish() async {
    _profile = _profile.copyWith(onboardingComplete: true);
    await _storage.saveProfile(_profile);
    notifyListeners();
  }
}
