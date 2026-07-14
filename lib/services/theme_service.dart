import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../models/app_settings.dart';
import 'hive_service.dart';

/// Controls the app's Light/Dark theme. Persisted in Hive (AppSettings),
/// and exposes a static `isDark` flag that AppColors reads synchronously
/// (no BuildContext needed) so every screen's existing `AppColors.xxx`
/// references automatically follow the live toggle.
class ThemeService extends ChangeNotifier {
  static final ThemeService instance = ThemeService._internal();
  ThemeService._internal();

  static bool isDark = true;

  static Box<AppSettings> get _box => Hive.box<AppSettings>(HiveBoxes.appSettings);

  /// Call once at startup after Hive is initialized, to load the saved
  /// preference before the first frame renders.
  static void loadInitial() {
    if (_box.isNotEmpty) {
      isDark = _box.getAt(0)!.isDarkMode;
    }
  }

  ThemeMode get themeMode => isDark ? ThemeMode.dark : ThemeMode.light;

  Future<void> setDark(bool value) async {
    isDark = value;
    if (_box.isNotEmpty) {
      final settings = _box.getAt(0)!;
      settings.isDarkMode = value;
      await settings.save();
    }
    notifyListeners();
  }

  Future<void> toggle() => setDark(!isDark);
}
