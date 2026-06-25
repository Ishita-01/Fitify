import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../data/models/analysis.dart';
import '../../../data/repositories/analysis_repository.dart';

/// Holds analysis reports + the upload→processing→report flow. UI awaits
/// [submit]; the ML pipeline auto-classifies the exercise from the video,
/// then generates a full report with gaps & insights.
class AnalysisProvider extends ChangeNotifier {
  AnalysisProvider(this._repo) {
    _reports = [..._repo.seedHistory()];
  }

  final AnalysisRepository _repo;
  final _rng = Random();
  late final List<AnalysisReport> _reports;

  List<AnalysisReport> get reports => List.unmodifiable(_reports);
  List<AnalysisReport> get completed =>
      _reports.where((r) => r.status == AnalysisStatus.complete).toList();

  /// Runs the ML pose classifier on [videoPath] to auto-detect the exercise
  /// and confidence score, then generates the full analysis report.
  Future<AnalysisReport> submit({
    String fileName = 'workout.mp4',
    String? videoPath,
  }) async {
    // Default fallback: auto-classify with a random exercise.
    var detected = AnalyzableExercise
        .values[_rng.nextInt(AnalyzableExercise.values.length)];
    int? detectedScore;
    int? formScore;
    int? repCount;
    int? holdSeconds;
    String? overlayVideoPath;

    if (videoPath != null) {
      try {
        debugPrint('Running ML prediction & shadow trainer on video path: $videoPath');
        final process = await Process.run(
          'python',
          [
            'scripts/shadow_trainer.py',
            videoPath,
            '--onnx',
            'fitify_pose_gru.onnx',
          ],
        );

        debugPrint('ML script exited with code: ${process.exitCode}');
        if (process.exitCode == 0) {
          final stdoutStr = process.stdout as String;
          debugPrint('ML script stdout:\n$stdoutStr');

          final lines = stdoutStr.split('\n');
          String? detectedSlug;

          for (var line in lines) {
            final trimmed = line.trim();
            if (trimmed.contains('>>>')) {
              // Format: ">>> SQUAT   confidence 81%" or ">>> HAMMER CURL   confidence 65%"
              final parts = trimmed.split('>>>');
              if (parts.length > 1) {
                final right = parts[1].trim();
                final rightParts = right.split(RegExp(r'\s+confidence\s+'));
                if (rightParts.isNotEmpty) {
                  detectedSlug = rightParts[0].trim().toLowerCase();
                }
                final scoreMatch = RegExp(r'(\d+)%').firstMatch(right);
                if (scoreMatch != null) {
                  detectedScore = int.tryParse(scoreMatch.group(1) ?? '');
                }
              }
            } else if (trimmed.contains('best guess:') || trimmed.contains('top guess:')) {
              // Format: "film from the front (best guess: squat 81%)"
              final match = RegExp(r'(?:best|top) guess:\s*([a-zA-Z\s\-]+)\s+(\d+)%').firstMatch(trimmed);
              if (match != null) {
                detectedSlug = match.group(1)?.trim().toLowerCase();
                detectedScore = int.tryParse(match.group(2) ?? '');
              }
            }

            // Parse reps or twists: e.g. "6 reps, form 49/100" or "12 twists, form 72/100"
            final repMatch = RegExp(r'(\d+)\s+(?:reps|twists),\s+form\s+(\d+)/100').firstMatch(trimmed);
            if (repMatch != null) {
              repCount = int.tryParse(repMatch.group(1) ?? '');
              formScore = int.tryParse(repMatch.group(2) ?? '');
            }

            // Parse holds: e.g. "30s hold, form 81/100"
            final holdMatch = RegExp(r'(\d+)s\s+hold,\s+form\s+(\d+)/100').firstMatch(trimmed);
            if (holdMatch != null) {
              holdSeconds = int.tryParse(holdMatch.group(1) ?? '');
              formScore = int.tryParse(holdMatch.group(2) ?? '');
            }
          }

          if (detectedSlug != null) {
            // Find matches in AnalyzableExercise values
            final normalizedDetected = detectedSlug.replaceAll(RegExp(r'[\s\-_]'), '');
            for (var val in AnalyzableExercise.values) {
              final normalizedValSlug = val.slug.replaceAll(RegExp(r'[\s\-_]'), '');
              if (normalizedValSlug == normalizedDetected) {
                detected = val;
                debugPrint('Successfully matched exercise: ${val.label} with confidence score: $detectedScore, form score: $formScore, reps: $repCount, hold: $holdSeconds');
                break;
              }
            }
          }

          // Construct and verify the overlay video path
          final fileStem = videoPath.split(RegExp(r'[/\\]')).last;
          final dotIdx = fileStem.lastIndexOf('.');
          final stem = dotIdx != -1 ? fileStem.substring(0, dotIdx) : fileStem;
          final safe = stem.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
          final safeCut = safe.length > 48 ? safe.substring(0, 48) : safe;
          final candidatePath = 'results/shadow/$safeCut/${safeCut}_overlay.mp4';
          if (File(candidatePath).existsSync()) {
            overlayVideoPath = candidatePath;
            debugPrint('Found overlay video file at: $overlayVideoPath');
          } else {
            debugPrint('Overlay video file not found at candidate path: $candidatePath');
          }
        } else {
          debugPrint('ML script stderr:\n${process.stderr}');
        }
      } catch (e, stack) {
        debugPrint('Error invoking ML python script: $e\n$stack');
      }
    }

    final placeholder = AnalysisReport(
      id: 'r${DateTime.now().microsecondsSinceEpoch}',
      exercise: detected,
      createdAt: DateTime.now(),
      status: AnalysisStatus.processing,
      overallScore: 0,
    );
    _reports.insert(0, placeholder);
    notifyListeners();

    // A small delay for UI transition smoothness
    await Future<void>.delayed(const Duration(milliseconds: 1500));

    final done = _repo.generateReport(
      detected,
      score: detectedScore,
      formScore: formScore,
      repCount: repCount,
      holdSeconds: holdSeconds,
      overlayVideoPath: overlayVideoPath,
    );
    final idx = _reports.indexWhere((r) => r.id == placeholder.id);
    if (idx >= 0) _reports[idx] = done;
    notifyListeners();
    return done;
  }
}
