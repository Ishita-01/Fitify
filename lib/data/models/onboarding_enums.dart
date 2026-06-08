import 'package:flutter/material.dart';

/// Onboarding answer enums. Each carries a display [label] (and where useful an
/// [icon]) so screens stay declarative and JSON stays stable (stored by `name`).

enum Gender {
  male('Male', Icons.male_rounded),
  female('Female', Icons.female_rounded),
  preferNotToSay('Prefer not to say', Icons.remove_rounded);

  const Gender(this.label, this.icon);
  final String label;
  final IconData icon;
}

enum FitnessGoal {
  lookAttractive('Look More Attractive', Icons.auto_awesome_rounded),
  gainConfidence('Gain Confidence', Icons.emoji_emotions_rounded),
  buildMuscle('Build Muscle', Icons.fitness_center_rounded),
  loseWeight('Lose Weight', Icons.monitor_weight_rounded),
  improveFitness('Improve Fitness', Icons.directions_run_rounded),
  increaseVitality('Increase Vitality', Icons.bolt_rounded),
  stayHealthy('Stay Healthy', Icons.favorite_rounded);

  const FitnessGoal(this.label, this.icon);
  final String label;
  final IconData icon;
}

enum BodyShape {
  skinny('Skinny', Icons.accessibility_new_rounded),
  medium('Medium', Icons.accessibility_rounded),
  flabby('Flabby', Icons.airline_seat_recline_normal_rounded),
  muscular('Muscular', Icons.sports_mma_rounded);

  const BodyShape(this.label, this.icon);
  final String label;
  final IconData icon;
}

enum DesiredShape {
  lean('Lean', Icons.straighten_rounded),
  athletic('Athletic', Icons.directions_bike_rounded),
  muscular('Muscular', Icons.sports_mma_rounded),
  fitToned('Fit & Toned', Icons.self_improvement_rounded);

  const DesiredShape(this.label, this.icon);
  final String label;
  final IconData icon;
}

enum WorkoutRecency {
  thisWeek('This Week', Icons.today_rounded),
  withinMonth('Within Last Month', Icons.calendar_month_rounded),
  threeToSixMonths('3–6 Months Ago', Icons.history_rounded),
  moreThanSixMonths('More Than 6 Months Ago', Icons.hourglass_empty_rounded),
  never('Never Worked Out', Icons.spa_rounded);

  const WorkoutRecency(this.label, this.icon);
  final String label;
  final IconData icon;
}

enum WorkoutIntensity {
  easyStart('Easy Start', 'Gentle pace to ease in', Icons.spa_rounded),
  breakSweat('Break a Little Sweat', 'Moderate, steady effort', Icons.water_drop_rounded),
  challenging('Challenging', 'Push yourself each set', Icons.local_fire_department_rounded),
  pushLimits('Push My Limits', 'Maximum intensity', Icons.bolt_rounded);

  const WorkoutIntensity(this.label, this.subtitle, this.icon);
  final String label;
  final String subtitle;
  final IconData icon;
}

enum Activity {
  homeFitness('Home Fitness', Icons.home_rounded),
  calisthenics('Calisthenics', Icons.sports_gymnastics_rounded),
  stretching('Stretching', Icons.accessibility_new_rounded),
  running('Running', Icons.directions_run_rounded),
  yoga('Yoga', Icons.self_improvement_rounded),
  hiit('HIIT', Icons.local_fire_department_rounded),
  mobility('Mobility Training', Icons.accessibility_rounded);

  const Activity(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// Resolve an enum from its stored `name`, returning null if absent/unknown.
T? enumFromName<T extends Enum>(List<T> values, String? name) {
  if (name == null) return null;
  for (final v in values) {
    if (v.name == name) return v;
  }
  return null;
}
