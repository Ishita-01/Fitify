import 'package:flutter/material.dart';

/// Post-workout video analysis domain models. The flagship feature: users
/// upload a recorded video of an exercise, a (future) ML service evaluates it,
/// and a detailed report is returned. No real-time/camera processing.

/// The 12 exercises our pose classifier recognises (must match the model's
/// label map). `slug` is the lower-case name the ML backend returns.
enum AnalyzableExercise {
  squat('Squat', 'squat', Icons.accessibility_new_rounded),
  deadlift('Deadlift', 'deadlift', Icons.fitness_center_rounded),
  romanianDeadlift('Romanian Deadlift', 'romanian deadlift', Icons.straighten_rounded),
  pushUp('Push-Up', 'push-up', Icons.sports_martial_arts_rounded),
  pullUp('Pull-Up', 'pull up', Icons.sports_handball_rounded),
  shoulderPress('Shoulder Press', 'shoulder press', Icons.sports_gymnastics_rounded),
  hammerCurl('Hammer Curl', 'hammer curl', Icons.sports_mma_rounded),
  lateralRaise('Lateral Raise', 'lateral raise', Icons.open_in_full_rounded),
  plank('Plank', 'plank', Icons.airline_seat_flat_rounded),
  legRaises('Leg Raises', 'leg raises', Icons.airline_seat_legroom_extra_rounded),
  russianTwist('Russian Twist', 'russian twist', Icons.rotate_right_rounded),
  hipThrust('Hip Thrust', 'hip thrust', Icons.airline_seat_recline_normal_rounded);

  const AnalyzableExercise(this.label, this.slug, this.icon);
  final String label;
  final String slug;
  final IconData icon;
}

enum AnalysisStatus { processing, complete, failed }

/// A single scored dimension (0–100) shown in the report + radar chart.
class MetricScore {
  final String label;
  final int score; // 0..100
  const MetricScore(this.label, this.score);
}

class DetectedIssue {
  final String title;
  final String severity; // 'minor' | 'moderate' | 'major'
  const DetectedIssue(this.title, this.severity);
}

class AnalysisReport {
  final String id;
  final AnalyzableExercise exercise;
  final DateTime createdAt;
  final AnalysisStatus status;
  final int overallScore; // 0..100

  /// Posture, Movement Quality, Range of Motion, Joint Angles, Stability.
  final List<MetricScore> metrics;
  final List<DetectedIssue> issues;
  final List<String> recommendations;

  const AnalysisReport({
    required this.id,
    required this.exercise,
    required this.createdAt,
    required this.status,
    required this.overallScore,
    this.metrics = const [],
    this.issues = const [],
    this.recommendations = const [],
  });

  AnalysisReport copyWith({
    AnalysisStatus? status,
    int? overallScore,
    List<MetricScore>? metrics,
    List<DetectedIssue>? issues,
    List<String>? recommendations,
  }) {
    return AnalysisReport(
      id: id,
      exercise: exercise,
      createdAt: createdAt,
      status: status ?? this.status,
      overallScore: overallScore ?? this.overallScore,
      metrics: metrics ?? this.metrics,
      issues: issues ?? this.issues,
      recommendations: recommendations ?? this.recommendations,
    );
  }
}
