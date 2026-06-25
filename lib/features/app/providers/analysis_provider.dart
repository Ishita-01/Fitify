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

    if (videoPath != null) {
      try {
        debugPrint('Running ML prediction on video path: $videoPath');
        final process = await Process.run(
          'python',
          [
            'scripts/predict.py',
            '--onnx',
            'fitify_pose_gru.onnx',
            videoPath,
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
          }

          if (detectedSlug != null) {
            // Find matches in AnalyzableExercise values
            final normalizedDetected = detectedSlug.replaceAll(RegExp(r'[\s\-_]'), '');
            for (var val in AnalyzableExercise.values) {
              final normalizedValSlug = val.slug.replaceAll(RegExp(r'[\s\-_]'), '');
              if (normalizedValSlug == normalizedDetected) {
                detected = val;
                debugPrint('Successfully matched exercise: ${val.label} with score: $detectedScore');
                break;
              }
            }
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

    final done = _repo.generateReport(detected, score: detectedScore);
    final idx = _reports.indexWhere((r) => r.id == placeholder.id);
    if (idx >= 0) _reports[idx] = done;
    notifyListeners();
    return done;
  }
}
