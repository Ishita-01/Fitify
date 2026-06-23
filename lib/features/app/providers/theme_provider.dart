import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/services/local_storage_service.dart';

/// Drives the app-wide light/dark toggle. Holds the mode, mirrors it into
/// [AppColors] (so the central palette resolves correctly), persists it, and
/// notifies `MaterialApp` to rebuild with the new [AppTheme.current].
class ThemeController extends ChangeNotifier {
  ThemeController(this._storage) {
    _hydrate();
  }

  final LocalStorageService _storage;
  bool _isDark = false;
  bool get isDark => _isDark;

  Future<void> _hydrate() async {
    _isDark = await _storage.loadThemeDark();
    AppColors.setMode(_isDark);
    notifyListeners();
  }

  Future<void> setDark(bool dark) async {
    if (dark == _isDark) return;
    _isDark = dark;
    AppColors.setMode(dark);
    notifyListeners();
    await _storage.saveThemeDark(dark);
  }

  void toggle() => setDark(!_isDark);
}
