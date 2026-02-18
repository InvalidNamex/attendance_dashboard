import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/constants.dart';
import '../../core/di/injection.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(_loadInitial());

  static ThemeMode _loadInitial() {
    final prefs = getIt<SharedPreferences>();
    final value = prefs.getString(AppConstants.keyThemeMode);
    if (value == 'dark') return ThemeMode.dark;
    return ThemeMode.light;
  }

  Future<void> toggleTheme() async {
    final newMode = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    emit(newMode);
    final prefs = getIt<SharedPreferences>();
    await prefs.setString(
      AppConstants.keyThemeMode,
      newMode == ThemeMode.dark ? 'dark' : 'light',
    );
  }

  bool get isDark => state == ThemeMode.dark;
}
