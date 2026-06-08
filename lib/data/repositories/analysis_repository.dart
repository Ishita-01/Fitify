import 'dart:math';

import '../models/analysis.dart';

/// Contract for the video-analysis flagship. A real impl would upload the
/// video to a Pose/Video Analysis ML service and poll for the result; this mock
/// generates a plausible report so the UI is fully functional offline.
abstract class AnalysisRepository {
  /// Sample past reports to seed history.
  List<AnalysisReport> seedHistory();

  /// Produce a completed report for [exercise] (stands in for the ML result).
  AnalysisReport generateReport(AnalyzableExercise exercise);
}

class MockAnalysisRepository implements AnalysisRepository {
  final _rng = Random();

  @override
  List<AnalysisReport> seedHistory() => [
        _build(AnalyzableExercise.squat,
            DateTime.now().subtract(const Duration(days: 2)), 82),
        _build(AnalyzableExercise.pushUp,
            DateTime.now().subtract(const Duration(days: 6)), 74),
      ];

  @override
  AnalysisReport generateReport(AnalyzableExercise exercise) {
    final base = 70 + _rng.nextInt(25); // 70..94
    return _build(exercise, DateTime.now(), base);
  }

  AnalysisReport _build(AnalyzableExercise ex, DateTime when, int overall) {
    int near() => (overall - 8 + _rng.nextInt(16)).clamp(40, 99);
    final metrics = [
      MetricScore('Posture', near()),
      MetricScore('Movement', near()),
      MetricScore('Range of Motion', near()),
      MetricScore('Joint Angles', near()),
      MetricScore('Stability', near()),
    ];

    final issuePool = _issuesFor(ex);
    final recsPool = _recsFor(ex);
    final issueCount = overall >= 88 ? 1 : (overall >= 78 ? 2 : 3);

    return AnalysisReport(
      id: 'r${when.microsecondsSinceEpoch}',
      exercise: ex,
      createdAt: when,
      status: AnalysisStatus.complete,
      overallScore: overall,
      metrics: metrics,
      issues: issuePool.take(issueCount).toList(),
      recommendations: recsPool.take(issueCount + 1).toList(),
    );
  }

  List<DetectedIssue> _issuesFor(AnalyzableExercise ex) {
    switch (ex) {
      case AnalyzableExercise.squat:
        return const [
          DetectedIssue('Shallow squat depth', 'moderate'),
          DetectedIssue('Knee valgus (knees caving in)', 'major'),
          DetectedIssue('Forward lean', 'minor'),
        ];
      case AnalyzableExercise.pushUp:
        return const [
          DetectedIssue('Sagging hips', 'moderate'),
          DetectedIssue('Flared elbows', 'minor'),
          DetectedIssue('Partial range of motion', 'moderate'),
        ];
      case AnalyzableExercise.plank:
        return const [
          DetectedIssue('Hips too high', 'minor'),
          DetectedIssue('Lower-back arch', 'moderate'),
          DetectedIssue('Head dropping', 'minor'),
        ];
      case AnalyzableExercise.lunges:
        return const [
          DetectedIssue('Front knee past toes', 'moderate'),
          DetectedIssue('Torso leaning forward', 'minor'),
          DetectedIssue('Unstable back leg', 'moderate'),
        ];
      case AnalyzableExercise.deadlift:
        return const [
          DetectedIssue('Rounded back', 'major'),
          DetectedIssue('Bar drifting away from shins', 'moderate'),
          DetectedIssue('Hips rising too early', 'moderate'),
        ];
      case AnalyzableExercise.shoulderPress:
        return const [
          DetectedIssue('Excessive lower-back arch', 'moderate'),
          DetectedIssue('Uneven left/right press', 'minor'),
          DetectedIssue('Incomplete lockout', 'minor'),
        ];
    }
  }

  List<String> _recsFor(AnalyzableExercise ex) {
    switch (ex) {
      case AnalyzableExercise.squat:
        return const [
          'Increase squat depth — aim for thighs parallel to the floor.',
          'Drive your knees outward to keep them over your toes.',
          'Keep your chest upright and core braced.',
          'Try box squats to groove consistent depth.',
        ];
      case AnalyzableExercise.pushUp:
        return const [
          'Brace your core to keep hips in line with shoulders.',
          'Tuck elbows to ~45° from your torso.',
          'Lower until your chest is just above the floor.',
        ];
      case AnalyzableExercise.plank:
        return const [
          'Lower your hips so your body forms a straight line.',
          'Tuck your pelvis to remove the lower-back arch.',
          'Keep your neck neutral — gaze just ahead of your hands.',
        ];
      case AnalyzableExercise.lunges:
        return const [
          'Keep your front shin vertical; knee over the ankle.',
          'Stay tall through the torso.',
          'Slow the descent for more control and balance.',
        ];
      case AnalyzableExercise.deadlift:
        return const [
          'Maintain a neutral spine — hinge from the hips.',
          'Keep the bar close, dragging up your shins.',
          'Push the floor away; let hips and chest rise together.',
        ];
      case AnalyzableExercise.shoulderPress:
        return const [
          'Squeeze your glutes to stop the back arching.',
          'Press both arms evenly to lockout.',
          'Finish with biceps by your ears.',
        ];
    }
  }
}
