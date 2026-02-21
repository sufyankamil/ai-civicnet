import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  static const _boxName = 'settings';
  static const _themeKey = 'themeMode';

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  /// Must be called once during app startup (after Hive.initFlutter).
  Future<void> init() async {
    final box = await Hive.openBox(_boxName);
    final saved = box.get(_themeKey, defaultValue: 'system') as String;
    _themeMode = _fromString(saved);
  }

  Future<void> toggleTheme(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    final box = await Hive.openBox(_boxName);
    await box.put(_themeKey, _toString(mode));
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static String _toString(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        _ => 'system',
      };

  static ThemeMode _fromString(String s) => switch (s) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
}
