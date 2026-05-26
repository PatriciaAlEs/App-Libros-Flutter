import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';

final appThemeControllerProvider =
    StateNotifierProvider<AppThemeController, ReadingTrackerTheme>(
      (ref) => AppThemeController(),
    );

class AppThemeController extends StateNotifier<ReadingTrackerTheme> {
  AppThemeController() : super(ReadingTrackerTheme.burgundy) {
    _loadTheme();
  }

  static const _storageKey = 'reading_tracker_theme';

  Future<void> setTheme(ReadingTrackerTheme theme) async {
    state = theme;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storageKey, theme.id);
  }

  Future<void> _loadTheme() async {
    final preferences = await SharedPreferences.getInstance();
    state = ReadingTrackerTheme.fromId(preferences.getString(_storageKey));
  }
}
