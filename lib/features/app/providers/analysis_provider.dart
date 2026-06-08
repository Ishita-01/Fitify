import 'package:flutter/foundation.dart';

import '../../../data/models/analysis.dart';
import '../../../data/repositories/analysis_repository.dart';

/// Holds analysis reports + the upload→processing→report flow. UI awaits
/// [submit]; a placeholder "processing" report appears immediately, then is
/// replaced by the generated result.
class AnalysisProvider extends ChangeNotifier {
  AnalysisProvider(this._repo) {
    _reports = [..._repo.seedHistory()];
  }

  final AnalysisRepository _repo;
  late final List<AnalysisReport> _reports;

  List<AnalysisReport> get reports => List.unmodifiable(_reports);
  List<AnalysisReport> get completed =>
      _reports.where((r) => r.status == AnalysisStatus.complete).toList();

  AnalyzableExercise selected = AnalyzableExercise.squat;
  void select(AnalyzableExercise e) {
    selected = e;
    notifyListeners();
  }

  /// Simulates uploading [fileName] for [exercise] and running the ML pipeline.
  Future<AnalysisReport> submit(AnalyzableExercise exercise,
      {String fileName = 'workout.mp4'}) async {
    final placeholder = AnalysisReport(
      id: 'r${DateTime.now().microsecondsSinceEpoch}',
      exercise: exercise,
      createdAt: DateTime.now(),
      status: AnalysisStatus.processing,
      overallScore: 0,
    );
    _reports.insert(0, placeholder);
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 2600));

    final done = _repo.generateReport(exercise);
    final idx = _reports.indexWhere((r) => r.id == placeholder.id);
    if (idx >= 0) _reports[idx] = done;
    notifyListeners();
    return done;
  }
}
