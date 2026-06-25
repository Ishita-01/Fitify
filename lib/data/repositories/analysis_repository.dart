import 'dart:math';

import '../models/analysis.dart';

/// Contract for the video-analysis flagship. A real impl would upload the
/// video to a Pose/Video Analysis ML service and poll for the result; this mock
/// generates a plausible report so the UI is fully functional offline.
abstract class AnalysisRepository {
  /// Sample past reports to seed history.
  List<AnalysisReport> seedHistory();

  /// Produce a completed report for [exercise] (stands in for the ML result).
  AnalysisReport generateReport(
    AnalyzableExercise exercise, {
    int? score,
    int? formScore,
    int? repCount,
    int? holdSeconds,
    String? overlayVideoPath,
  });
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
  AnalysisReport generateReport(
    AnalyzableExercise exercise, {
    int? score,
    int? formScore,
    int? repCount,
    int? holdSeconds,
    String? overlayVideoPath,
  }) {
    // If formScore is provided directly from the ML script, use it. Otherwise,
    // introduce a small +/- 3 point fluctuation on confidence.
    final base = formScore ?? (score != null
        ? (score - 3 + _rng.nextInt(7)).clamp(40, 99)
        : (70 + _rng.nextInt(25))); // 70..94
    return _build(
      exercise,
      DateTime.now(),
      base,
      repCount: repCount,
      holdSeconds: holdSeconds,
      overlayVideoPath: overlayVideoPath,
    );
  }

  AnalysisReport _build(
    AnalyzableExercise ex,
    DateTime when,
    int overall, {
    int? repCount,
    int? holdSeconds,
    String? overlayVideoPath,
  }) {
    int near() => (overall - 8 + _rng.nextInt(16)).clamp(40, 99);
    final metrics = [
      MetricScore('Posture', near()),
      MetricScore('Movement', near()),
      MetricScore('Range of Motion', near()),
      MetricScore('Joint Angles', near()),
      MetricScore('Stability', near()),
    ];

    // Compute overall score dynamically as the average of the metrics
    final dynamicOverall = (metrics.map((m) => m.score).reduce((a, b) => a + b) / metrics.length).round();

    final issuePool = _issuesFor(ex);
    final recsPool = _recsFor(ex);
    final issueCount = dynamicOverall >= 88 ? 1 : (dynamicOverall >= 78 ? 2 : 3);

    return AnalysisReport(
      id: 'r${when.microsecondsSinceEpoch}',
      exercise: ex,
      createdAt: when,
      status: AnalysisStatus.complete,
      overallScore: dynamicOverall,
      metrics: metrics,
      issues: issuePool.take(issueCount).toList(),
      recommendations: recsPool.take(issueCount + 1).toList(),
      repCount: repCount,
      holdSeconds: holdSeconds,
      overlayVideoPath: overlayVideoPath,
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
      case AnalyzableExercise.deadlift:
        return const [
          DetectedIssue('Rounded back', 'major'),
          DetectedIssue('Bar drifting away from shins', 'moderate'),
          DetectedIssue('Hips rising too early', 'moderate'),
        ];
      case AnalyzableExercise.romanianDeadlift:
        return const [
          DetectedIssue('Rounding at the lower back', 'major'),
          DetectedIssue('Bending the knees too much', 'moderate'),
          DetectedIssue('Limited hip hinge depth', 'minor'),
        ];
      case AnalyzableExercise.shoulderPress:
        return const [
          DetectedIssue('Excessive lower-back arch', 'moderate'),
          DetectedIssue('Uneven left/right press', 'minor'),
          DetectedIssue('Incomplete lockout', 'minor'),
        ];
      case AnalyzableExercise.pullUp:
        return const [
          DetectedIssue('Partial range — chin not over the bar', 'moderate'),
          DetectedIssue('Using leg kip for momentum', 'minor'),
          DetectedIssue('Shrugged shoulders at the bottom', 'moderate'),
        ];
      case AnalyzableExercise.hammerCurl:
        return const [
          DetectedIssue('Swinging the elbows', 'moderate'),
          DetectedIssue('Incomplete stretch at the bottom', 'minor'),
          DetectedIssue('Wrist rolling inward', 'minor'),
        ];
      case AnalyzableExercise.lateralRaise:
        return const [
          DetectedIssue('Raising above shoulder height', 'moderate'),
          DetectedIssue('Using momentum / trap shrug', 'moderate'),
          DetectedIssue('Bent elbows dropping the load', 'minor'),
        ];
      case AnalyzableExercise.legRaises:
        return const [
          DetectedIssue('Lower-back lifting off the floor', 'major'),
          DetectedIssue('Bending the knees too early', 'minor'),
          DetectedIssue('Dropping legs too fast', 'moderate'),
        ];
      case AnalyzableExercise.russianTwist:
        return const [
          DetectedIssue('Rotating from arms, not the torso', 'moderate'),
          DetectedIssue('Rounded back', 'moderate'),
          DetectedIssue('Uneven left/right rotation', 'minor'),
        ];
      case AnalyzableExercise.hipThrust:
        return const [
          DetectedIssue('Incomplete hip lockout at the top', 'moderate'),
          DetectedIssue('Over-arching the lower back', 'moderate'),
          DetectedIssue('Heels too far forward', 'minor'),
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
      case AnalyzableExercise.deadlift:
        return const [
          'Maintain a neutral spine — hinge from the hips.',
          'Keep the bar close, dragging up your shins.',
          'Push the floor away; let hips and chest rise together.',
        ];
      case AnalyzableExercise.romanianDeadlift:
        return const [
          'Keep a soft knee bend and push the hips back.',
          'Stop when you feel the hamstring stretch — keep the spine flat.',
          'Drag the weight close to your legs the whole way.',
        ];
      case AnalyzableExercise.shoulderPress:
        return const [
          'Squeeze your glutes to stop the back arching.',
          'Press both arms evenly to lockout.',
          'Finish with biceps by your ears.',
        ];
      case AnalyzableExercise.pullUp:
        return const [
          'Pull until your chin clears the bar each rep.',
          'Start from a full dead hang with shoulders pulled down.',
          'Control the descent — avoid kipping for momentum.',
        ];
      case AnalyzableExercise.hammerCurl:
        return const [
          'Pin your elbows to your sides — no swinging.',
          'Fully straighten at the bottom for a complete stretch.',
          'Keep a neutral wrist throughout the curl.',
        ];
      case AnalyzableExercise.lateralRaise:
        return const [
          'Raise only to shoulder height — no higher.',
          'Lead with the elbows and keep the traps relaxed.',
          'Lower slowly; resist the weight on the way down.',
        ];
      case AnalyzableExercise.legRaises:
        return const [
          'Press your lower back into the floor the whole set.',
          'Keep your legs straighter for a longer lever.',
          'Lower with control — about a 2-second descent.',
        ];
      case AnalyzableExercise.russianTwist:
        return const [
          'Rotate from your torso, not just your arms.',
          'Sit tall with a flat back and braced core.',
          'Touch evenly on both sides for balanced rotation.',
        ];
      case AnalyzableExercise.hipThrust:
        return const [
          'Drive hips to a full lockout — squeeze the glutes at the top.',
          'Keep ribs down to avoid arching the lower back.',
          'Set heels under your knees for the best line of drive.',
        ];
    }
  }
}
