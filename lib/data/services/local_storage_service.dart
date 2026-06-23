import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';

/// Thin wrapper over [SharedPreferences] for persisting the user profile.
/// Swap this implementation for a remote API client later without touching
/// the rest of the app.
class LocalStorageService {
  static const _profileKey = 'user_profile';
  static const _planProgressKey = 'plan_progress';
  static const _themeDarkKey = 'theme_dark';
  static const _imperialKey = 'units_imperial';

  Future<void> saveThemeDark(bool dark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeDarkKey, dark);
  }

  Future<bool> loadThemeDark() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_themeDarkKey) ?? false;
  }

  Future<void> saveImperial(bool imperial) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_imperialKey, imperial);
  }

  Future<bool> loadImperial() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_imperialKey) ?? false;
  }

  Future<void> saveProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
  }

  /// Persists lightweight plan progress (start date + completed session ids).
  /// The plan itself is regenerated deterministically from the profile, so we
  /// only store what can't be recomputed.
  Future<void> savePlanProgress(Map<String, dynamic> progress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_planProgressKey, jsonEncode(progress));
  }

  Future<Map<String, dynamic>?> loadPlanProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_planProgressKey);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<UserProfile?> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileKey);
    if (raw == null) return null;
    try {
      return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileKey);
  }
}
