import 'onboarding_enums.dart';

/// The user's onboarding answers and profile. Serializable so it can be
/// persisted locally now and POSTed to the backend later without changes.
class UserProfile {
  final String? name;
  final Gender? gender;
  final List<FitnessGoal> goals;
  final BodyShape? currentBodyShape;
  final DesiredShape? desiredBodyShape;
  final int? heightCm;
  final int? currentWeightKg;
  final int? targetWeightKg;
  final WorkoutRecency? lastWorkout;
  final WorkoutIntensity? intensity;
  final List<Activity> activities;
  final bool onboardingComplete;

  const UserProfile({
    this.name,
    this.gender,
    this.goals = const [],
    this.currentBodyShape,
    this.desiredBodyShape,
    this.heightCm,
    this.currentWeightKg,
    this.targetWeightKg,
    this.lastWorkout,
    this.intensity,
    this.activities = const [],
    this.onboardingComplete = false,
  });

  UserProfile copyWith({
    String? name,
    Gender? gender,
    List<FitnessGoal>? goals,
    BodyShape? currentBodyShape,
    DesiredShape? desiredBodyShape,
    int? heightCm,
    int? currentWeightKg,
    int? targetWeightKg,
    WorkoutRecency? lastWorkout,
    WorkoutIntensity? intensity,
    List<Activity>? activities,
    bool? onboardingComplete,
  }) {
    return UserProfile(
      name: name ?? this.name,
      gender: gender ?? this.gender,
      goals: goals ?? this.goals,
      currentBodyShape: currentBodyShape ?? this.currentBodyShape,
      desiredBodyShape: desiredBodyShape ?? this.desiredBodyShape,
      heightCm: heightCm ?? this.heightCm,
      currentWeightKg: currentWeightKg ?? this.currentWeightKg,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      lastWorkout: lastWorkout ?? this.lastWorkout,
      intensity: intensity ?? this.intensity,
      activities: activities ?? this.activities,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'gender': gender?.name,
        'goals': goals.map((g) => g.name).toList(),
        'currentBodyShape': currentBodyShape?.name,
        'desiredBodyShape': desiredBodyShape?.name,
        'heightCm': heightCm,
        'currentWeightKg': currentWeightKg,
        'targetWeightKg': targetWeightKg,
        'lastWorkout': lastWorkout?.name,
        'intensity': intensity?.name,
        'activities': activities.map((a) => a.name).toList(),
        'onboardingComplete': onboardingComplete,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    List<T> list<T extends Enum>(List<T> values, dynamic raw) {
      if (raw is! List) return const [];
      return raw
          .map((e) => enumFromName(values, e as String?))
          .whereType<T>()
          .toList();
    }

    return UserProfile(
      name: json['name'] as String?,
      gender: enumFromName(Gender.values, json['gender'] as String?),
      goals: list(FitnessGoal.values, json['goals']),
      currentBodyShape:
          enumFromName(BodyShape.values, json['currentBodyShape'] as String?),
      desiredBodyShape:
          enumFromName(DesiredShape.values, json['desiredBodyShape'] as String?),
      heightCm: json['heightCm'] as int?,
      currentWeightKg: json['currentWeightKg'] as int?,
      targetWeightKg: json['targetWeightKg'] as int?,
      lastWorkout:
          enumFromName(WorkoutRecency.values, json['lastWorkout'] as String?),
      intensity:
          enumFromName(WorkoutIntensity.values, json['intensity'] as String?),
      activities: list(Activity.values, json['activities']),
      onboardingComplete: json['onboardingComplete'] as bool? ?? false,
    );
  }
}
