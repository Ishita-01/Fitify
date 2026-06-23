import 'package:flutter/material.dart';

import '../../../data/services/local_storage_service.dart';

/// Metric ⇄ Imperial unit preference, persisted. Provides display formatters so
/// every weight/height in the app renders in the user's chosen units.
class UnitsController extends ChangeNotifier {
  UnitsController(this._storage) {
    _hydrate();
  }

  final LocalStorageService _storage;
  bool _imperial = false;
  bool get imperial => _imperial;
  String get label => _imperial ? 'Imperial (lb, ft)' : 'Metric (kg, cm)';

  Future<void> _hydrate() async {
    _imperial = await _storage.loadImperial();
    notifyListeners();
  }

  Future<void> setImperial(bool v) async {
    if (v == _imperial) return;
    _imperial = v;
    notifyListeners();
    await _storage.saveImperial(v);
  }

  void toggle() => setImperial(!_imperial);

  /// Weight in display units (input is kg).
  String weight(num kg) =>
      _imperial ? '${(kg * 2.20462).round()} lb' : '${kg.round()} kg';

  /// Just the numeric weight value (no unit suffix).
  String weightValue(num kg) =>
      _imperial ? '${(kg * 2.20462).round()}' : '${kg.round()}';

  String get weightUnit => _imperial ? 'lb' : 'kg';

  /// Height in display units (input is cm).
  String height(num cm) => _imperial ? _ftIn(cm) : '${cm.round()} cm';

  static String _ftIn(num cm) {
    final totalInches = cm / 2.54;
    final ft = totalInches ~/ 12;
    final inch = (totalInches % 12).round();
    return "$ft'$inch\"";
  }
}
